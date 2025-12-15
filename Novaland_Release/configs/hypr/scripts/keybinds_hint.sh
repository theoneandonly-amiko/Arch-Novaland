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
🚀  | SUPER + R        | Open App Launcher
   | SUPER + Q        | Open Terminal (Kitty)
   | SUPER + E        | Open File Manager (Thunar)
   | SUPER + M        | Open Power Menu
🔒  | SUPER + L        | Lock Screen
🖼   | SUPER + W        | Wallpaper Switcher
🎮  | SUPER + G        | Toggle Game Mode
⌨   | SUPER + K        | Show this Cheatsheet
📸  | PrtSc            | Capture Region
   | SUPER + PrtSc    | Full Screen Capture (immediate save)
📋  | SHIFT + PrtSc    | Capture Region (Copy to Clipboard)
✕   | SUPER + C        | Close hovered window
   | SUPER + V        | Toggle Float Window
   | ALT + TAB        | Switch Workspace (SUPER + TAB also work wtf)
"


# 3. Hiển thị
# -config /dev/null: Lệnh quan trọng nhất -> Bỏ qua toàn bộ config cũ của máy
# -theme "$theme_file": Chỉ dùng file theme ta vừa ttạo ở trên
echo "$data" | column -t -s '|' | rofi -dmenu -i -p "KEYBINDS" -config /dev/null -theme "$theme_file"
