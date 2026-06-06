#!/bin/bash

################################################################################
# 🚀 SCRIPT MIGRASI ISSUES - SHELL BASH VERSION
################################################################################
# Deskripsi:
#   Script ini memindahkan semua issues dari PM_TUKANG_DEKAT ke 
#   PM_UAS_rekayasa_Sistem_Informasi menggunakan GitHub CLI (gh)
#
# Prasyarat:
#   1. GitHub CLI (gh) harus terinstall
#      - Windows: choco install gh
#      - Mac: brew install gh
#      - Linux: sudo apt install gh (atau download dari github.com/cli/cli)
#   
#   2. Login ke GitHub:
#      gh auth login
#
# Cara Jalankan:
#   bash scripts/migrasi_issues.sh
#
# atau (jika file executable):
#   ./scripts/migrasi_issues.sh
#
################################################################################

set -e  # Keluar jika ada error

# WARNA TEXT
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# VARIABLE
SOURCE_REPO="radenelsa7-bot/PM_TUKANG_DEKAT"
TARGET_REPO="radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi"
MIGRATED=0
FAILED=0
SKIPPED=0
TEMP_FILE="/tmp/migrasi_issues.txt"

################################################################################
# FUNGSI - Print Header
################################################################################
print_header() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                   🚀 MIGRASI ISSUES BASH SCRIPT                    ║"
    echo "║         PM_TUKANG_DEKAT → PM_UAS_rekayasa_Sistem_Informasi       ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

################################################################################
# FUNGSI - Cek Prasyarat
################################################################################
check_requirements() {
    echo -e "${YELLOW}🔍 Memeriksa prasyarat...${NC}"
    
    # Cek GitHub CLI
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI (gh) tidak ditemukan!${NC}"
        echo ""
        echo -e "${YELLOW}Cara install GitHub CLI:${NC}"
        echo "  Windows (Chocolatey): choco install gh"
        echo "  Mac (Homebrew):       brew install gh"
        echo "  Linux (Debian):       sudo apt install gh"
        echo "  Download:             https://github.com/cli/cli"
        echo ""
        exit 1
    fi
    
    # Cek login GitHub
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ Belum login ke GitHub!${NC}"
        echo ""
        echo -e "${YELLOW}Silakan login terlebih dahulu:${NC}"
        echo "  gh auth login"
        echo ""
        exit 1
    fi
    
    echo -e "${GREEN}✅ GitHub CLI terinstall dan sudah login${NC}"
    echo ""
}

################################################################################
# FUNGSI - Get Repository Info
################################################################################
get_repo_info() {
    echo -e "${BLUE}📦 Informasi Repository:${NC}"
    
    # Source repo
    SOURCE_OWNER=$(echo $SOURCE_REPO | cut -d'/' -f1)
    SOURCE_NAME=$(echo $SOURCE_REPO | cut -d'/' -f2)
    
    # Target repo
    TARGET_OWNER=$(echo $TARGET_REPO | cut -d'/' -f1)
    TARGET_NAME=$(echo $TARGET_REPO | cut -d'/' -f2)
    
    echo "  📌 Sumber: $SOURCE_REPO"
    echo "  📌 Tujuan: $TARGET_REPO"
    echo ""
}

################################################################################
# FUNGSI - Get Issues dari Source Repository
################################################################################
get_issues() {
    echo -e "${YELLOW}📥 Mengambil data issues dari sumber...${NC}"
    
    # Ambil SEMUA issues (open dan closed)
    gh issue list \
        --repo "$SOURCE_REPO" \
        --state all \
        --limit 1000 \
        --json number,title,body,labels,assignees,state \
        > "$TEMP_FILE"
    
    TOTAL=$(jq 'length' "$TEMP_FILE" 2>/dev/null || echo 0)
    echo -e "${GREEN}✅ Total issues ditemukan: $TOTAL${NC}"
    echo ""
}

################################################################################
# FUNGSI - Migrasi Issues
################################################################################
migrate_issues() {
    echo -e "${CYAN}🔄 Memulai proses migrasi...${NC}"
    echo ""
    
    CURRENT=1
    
    # Loop setiap issue
    jq -r '.[] | @base64' "$TEMP_FILE" | while read -r base64_issue; do
        ISSUE=$(echo "$base64_issue" | base64 -d)
        
        ISSUE_NUMBER=$(echo "$ISSUE" | jq -r '.number')
        ISSUE_TITLE=$(echo "$ISSUE" | jq -r '.title')
        ISSUE_BODY=$(echo "$ISSUE" | jq -r '.body // empty')
        ISSUE_STATE=$(echo "$ISSUE" | jq -r '.state')
        
        # Labels
        LABELS=$(echo "$ISSUE" | jq -r '.labels[].name' | paste -sd ',' - || echo "")
        
        # Assignees
        ASSIGNEES=$(echo "$ISSUE" | jq -r '.assignees[].login' | paste -sd ',' - || echo "")
        
        # Progress
        printf "[%d/%d] " "$CURRENT" "$TOTAL"
        echo -e "${YELLOW}🔄 Memproses: $ISSUE_TITLE${NC}"
        
        # Siapkan body dengan referensi original
        ORIGINAL_LINK="https://github.com/$SOURCE_REPO/issues/$ISSUE_NUMBER"
        NEW_BODY="## ℹ️ Hasil Migrasi dari PM_TUKANG_DEKAT

**📌 Issue Original:** [#$ISSUE_NUMBER]($ORIGINAL_LINK)
**📅 Status Awal:** $([ "$ISSUE_STATE" = "open" ] && echo "🔓 Terbuka" || echo "🔒 Tertutup")

---

$ISSUE_BODY"
        
        # Create issue baru
        if [ -z "$ASSIGNEES" ]; then
            ASSIGNEES_ARG=""
        else
            ASSIGNEES_ARG="--assignee $ASSIGNEES"
        fi
        
        if [ -z "$LABELS" ]; then
            LABELS_ARG=""
        else
            LABELS_ARG="--label $LABELS"
        fi
        
        # Try create issue
        if NEW_ISSUE_URL=$(gh issue create \
            --repo "$TARGET_REPO" \
            --title "$ISSUE_TITLE" \
            --body "$NEW_BODY" \
            $LABELS_ARG \
            $ASSIGNEES_ARG \
            --state "$ISSUE_STATE" \
            2>&1); then
            
            NEW_ISSUE_NUM=$(echo "$NEW_ISSUE_URL" | grep -oP '/issues/\K[0-9]+' || echo "?")
            echo -e "  ${GREEN}✅ Berhasil dibuat: Issue #$NEW_ISSUE_NUM${NC}"
            
            if [ ! -z "$LABELS" ]; then
                echo "     📌 Label: $LABELS"
            fi
            if [ ! -z "$ASSIGNEES" ]; then
                echo "     👤 Assignee: $ASSIGNEES"
            fi
            
            MIGRATED=$((MIGRATED + 1))
        else
            echo -e "  ${RED}❌ Gagal membuat issue${NC}"
            FAILED=$((FAILED + 1))
        fi
        
        echo ""
        CURRENT=$((CURRENT + 1))
    done
}

################################################################################
# FUNGSI - Print Summary
################################################################################
print_summary() {
    echo -e "${CYAN}"
    echo "════════════════════════════════════════════════════════════════════"
    echo "                      📈 RINGKASAN HASIL MIGRASI"
    echo "════════════════════════════════════════════════════════════════════"
    echo -e "${NC}"
    echo -e "  ${GREEN}✅ Berhasil dimigrasikan${NC}: $MIGRATED issues"
    echo -e "  ${RED}❌ Gagal${NC}              : $FAILED issues"
    echo -e "  ${YELLOW}⏭️  Dilewati${NC}         : $SKIPPED issues"
    echo ""
    echo -e "  📊 Total diproses: $((MIGRATED + FAILED + SKIPPED)) issues"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ $MIGRATED -gt 0 ]; then
        echo -e "${GREEN}✨ Migrasi selesai! $MIGRATED issues berhasil dimigrasikan${NC}"
    else
        echo -e "${YELLOW}⚠️  Tidak ada issues baru yang dimigrasikan${NC}"
    fi
    
    echo ""
}

################################################################################
# FUNGSI - Cleanup
################################################################################
cleanup() {
    rm -f "$TEMP_FILE"
}

################################################################################
# MAIN EXECUTION
################################################################################
main() {
    print_header
    check_requirements
    get_repo_info
    get_issues
    migrate_issues
    print_summary
    cleanup
}

# Trap untuk cleanup saat error atau interrupt
trap cleanup EXIT

# Jalankan
main
