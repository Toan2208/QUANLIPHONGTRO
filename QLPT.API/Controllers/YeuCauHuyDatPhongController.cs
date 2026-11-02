using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QLPT.API.Models;
using QLPT.API.Services;
using System.Data;

namespace QLPT.API.Controllers;

[ApiController]
[Route("api/YeuCauHuyDatPhong")]
[Authorize]
public class YeuCauHuyDatPhongController : ControllerBase
{
    private readonly Klcn052QuanLyPhongTroContext _ctx;
    public YeuCauHuyDatPhongController(Klcn052QuanLyPhongTroContext ctx) => _ctx = ctx;

    [HttpPost("{maDatPhong:int}/gui")]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> GuiYeuCau(int maDatPhong, [FromBody] GuiYeuCauHuyDto? dto)
    {
        if (!int.TryParse(User.FindFirst("MaKhach")?.Value, out var maKhach))
            return Forbid();

        var dp = await _ctx.DatPhongs.FirstOrDefaultAsync(d =>
            d.MaDatPhong == maDatPhong && d.MaKhach == maKhach);
        if (dp == null) return NotFound(new { message = "Không tìm thấy đặt phòng của bạn." });
        if (dp.TrangThai != NghiepVu.DatPhong.DaDatCoc)
            return BadRequest(new { message = "Phiếu này không thể yêu cầu hủy." });
        if (!dp.NgayDuKienNhan.HasValue)
            return BadRequest(new { message = "Chưa có ngày dự kiến nhận phòng." });
        if (await _ctx.YeuCauHuyDatPhongs.AnyAsync(y =>
                y.MaDatPhong == maDatPhong && y.TrangThai == "Chờ duyệt"))
            return Conflict(new { message = "Yêu cầu hủy đang chờ xử lý." });

        var ngayBao = DateTime.Now;
        var soNgay = dp.NgayDuKienNhan.Value.DayNumber - DateOnly.FromDateTime(ngayBao).DayNumber;
        var tyLe = soNgay >= 7 ? 100m : soNgay >= 3 ? 50m : 0m;
        var tienHoan = Math.Round((dp.TienCoc ?? 0m) * tyLe / 100m, 0, MidpointRounding.AwayFromZero);
        var yeuCau = new YeuCauHuyDatPhong
        {
            MaDatPhong = maDatPhong,
            NgayYeuCau = ngayBao,
            LyDo = dto?.LyDo?.Trim(),
            TrangThai = "Chờ duyệt",
            SoNgayBaoTruoc = soNgay,
            TyLeHoan = tyLe,
            SoTienHoan = tienHoan
        };
        _ctx.YeuCauHuyDatPhongs.Add(yeuCau);
        await _ctx.SaveChangesAsync();
        return Ok(new
        {
            success = true,
            message = "Đã gửi yêu cầu hủy. Vui lòng chờ chủ trọ duyệt.",
            data = new { yeuCau.MaYeuCau, yeuCau.NgayYeuCau, yeuCau.SoNgayBaoTruoc, yeuCau.TyLeHoan, yeuCau.SoTienHoan }
        });
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DanhSach([FromQuery] string? trangThai = null)
    {
        var query = _ctx.YeuCauHuyDatPhongs.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(trangThai))
            query = query.Where(x => x.TrangThai == trangThai);

        var rows = await (from yc in query
                          join dp in _ctx.DatPhongs.AsNoTracking() on yc.MaDatPhong equals dp.MaDatPhong
                          orderby yc.NgayYeuCau descending
                          select new
                          {
                              yc.MaYeuCau,
                              yc.MaDatPhong,
                              dp.MaKhach,
                              dp.MaPhong,
                              dp.NgayDuKienNhan,
                              dp.TienCoc,
                              yc.NgayYeuCau,
                              yc.LyDo,
                              yc.TrangThai,
                              yc.SoNgayBaoTruoc,
                              yc.TyLeHoan,
                              yc.SoTienHoan,
                              yc.NgayXuLy,
                              yc.GhiChuXuLy
                          }).ToListAsync();
        return Ok(rows);
    }

    [HttpPut("{maYeuCau:int}/duyet")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Duyet(int maYeuCau, [FromBody] XuLyYeuCauHuyDto? dto)
    {
        // Serializable để tránh hai Admin xử lý cùng một yêu cầu và ghi hoàn cọc hai lần.
        await using var tx = await _ctx.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var yc = await _ctx.YeuCauHuyDatPhongs.FirstOrDefaultAsync(x => x.MaYeuCau == maYeuCau);
        if (yc == null) return NotFound(new { message = "Không tìm thấy yêu cầu." });
        if (yc.TrangThai != "Chờ duyệt")
            return Conflict(new { message = "Yêu cầu đã được xử lý." });

        var dp = await _ctx.DatPhongs.FirstOrDefaultAsync(x => x.MaDatPhong == yc.MaDatPhong);
        if (dp == null) return NotFound(new { message = "Không tìm thấy phiếu đặt phòng." });
        if (dp.TrangThai != NghiepVu.DatPhong.DaDatCoc)
            return Conflict(new { message = "Phiếu đặt phòng không còn ở trạng thái đã đặt cọc." });

        var phong = await _ctx.Phongs.FirstOrDefaultAsync(x => x.MaPhong == dp.MaPhong);
        if (phong == null) return NotFound(new { message = "Không tìm thấy phòng." });
        if (phong.TrangThai != NghiepVu.Phong.DaDatCoc)
            return Conflict(new { message = "Trạng thái phòng đã thay đổi, cần kiểm tra trước khi duyệt." });

        // Giá trị được tính và chốt tại thời điểm khách gửi yêu cầu.
        var tienHoan = yc.SoTienHoan ?? 0m;
        if (tienHoan < 0m || tienHoan > (dp.TienCoc ?? 0m))
            return BadRequest(new { message = "Số tiền hoàn cọc không hợp lệ." });

        dp.TrangThai = NghiepVu.DatPhong.DaHuy;
        phong.TrangThai = NghiepVu.Phong.Trong;
        yc.TrangThai = "Đã duyệt";
        yc.NgayXuLy = DateTime.Now;
        yc.GhiChuXuLy = dto?.GhiChu?.Trim();

        if (tienHoan > 0)
        {
            // Nếu dự án của em dùng chữ ký GhiPhieu khác, điều chỉnh đúng tại lời gọi này.
            NghiepVu.GhiPhieu(_ctx, "Chi", $"Hoàn cọc hủy đặt phòng #{dp.MaDatPhong}",
                tienHoan, $"Khách #{dp.MaKhach}",
                $"Yêu cầu #{yc.MaYeuCau}; ngày báo {yc.NgayYeuCau:dd/MM/yyyy}; {yc.TyLeHoan}% hoàn cọc");
        }

        await _ctx.SaveChangesAsync();
        await tx.CommitAsync();
        return Ok(new { success = true, message = "Đã duyệt yêu cầu hủy đặt phòng.", soTienHoan = tienHoan });
    }

    [HttpPut("{maYeuCau:int}/tu-choi")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> TuChoi(int maYeuCau, [FromBody] XuLyYeuCauHuyDto? dto)
    {
        await using var tx = await _ctx.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var yc = await _ctx.YeuCauHuyDatPhongs.FirstOrDefaultAsync(x => x.MaYeuCau == maYeuCau);
        if (yc == null) return NotFound(new { message = "Không tìm thấy yêu cầu." });
        if (yc.TrangThai != "Chờ duyệt")
            return Conflict(new { message = "Yêu cầu đã được xử lý." });
        yc.TrangThai = "Từ chối";
        yc.NgayXuLy = DateTime.Now;
        yc.GhiChuXuLy = dto?.GhiChu?.Trim();
        await _ctx.SaveChangesAsync();
        await tx.CommitAsync();
        return Ok(new { success = true, message = "Đã từ chối yêu cầu hủy. Phiếu đặt phòng được giữ nguyên." });
    }
}

public class GuiYeuCauHuyDto
{
    public string? LyDo { get; set; }
}

public class XuLyYeuCauHuyDto
{
    public string? GhiChu { get; set; }
}
