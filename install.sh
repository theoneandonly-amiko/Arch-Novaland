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
ORIGIN_USER="neonova_solara" 
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
    MSG_ERR_SRC="LỖI: Không tìm thấy thư mục '$SRC_DIR'. Hãy đảm bảo bạn đã giải nén đúng quy trình."
    MSG_CHECK_ARCH="Đang kiểm tra hệ thống..."
    MSG_NOT_ARCH="CẢNH BÁO: Bạn không dùng Arch Linux. Script có thể lỗi."
    MSG_INSTALL_YAY="Không thấy AUR Helper. Đang cài đặt yay..."
    MSG_INSTALL_PKG="Đang cài đặt các gói cần thiết (Không bao gồm SDDM & Fcitx)..."
    MSG_BACKUP="Đang sao lưu config cũ vào: $BACKUP_DIR"
    MSG_FIX_PATH="Đang cập nhật đường dẫn user và cấu hình..."
    MSG_MONITOR_FIX="Đang cấu hình Hyprland tự nhận diện màn hình tốt nhất..."
    MSG_COPY="Đang sao chép file cấu hình vào máy..."
    MSG_INSTALL_OMZ="Đang cài đặt Oh My Zsh..."
    MSG_ZSH_COPY="Đang cài đặt cấu hình Zsh (.zshrc)..."
    MSG_WALLPAPER="Đang sao chép hình nền vào ~/Pictures/Wallpapers..."
    MSG_SDDM_ASK="Bạn có muốn cài đặt và kích hoạt SDDM + Theme Sugar Candy không? (y/n): "
    MSG_SDDM_INSTALL="Đang cài đặt các gói SDDM và Theme (cần mật khẩu sudo)..."
    MSG_DONE="CÀI ĐẶT HOÀN TẤT! Hãy khởi động lại máy để tận hưởng."
    MSG_ZSH_NOTE="LƯU Ý: Config Kitty sử dụng Zsh. Hãy đảm bảo bạn đổi shell mặc định bằng lệnh: chsh -s /usr/bin/zsh"
else
    MSG_START="Starting Arch Novaland installation..."
    MSG_ERR_ROOT="ERROR: Do not run this script as root (sudo)."
    MSG_ERR_SRC="ERROR: Directory '$SRC_DIR' not found."
    MSG_CHECK_ARCH="Checking system..."
    MSG_NOT_ARCH="WARNING: You are not on Arch Linux."
    MSG_INSTALL_YAY="AUR Helper not found. Installing yay..."
    MSG_INSTALL_PKG="Installing dependencies (Excluding SDDM & Fcitx)..."
    MSG_BACKUP="Backing up old configs to: $BACKUP_DIR"
    MSG_FIX_PATH="Updating user paths and configs..."
    MSG_MONITOR_FIX="Configuring Hyprland to auto-detect best monitor mode..."
    MSG_COPY="Copying configuration files..."
    MSG_INSTALL_OMZ="Installing Oh My Zsh..."
    MSG_ZSH_COPY="Installing Zsh configuration (.zshrc)..."
    MSG_WALLPAPER="Copying wallpapers to ~/Pictures/Wallpapers..."
    MSG_SDDM_ASK="Do you want to install and enable SDDM + Sugar Candy Theme? (y/n): "
    MSG_SDDM_INSTALL="Installing SDDM packages and Theme..."
    MSG_DONE="INSTALLATION COMPLETE! Please reboot your system."
    MSG_ZSH_NOTE="NOTE: Kitty config uses Zsh. Make sure to change your default shell: chsh -s /usr/bin/zsh"
fi

# --- 1. PRE-CHECKS ---
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}$MSG_ERR_ROOT${NC}"
    exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
    echo -e "${RED}$MSG_ERR_SRC${NC}"
    exit 1
fi

echo -e "${GREEN}$MSG_START${NC}"

if [ ! -f /etc/arch-release ]; then
    echo -e "${YELLOW}$MSG_NOT_ARCH${NC}"
    sleep 3
fi

# --- 2. INSTALL DEPENDENCIES ---
echo -e "${YELLOW}$MSG_INSTALL_PKG${NC}"

PKGS=(
    # --- Core Components ---
    hyprland
    hyprpaper
    hyprlock
    waybar
    rofi-wayland
    swaync
    wlogout
    fastfetch
    
    # --- Terminal & Shell ---
    kitty
    zsh
    curl # Cần để cài Oh My Zsh
    git  # Cần để cài Oh My Zsh
    
    # --- File Manager ---
    thunar
    
    # --- Audio & Media ---
    pipewire
    wireplumber
    pavucontrol
    playerctl
    cava
    
    # --- System Utilities ---
    brightnessctl
    libnotify
    power-profiles-daemon
    polkit-gnome
    wl-clipboard
    grim
    slurp
    swappy
    
    # --- Network & Bluetooth ---
    nm-connection-editor
    network-manager-applet
    blueman
    
    # --- Fonts ---
    ttf-jetbrains-mono-nerd
    ttf-hack-nerd
    noto-fonts-emoji
    
    # --- Scripts Support ---
    python-requests
    
    # ĐÃ GỠ: fcitx5* và sddm* khỏi danh sách này theo yêu cầu
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

# Enable services quan trọng
echo -e "${BLUE}Enabling services (Bluetooth, Power Profile)...${NC}"
sudo systemctl enable --now bluetooth
sudo systemctl enable --now power-profiles-daemon

# --- 3. FIX PATHS & PREPARE ---
echo -e "${YELLOW}$MSG_FIX_PATH${NC}"
# Sửa đường dẫn username
find "$SRC_DIR" -type f -exec sed -i "s|/home/$ORIGIN_USER|/home/$CURRENT_USER|g" {} +

# Vô hiệu hóa fcitx5 trong config hyprland vì đã gỡ bỏ gói cài đặt
if [ -f "$SRC_DIR/configs/hypr/hyprland.conf" ]; then
    sed -i 's/^exec-once = fcitx5/# exec-once = fcitx5/g' "$SRC_DIR/configs/hypr/hyprland.conf"
fi

# [NEW] Cấu hình Monitor tự động nhận diện (highres, auto)
echo -e "${YELLOW}$MSG_MONITOR_FIX${NC}"
if [ -f "$SRC_DIR/configs/hypr/hyprland.conf" ]; then
    # Tìm dòng bắt đầu bằng monitor= và thay thế bằng cấu hình auto
    sed -i 's/^monitor=.*/monitor=,highres,auto,1/g' "$SRC_DIR/configs/hypr/hyprland.conf"
    echo "  -> Updated monitor config to: monitor=,highres,auto,1"
fi

# --- 4. BACKUP OLD CONFIGS ---
echo -e "${BLUE}$MSG_BACKUP${NC}"
mkdir -p "$BACKUP_DIR"
for folder in hypr waybar rofi kitty cava wlogout swaync; do
    if [ -d "$HOME/.config/$folder" ]; then
        mv "$HOME/.config/$folder" "$BACKUP_DIR/"
    fi
done

# Backup .zshrc nếu có
if [ -f "$HOME/.zshrc" ]; then
    mv "$HOME/.zshrc" "$BACKUP_DIR/"
fi

# --- 5. COPY CONFIGS ---
echo -e "${GREEN}$MSG_COPY${NC}"
mkdir -p "$HOME/.config"
cp -r "$SRC_DIR/configs/"* "$HOME/.config/"

# [NEW] Install Oh My Zsh (Trước khi copy .zshrc của Novaland)
echo -e "${YELLOW}$MSG_INSTALL_OMZ${NC}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    # Cài đặt không giám sát (unattended) để script không bị dừng lại chờ user
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "  -> Oh My Zsh installed successfully."
else
    echo "  -> Oh My Zsh already installed. Skipping..."
fi

# [NEW] Cài đặt Zsh Config (.zshrc)
echo -e "${GREEN}$MSG_ZSH_COPY${NC}"
ZSHRC_FOUND=0

# Tìm file .zshrc trong thư mục gốc hoặc configs của bộ cài
if [ -f "$SRC_DIR/.zshrc" ]; then
    cp "$SRC_DIR/.zshrc" "$HOME/"
    ZSHRC_FOUND=1
elif [ -f "$SRC_DIR/configs/.zshrc" ]; then
    cp "$SRC_DIR/configs/.zshrc" "$HOME/"
    ZSHRC_FOUND=1
fi

# Copy thêm file powerlevel10k nếu có
if [ -f "$SRC_DIR/.p10k.zsh" ]; then
    cp "$SRC_DIR/.p10k.zsh" "$HOME/"
fi

if [ $ZSHRC_FOUND -eq 1 ]; then
    echo "  -> Installed .zshrc to $HOME"
    # Fix lại path user trong .zshrc vừa copy
    sed -i "s|/home/$ORIGIN_USER|/home/$CURRENT_USER|g" "$HOME/.zshrc"
else
    echo -e "${YELLOW}  -> Warning: .zshrc not found in source directory.${NC}"
fi

# Cấp quyền thực thi script
chmod +x "$HOME/.config/hypr/scripts/"*.sh
chmod +x "$HOME/.config/waybar/scripts/"*

# [NEW] Sao chép Wallpapers
echo -e "${GREEN}$MSG_WALLPAPER${NC}"
mkdir -p "$HOME/Pictures/Wallpapers"

# 1. Tìm thư mục wallpapers trong nguồn (nếu bạn đóng gói thư mục tên là 'wallpapers')
if [ -d "$SRC_DIR/wallpapers" ]; then
    cp -r "$SRC_DIR/wallpapers/"* "$HOME/Pictures/Wallpapers/"
    echo "  -> Copied from $SRC_DIR/wallpapers"
# 2. Nếu không thấy, copy từ sddm backgrounds như phương án dự phòng
elif [ -d "$SRC_DIR/sddm_theme/Backgrounds" ]; then
    cp "$SRC_DIR/sddm_theme/Backgrounds/"* "$HOME/Pictures/Wallpapers/"
    echo "  -> Copied from SDDM Backgrounds"
fi

# Copy thêm file Stargazing-min.png nếu nó nằm lẻ bên ngoài (check theo config cũ của bạn)
# Nếu bạn để file ảnh này ở đâu đó khác trong repo, hãy đảm bảo script này tìm thấy nó
# Ví dụ: nếu nó nằm trong configs/hypr/wallpapers/
if [ -d "$SRC_DIR/configs/hypr/wallpapers" ]; then
    cp -r "$SRC_DIR/configs/hypr/wallpapers/"* "$HOME/Pictures/Wallpapers/"
fi

# --- 6. INSTALL SDDM THEME (Optional) ---
echo -ne "${YELLOW}$MSG_SDDM_ASK${NC}"
read -r INSTALL_SDDM
if [[ "$INSTALL_SDDM" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}$MSG_SDDM_INSTALL${NC}"
    
    # Cài đặt các gói SDDM + theme Sugar Candy Git
    $AUR_HELPER -S --needed sddm sddm-sugar-candy-git qt5-graphicaleffects qt5-quickcontrols2 qt5-svg --noconfirm

    # Copy theme riêng Novaland
    sudo mkdir -p /usr/share/sddm/themes
    if [ -d "$SRC_DIR/sddm_theme" ]; then
        sudo cp -r "$SRC_DIR/sddm_theme" /usr/share/sddm/themes/Novaland
    fi
    
    # Tạo config file cho SDDM
    if [ ! -d "/etc/sddm.conf.d" ]; then
        sudo mkdir -p /etc/sddm.conf.d
    fi
    
    # Mặc định dùng theme Novaland.
    echo "[Theme]
Current=Novaland" | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null
    
    sudo systemctl enable sddm
    echo "  -> SDDM installed and enabled."
fi

# --- FINISH ---
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}$MSG_DONE${NC}"
echo -e "${YELLOW}$MSG_ZSH_NOTE${NC}"
echo -e "${GREEN}======================================${NC}"
