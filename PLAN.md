# Game2D — Kiếm Khí Truyền Thuyết

**Trạng thái:** nhánh nâng cấp hình ảnh/gameplay đang được kiểm thử. Đây là project Godot, chưa phải APK Android đã xuất và xác nhận cài đặt.

## 1. Mục tiêu sản phẩm

Một game hành động chiến thuật 2D góc nhìn từ trên xuống, mỹ thuật pixel-art fantasy phương Đông pha dark fantasy. Ưu tiên hình dáng dễ đọc, hoạt ảnh có trọng lượng, phản hồi đòn đánh rõ, điều khiển thuận tiện bằng ngón cái và hiệu năng phù hợp với vivo V2120 / Android 12.

Tham chiếu cảm hứng: chất liệu, ánh sáng và không khí võ hiệp từ các game người chơi yêu thích; nhịp chiến đấu và quyết định dùng kỹ năng từ game hành động cạnh tranh. Không sao chép tài sản, nhân vật, mã nguồn hay thương hiệu của game khác.

## 2. Kỹ thuật

- Godot 4.7.2 Stable; GDScript.
- Logical viewport 960 × 540, landscape, Compatibility renderer.
- Không yêu cầu PC, root, C#/.NET, plugin native, đăng nhập, server, quảng cáo hay giao dịch.
- Nền, nhân vật, quái, phù văn, đạn và nút hành động hiện dùng hình học 2D tùy chỉnh. Đây là lớp đồ họa prototype có chủ ý; chưa phải bộ sprite pixel-art được vẽ thủ công theo từng frame hoặc bộ tài nguyên thương mại hoàn chỉnh.
- Nhánh feature/vn-visual-combat được tách khỏi prototype/m1-combat để giữ lại bản đang chạy. Chỉ nhập PR sau khi kiểm tra CI và đánh giá thay đổi.

## 3. Vòng chơi và chiến đấu

- Một nhân vật kiếm khách, một đấu trường, đợt quái tăng áp lực theo thời gian.
- Lượt chơi có giới hạn tối đa 8 phút; trùm xuất hiện ở phút thứ 6. Hạ trùm là điều kiện chiến thắng; hết giờ mà trùm còn sống là thất bại; sinh lực về 0 cũng là thất bại.
- Quái thường, quỷ nhanh, hộ vệ, tinh anh và trùm có tốc độ, sinh lực, sát thương và thời gian báo đòn khác nhau.
- Đánh thường hồi một ít nội lực và gắn Kiếm Ấn. Kiếm Khí tự chọn mục tiêu còn sống gần nhất trong tầm và tiêu hao nội lực; đòn trúng mục tiêu có ấn kích nổ combo.
- Lướt có hồi chiêu; lướt đúng lúc đòn đối thủ đang báo trước sẽ hủy đòn và phản kích.
- Phá Trận gây sát thương diện rộng, tiêu hao nội lực và có hồi chiêu.
- Tuyệt Kỹ cần đủ 100 nội lực; tạo vùng tấn công diện rộng và một khoảng bảo vệ ngắn.
- Nội lực hồi từ từ, từ đòn đánh thường, hạ quái và né hoàn hảo. Giao diện hiển thị thanh sinh lực, nội lực, hồi chiêu và trạng thái thiếu tài nguyên.
- Lên cấp từ 8 kinh nghiệm, ngưỡng tăng thêm 3 mỗi lần nhằm hạn chế việc bảng chọn nâng cấp ngắt nhịp quá thường xuyên. Chọn một trong ba nâng cấp và tạm dừng chiến đấu trong lúc chọn.
- Quái thường có 7% cơ hội rơi một tinh thạch. Tinh anh có 68% cơ hội rơi 2–3 tinh thạch. Trùm thưởng 10 tinh thạch. Tinh thạch được hút về khi người chơi đến gần và tiến trình lưu cục bộ.
- Bảo Vật Phản Kích có giá 35 tinh thạch và được lưu vĩnh viễn.

## 4. Điều khiển

| Nút | Tác dụng |
|---|---|
| Joystick trái | Di chuyển 8 hướng |
| Đánh | Cận chiến, gắn Kiếm Ấn và hồi một ít nội lực |
| Kiếm Khí | Tự nhắm kẻ địch gần nhất trong tầm, tiêu hao 9 nội lực |
| Lướt | Né đòn, hồi chiêu khoảng 1,15 giây |
| Phá Trận | Đòn diện rộng, tiêu hao 32 nội lực, hồi chiêu 7 giây |
| Tuyệt Kỹ | Đòn diện rộng mạnh, tiêu hao 100 nội lực |
| Tạm dừng | Dừng mô phỏng và mở menu |

## 5. Các cổng kiểm thử

### Cổng A — mã nguồn và khởi động
- Godot 4.7.2 import/parse không có lỗi.
- Kiểm thử luật chiến đấu và luồng scene vượt qua.
- Main scene headless khởi động thành công.

### Cổng B — cảm ứng và chiến đấu trên điện thoại
- Joystick hồi về trung tính khi nhả; có thể giữ joystick đồng thời bấm nút khác.
- Hồi chiêu, năng lượng, nút thiếu nội lực và báo đòn đọc được trên màn hình thật.
- Không có nút đè lên nhau hoặc ra khỏi vùng an toàn.

### Cổng C — lượt chơi và lưu
- Trùm, thắng/thua, nâng cấp, phần thưởng và tinh thạch hoạt động đúng; không trả thưởng hai lần.
- Lưu cục bộ còn tồn tại sau khi đóng/mở ứng dụng và khi offline.

### Cổng D — hiệu năng / APK
- Đo FPS theo tải, frame time, bộ nhớ, nhiệt độ và pin trên vivo V2120.
- Xuất APK bằng export template phù hợp Godot 4.7.2, kiểm tra ABI và cài đặt thật.
- Mục tiêu sơ bộ: gần 60 FPS ở tải nhẹ và không dưới 30 FPS trong cảnh áp lực; đây là mục tiêu cần đo, không phải kết quả đã đạt.

## 6. Quy tắc trung thực

CI headless không xác nhận cảm giác điều khiển, hiệu năng, nhiệt độ, pin, hành vi cảm ứng hay APK. Không tuyên bố các cổng B/C/D đạt cho đến khi có bằng chứng trên điện thoại. Tài nguyên có giấy phép chưa rõ không được nhập vào repo.
