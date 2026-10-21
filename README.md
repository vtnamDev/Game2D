# Game2D — Kiếm Khí Truyền Thuyết

Prototype hành động chiến thuật 2D góc nhìn từ trên xuống, viết bằng GDScript với Godot 4.7.2. Bản mở rộng tập trung vào thế giới rộng hơn, chiến đấu có lựa chọn chiến thuật và giảm chi phí dựng cảnh trên Android.

## Trạng thái

- Nhánh nâng cấp gameplay/đồ họa: `feature/world-strategy-android-opt`.
- Nhánh sửa hiển thị ban đầu: `fix/visible-actors-wood-barricades`.
- Bản gameplay trước đó `prototype/m1-combat` vẫn còn; `main` không bị thay đổi.
- Màn hình ngang, viewport logic 960 × 540, Compatibility renderer.
- Bản đồ 2400 × 1600, camera bám kiếm khách, minimap hiện người chơi/quái/chướng ngại.
- 12 rào gỗ có collider thật; nhân vật và quái có thể bị chặn đường.
- Nền đá được vẽ theo vùng gần camera thay vì phải dựng chi tiết toàn bộ thế giới mỗi lần cập nhật.
- Giới hạn 12 quái hoạt động đồng thời, thời gian sinh quái giãn hơn để giảm tải trên thiết bị yếu.
- Hình thể nhân vật/quái được vẽ bằng GDScript để có hình dự phòng ngay cả khi sprite texture gặp vấn đề; nền đá, rêu, tàn tích và gỗ là hình học procedural.
- Có quái thường, quái nhanh, hộ vệ, tinh anh và trùm; mỗi loại có thông số sinh lực, tốc độ, sát thương và thời gian báo đòn khác nhau.
- Lượt chơi tối đa 8 phút; trùm xuất hiện ở phút thứ 6. Hạ trùm để thắng; hết giờ mà trùm còn sống là thất bại.
- Tinh thạch và Bảo Vật Phản Kích được lưu cục bộ. Bản thử nghiệm không cần đăng nhập, máy chủ, quảng cáo hay mua hàng.

Đây vẫn là prototype đồ họa 2D, chưa phải chất lượng thương mại. Chưa có bộ sprite-sheet hoạt ảnh nhiều khung hình, âm thanh chiến đấu hoàn chỉnh hoặc đo hiệu năng trên vivo V2120.

## Điều khiển

| Nút | Chức năng |
|---|---|
| Joystick trái | Di chuyển |
| Đánh | Cận chiến, gắn Kiếm Ấn và hồi một ít nội lực |
| Kiếm Khí | Tự chọn mục tiêu gần nhất trong tầm; tốn 9 nội lực |
| Lướt | Né đòn; lướt đúng lúc báo đòn có thể phản kích |
| Phá Trận | Gây sát thương diện rộng; tốn 32 nội lực, hồi chiêu 7 giây |
| Tuyệt Kỹ | Đòn diện rộng mạnh; yêu cầu đủ 100 nội lực |
| Băng Phong | Đánh nhẹ và làm chậm quái gần đó trong 2,6 giây; tốn 28 nội lực, hồi chiêu 9,5 giây |
| Lôi Chuỗi | Sét nảy qua tối đa 4 mục tiêu; tốn 34 nội lực, hồi chiêu 10 giây |
| Nút II | Tạm dừng |

Phím thử trên bàn phím: mũi tên di chuyển, Space đánh, F kiếm khí, Shift lướt, E Phá Trận, Q Tuyệt Kỹ, R Băng Phong, T Lôi Chuỗi, Esc tạm dừng.

Phép Băng Phong/Lôi Chuỗi không tiêu hao nội lực hoặc bắt đầu hồi chiêu nếu không tìm thấy mục tiêu phù hợp.

## Kiểm thử tự động

GitHub Actions tải Godot 4.7.2 chính thức và thực hiện:
1. Import/parse project, kiểm tra log lỗi script.
2. Kiểm thử luật chiến đấu.
3. Kiểm thử scene: khởi tạo thanh trạng thái, camera/bản đồ, chướng ngại có collider, năng lượng, combo, né phản kích, phép mới, nâng cấp và phần thưởng.
4. Khởi động scene chính ở chế độ headless.

CI thành công chỉ xác nhận các bước trên Linux headless. Nó **không chứng minh** FPS, nhiệt độ, mức tiêu thụ pin, cảm ứng đa điểm, font tiếng Việt trên điện thoại, xuất APK hay cài đặt thành công trên vivo V2120.

## Mở project trên Godot Android

1. Tải ZIP của nhánh `feature/world-strategy-android-opt`.
2. Trong Godot Android 4.7.2, chọn **Nhập** và chọn ZIP. Nếu không chọn được ZIP, giải nén bằng trình quản lý tệp rồi chọn thư mục chứa `project.godot`.
3. Mở project và nhấn **Chạy**.
4. Kiểm tra camera khi di chuyển, minimap, collider rào gỗ, phép Băng Phong/Lôi Chuỗi và các nút cảm ứng cùng lúc.

Chưa có APK đã xuất và cài đặt kiểm thử trong repo. Không coi project chạy trong editor là bằng chứng rằng APK đã sẵn sàng.

## Nguyên tắc phát triển

- Không sao chép sprite, âm thanh hoặc mã của game thương mại.
- Giữ GDScript; không yêu cầu PC, root, C#/.NET hay plugin native.
- Ưu tiên silhouette rõ, tín hiệu báo đòn dễ đọc và hiệu năng ổn định hơn hiệu ứng nặng.
- Không tuyên bố đã đạt mục tiêu FPS/hiệu năng nếu chưa đo trên thiết bị thật.
