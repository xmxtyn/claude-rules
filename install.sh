#!/bin/bash
# ============================================================
# Claude 规则体系安装管理脚本
# ============================================================
# 使用方法：
#   bash install.sh              # 启动交互式菜单
# ============================================================

set -euo pipefail

# -------------------- 配置 --------------------
REPO_URL="${REPO_URL:-https://gitee.com/xmxtyn/claude-rules.git}"
BACKUP_DIR="${HOME}/.claude/.backup"
ORIGINAL_BACKUP="${HOME}/.claude/.original_backup.tar.gz"
MAX_KEEP=5
TEMPLATE_VERSION_FILE="${HOME}/.claude/.template_version"

# -------------------- 颜色 --------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# -------------------- 工具函数 --------------------
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# -------------------- 菜单 --------------------
show_menu() {
    clear
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}      ${GREEN}Claude 规则体系 - 安装管理${NC}          ${CYAN}║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}1.${NC}  安装/升级                             ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}2.${NC}  备份当前配置                         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}3.${NC}  卸载（恢复原始配置）                 ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}4.${NC}  回滚到上一版本                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}5.${NC}  查看备份列表                         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}0.${NC}  退出                                ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

# -------------------- 备份当前配置 --------------------
backup_current() {
    log_info "开始备份当前配置..."

    if [[ ! -d "${HOME}/.claude" ]] || [[ -z "$(ls -A "${HOME}/.claude" 2>/dev/null)" ]]; then
        log_warn " ~/.claude/ 为空或不存在，无需备份"
        return 0
    fi

    if ! command -v tar &>/dev/null; then
        log_error "tar 命令不可用，无法创建备份"
        return 1
    fi

    if [[ -f "$ORIGINAL_BACKUP" ]]; then
        log_info "删除旧备份文件..."
        rm -f "$ORIGINAL_BACKUP"
    fi

    cd "${HOME}"
    tar -czf "$ORIGINAL_BACKUP" \
        --exclude='.backup' \
        --exclude='.original_backup.tar.gz' \
        --exclude='.template_version' \
        claude 2>/dev/null || true

    if [[ -f "$ORIGINAL_BACKUP" ]]; then
        size=$(du -h "$ORIGINAL_BACKUP" | cut -f1)
        log_success "备份完成！"
        log_info "备份文件：${ORIGINAL_BACKUP}"
        log_info "备份大小：${size}"
        echo ""
        log_warn "此备份文件用于恢复原始配置，请勿删除！"
    else
        log_error "备份失败"
        return 1
    fi
}

# -------------------- 卸载并恢复 --------------------
uninstall() {
    log_info "开始卸载..."

    if [[ ! -f "$ORIGINAL_BACKUP" ]]; then
        log_error "找不到原始备份文件：${ORIGINAL_BACKUP}"
        echo ""
        echo "请先在菜单选择「2. 备份当前配置」"
        return 1
    fi

    if ! tar -tzf "$ORIGINAL_BACKUP" &>/dev/null; then
        log_error "备份文件损坏，无法恢复"
        return 1
    fi

    echo ""
    log_warn "即将恢复原始配置，当前配置将被覆盖！"
    read -r -p "确认恢复？[y/N] " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "取消恢复"
        return 0
    fi

    log_info "清理当前配置..."
    rm -rf "${HOME}/.claude"/*

    log_info "恢复原始配置..."
    cd "${HOME}"
    tar -xzf "$ORIGINAL_BACKUP"

    rm -f "$TEMPLATE_VERSION_FILE"

    log_success "卸载完成！"
    log_info "已恢复到原始配置"
    echo ""
    echo "提示：原始备份文件仍保留在 ${ORIGINAL_BACKUP}"
}

# -------------------- 列出备份 --------------------
list_backups() {
    echo ""
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_warn "暂无版本备份"
    else
        log_info "可用版本备份："
        echo ""
        printf "%-50s %s\n" "版本目录" "创建时间"
        printf "%s\n" "----------------------------------------------------------------------"
        ls -ltd "${BACKUP_DIR}"/*/ 2>/dev/null | while read -r dir; do
            dirname=$(basename "$dir")
            mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$dir" 2>/dev/null || stat -c "%y" "$dir" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
            printf "%-50s %s\n" "$dirname" "$mtime"
        done
        echo ""
    fi

    if [[ -f "$ORIGINAL_BACKUP" ]]; then
        size=$(du -h "$ORIGINAL_BACKUP" | cut -f1)
        mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$ORIGINAL_BACKUP" 2>/dev/null || stat -c "%y" "$ORIGINAL_BACKUP" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
        log_info "原始备份："
        printf "  文件：%s\n" "$ORIGINAL_BACKUP"
        printf "  大小：%s\n" "$size"
        printf "  时间：%s\n" "$mtime"
    else
        log_info "原始备份：无（未执行过备份）"
    fi
    echo ""
}

# -------------------- 回滚 --------------------
rollback() {
    log_info "开始回滚..."

    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_error "没有可用的备份"
        return 1
    fi

    backups=($(ls -ltd "${BACKUP_DIR}"/*/ 2>/dev/null | head -n 2))

    if [[ ${#backups[@]} -lt 2 ]]; then
        log_error "需要至少 2 个版本备份才能回滚"
        return 1
    fi

    current_backup="${backups[0]}"
    previous_backup="${backups[1]}"

    log_warn "当前版本：$(basename "$current_backup")"
    log_info "将回滚到：$(basename "$previous_backup")"
    echo ""

    read -r -p "确认回滚？[y/N] " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "取消回滚"
        return 0
    fi

    rm -rf "${HOME}/.claude"/*
    cp -a "${previous_backup}"/* "${HOME}/.claude"/

    log_success "回滚完成"
    log_info "已回滚到：$(basename "$previous_backup")"
}

# -------------------- 校验函数 --------------------
verify_checksums() {
    local source_dir="$1"

    if [[ ! -f "${source_dir}/sha256sums.txt" ]]; then
        log_error "找不到 sha256sums.txt"
        return 1
    fi

    log_info "正在校验文件完整性..."

    cd "${source_dir}"

    if ! command -v sha256sum &>/dev/null; then
        if command -v certutil &>/dev/null; then
            log_warn "sha256sum 不可用，Windows 环境跳过校验"
            return 0
        fi
        log_error "sha256sum 不可用，无法校验"
        return 1
    fi

    if sha256sum -c sha256sums.txt --status; then
        log_success "文件完整性校验通过"
        return 0
    else
        log_error "文件完整性校验失败！"
        echo ""
        echo "可能原因："
        echo "  1. 网络劫持（公共 WiFi 下常见）"
        echo "  2. 下载损坏"
        echo "  3. 仓库被篡改"
        echo ""
        echo "解决方案："
        echo "  1. 重试：重新选择安装"
        echo "  2. 报告问题：https://gitee.com/xmxtyn/claude-rules/issues"
        echo ""
        return 1
    fi
}

# -------------------- 安装函数 --------------------
do_install() {
    log_info "开始安装 Claude 规则体系..."

    # 检查是否有原始备份
    if [[ ! -f "$ORIGINAL_BACKUP" ]]; then
        echo ""
        log_warn "未找到原始备份，建议先备份当前配置"
        read -r -p "是否先备份？[y/N] " backup_choice
        if [[ "$backup_choice" == "y" || "$backup_choice" == "Y" ]]; then
            backup_current
        else
            log_info "跳过备份，继续安装..."
        fi
    else
        log_info "已存在原始备份：${ORIGINAL_BACKUP}"
    fi

    # 创建备份目录
    mkdir -p "${BACKUP_DIR}"

    # 检查是否已安装
    if [[ -f "${TEMPLATE_VERSION_FILE}" ]]; then
        current_version=$(cat "${TEMPLATE_VERSION_FILE}")
        log_warn "检测到已安装版本：${current_version}"
        echo ""
        echo "1. 覆盖安装（保留当前版本为备份）"
        echo "2. 取消安装"
        read -r -p "请选择 [1/2]: " choice
        case "$choice" in
            2) log_info "取消安装"; return 0 ;;
            *) log_info "继续覆盖安装..." ;;
        esac
    fi

    # 创建临时目录
    temp_dir=$(mktemp -d -p "${HOME}" ".claude-install-XXXXX")
    chmod 700 "$temp_dir"
    trap "rm -rf '$temp_dir'" EXIT

    log_info "克隆仓库到临时目录..."
    if ! git clone --depth 1 "${REPO_URL}" "${temp_dir}/repo"; then
        log_error "克隆失败，请检查网络连接"
        return 1
    fi

    cd "${temp_dir}/repo"

    # 校验
    verify_checksums "${temp_dir}/repo" || return 1

    # 生成版本信息
    version=$(git describe --tags 2>/dev/null || echo "v0.0.0")
    timestamp=$(date +%Y%m%d_%H%M%S)
    checksum=$(sha256sum sha256sums.txt 2>/dev/null | cut -d' ' -f1 | cut -c1-8)

    # 备份当前版本
    if [[ -d "${HOME}/.claude" ]] && [[ "$(ls -A "${HOME}/.claude")" ]]; then
        backup_name="v${version}_${timestamp}_${checksum}"
        log_info "创建版本备份：${backup_name}"
        cp -a "${HOME}/.claude" "${BACKUP_DIR}/${backup_name}"

        # 清理旧备份
        backups=($(ls -ltd "${BACKUP_DIR}"/*/ 2>/dev/null))
        if [[ ${#backups[@]} -gt $MAX_KEEP ]]; then
            log_info "清理旧版本备份，保留最近 ${MAX_KEEP} 个..."
            for ((i=$MAX_KEEP; i<${#backups[@]}; i++)); do
                rm -rf "${backups[$i]}"
            done
        fi
    fi

    # 安装文件
    log_info "安装文件到 ${HOME}/.claude/..."
    mkdir -p "${HOME}/.claude"
    cp -a . "${HOME}/.claude"/

    # 写入版本文件
    echo "$version" > "${TEMPLATE_VERSION_FILE}"

    # 清理
    rm -rf "$temp_dir"
    trap - EXIT

    log_success "安装完成！"
    echo ""
    log_info "安装版本：${version}"
}

# -------------------- 主循环 --------------------
main() {
    while true; do
        show_menu
        read -r -p "请选择 [0-5]: " choice
        echo ""

        case "$choice" in
            1)
                do_install
                echo ""
                read -r -p "按回车继续..." _
                ;;
            2)
                backup_current
                echo ""
                read -r -p "按回车继续..." _
                ;;
            3)
                uninstall
                echo ""
                read -r -p "按回车继续..." _
                ;;
            4)
                rollback
                echo ""
                read -r -p "按回车继续..." _
                ;;
            5)
                list_backups
                read -r -p "按回车继续..." _
                ;;
            0)
                echo "再见！"
                break
                ;;
            *)
                log_error "无效选择，请输入 0-5"
                echo ""
                read -r -p "按回车继续..." _
                ;;
        esac
    done
}

main "$@"
