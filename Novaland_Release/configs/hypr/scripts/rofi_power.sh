#!/bin/bash

# 1. Tạo file giao diện (Giữ nguyên style Neon ngang đẹp)
cat > /tmp/rofi_power.rasi <<EOF
configuration {
    show-icons: false;
}

* {
    background-color: #0d0f18;
    text-color:       #cdd6f4;
    sel-bg:           #2de2e6;
    sel-fg:           #0d0f18;
    
    font: "JetBrainsMono Nerd Font Bold 12";
}

window {
    width: 500px;
    height: 90px;
    border: 2px;
    border-color: #2de2e6;
    border-radius: 10px;
    padding: 0px;
    children: [ listview ];
}

listview {
    columns: 4;
    lines: 1;
    spacing: 10px;
    padding: 15px;
    layout: vertical;
}

element {
    background-color: transparent;
    text-color:       inherit;
    border-radius:    6px;
    padding:          15px 5px 15px 5px;
    cursor:           pointer;
}

element selected {
    background-color: @sel-bg;
    text-color:       @sel-fg;
}

element-text {
    background-color: transparent;
    text-color:       inherit;
    horizontal-align: 0.5;
    vertical-align:   0.5;
    cursor:           inherit;
}
EOF

# 2. Định nghĩa các nút
lock=" Lock"
logout=" Logout"
reboot=" Reboot"
shutdown=" Power"

# 3. Mở Rofi
options="$lock\n$logout\n$reboot\n$shutdown"
selected_option=$(echo -e "$options" | rofi -dmenu -i -p "POWER" -theme /tmp/rofi_power.rasi)

# 4. Xử lý hành động
case $selected_option in
    "$lock")
        hyprlock
        ;;
    "$logout")
        # --- ĐÃ SỬA Ở ĐÂY ---
        # Thay vì "giết" user, ta bảo Hyprland thoát nhẹ nhàng
        hyprctl dispatch exit
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$shutdown")
        systemctl poweroff
        ;;
esac
