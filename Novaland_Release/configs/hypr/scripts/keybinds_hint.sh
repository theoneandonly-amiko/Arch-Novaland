#!/bin/bash

# 1. Tạo file giao diện riêng biệt (Theme cô lập hoàn toàn)
theme_file="/tmp/rofi_cheat_sheet.rasi"

cat > "$theme_file" <<EOF
/* Xóa sạch cấu hình cũ */
configuration {
    show-icons: false;
}

* {
    /* Màu sắc Neon Tech */
    background-color: #0d0f18;
    text-color:       #cdd6f4;
    border-color:     #2de2e6;
    
    /* Font Mono để căn thẳng hàng tuyệt đối */
    font: "JetBrainsMono Nerd Font Mono 11";
}

window {
    width:            950px; /* Tăng rộng chút để chứa đủ text */
    height:           650px; /* Tăng cao để chứa thêm dòng */
    border:           2px;
    border-radius:    10px;
    padding:          20px;
}

mainbox {
    children:         [ listview ]; /* Chỉ hiện danh sách, bỏ thanh tìm kiếm */
}

listview {
    columns:          1;      /* Bắt buộc 1 cột */
    lines:            18;     /* Tăng số dòng hiển thị */
    spacing:          10px;   /* Khoảng cách giữa các dòng */
    cycle:            false;
}

element {
    orientation:      horizontal;
    children:         [ element-text ]; /* QUAN TRỌNG: Chỉ giữ lại Text, vứt bỏ Icon */
    padding:          5px;
    background-color: transparent;
}

element selected {
    background-color: #2de2e6; /* Màu Cyan khi chọn */
    text-color:       #0d0f18;
    border-radius:    5px;
}

element-text {
    vertical-align:   0.5;
    background-color: transparent;
    text-color:       inherit;
}
EOF

# 2. Dữ liệu phím tắt (Thẳng hàng)
# Lưu ý: Dùng dấu gạch đứng | để chia cột
# Đã cập nhật theo hyprland.conf của Neonova_solara
data="
🚀  | SUPER + R        | Mở Menu Ứng Dụng (App Launcher)
   | SUPER + Q        | Mở Terminal (Kitty)
   | SUPER + E        | Mở Trình Quản Lý File (Thunar)
   | SUPER + M        | Mở Menu Nguồn (Power Menu)
🔒  | SUPER + L        | Khóa Màn Hình (Lock Screen)
🖼   | SUPER + W        | Đổi Hình Nền (Wallpaper Switcher)
🎮  | SUPER + G        | Bật/Tắt Game Mode (Hiệu năng cao)
⌨   | SUPER + K        | Hiện Bảng Phím Tắt Này
📸  | PrtSc            | Chụp Vùng + Chỉnh Sửa (Swappy)
   | SUPER + PrtSc    | Chụp Toàn Màn Hình (Lưu Ảnh)
📋  | SHIFT + PrtSc    | Chụp Vùng (Lưu vào Clipboard)
✕   | SUPER + C        | Đóng Cửa Sổ Hiện Tại
   | SUPER + V        | Bật/Tắt Cửa Sổ Nổi (Floating)
   | SUPER + Arrows   | Di Chuyển Tiêu Điểm Cửa Sổ
   | ALT + TAB        | Chuyển Workspace (Tất cả)
   | SUPER + TAB      | Chuyển Workspace (Có App đang mở)
☀   | FN Keys          | Tăng/Giảm Độ Sáng & Âm Lượng
"


# 3. Hiển thị
# -config /dev/null: Lệnh quan trọng nhất -> Bỏ qua toàn bộ config cũ của máy
# -theme "$theme_file": Chỉ dùng file theme ta vừa ttạo ở trên
echo "$data" | column -t -s '|' | rofi -dmenu -i -p "KEYBINDS" -config /dev/null -theme "$theme_file"
