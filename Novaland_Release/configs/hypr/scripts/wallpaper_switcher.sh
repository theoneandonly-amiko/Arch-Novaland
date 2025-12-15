#!/bin/bash

# --- CẤU HÌNH ---
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CONFIG_FILE="$HOME/.config/hypr/hyprpaper.conf"
TEMP_THEME="/tmp/rofi_wallpaper.rasi"

# Kiểm tra thư mục
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Thư mục $WALLPAPER_DIR không tồn tại!"
    exit 1
fi

# --- 1. TẠO FILE GIAO DIỆN RIÊNG (FIXED SYNTAX) ---
cat > "$TEMP_THEME" <<EOF
configuration {
    show-icons: true;
}

* {
    background-color: #0d0f18;
    text-color:       #cdd6f4;
    font:             "JetBrainsMono Nerd Font Bold 10";
}

window {
    width:            950px;
    height:           600px;
    border:           2px;
    border-color:     #2de2e6;
    border-radius:    12px;
    padding:          10px;
}

mainbox {
    children:         [ listview ];
    padding:          10px;
}

/* Lưới 4 cột x 2 hàng */
listview {
    columns:          4;
    lines:            2;
    spacing:          20px;
    padding:          10px;
    flow:             horizontal;
    fixed-height:     false;
    background-color: transparent;
}

/* Ô chứa ảnh */
element {
    orientation:      vertical;
    padding:          10px;
    border-radius:    8px;
    spacing:          5px;
    cursor:           pointer;
    background-color: transparent;
    text-color:       inherit;
}

element selected {
    background-color: #2de2e6;
    text-color:       #0d0f18;
    /* --- ĐOẠN SỬA LỖI TẠI ĐÂY --- */
    border:           2px solid;  /* Chỉ khai báo độ dày và kiểu */
    border-color:     #cdd6f4;    /* Khai báo màu riêng */
}

/* Cấu hình kích thước Thumbnail */
element-icon {
    size:             180px;
    horizontal-align: 0.5;
    vertical-align:   0.5;
    cursor:           inherit;
    background-color: transparent;
}

element-text {
    horizontal-align: 0.5;
    vertical-align:   0.5;
    background-color: transparent;
    text-color:       inherit;
}
EOF

# --- 2. TẠO DANH SÁCH ẢNH KÈM THUMBNAIL ---
list_items=""
while IFS= read -r file; do
    filename=$(basename "$file")
    list_items+="${filename}\0icon\x1f${file}\n"
done < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort)

# --- 3. HIỂN THỊ ROFI ---
selected_name=$(echo -ne "$list_items" | rofi -dmenu -i -p "🖼 GALLERY" \
    -format 's' \
    -theme "$TEMP_THEME")

# Nếu không chọn gì thì thoát
if [ -z "$selected_name" ]; then
    exit 0
fi

# --- 4. XỬ LÝ ĐỔI ẢNH ---
FULL_PATH="$WALLPAPER_DIR/$selected_name"

echo "Changing to: $FULL_PATH"

hyprctl hyprpaper preload "$FULL_PATH"
hyprctl hyprpaper wallpaper ",$FULL_PATH"
hyprctl hyprpaper unload unused

# Lưu config
echo "preload = $FULL_PATH" > "$CONFIG_FILE"
echo "wallpaper = ,$FULL_PATH" >> "$CONFIG_FILE"
echo "splash = false" >> "$CONFIG_FILE"

# Thông báo
notify-send "Wallpaper Gallery" "Đã chọn: $selected_name" -i "$FULL_PATH"
