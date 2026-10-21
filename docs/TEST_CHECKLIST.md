# Game2D — danh sách nghiệm thu

**Trạng thái thiết bị:** CHƯA KIỂM THỬ. Các bước headless/CI không được xem là bằng chứng đã chạy trên vivo V2120. Chỉ đánh dấu đạt khi thực hiện trên thiết bị và ghi lại bằng chứng.

Ghi nhận mỗi phiên:
- Commit SHA:
- Phiên bản Godot:
- Điện thoại / phiên bản Android:
- Cấu hình render:
- Mã bài kiểm thử:
- Kết quả mong đợi:
- Kết quả thực tế:
- Đạt / Không đạt / Bị chặn:
- Ảnh hoặc log:

## A. Import và khởi động

- [ ] A-01: Import project bằng Godot 4.7.2, không thiếu tài nguyên.
- [ ] A-02: Main scene chạy không có lỗi parser hoặc tài nguyên.
- [ ] A-03: Nền đá so le, nhân vật, quái, phù văn và các rào gỗ hiển thị ổn định.
- [ ] A-09: Tile nền SVG hiển thị trên Android; không còn màn hình nền đen khi bắt đầu hoặc khi di chuyển camera.
- [ ] A-10: Nền vẫn được vẽ khi texture tile không sẵn sàng, không để lộ clear color tối.
- [ ] A-07: Camera theo người chơi trên bản đồ lớn mà không lộ khoảng trống ngoài ranh giới.
- [ ] A-08: Minimap cập nhật vị trí người chơi, quái và chướng ngại khi di chuyển.
- [ ] A-04: Tiếng Việt hiển thị đúng dấu, không bị ô vuông hoặc cắt chữ.
- [ ] A-05: Menu, tạm dừng, nâng cấp, thắng/thua đều có thể bấm.
- [ ] A-06: Chạy thử bằng bàn phím: mũi tên, Space, F, Shift, E, Q, Esc.

## B. Điều khiển cảm ứng

- [ ] B-01: Joystick di chuyển 8 hướng.
- [ ] B-02: Nhả joystick thì nhân vật ngừng di chuyển.
- [ ] B-03: Giữ joystick và bấm một nút kỹ năng đồng thời hoạt động.
- [ ] B-04: Chạm nút hành động không gây di chuyển ngoài ý muốn.
- [ ] B-05: Vùng chết joystick ngăn trôi nhẹ.
- [ ] B-06: Tám nút hành động đọc được, đủ vùng chạm và không chồng lấn trên vivo V2120.
- [ ] B-10: Nút Hồi Máu không chồng nhãn/icon và hiển thị rõ trạng thái đủ máu, thiếu nội lực và hồi chiêu.
- [ ] B-09: Minimap và nút tạm dừng không che nhau hoặc che vùng điều khiển.
- [ ] B-07: Vòng hồi chiêu và trạng thái thiếu nội lực rõ ràng.
- [ ] B-08: Nút tạm dừng không bị che bởi phần viền/điều hướng hệ thống.

## C. Chiến đấu

- [ ] C-01: Đánh ngoài tầm không gây sát thương và không gắn Kiếm Ấn.
- [ ] C-02: Đánh trong tầm gắn ấn và gây sát thương đúng một lần.
- [ ] C-03: Kiếm Khí chọn mục tiêu còn sống gần nhất trong tầm.
- [ ] C-04: Không có mục tiêu thì không tạo đạn, không dùng nội lực và không bắt đầu hồi chiêu bắn.
- [ ] C-05: Bắn vào mục tiêu không có ấn chỉ gây sát thương cơ bản.
- [ ] C-06: Bắn vào mục tiêu có ấn gây sát thương combo một lần rồi tiêu thụ ấn.
- [ ] C-07: Phá Trận dùng 32 nội lực và bắt đầu hồi chiêu khi đủ năng lượng.
- [ ] C-08: Kỹ năng không đủ nội lực bị từ chối mà không trừ năng lượng.
- [ ] C-09: Tuyệt Kỹ chỉ dùng được khi đủ 100 nội lực, sau khi dùng thanh nội lực về 0.
- [ ] C-10: Lướt thường tránh đòn trong cửa sổ bất tử ngắn.
- [ ] C-11: Lướt đúng lúc báo đòn hủy đòn và tạo đúng một phản kích.
- [ ] C-12: Không thể lướt liên tục trong lúc hồi chiêu.
- [ ] C-13: Mỗi loại quái có ngoại hình, tốc độ, sinh lực và báo đòn hợp lý.
- [ ] C-14: Trùm xuất hiện gần phút thứ 6, báo đòn dễ đọc và có thể bị đánh bại.
- [ ] C-15: Hạ trùm tạo chiến thắng; hết 8 phút mà trùm còn sống là thất bại.
- [ ] C-16: Sinh lực về 0 là thất bại.
- [ ] C-17: Đánh diện rộng/đòn cuối không tạo sát thương hoặc phần thưởng lặp ngoài ý muốn.
- [ ] C-18: Băng Phong chỉ dùng nội lực khi có quái trong vùng; quái bị làm chậm đúng thời lượng.
- [ ] C-19: Lôi Chuỗi chọn tối đa bốn mục tiêu riêng biệt trong tầm và tiêu thụ Kiếm Ấn đúng một lần.
- [ ] C-20: Hai phép mới không trừ nội lực hoặc bật hồi chiêu khi không có mục tiêu phù hợp.
- [ ] C-21: Nhân vật và quái không xuyên qua collider của rào gỗ.
- [ ] C-22: Hồi Máu phục hồi 32 HP, tiêu hao 30 nội lực và hồi chiêu 18 giây.
- [ ] C-23: Hồi Máu khi máu đầy hoặc thiếu nội lực không tiêu hao tài nguyên/không khởi động hồi chiêu.
- [ ] C-24: Đấu Sĩ Hạng Nặng và Pháp Sư Tầm Xa có ngoại hình, tầm đánh và thông số khác nhau.

## D. Tiến trình, nâng cấp và vật phẩm

- [ ] D-01: Kinh nghiệm nhận theo loại kẻ địch.
- [ ] D-02: Ngưỡng ban đầu là 8 XP; ngưỡng kế tiếp tăng thêm 3.
- [ ] D-03: Bảng lên cấp tạm dừng mô phỏng cho đến khi chọn.
- [ ] D-04: Chọn một nâng cấp chỉ áp dụng hiệu ứng của lựa chọn đó.
- [ ] D-05: Tinh thạch rơi hiếm hơn quái XP thông thường; vật phẩm hút về khi người chơi ở gần.
- [ ] D-06: Tinh anh có cơ hội rơi 2–3 tinh thạch; trùm trả 10 tinh thạch.
- [ ] D-07: Phần thưởng lượt chơi chỉ được cộng một lần.
- [ ] D-08: Mở Bảo Vật Phản Kích kiểm tra đủ 35 tinh thạch, trừ đúng một lần và lưu qua lần mở sau.
- [ ] D-09: Chơi lại đặt lại thời gian, nhân vật, quái, XP, kỹ năng tạm thời và hồi chiêu.
- [ ] D-10: Lưu cục bộ vẫn chính xác sau nhiều lần chơi.

## E. Offline và vòng đời ứng dụng

- [ ] E-01: Chơi được khi bật chế độ máy bay.
- [ ] E-02: Tinh thạch được lưu sau khi đóng/mở ứng dụng.
- [ ] E-03: Bảo vật đã mở vẫn còn sau khi đóng/mở.
- [ ] E-04: Tạm chuyển ứng dụng ra nền rồi quay lại không làm trùng thưởng hoặc treo input.
- [ ] E-05: Lỗi ghi save được ghi log.

## F. Hiệu năng trên thiết bị

- [ ] F-01: Ghi FPS/frame time ở đấu trường ít quái.
- [ ] F-02: Ghi FPS khi có 5, 8 và 10 quái hoạt động.
- [ ] F-03: Đo giật khung hình trong combo, hiệu ứng diện rộng và nhiều báo đòn đồng thời.
- [ ] F-04: Chạy tối thiểu 10 phút, ghi bộ nhớ trước/trong/sau.
- [ ] F-05: Ghi nhiệt độ pin và phần trăm pin đầu/cuối.
- [ ] F-06: Chơi lặp 10 lượt, ghi crash, treo, lỗi lưu và giật nặng nhất.
- [ ] F-07: Đo frame time khi camera di chuyển qua các ô nền khác nhau.
- [ ] F-08: Đo FPS với 10 quái đang hoạt động và khi dùng đồng thời Băng Phong/Lôi Chuỗi/Hồi Máu.

Mục tiêu tạm thời: gần 60 FPS ở cảnh nhẹ và ít nhất 30 FPS khi tải cao. Chưa có phép đo nào được xem là đạt.

## G. Xuất APK — cổng riêng

- [ ] G-01: Kiểm tra export template khớp Godot 4.7.2.
- [ ] G-02: Xuất debug APK theo đường dẫn được hỗ trợ.
- [ ] G-03: Kiểm tra ABI trong APK, gồm armeabi-v7a nếu cần 32-bit.
- [ ] G-04: Cài và mở đúng APK trên vivo V2120.
- [ ] G-05: Lặp lại bài B/C/D/E trên APK, không chỉ trong editor.
- [ ] G-06: Lưu log xuất, SHA commit, metadata APK, kết quả cài đặt và kiểm thử.

## Tự động hóa CI

Workflow tải Godot 4.7.2 chính thức cho Linux và chạy:
1. Import/parse project, quét log lỗi script.
2. Test luật chiến đấu.
3. Test scene: nội lực, chiêu thức, combo, né phản kích, nâng cấp và phần thưởng.
4. Smoke test scene chính.

CI không thể xác nhận cảm giác cảm ứng, đa chạm trên điện thoại, nhiệt độ, pin, frame pacing thật, lưu sau khi kill process trên Android hoặc cài APK.
