using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QLPT.API.Models;
using QLPT.API.Services;

namespace QLPT.API.Controllers;

[Route("api/[controller]")]
[ApiController]
public class BaoTraPhongController : ControllerBase
{
    private readonly Klcn052QuanLyPhongTroContext _context;
    public BaoTraPhongController(Klcn052QuanLyPhongTroContext context) => _context = context;

    private const string ChoXuLy = "Chờ xử lý";
    private const string DaTuChoi = "Đã từ chối";

    // Lấy tên khóa chính từ EF metadata, không cần sửa bảng/model SQL.
    private string PrimaryKeyName => _context.Model.FindEntityType(typeof(BaoTraPhong))!
        .FindPrimaryKey()!.Properties.Single().Name;

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll()
    {
        try
        {
            var key = PrimaryKeyName;
            var list = await _context.BaoTraPhongs.AsNoTracking()
                .OrderByDescending(b => b.NgayBao)
                .Select(b => new
                {
                    id = EF.Property<int>(b, key),
                    maHopDong = b.MaHopDong,
                    maKhach = b.MaKhach,
                    ngayBao = b.NgayBao,
                    ngayTraDuKien = (DateOnly?)null,
                    lyDo = b.LyDo,
                    ghiChu = b.GhiChu,
                    trangThai = b.TrangThai,
                    tenPhong = b.MaHopDongNavigation != null && b.MaHopDongNavigation.MaPhongNavigation != null
                        ? b.MaHopDongNavigation.MaPhongNavigation.TenPhong : "",
                    tenKhach = b.MaKhachNavigation != null ? b.MaKhachNavigation.HoTen : ""
                }).ToListAsync();
            return Ok(list);
        }
        catch (Exception ex) { return StatusCode(500, new { success = false, message = ex.InnerException?.Message ?? ex.Message }); }
    }

    [HttpPost]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> Create([FromBody] BaoTraPhong model)
    {
        if (model == null || model.MaHopDong <= 0 || model.MaKhach <= 0)
            return BadRequest(new { success = false, message = "Thiếu mã hợp đồng hoặc mã khách." });
        try
        {
            var hd = await _context.HopDongs.AsNoTracking().FirstOrDefaultAsync(h => h.MaHopDong == model.MaHopDong);
            if (hd == null || hd.MaKhachDaiDien != model.MaKhach || hd.TrangThai != NghiepVu.HopDong.HieuLuc)
                return BadRequest(new { success = false, message = "Hợp đồng không hợp lệ hoặc không còn hiệu lực." });
            if (await _context.BaoTraPhongs.AnyAsync(b => b.MaHopDong == model.MaHopDong && b.TrangThai == ChoXuLy))
                return Conflict(new { success = false, message = "Hợp đồng đã có yêu cầu trả phòng đang chờ xử lý." });
            model.NgayBao = DateOnly.FromDateTime(DateTime.Now);
            model.TrangThai = ChoXuLy;
            _context.BaoTraPhongs.Add(model);
            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = "Đã gửi yêu cầu trả phòng đến chủ trọ." });
        }
        catch (Exception ex) { return StatusCode(500, new { success = false, message = ex.InnerException?.Message ?? ex.Message }); }
    }

    // Duyệt chỉ ghi nhận quyết định, KHÔNG tự thanh lý / hoàn cọc.
    // Trạng thái "Chờ thanh lý" là giá trị ứng dụng lưu trong cột TrangThai hiện có.
    [HttpPut("{id:int}/duyet")]
    [Authorize(Roles = "Admin")]
    public Task<IActionResult> Duyet(int id) => UpdateStatus(id, "Chờ thanh lý");

    [HttpPut("{id:int}/tu-choi")]
    [Authorize(Roles = "Admin")]
    public Task<IActionResult> TuChoi(int id) => UpdateStatus(id, DaTuChoi);

    private async Task<IActionResult> UpdateStatus(int id, string newStatus)
    {
        try
        {
            var key = PrimaryKeyName;
            var item = await _context.BaoTraPhongs
                .FirstOrDefaultAsync(b => EF.Property<int>(b, key) == id);
            if (item == null) return NotFound(new { success = false, message = "Không tìm thấy yêu cầu." });
            if (item.TrangThai != ChoXuLy)
                return Conflict(new { success = false, message = "Yêu cầu đã được xử lý trước đó." });
            item.TrangThai = newStatus;
            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = newStatus == DaTuChoi ? "Đã từ chối yêu cầu." : "Đã duyệt, chờ quyết toán thanh lý hợp đồng." });
        }
        catch (Exception ex) { return StatusCode(500, new { success = false, message = ex.InnerException?.Message ?? ex.Message }); }
    }
}
