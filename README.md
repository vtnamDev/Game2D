# Game2D — Kiếm Khí Truyền Thuyết

Prototype game hành động chiến thuật 2D góc nhìn từ trên xuống, dùng GDScript và Godot 4.7.2. Bản sửa này tập trung khắc phục nền đen trên Android, loại bỏ giới hạn di chuyển ẩn bên trong bản đồ, làm rõ hiệu ứng chiến đấu và thêm kỹ năng hồi máu.

## Thay đổi chính

- Nền đá chuyển từ texture lớn được tạo lúc chạy sang tile SVG nhập sẵn, lặp trên toàn bản đồ. Có lớp nền màu dự phòng để tránh lộ màu clear gần đen nếu texture gặp lỗi.
- Bản đồ 2400 × 1600, Camera2D bám nhân vật, minimap chỉ vị trí người chơi/quái/chướng ngại, 12 rào gỗ có collider.
- Bỏ giới hạn di chuyển kiểu nửa kích thước viewport. Người chơi có thể đến sát biên thật của map; camera giới hạn khung hình ở rìa thế giới.
- Thêm nút **Hồi Máu**: hồi 32 sinh lực, tiêu hao 30 nội lực, hồi chiêu 18 giây. Nút không tiêu hao tài nguyên nếu sinh lực đã đầy hoặc thiếu nội lực. Hồi máu có hoạt ảnh, vòng hiệu ứng, âm thanh và phản hồi giao diện.
- Thêm quái **Đấu Sĩ Hạng Nặng** (nhiều sinh lực/sát thương, di chuyển chậm) và **Pháp Sư Tầm Xa** (tầm đánh xa, báo đòn riêng), bổ sung tỷ lệ xuất hiện theo thời gian và tăng độ khó dần.
- Tối đa 10 quái hoạt động đồng thời; dùng một bộ quản lý VFX có giới hạn hiệu ứng và sáu voice âm thanh tái sử dụng. Mục tiêu là giữ tải có thể kiểm soát, không phải cam kết FPS trước khi đo trên điện thoại.
- Camera rung nhẹ theo cường độ đòn đánh, kỹ năng và sát thương nhận vào; hiệu ứng chém, băng, sét, hồi máu và tuyệt kỹ rõ hơn.
- Nút kỹ năng có nhãn bên dưới biểu tượng, vòng hồi chiêu, trạng thái thiếu nội lực và vòng nhấn.

## Điều khiển

| Nút | Chức năng |
|---|---|
| Joystick trái | Di chuyển |
| Đánh | Cận chiến, gắn Kiếm Ấn và hồi một ít nội lực |
| Kiếm Khí | Tự chọn mục tiêu trong tầm; tốn 9 nội lực |
| Lướt | Né đòn; né đúng lúc có thể phản kích |
| Phá Trận | Gây sát thương diện rộng; tốn 32 nội lực, hồi chiêu 7 giây |
| Tuyệt Kỹ | Đòn diện rộng mạnh; cần đủ 100 nội lực |
| Băng Phong | Gây sát thương và làm chậm; tốn 28 nội lực, hồi chiêu 9,5 giây |
| Lôi Chuỗi | Sét nảy tối đa 4 mục tiêu; tốn 34 nội lực, hồi chiêu 10 giây |
| Hồi Máu | +32 sinh lực, −30 nội lực, hồi chiêu 18 giây |
| Nút II | Tạm dừng |

Phím bàn phím nếu dùng được: mũi tên di chuyển, Space đánh, F kiếm khí, Shift lướt, E Phá Trận, Q Tuyệt Kỹ, R Băng Phong, T Lôi Chuỗi, H Hồi Máu, Esc tạm dừng.

## Kiểm thử

GitHub Actions với Godot 4.7.2 thực hiện import/parse, test luật chiến đấu, test tích hợp và smoke-test scene. Test tích hợp kiểm tra texture nền, vùng di chuyển, camera/map, chướng ngại, kỹ năng, hồi máu/VFX/SFX, archetype quái, combo, né phản kích, nâng cấp và phần thưởng.

CI thành công không chứng minh đồ họa hiển thị đúng trên vivo V2120, cũng không xác nhận FPS, nhiệt độ, pin, đa chạm hay xuất APK. Cần kiểm thử bản ZIP trên điện thoại thật trước khi tuyên bố hoàn thành.

## Nhập trong Godot Android

1. Tải ZIP từ nhánh `fix/restore-arena-floor-healing-combat`.
2. Mở Godot Android 4.7.2 → **Nhập** → chọn ZIP; nếu không được, giải nén và chọn thư mục có `project.godot`.
3. Nhấn **Chạy**. Kiểm tra nền có gạch đá, đi được sát rìa map, thử Hồi Máu và đánh các loại quái mới.

Chưa có APK Android được xuất và cài đặt xác nhận trong repo. Đồ họa vẫn là prototype 2D có tài nguyên tự tạo; chưa đạt mức hoàn thiện thương mại.

## Nguyên tắc kỹ thuật

- Compatibility renderer và GDScript; không cần PC, root, C#/.NET hay plugin native.
- Không sao chép sprite, âm thanh hoặc mã của game thương mại.
- Dùng hiệu ứng dạng hình học/texture và pool âm thanh để kiểm soát số node và cấp phát trong combat.
- Không tuyên bố đạt mục tiêu FPS nếu chưa có phép đo trên thiết bị thật.
