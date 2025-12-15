#!/bin/bash

# ==============================================================================
#  GIT AUTO PUSH SCRIPT
#  Hỗ trợ đẩy code lên GitHub nhanh gọn lẹ
# ==============================================================================

# Màu sắc cho đẹp
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

echo -e "${YELLOW}=== KIỂM TRA TRẠNG THÁI GIT ===${NC}"

# Kiểm tra xem đã init git chưa
if [ ! -d ".git" ]; then
    echo -e "${RED}Lỗi: Thư mục này chưa khởi tạo Git.${NC}"
    echo "Vui lòng chạy lệnh sau lần đầu tiên:"
    echo "  git init"
    echo "  git branch -M main"
    echo "  git remote add origin <URL_REPO_CUA_BAN>"
    exit 1
fi

# --- 1. KIỂM TRA IDENTITY (User Name & Email) ---
if [ -z "$(git config user.name)" ] || [ -z "$(git config user.email)" ]; then
    echo -e "${YELLOW}⚠️  CẢNH BÁO: Git chưa có thông tin người dùng (Identity).${NC}"
    echo "Để commit được, Git cần biết bạn là ai."
    echo "---------------------------------------------"
    
    read -p "Nhập Tên hiển thị (VD: Neonova): " GIT_NAME
    read -p "Nhập Email (VD: you@example.com): " GIT_EMAIL
    
    if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
        git config user.name "$GIT_NAME"
        git config user.email "$GIT_EMAIL"
        echo -e "${GREEN}✅ Đã lưu cấu hình Identity cho repository này.${NC}"
        echo ""
    else
        echo -e "${RED}❌ Lỗi: Bạn chưa nhập đủ thông tin. Hủy thao tác.${NC}"
        exit 1
    fi
fi

# Hiển thị trạng thái file
git status -s

# Biến kiểm tra trạng thái
HAS_CHANGES=$(git status --porcelain)
# Kiểm tra xem có commit nào chưa được push không (so với origin/main hoặc branch hiện tại)
# Lệnh này đếm số commit local nhiều hơn remote
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then CURRENT_BRANCH="main"; fi
UNPUSHED_COMMITS=$(git log origin/$CURRENT_BRANCH..HEAD --oneline 2>/dev/null)

# --- XỬ LÝ LOGIC ---

if [ -z "$HAS_CHANGES" ]; then
    if [ -n "$UNPUSHED_COMMITS" ]; then
        echo -e "${YELLOW}⚠️  Bạn đã Commit rồi nhưng CHƯA Push thành công (Có thể do lỗi mạng/password lần trước).${NC}"
        echo "Git đã sẵn sàng để đẩy code lên."
    else
        echo -e "${GREEN}Mọi thứ đã đồng bộ. Không có gì để push.${NC}"
        exit 0
    fi
else
    echo ""
    echo "---------------------------------------------"
    echo -e "Bạn có muốn đẩy tất cả thay đổi lên GitHub? (y/n)"
    read -p "Lựa chọn: " CONFIRM

    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Đang thêm file (git add)...${NC}"
        git add .
        
        echo "---------------------------------------------"
        read -p "Nhập nội dung commit (Enter để dùng mặc định): " COMMIT_MSG
        
        if [ -z "$COMMIT_MSG" ]; then
            COMMIT_MSG="Update: $(date +'%d/%m/%Y %H:%M')"
        fi
        
        echo -e "${YELLOW}Đang commit: '$COMMIT_MSG'...${NC}"
        git commit -m "$COMMIT_MSG"
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Lỗi: Commit thất bại.${NC}"
            exit 1
        fi
    else
        echo "Đã hủy thao tác."
        exit 0
    fi
fi

# --- PHẦN PUSH (Chạy cho cả trường hợp commit mới hoặc push lại commit cũ) ---
echo "---------------------------------------------"
echo -e "${YELLOW}Đang chuẩn bị đẩy lên nhánh '$CURRENT_BRANCH'...${NC}"
echo "Lưu ý: Nhập TOKEN (ghp_...) thay cho mật khẩu."

git push origin "$CURRENT_BRANCH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ THÀNH CÔNG! Code đã lên GitHub.${NC}"
else
    echo -e "${RED}❌ THẤT BẠI KHI PUSH CODE.${NC}"
    echo "--------------------------------------------------------"
    echo -e "${YELLOW}GỢI Ý KHẮC PHỤC LỖI 'Authentication failed':${NC}"
    echo "1. GitHub KHÔNG hỗ trợ mật khẩu tài khoản thường."
    echo "2. Bạn phải dùng **Personal Access Token (PAT)** làm mật khẩu."
    echo "3. Lấy Token tại: Settings -> Developer Settings -> Personal Access Tokens (Classic)."
    echo "4. Khi nhập Password, hãy Paste cái Token (bắt đầu bằng ghp_...) vào."
    echo "--------------------------------------------------------"
fi
