# Ghi chú nghiên cứu — mỹ thuật, cảm ứng và hiệu năng

Tài liệu này ghi lại các nguyên tắc đã tham khảo, cách áp dụng trong Game2D và những phần còn phải kiểm chứng trên vivo V2120. Repo không sao chép mã, sprite, âm thanh hay nhân vật từ các game thương mại.

## 1. Godot custom drawing và kiến trúc sprite

Nguồn:
- https://docs.godotengine.org/en/stable/classes/class_canvasitem.html
- https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html
- https://docs.godotengine.org/en/4.7/about/list_of_features.html

Các điểm áp dụng:
- CanvasItem/Node2D có thể vẽ hình học trong _draw(). Godot cache lệnh vẽ và chỉ yêu cầu vẽ lại khi cần; nền đấu trường dùng seed cố định và không gọi redraw theo từng frame.
- Sprite nhân vật/quái tách khỏi các hiệu ứng báo đòn, thanh máu và vệt kỹ năng, để mỗi lớp có trách nhiệm riêng.
- Sprite gốc được lưu dạng SVG pixel-art có hình khối bậc thang, hiển thị bằng nearest texture filtering để giữ cạnh sắc.
- Các hiệu ứng tấn công dùng draw_arc/draw_line và vệt kiếm khí; chúng là hiệu ứng procedural, chưa thay thế cho sprite-sheet hoạt ảnh nhiều frame.
- Đây là nền tảng đồ họa đầu tiên. Sau kiểm thử trên điện thoại, bước tiếp theo có thể là sprite-sheet chuyển động, tile set vẽ tay và âm thanh/nhạc có giấy phép.

## 2. Ánh sáng 2D và bóng giả lập

Nguồn:
- https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html
- https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html

Godot hỗ trợ CanvasModulate, PointLight2D, DirectionalLight2D và LightOccluder2D. Tuy nhiên, tài liệu engine cảnh báo ánh sáng có bóng trên renderer mobile/Compatibility có thể tốn hơn ánh sáng không bóng và hiệu năng không tăng tuyến tính khi có nhiều đèn có bóng.

Quyết định cho prototype:
- Tạo cảm giác khối bằng bóng tiếp xúc ellipse, các lớp màu, rêu, mép đá sáng/tối, phù văn và viền tối thay vì bật hàng loạt ánh sáng động.
- Giữ rõ tương phản nhân vật/quái với nền và màu báo đòn.
- Không khẳng định đây là chiếu sáng vật lý hoặc đồ họa chân thực; đây là mỹ thuật pixel-art fantasy có chủ đích.
- Nếu hiệu năng thiết bị còn dư, có thể thử một vài đèn không bóng quanh trùm/điểm nhấn rồi đo frame time so với baseline.

## 3. Cảm ứng đa điểm

Nguồn:
- https://docs.godotengine.org/en/4.7/classes/class_inputeventscreentouch.html
- https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html
- https://github.com/abdulroufsidhu/godot_touch_screen_joystick

InputEventScreenTouch cung cấp index và vị trí riêng cho các lần chạm, cho phép xử lý nhiều ngón tay. Prototype giữ pointer ID riêng cho joystick và tách tín hiệu các nút hành động; repo joystick công khai chỉ dùng làm tham chiếu khái niệm, không nhập add-on hoặc mã nguồn của nó.

Các mục bắt buộc trên thiết bị:
- Giữ joystick và bấm kỹ năng cùng lúc.
- Xác nhận nhả joystick sẽ xóa hướng di chuyển.
- Xác nhận chạm nút không vô tình kích hoạt joystick.
- Kiểm tra safe area/viền hệ thống và kích thước chữ/nút ở hướng ngang.

## 4. Thiết kế chiến đấu và phân cấp thông tin

Nguyên tắc được dùng:
- Báo đòn phải xuất hiện trước khi sát thương xảy ra; màu/vòng cảnh báo khác biệt với hiệu ứng tấn công thông thường.
- Hồi chiêu và thiếu nội lực được biểu đạt ngay trên nút, không chỉ bằng một dòng thông báo.
- Đòn thường gắn Kiếm Ấn, Kiếm Khí tiêu thụ ấn để tạo combo, lướt hoàn hảo ngắt đòn, kỹ năng diện rộng tiêu hao nội lực, Tuyệt Kỹ yêu cầu thanh đầy.
- Hạ quái thường không cho tinh thạch chắc chắn; tinh anh/trùm là nguồn thưởng tốt hơn.
- Lên cấp không quá dày: yêu cầu ban đầu 8 XP và tăng dần 3 XP mỗi lần. Bảng nâng cấp vẫn tạm dừng mô phỏng; kiểm tra trên điện thoại sẽ xác định tần suất này có còn gây gián đoạn quá nhiều hay không.

## 5. Tài nguyên và giấy phép

- Sáu sprite SVG trong assets/art là tài nguyên gốc do dự án tạo.
- Không có sprite/nhạc lấy từ Nghịch Thủy Hàn, GTA V, Free Fire hay Liên Quân.
- Không dùng add-on runtime hoặc thư viện ngoài.
- Mọi tài nguyên bên ngoài sẽ cần kiểm tra giấy phép riêng trước khi nhập.

## 6. Android export và giới hạn kiểm chứng

Nguồn:
- https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
- https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html
- https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformandroid.html

Project khởi động trong editor không chứng minh APK đã xuất/cài thành công. Export template phải khớp Godot; ABI armeabi-v7a/arm64-v8a phải được kiểm tra trong artifact thay vì đoán từ máy phát triển.

GitHub Actions đang dùng headless Linux để kiểm tra import/parse, test gameplay và khởi động scene. Kết quả đó không đo FPS, nhiệt độ, pin, độ trễ cảm ứng, giữ trạng thái sau khi kill process hoặc việc cài APK trên vivo V2120. Các bước này vẫn cần nghiệm thu trên thiết bị thật.
