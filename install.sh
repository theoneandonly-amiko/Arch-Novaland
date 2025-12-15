#!/bin/bash

# ==============================================================================
#  ARCH NOVALAND INSTALLER
#  Author: Neonova Solara
#  Description: Automated setup script for Hyprland Novaland Rice
# ==============================================================================

# --- VARIABLES ---
LOG="install.log"
BACKUP_DIR="$HOME/.config/Novaland_Backup_$(date +%Y%m%d_%H%M%S)"
CURRENT_USER=$(whoami)
# Username gốc trong config cần thay thế
ORIGIN_USER="neonova_solara"
# Tên thư mục chứa config (nằm cùng cấp với script này)
SRC_DIR="Novaland_Release"

# Colors
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# --- LANGUAGE SELECTION ---
clear
echo -e "${BLUE}"
echo "███╗   ██╗ ██████╗ ██╗   ██╗ █████╗ ██╗      █████╗ ███╗   ██╗██████╗ "
echo "████╗  ██║██╔═══██╗██║   ██║██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗"
echo "██╔██╗ ██║██║   ██║██║   ██║███████║██║     ███████║██╔██╗ ██║██║  ██║"
echo "██║╚██╗██║██║   ██║╚██╗ ██╔╝██╔══██║██║     ██╔══██║██║╚██╗██║██║  ██║"
echo "██║ ╚████║╚██████╔╝ ╚████╔╝ ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝"
echo "╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ "
echo -e "${NC}"
echo "=== ARCH NOVALAND INSTALLER ==="
echo "1. English"
echo "2. Tiếng Việt"
echo "-------------------------------------"
read -p "Select language / Chọn ngôn ngữ (1/2): " LANG_OPT

if [ "$LANG_OPT" == "2" ]; then
    MSG_START="Bắt đầu cài đặt Arch Novaland..."
    MSG_ERR_ROOT="LỖI: Không chạy script này bằng quyền root (sudo). Hãy chạy với user thường."
    MSG_ERR_SRC="LỖI: Không tìm thấy thư mục '$SRC_DIR'. Hãy đảm bảo bạn đã giải nén đúng quy trình (Thư mục '$SRC_DIR' phải nằm cạnh file install.sh)."
    MSG_CHECK_ARCH="Đang kiểm tra hệ thống..."
    MSG_NOT_ARCH="CẢNH BÁO: Bạn không dùng Arch Linux. Script có thể lỗi."
    MSG_INSTALL_YAY="Không thấy AUR Helper. Đang cài đặt yay..."
    MSG_INSTALL_PKG="Đang cài đặt các gói cần thiết (Hyprland, Waybar, Rofi, Python Requests...)..."
    MSG_BACKUP="Đang sao lưu config cũ vào: $BACKUP_DIR"
    MSG_FIX_PATH="Đang cập nhật đường dẫn user từ '$ORIGIN_USER' sang '$CURRENT_USER'..."
    MSG_COPY="Đang sao chép file cấu hình vào máy..."
    MSG_SDDM_ASK="Bạn có muốn cài Theme màn hình đăng nhập (SDDM) không? (y/n): "
    MSG_SDDM_INSTALL="Đang cài đặt SDDM Theme (cần mật khẩu sudo)..."
    MSG_DONE="CÀI ĐẶT HOÀN TẤT! Hãy khởi động lại máy để tận hưởng."
    MSG_ERR="Có lỗi xảy ra. Vui lòng kiểm tra lại."
else
    MSG_START="Starting Arch Novaland installation..."
    MSG_ERR_ROOT="ERROR: Do not run this script as root (sudo). Run as normal user."
    MSG_ERR_SRC="ERROR: Directory '$SRC_DIR' not found. Please ensure correct extraction (Directory '$SRC_DIR' must be next to install.sh)."
    MSG_CHECK_ARCH="Checking system..."
    MSG_NOT_ARCH="WARNING: You are not on Arch Linux. Proceed with caution."
    MSG_INSTALL_YAY="AUR Helper not found. Installing yay..."
    MSG_INSTALL_PKG="Installing dependencies (Hyprland, Waybar, Rofi, Python Requests...)..."
    MSG_BACKUP="Backing up old configs to: $BACKUP_DIR"
    MSG_FIX_PATH="Updating user paths from '$ORIGIN_USER' to '$CURRENT_USER'..."
    MSG_COPY="Copying configuration files..."
    MSG_SDDM_ASK="Do you want to install the SDDM Login Theme? (y/n): "
    MSG_SDDM_INSTALL="Installing SDDM Theme (sudo password required)..."
    MSG_DONE="INSTALLATION COMPLETE! Please reboot your system."
    MSG_ERR="An error occurred."
fi

# --- 1. PRE-CHECKS ---
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}$MSG_ERR_ROOT${NC}"
    exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
    echo -e "${RED}$MSG_ERR_SRC${NC}"
    echo "Expected path: $(pwd)/$SRC_DIR"
    exit 1
fi

echo -e "${GREEN}$MSG_START${NC}"

# Check Arch
if [ ! -f /etc/arch-release ]; then
    echo -e "${YELLOW}$MSG_NOT_ARCH${NC}"
    sleep 3
fi

# --- 2. INSTALL DEPENDENCIES ---
echo -e "${YELLOW}$MSG_INSTALL_PKG${NC}"

# Danh sách gói đã thêm python-requests cho script weather
PKGS=(
    hyprland
    hyprpaper
    hyprlock
    waybar
    rofi-wayland
    kitty
    thunar
    cava
    swaync
    wlogout
    grim
    slurp
    swappy
    wl-clipboard
    brightnessctl
    playerctl
    nm-connection-editor
    network-manager-applet
    blueman
    ttf-jetbrains-mono-nerd
    noto-fonts-emoji
    polkit-gnome
    sddm
    qt5-graphicaleffects
    qt5-quickcontrols2
    qt5-svg
    python-requests
)

# Cài Yay nếu chưa có
if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
    echo -e "${BLUE}$MSG_INSTALL_YAY${NC}"
    sudo pacman -S --needed git base-devel --noconfirm
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

AUR_HELPER=$(command -v paru || command -v yay)
$AUR_HELPER -S --needed "${PKGS[@]}" --noconfirm

# --- 3. FIX PATHS & PREPARE ---
echo -e "${YELLOW}$MSG_FIX_PATH${NC}"
# Tìm và thay thế username cũ bằng username mới trong thư mục nguồn trước khi copy
find "$SRC_DIR" -type f -exec sed -i "s|/home/$ORIGIN_USER|/home/$CURRENT_USER|g" {} +

# --- 4. BACKUP OLD CONFIGS ---
echo -e "${BLUE}$MSG_BACKUP${NC}"
mkdir -p "$BACKUP_DIR"
for folder in hypr waybar rofi kitty cava wlogout swaync; do
    if [ -d "$HOME/.config/$folder" ]; then
        mv "$HOME/.config/$folder" "$BACKUP_DIR/"
        echo "  -> Backed up $folder"
    fi
done

# --- 5. COPY CONFIGS ---
echo -e "${GREEN}$MSG_COPY${NC}"
mkdir -p "$HOME/.config"
cp -r "$SRC_DIR/configs/"* "$HOME/.config/"

# Cấp quyền thực thi cho các script con (bao gồm cả weather.py mới)
chmod +x "$HOME/.config/hypr/scripts/"*.sh
chmod +x "$HOME/.config/waybar/scripts/"* # Cấp quyền cho cả folder scripts waybar để dính file .py và .sh

# Tạo thư mục Wallpaper để tránh lỗi hyprpaper
mkdir -p "$HOME/Pictures/Wallpapers"
if [ -f "$SRC_DIR/sddm_theme/Backgrounds/Mountain.jpg" ]; then
    cp "$SRC_DIR/sddm_theme/Backgrounds/Mountain.jpg" "$HOME/Pictures/Wallpapers/Default_Novaland.jpg"
fi

# --- 6. INSTALL SDDM THEME ---
echo -ne "${YELLOW}$MSG_SDDM_ASK${NC}"
read -r INSTALL_SDDM
if [[ "$INSTALL_SDDM" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}$MSG_SDDM_INSTALL${NC}"
    sudo mkdir -p /usr/share/sddm/themes
    sudo cp -r "$SRC_DIR/sddm_theme" /usr/share/sddm/themes/Novaland

    # Tạo config file cho SDDM
    # Kiểm tra thư mục config sddm
    if [ ! -d "/etc/sddm.conf.d" ]; then
        sudo mkdir -p /etc/sddm.conf.d
    fi

    echo "[Theme]
Current=Novaland" | sudo tee /etc/sddm.conf.d/theme.conf.user > /dev/null

    # Enable SDDM service
    sudo systemctl enable sddm
    echo "  -> SDDM Theme installed."
fi

# --- FINISH ---
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}$MSG_DONE${NC}"
