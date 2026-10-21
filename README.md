# Game2D — Kiếm Khí Truyền Thuyết

Prototype game hành động chiến thuật 2D góc nhìn từ trên xuống, viết bằng GDScript với Godot 4.7.2. Hướng mỹ thuật là pixel-art fantasy phương Đông pha dark fantasy, kết hợp sprite gốc dạng SVG, đấu trường procedural, kiếm khí, phù văn, vòng báo đòn và nút hành động phong cách fantasy.

## Trạng thái hiện tại

- Nhánh nâng cấp: **feature/vn-visual-combat**.
- Nhánh gameplay trước đó **prototype/m1-combat** vẫn được giữ; nhánh **main** không bị thay đổi.
- Chạy ngang màn hình, logical viewport 960 × 540, Compatibility renderer.
- Nhân vật kiếm khách có sprite gốc, hiệu ứng chém, lướt, kiếm khí, Phá Trận và Tuyệt Kỹ.
- Sáu sprite gốc riêng cho kiếm khách, quỷ thường, quỷ nhanh, hộ vệ, tinh anh và trùm. Môi trường đá/rêu/tàn tích được dựng procedural; hiệu ứng báo đòn, ánh sáng giả lập và vệt đạn được vẽ bằng GDScript.
- Nhiều loại địch có tốc độ, sinh lực, sát thương và thời gian báo đòn khác nhau.
- Vòng chơi tối đa 8 phút. Trùm xuất hiện ở phút thứ 6; tiêu diệt trùm để thắng, hết giờ mà trùm còn sống là thất bại.
- Giao diện, menu, thông báo và điều khiển đã chuyển sang tiếng Việt.
- Quái thường có 7% cơ hội rơi một tinh thạch; tinh anh có 68% cơ hội rơi cụm 2–3 tinh thạch; trùm thưởng 10 tinh thạch.
- Lên cấp từ 8 kinh nghiệm; ngưỡng kế tiếp tăng thêm 3, nhằm giảm số lần bảng nâng cấp ngắt nhịp chiến đấu.
- Tiến trình tinh thạch và Bảo Vật Phản Kích được lưu cục bộ. Không cần đăng nhập, máy chủ, quảng cáo hoặc mua hàng trong bản thử nghiệm.
- Sprite là tài nguyên gốc của dự án nhưng vẫn là bản nghệ thuật ban đầu; chưa có bộ hoạt ảnh sprite-sheet nhiều frame hoặc âm thanh hoàn chỉnh.

## Điều khiển

| Nút | Chức năng |
|---|---|
| Joystick bên trái | Di chuyển |
| Đánh | Chém cận chiến, gắn Kiếm Ấn và hồi một ít nội lực |
| Kiếm Khí | Tự chọn kẻ địch gần nhất trong tầm; tốn 9 nội lực |
| Lướt | Né đòn; lướt đúng lúc báo đòn sẽ phản kích và hồi nội lực |
| Phá Trận | Đánh diện rộng; tốn 32 nội lực, hồi chiêu 7 giây |
| Tuyệt Kỹ | Đánh diện rộng mạnh; yêu cầu đủ 100 nội lực |
| Nút II | Tạm dừng |

Phím thử trên bàn phím: mũi tên di chuyển, Space đánh, F kiếm khí, Shift lướt, E Phá Trận, Q Tuyệt Kỹ, Esc tạm dừng.

## Kiểm tra tự động

CI tải Godot 4.7.2 chính thức và chạy:
1. Import/parse project.
2. Kiểm thử luật chiến đấu.
3. Kiểm thử luồng scene, năng lượng, chiêu thức, combo, né phản kích, nâng cấp và phần thưởng.
4. Khởi động scene chính ở chế độ headless.

CI thành công chỉ xác nhận các bước chạy trên Linux headless. Nó **không chứng nhận FPS, nhiệt độ, mức tiêu thụ pin, cảm ứng đa điểm, font tiếng Việt trên điện thoại, xuất APK hay cài đặt trên vivo V2120**.

## Mở project trên Android

1. Tải ZIP của nhánh **feature/vn-visual-combat**.
2. Trong Godot Android 4.7.2, chọn Nhập và chọn ZIP; nếu không được thì giải nén bằng trình quản lý tệp rồi chọn thư mục chứa **project.godot**.
3. Mở project và nhấn Chạy.
4. Kiểm tra điều khiển đồng thời, các nút năng lượng, trùm, bảng nâng cấp và font tiếng Việt trên thiết bị thật.

Chưa có APK đã xuất và kiểm thử trong repo này. Không nên coi bản project đang chạy trong editor là bằng chứng rằng APK đã sẵn sàng.

## Nguyên tắc phát triển

- Không sao chép sprite, âm thanh hoặc mã của game thương mại.
- Giữ GDScript, không thêm C#/.NET, root, native plugin hay yêu cầu máy tính bàn.
- Ưu tiên hình dáng dễ đọc, phản hồi đòn rõ, vùng chạm đủ lớn và hiệu năng ổn định.
- Không tuyên bố hiệu năng hoặc kiểm thử thiết bị đạt yêu cầu cho đến khi có kết quả đo được.
