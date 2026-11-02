using Microsoft.EntityFrameworkCore;
using QLPT.API.Models;

namespace QLPT.API.Services;

/// <summary>
/// Lập hóa đơn tháng theo quy trình: Ghi chỉ số → Tính tiền dịch vụ → Tạo hóa đơn.
/// Định dạng dòng chi tiết bám theo hóa đơn đang có trong CSDL, ví dụ:
///   Tiền phòng tháng 9/2026                              1 × 2.500.000
///   Tiền điện tháng 9/2026 (chỉ số 1787 -> 1885 kWh)    98 × 3.500
///   Phí Internet                                         1 × 100.000
/// Điện/Nước tính theo số tiêu thụ; các dịch vụ khác tính phí cố định.
/// Bản cũ (tinh-tien-ocr) cộng Điện/Nước hai lần: một lần theo chỉ số, một lần
/// nữa như phí cố định trong vòng lặp dịch vụ.
/// </summary>
public static class HoaDonBuilder
{
    public const decimal DonGiaDienMacDinh = 3500;
    public const decimal DonGiaNuocMacDinh = 20000;
    public const int SoNgayHanThanhToan = 7;

    // Cột ChiTietHoaDon.NoiDung trong CSDL dài tối đa 200 ký tự.
    private const int DoDaiNoiDungToiDa = 200;

    public sealed record KetQua(List<ChiTietHoaDon> ChiTiet, decimal TongTien, string? Loi);

    private static ChiTietHoaDon Dong(string noiDung, decimal soLuong, decimal donGia) => new()
    {
        NoiDung = noiDung,
        SoLuong = soLuong,
        DonGia = donGia,
        ThanhTien = Math.Round(soLuong * donGia, 0)
    };

    // Nội dung vi phạm có thể dài tới 500 ký tự, nên phải cắt để không vượt cột NoiDung (200).
    private static string CatNoiDung(string noiDung) =>
        noiDung.Length <= DoDaiNoiDungToiDa ? noiDung : noiDung[..(DoDaiNoiDungToiDa - 1)] + "…";

    public static async Task<KetQua> TinhAsync(Klcn052QuanLyPhongTroContext ctx, HopDong hd,
        int thang, int nam, decimal? donGiaDien = null, decimal? donGiaNuoc = null)
    {
        string ky = $"{thang}/{nam}";
        var dong = new List<ChiTietHoaDon>();

        // 1. Tiền phòng — ưu tiên giá trên hợp đồng (đã chốt khi ký / gia hạn).
        decimal tienPhong = hd.GiaThueThang
            ?? await ctx.Phongs.Where(p => p.MaPhong == hd.MaPhong).Select(p => p.GiaThue).FirstOrDefaultAsync()
            ?? 0;
        dong.Add(Dong($"Tiền phòng tháng {ky}", 1, tienPhong));

        var dangKy = await ctx.DangKyDichVus.Include(d => d.MaDichVuNavigation)
            .Where(d => d.MaHopDong == hd.MaHopDong && d.TrangThai == NghiepVu.DichVu.DangSuDung)
            .ToListAsync();
        var danhMuc = await ctx.DichVus.ToListAsync();
        var chiSo = await ctx.ChiSoDienNuocs
            .Where(c => c.MaPhong == hd.MaPhong && c.Thang == thang && c.Nam == nam)
            .ToListAsync();

        // 2. Điện / Nước theo chỉ số. Đã đăng ký mà chưa ghi chỉ số thì chặn, để
        //    không phát hành hóa đơn thiếu tiền điện nước mà không ai hay.
        var thieu = new List<string>();
        foreach (var (ten, laLoai, donVi, ghiDe, macDinh) in new (string, Func<string?, bool>, string, decimal?, decimal)[]
        {
            ("Điện", NghiepVu.LaDien, "kWh", donGiaDien, DonGiaDienMacDinh),
            ("Nước", NghiepVu.LaNuoc, "m³",  donGiaNuoc, DonGiaNuocMacDinh),
        })
        {
            var dk = dangKy.FirstOrDefault(d => laLoai(d.MaDichVuNavigation?.TenDichVu));
            var cs = chiSo.FirstOrDefault(c => laLoai(c.LoaiChiSo));
            if (cs == null)
            {
                if (dk != null) thieu.Add(ten);
                continue;
            }

            decimal cu = cs.ChiSoCu ?? 0;
            decimal moi = cs.ChiSoMoi ?? cs.ChiSoXacNhan ?? cu;
            decimal tieuThu = Math.Max(0, moi - cu);
            decimal gia = ghiDe is > 0 ? ghiDe.Value
                : dk?.DonGiaApDung
                  ?? dk?.MaDichVuNavigation?.DonGia
                  ?? danhMuc.FirstOrDefault(d => laLoai(d.TenDichVu))?.DonGia
                  ?? macDinh;

            dong.Add(Dong($"Tiền {ten.ToLower()} tháng {ky} (chỉ số {cu:0.##} -> {moi:0.##} {donVi})", tieuThu, gia));
        }
        if (thieu.Count > 0)
            return new KetQua(dong, 0,
                $"Chưa ghi chỉ số {string.Join(" và ", thieu)} tháng {ky} cho phòng của hợp đồng #{hd.MaHopDong}. " +
                "Hãy ghi chỉ số trước khi lập hóa đơn.");

        // 3. Dịch vụ cố định (Internet, rác, giữ xe…) — bỏ qua Điện/Nước đã tính ở trên.
        foreach (var dk in dangKy)
        {
            string? tenDv = dk.MaDichVuNavigation?.TenDichVu;
            if (NghiepVu.LaDien(tenDv) || NghiepVu.LaNuoc(tenDv)) continue;
            decimal gia = dk.DonGiaApDung ?? dk.MaDichVuNavigation?.DonGia ?? 0;
            if (gia <= 0) continue;
            dong.Add(Dong($"Phí {tenDv}", 1, gia));
        }

        // 4. Tiền phạt vi phạm được đánh dấu tính vào hóa đơn và chưa nằm trong hóa đơn nào.
        var viPhams = await LayViPhamChuaTinhAsync(ctx, hd);
        foreach (var viPham in viPhams)
        {
            var tienPhat = viPham.TienPhat!.Value;
            string lyDo = string.IsNullOrWhiteSpace(viPham.NoiDung) ? "" : $": {viPham.NoiDung.Trim()}";
            dong.Add(new ChiTietHoaDon
            {
                MaViPham = viPham.MaViPham,
                NoiDung = CatNoiDung($"Tiền phạt vi phạm #{viPham.MaViPham}{lyDo}"),
                SoLuong = 1,
                DonGia = tienPhat,
                ThanhTien = tienPhat
            });
        }

        return new KetQua(dong, dong.Sum(d => d.ThanhTien ?? 0), null);
    }

    /// <summary>Tạo hóa đơn (chưa SaveChanges). Trả lỗi nghiệp vụ nếu không lập được.</summary>
    public static async Task<(HoaDon? HoaDon, string? Loi)> LapAsync(Klcn052QuanLyPhongTroContext ctx, HopDong hd,
        int thang, int nam, decimal? donGiaDien = null, decimal? donGiaNuoc = null)
    {
        if (thang is < 1 or > 12) return (null, "Tháng phải từ 1 đến 12.");
        if (hd.TrangThai != NghiepVu.HopDong.HieuLuc)
            return (null, $"Hợp đồng #{hd.MaHopDong} không còn hiệu lực (trạng thái: {hd.TrangThai}).");
        if (await ctx.HoaDons.AnyAsync(h => h.MaHopDong == hd.MaHopDong && h.Thang == thang && h.Nam == nam))
            return (null, $"Hóa đơn tháng {thang}/{nam} của hợp đồng #{hd.MaHopDong} đã tồn tại.");

        var kq = await TinhAsync(ctx, hd, thang, nam, donGiaDien, donGiaNuoc);
        if (kq.Loi != null) return (null, kq.Loi);

        return (TaoHoaDon(ctx, hd.MaHopDong, thang, nam, kq.ChiTiet), null);
    }

    /// <summary>Gắn hóa đơn với danh sách dòng chi tiết vào context (chưa SaveChanges).</summary>
    public static HoaDon TaoHoaDon(Klcn052QuanLyPhongTroContext ctx, int maHopDong, int thang, int nam,
                                   IEnumerable<ChiTietHoaDon> chiTiet)
    {
        var today = DateOnly.FromDateTime(DateTime.Now);
        var list = chiTiet.ToList();
        decimal tong = list.Sum(c => c.ThanhTien ?? 0);
        var hoaDon = new HoaDon
        {
            MaHopDong = maHopDong,
            Thang = thang,
            Nam = nam,
            NgayLap = today,
            HanThanhToan = today.AddDays(SoNgayHanThanhToan),
            TongTien = tong,
            DaThanhToan = 0,
            ConLai = tong,
            TrangThai = NghiepVu.HoaDon.ChuaThanhToan
        };
        foreach (var ct in list) hoaDon.ChiTietHoaDons.Add(ct);
        ctx.HoaDons.Add(hoaDon);
        return hoaDon;
    }

    /// <summary>
    /// Vi phạm của khách đại diện trong phòng của hợp đồng này, có tiền phạt, được đánh dấu
    /// tính vào hóa đơn và chưa nằm trong dòng chi tiết hóa đơn nào (không cần chờ "Đã xử lý").
    /// </summary>
    public static Task<List<ViPham>> LayViPhamChuaTinhAsync(
        Klcn052QuanLyPhongTroContext ctx,
        HopDong hd)
    {
        return ctx.ViPhams
            .Where(v =>
                v.DuocTinhHoaDon &&
                v.MaPhong == hd.MaPhong &&
                v.MaKhach == hd.MaKhachDaiDien &&
                v.TienPhat.HasValue &&
                v.TienPhat.Value > 0 &&
                !ctx.ChiTietHoaDons.Any(ct => ct.MaViPham == v.MaViPham))
            .OrderBy(v => v.NgayViPham)
            .ThenBy(v => v.MaViPham)
            .ToListAsync();
    }

    /// <summary>Hóa đơn → dữ liệu trả về client (tránh vòng tham chiếu navigation).</summary>
    public static object ToDto(HoaDon h) => new
    {
        maHoaDon = h.MaHoaDon,
        maHopDong = h.MaHopDong,
        thang = h.Thang,
        nam = h.Nam,
        tongTien = h.TongTien,
        daThanhToan = h.DaThanhToan,
        conLai = h.ConLai,
        trangThai = h.TrangThai,
        chiTiet = h.ChiTietHoaDons.Select(c => new
        {
            c.MaViPham,
            c.NoiDung,
            c.SoLuong,
            c.DonGia,
            c.ThanhTien
        })
    };
}