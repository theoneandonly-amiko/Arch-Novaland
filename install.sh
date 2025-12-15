#!/bin/bash

# ==============================================================================
#  ARCH NOVALAND INSTALLER
#  Author: Neonova Solara
#  Description: Automated setup script for Hyprland Novaland Rice
# ==============================================================================

# Dừng script ngay lập tức nếu có lệnh bị lỗi
set -e
set -o pipefail

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

# Hàm ghi log
log_msg() {
    echo -e "$1" | tee -a "$LOG"
}

# Xóa log cũ
rm -f "$LOG"
touch "$LOG"

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
    MSG_ERR_SRC="LỖI: Không tìm thấy thư mục '$SRC_DIR'. Hãy đảm bảo bạn đang chạy script nằm CẠNH thư mục này."
    MSG_CHECK_ARCH="Đang kiểm tra hệ thống..."
    MSG_NOT_ARCH="CẢNH BÁO: Bạn không dùng Arch Linux. Script có thể lỗi."
    MSG_UPDATE_SYS="Đang cập nhật cơ sở dữ liệu gói (pacman -Sy)..."
    MSG_INSTALL_PKG="Đang cài đặt các gói cần thiết (Core)..."
    MSG_BACKUP="Đang sao lưu config cũ vào: $BACKUP_DIR"
    MSG_FIX_PATH="Đang cập nhật đường dẫn user và cấu hình..."
    MSG_MONITOR_FIX="Đang cấu hình Hyprland tự nhận diện màn hình tốt nhất..."
    MSG_COPY="Đang sao chép file cấu hình vào máy..."
    MSG_INSTALL_OMZ="Đang cài đặt Oh My Zsh..."
    MSG_INSTALL_P10K="Đang tải theme Powerlevel10k..."
    MSG_ZSH_COPY="Đang cài đặt cấu hình Zsh (.zshrc)..."
    MSG_WALLPAPER="Đang sao chép hình nền vào ~/Pictures/Wallpapers..."
    MSG_WALLPAPER_FIX="Đang sửa lỗi hình nền (trỏ về ảnh mặc định)..."
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
    MSG_UPDATE_SYS="Updating package database (pacman -Sy)..."
    MSG_INSTALL_PKG="Installing dependencies (Core)..."
    MSG_BACKUP="Backing up old configs to: $BACKUP_DIR"
    MSG_FIX_PATH="Updating user paths and configs..."
    MSG_MONITOR_FIX="Configuring Hyprland to auto-detect best monitor mode..."
    MSG_COPY="Copying configuration files..."
    MSG_INSTALL_OMZ="Installing Oh My Zsh..."
    MSG_INSTALL_P10K="Downloading Powerlevel10k theme..."
    MSG_ZSH_COPY="Installing Zsh configuration (.zshrc)..."
    MSG_WALLPAPER="Copying wallpapers to ~/Pictures/Wallpapers..."
    MSG_WALLPAPER_FIX="Fixing wallpaper config (pointing to default image)..."
    MSG_SDDM_ASK="Do you want to install and enable SDDM + Sugar Candy Theme? (y/n): "
    MSG_SDDM_INSTALL="Installing SDDM packages and Theme..."
    MSG_DONE="INSTALLATION COMPLETE! Please reboot your system."
    MSG_ZSH_NOTE="NOTE: Kitty config uses Zsh. Make sure to change your default shell: chsh -s /usr/bin/zsh"
fi

# --- 1. PRE-CHECKS ---
if [ "$EUID" -eq 0 ]; then
    log_msg "${RED}$MSG_ERR_ROOT${NC}"
    exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
    log_msg "${RED}$MSG_ERR_SRC${NC}"
    echo "Current Dir: $(pwd)"
    echo "Expected: $(pwd)/$SRC_DIR"
    exit 1
fi

log_msg "${GREEN}$MSG_START${NC}"
log_msg "Log file: $(pwd)/$LOG"

if [ ! -f /etc/arch-release ]; then
    log_msg "${YELLOW}$MSG_NOT_ARCH${NC}"
    sleep 3
fi

# --- 2. UPDATE & INSTALL DEPENDENCIES ---
log_msg "${YELLOW}$MSG_UPDATE_SYS${NC}"
sudo pacman -Sy --noconfirm 2>&1 | tee -a "$LOG"

log_msg "${YELLOW}$MSG_INSTALL_PKG${NC}"

PKGS=(
    hyprland hyprpaper hyprlock waybar rofi-wayland swaync wlogout
    kitty zsh curl git thunar
    pipewire wireplumber pavucontrol playerctl cava
    brightnessctl libnotify power-profiles-daemon polkit-gnome
    wl-clipboard grim slurp swappy
    nm-connection-editor network-manager-applet blueman
    ttf-jetbrains-mono-nerd ttf-hack-nerd noto-fonts-emoji
    python-requests fastfetch
)

if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
    log_msg "${BLUE}Installing yay...${NC}"
    sudo pacman -S --needed git base-devel --noconfirm >> "$LOG" 2>&1
    git clone https://aur.archlinux.org/yay.git >> "$LOG" 2>&1
    cd yay
    makepkg -si --noconfirm >> "$LOG" 2>&1
    cd ..
    rm -rf yay
fi

AUR_HELPER=$(command -v paru || command -v yay)
if ! $AUR_HELPER -S --needed "${PKGS[@]}" --noconfirm 2>&1 | tee -a "$LOG"; then
    log_msg "${RED}❌ LỖI: Cài đặt thất bại. Vui lòng kiểm tra file $LOG.${NC}"
    exit 1
fi

log_msg "${BLUE}Enabling services...${NC}"
sudo systemctl enable --now bluetooth >> "$LOG" 2>&1 || true
sudo systemctl enable --now power-profiles-daemon >> "$LOG" 2>&1 || true

# --- 3. FIX PATHS & PREPARE ---
log_msg "${YELLOW}$MSG_FIX_PATH${NC}"
find "$SRC_DIR" -type f -exec sed -i "s|/home/$ORIGIN_USER|/home/$CURRENT_USER|g" {} +

if [ -f "$SRC_DIR/configs/hypr/hyprland.conf" ]; then
    sed -i 's/^exec-once = fcitx5/# exec-once = fcitx5/g' "$SRC_DIR/configs/hypr/hyprland.conf"
fi

log_msg "${YELLOW}$MSG_MONITOR_FIX${NC}"
if [ -f "$SRC_DIR/configs/hypr/hyprland.conf" ]; then
    sed -i 's/^monitor=.*/monitor=,highres,auto,1/g' "$SRC_DIR/configs/hypr/hyprland.conf"
fi

# --- 4. BACKUP OLD CONFIGS ---
log_msg "${BLUE}$MSG_BACKUP${NC}"
mkdir -p "$BACKUP_DIR"
for folder in hypr waybar rofi kitty cava wlogout swaync; do
    if [ -d "$HOME/.config/$folder" ]; then
        mv "$HOME/.config/$folder" "$BACKUP_DIR/"
    fi
done
if [ -f "$HOME/.zshrc" ]; then mv "$HOME/.zshrc" "$BACKUP_DIR/"; fi

# --- 5. COPY CONFIGS ---
log_msg "${GREEN}$MSG_COPY${NC}"
mkdir -p "$HOME/.config"
cp -r "$SRC_DIR/configs/"* "$HOME/.config/"

# [NEW] Install Oh My Zsh & P10k
log_msg "${YELLOW}$MSG_INSTALL_OMZ${NC}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >> "$LOG" 2>&1 || true
fi

log_msg "${YELLOW}$MSG_INSTALL_P10K${NC}"
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" >> "$LOG" 2>&1
fi

# [NEW] Copy Zshrc
log_msg "${GREEN}$MSG_ZSH_COPY${NC}"
ZSHRC_FOUND=0
if [ -f "$SRC_DIR/.zshrc" ]; then
    cp "$SRC_DIR/.zshrc" "$HOME/"
    ZSHRC_FOUND=1
elif [ -f "$SRC_DIR/configs/.zshrc" ]; then
    cp "$SRC_DIR/configs/.zshrc" "$HOME/"
    ZSHRC_FOUND=1
fi

if [ -f "$SRC_DIR/.p10k.zsh" ]; then cp "$SRC_DIR/.p10k.zsh" "$HOME/"; fi
if [ -f "$SRC_DIR/configs/.p10k.zsh" ]; then cp "$SRC_DIR/configs/.p10k.zsh" "$HOME/"; fi

if [ $ZSHRC_FOUND -eq 1 ]; then
    sed -i "s|/home/$ORIGIN_USER|/home/$CURRENT_USER|g" "$HOME/.zshrc"
    log_msg "  -> Installed .zshrc"
else
    log_msg "${YELLOW}  -> Warning: .zshrc not found.${NC}"
fi

chmod +x "$HOME/.config/hypr/scripts/"*.sh
chmod +x "$HOME/.config/waybar/scripts/"*

# [NEW] Wallpapers & Fix
log_msg "${GREEN}$MSG_WALLPAPER${NC}"
mkdir -p "$HOME/Pictures/Wallpapers"

# Copy wallpapers (ưu tiên thư mục wallpapers nếu có, không thì lấy từ SDDM)
if [ -d "$SRC_DIR/wallpapers" ]; then
    cp -r "$SRC_DIR/wallpapers/"* "$HOME/Pictures/Wallpapers/"
fi
if [ -d "$SRC_DIR/sddm_theme/Backgrounds" ]; then
    cp -r "$SRC_DIR/sddm_theme/Backgrounds/"* "$HOME/Pictures/Wallpapers/"
    # Đổi tên Mountain.jpg thành Default_Novaland.jpg cho đồng bộ
    if [ -f "$HOME/Pictures/Wallpapers/Mountain.jpg" ]; then
        cp "$HOME/Pictures/Wallpapers/Mountain.jpg" "$HOME/Pictures/Wallpapers/Default_Novaland.jpg"
    fi
fi
if [ -d "$SRC_DIR/configs/hypr/wallpapers" ]; then
    cp -r "$SRC_DIR/configs/hypr/wallpapers/"* "$HOME/Pictures/Wallpapers/"
fi

# [NEW] Tự động sửa config hyprpaper để trỏ vào ảnh mặc định
log_msg "${YELLOW}$MSG_WALLPAPER_FIX${NC}"
if [ -f "$HOME/.config/hypr/hyprpaper.conf" ]; then
    # Thay thế file ảnh bị thiếu (Stargazing-min.png) bằng ảnh mặc định (Default_Novaland.jpg)
    sed -i "s|Stargazing-min.png|Default_Novaland.jpg|g" "$HOME/.config/hypr/hyprpaper.conf"
    log_msg "  -> Fixed hyprpaper.conf to use Default_Novaland.jpg"
fi

# --- 6. INSTALL SDDM THEME ---
echo -ne "${YELLOW}$MSG_SDDM_ASK${NC}"
read -r INSTALL_SDDM
if [[ "$INSTALL_SDDM" =~ ^[Yy]$ ]]; then
    log_msg "${BLUE}$MSG_SDDM_INSTALL${NC}"
    
    if ! $AUR_HELPER -S --needed sddm sddm-sugar-candy-git qt5-graphicaleffects qt5-quickcontrols2 qt5-svg --noconfirm 2>&1 | tee -a "$LOG"; then
         log_msg "${RED}Lỗi cài đặt SDDM. Kiểm tra log.${NC}"
    else
        sudo mkdir -p /usr/share/sddm/themes
        if [ -d "$SRC_DIR/sddm_theme" ]; then
            sudo cp -r "$SRC_DIR/sddm_theme" /usr/share/sddm/themes/Novaland
        fi
        if [ ! -d "/etc/sddm.conf.d" ]; then sudo mkdir -p /etc/sddm.conf.d; fi
        
        echo "[Theme]
Current=Novaland" | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null
        
        sudo systemctl enable sddm >> "$LOG" 2>&1 || true
        log_msg "  -> SDDM installed and enabled."
    fi
fi

# --- FINISH ---
log_msg "${GREEN}======================================${NC}"
log_msg "${GREEN}$MSG_DONE${NC}"
log_msg "${YELLOW}$MSG_ZSH_NOTE${NC}"
log_msg "${GREEN}======================================${NC}"
