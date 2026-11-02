using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QLPT.API.Models;
using QLPT.API.Services;

namespace QLPT.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DatPhongController : ControllerBase
    {
        private readonly Klcn052QuanLyPhongTroContext _context;

        public DatPhongController(Klcn052QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // Quy định mẫu của nhóm, cần được công bố và thỏa thuận với khách trước khi đặt cọc.
        // >= 7 ngày: 100%; 3-6 ngày: 50%; < 3 ngày: 0%.
        private static decimal TyLeHoanCoc(int soNgayBaoTruoc)
        {
            if (soNgayBaoTruoc >= 7) return 1m;
            if (soNgayBaoTruoc >= 3) return 0.5m;
            return 0m;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                var list = await _context.DatPhongs
                    .Include(d => d.MaPhongNavigation)
                    .Include(d => d.MaKhachNavigation)
                    .Select(d => new
                    {
                        maDatPhong = d.MaDatPhong,
                        maPhong = d.MaPhong,
                        tenPhong = d.MaPhongNavigation != null ? d.MaPhongNavigation.TenPhong : "",
                        maKhach = d.MaKhach,
                        tenKhach = d.MaKhachNavigation != null ? d.MaKhachNavigation.HoTen : "",
                        ngayDat = d.NgayDat,
                        ngayDuKienNhan = d.NgayDuKienNhan,
                        tienCoc = d.TienCoc,
                        trangThai = d.TrangThai,
                        ghiChu = d.GhiChu
                    })
                    .ToListAsync();

                return Ok(list);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = $"Lỗi server: {ex.Message}" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] DatPhong model)
        {
            if (model == null)
                return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ." });
            if (model.TienCoc is < 0)
                return BadRequest(new { success = false, message = "Tiền cọc không được âm." });

            var homNay = DateOnly.FromDateTime(DateTime.Today);
            if (model.NgayDuKienNhan.HasValue && model.NgayDuKienNhan.Value < homNay)
                return BadRequest(new { success = false, message = "Ngày dự kiến nhận phòng không được trước ngày hôm nay." });

            await using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                var phong = await _context.Phongs.FindAsync(model.MaPhong);
                if (phong == null)
                    return NotFound(new { success = false, message = $"Không tìm thấy phòng #{model.MaPhong}." });
                if (phong.TrangThai != NghiepVu.Phong.Trong)
                    return BadRequest(new { success = false, message = $"{phong.TenPhong} đang ở trạng thái '{phong.TrangThai}', chỉ đặt được phòng trống." });

                var khach = await _context.KhachThues.FindAsync(model.MaKhach);
                if (khach == null)
                    return NotFound(new { success = false, message = $"Không tìm thấy khách thuê #{model.MaKhach}." });

                if (model.NgayDat == default) model.NgayDat = homNay;
                model.TrangThai = NghiepVu.DatPhong.DaDatCoc;
                _context.DatPhongs.Add(model);
                phong.TrangThai = NghiepVu.Phong.DaDatCoc;

                NghiepVu.GhiPhieu(
                    _context,
                    NghiepVu.PhieuThu,
                    $"Thu tiền đặt cọc {NghiepVu.ChuThuongDau(phong.TenPhong)}",
                    model.TienCoc ?? 0,
                    khach.HoTen);

                await _context.SaveChangesAsync();
                await tx.CommitAsync();
                return Ok(new
                {
                    success = true,
                    message = "Đặt phòng/Giữ chỗ thành công.",
                    data = new { model.MaDatPhong }
                });
            }
            catch (Exception ex)
            {
                await tx.RollbackAsync();
                return StatusCode(500, new { success = false, message = $"Lỗi server: {ex.InnerException?.Message ?? ex.Message}" });
            }
        }

        // Hủy giữ chỗ: server tự tính hoàn cọc theo số ngày báo trước.
        // Request body có thể là {} hoặc {"hoanCoc":true/false} từ Flutter cũ;
        // các giá trị này không được dùng để vượt qua chính sách hoàn cọc.
        [HttpPut("{id}/huy")]
        public async Task<IActionResult> Huy(int id, [FromBody] HuyDatPhongDto? dto)
        {
            var dp = await _context.DatPhongs
                .Include(d => d.MaPhongNavigation)
                .Include(d => d.MaKhachNavigation)
                .FirstOrDefaultAsync(d => d.MaDatPhong == id);

            if (dp == null)
                return NotFound(new { success = false, message = "Không tìm thấy phiếu đặt phòng." });
            if (dp.TrangThai != NghiepVu.DatPhong.DaDatCoc)
                return BadRequest(new { success = false, message = $"Chỉ hủy được phiếu đang giữ chỗ (hiện: {dp.TrangThai})." });
            if (!dp.NgayDuKienNhan.HasValue)
                return BadRequest(new { success = false, message = "Phiếu đặt phòng chưa có ngày dự kiến nhận; không thể tính chính sách hoàn cọc." });

            var ngayHuy = DateOnly.FromDateTime(DateTime.Today);
            int soNgayBaoTruoc = dp.NgayDuKienNhan.Value.DayNumber - ngayHuy.DayNumber;
            decimal coc = dp.TienCoc ?? 0m;
            decimal tyLe = TyLeHoanCoc(soNgayBaoTruoc);
            decimal hoan = Math.Round(coc * tyLe, 0, MidpointRounding.AwayFromZero);
            decimal giuLai = coc - hoan;

            await using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                dp.TrangThai = NghiepVu.DatPhong.DaHuy;
                var phong = dp.MaPhongNavigation;
                bool conGiuCho = await _context.DatPhongs.AnyAsync(d =>
                    d.MaPhong == dp.MaPhong &&
                    d.MaDatPhong != id &&
                    d.TrangThai == NghiepVu.DatPhong.DaDatCoc);

                if (phong != null &&
                    phong.TrangThai == NghiepVu.Phong.DaDatCoc &&
                    !conGiuCho)
                {
                    phong.TrangThai = NghiepVu.Phong.Trong;
                }

                NghiepVu.GhiPhieu(
                    _context,
                    NghiepVu.PhieuChi,
                    $"Hoàn tiền đặt cọc {NghiepVu.ChuThuongDau(phong?.TenPhong ?? $"phòng #{dp.MaPhong}")} (khách hủy, báo trước {soNgayBaoTruoc} ngày, hoàn {tyLe * 100:0}%)",
                    hoan,
                    dp.MaKhachNavigation?.HoTen);

                await _context.SaveChangesAsync();
                await tx.CommitAsync();

                return Ok(new
                {
                    success = true,
                    message = $"Đã hủy giữ chỗ. Hoàn {NghiepVu.Tien(hoan)} ({tyLe * 100:0}%), giữ lại {NghiepVu.Tien(giuLai)}.",
                    data = new
                    {
                        ngayHuy,
                        ngayDuKienNhan = dp.NgayDuKienNhan,
                        soNgayBaoTruoc,
                        tyLeHoanPhanTram = tyLe * 100,
                        tienCoc = coc,
                        tienHoan = hoan,
                        tienGiuLai = giuLai
                    }
                });
            }
            catch (Exception ex)
            {
                await tx.RollbackAsync();
                return StatusCode(500, new { success = false, message = $"Lỗi server: {ex.InnerException?.Message ?? ex.Message}" });
            }
        }
    }

    // Giữ DTO để Flutter cũ gửi {"hoanCoc":...} vẫn bind được.
    // Backend không dùng hai trường này để thay đổi số tiền hoàn theo chính sách.
    public class HuyDatPhongDto
    {
        public bool HoanCoc { get; set; } = true;
        public decimal? SoTienHoan { get; set; }
    }
}
