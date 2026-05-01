#!/bin/bash
# ============================================================
# Claude 规则体系一键安装脚本
# ============================================================
# 用法：
#   curl ... | bash                    # 一键安装
#   bash install.sh --dry-run         # 演练模式
#   bash install.sh --rollback        # 回滚到上一版本
#   bash install.sh --list-backups    # 列出所有备份
#   bash install.sh --no-verify       # 跳过校验（应急用）
# ============================================================

set -euo pipefail

# -------------------- 配置 --------------------
REPO_URL="${REPO_URL:-https://github.com/xmxtyn/claude-rules.git}"
BACKUP_DIR="${HOME}/.claude/.backup"
MAX_KEEP=5
TEMPLATE_VERSION_FILE="${HOME}/.claude/.template_version"

# -------------------- 颜色 --------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -------------------- 工具函数 --------------------
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# -------------------- 帮助信息 --------------------
show_help() {
    cat << 'EOF'
Claude 规则体系安装脚本

用法：
    bash install.sh [选项]

选项：
    --dry-run         演练模式，显示将要执行的操作
    --verify          校验完整性（默认强制）
    --no-verify       跳过校验（应急用）
    --rollback        回滚到上一版本
    --list-backups    列出所有可用备份
    --help            显示帮助信息

示例：
    bash install.sh                    # 标准安装
    bash install.sh --dry-run         # 先看看会做什么
    bash install.sh --rollback         # 回滚
EOF
}

# -------------------- 备份相关函数 --------------------
list_backups() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_warn "暂无备份"
        return
    fi

    log_info "可用备份："
    echo ""
    printf "%-50s %s\n" "版本目录" "创建时间"
    printf "%s\n" "----------------------------------------------------------------------"
    ls -ltd "${BACKUP_DIR}"/*/ 2>/dev/null | while read -r dir; do
        dirname=$(basename "$dir")
        mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$dir" 2>/dev/null || stat -c "%y" "$dir" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
        printf "%-50s %s\n" "$dirname" "$mtime"
    done
    echo ""
}

rollback() {
    log_info "开始回滚..."

    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_error "没有可用的备份"
        exit 1
    fi

    # 获取最新的两个备份
    backups=($(ls -ltd "${BACKUP_DIR}"/*/ 2>/dev/null | head -n 2))

    if [[ ${#backups[@]} -lt 2 ]]; then
        log_error "需要至少 2 个备份才能回滚"
        exit 1
    fi

    current_backup="${backups[0]}"
    previous_backup="${backups[1]}"

    log_warn "当前版本：$(basename "$current_backup")"
    log_info "将回滚到：$(basename "$previous_backup")"
    echo ""

    read -r -p "确认回滚？[y/N] " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "取消回滚"
        exit 0
    fi

    # 执行回滚
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

    # 切换到源目录
    cd "${source_dir}"

    # 检查 sha256sum 命令
    if ! command -v sha256sum &>/dev/null; then
        # Windows 环境尝试使用 certutil 或其他方式
        if command -v certutil &>/dev/null; then
            log_warn "sha256sum 不可用，Windows 环境跳过校验"
            return 0
        fi
        log_error "sha256sum 不可用，无法校验"
        exit 1
    fi

    # 校验
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
        echo "  1. 重试：再次运行 install.sh"
        echo "  2. 跳过校验：bash install.sh --no-verify"
        echo "  3. 报告问题：https://github.com/xmxtyn/claude-rules/issues"
        echo ""
        exit 1
    fi
}

# -------------------- 安装函数 --------------------
do_install() {
    local verify="${1:-true}"
    local dry_run="${2:-false}"

    log_info "开始安装 Claude 规则体系..."

    # 创建备份目录
    mkdir -p "${BACKUP_DIR}"

    # 检查是否已安装
    if [[ -f "${TEMPLATE_VERSION_FILE}" ]]; then
        current_version=$(cat "${TEMPLATE_VERSION_FILE}")
        log_warn "检测到已安装版本：${current_version}"
        echo ""
        echo "1. 覆盖安装（保留当前版本为备份）"
        echo "2. 退出"
        read -r -p "请选择 [1/2]: " choice
        case "$choice" in
            2) log_info "退出安装"; exit 0 ;;
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
        exit 1
    fi

    # 切换到仓库目录
    cd "${temp_dir}/repo"

    # 校验
    if [[ "$verify" == "true" ]]; then
        verify_checksums "${temp_dir}/repo"
    else
        log_warn "跳过完整性校验（--no-verify）"
    fi

    # 生成版本信息
    version=$(git describe --tags 2>/dev/null || echo "v0.0.0")
    timestamp=$(date +%Y%m%d_%H%M%S)
    checksum=$(sha256sum sha256sums.txt 2>/dev/null | cut -d' ' -f1 | cut -c1-8)

    # 备份当前版本
    if [[ -d "${HOME}/.claude" ]] && [[ "$(ls -A "${HOME}/.claude")" ]]; then
        backup_name="v${version}_${timestamp}_${checksum}"
        log_info "创建备份：${backup_name}"
        cp -a "${HOME}/.claude" "${BACKUP_DIR}/${backup_name}"

        # 清理旧备份，保留最多 MAX_KEEP 个
        backups=($(ls -ltd "${BACKUP_DIR}"/*/ 2>/dev/null))
        if [[ ${#backups[@]} -gt $MAX_KEEP ]]; then
            log_info "清理旧备份，保留最近 ${MAX_KEEP} 个..."
            for ((i=$MAX_KEEP; i<${#backups[@]}; i++)); do
                rm -rf "${backups[$i]}"
            done
        fi
    fi

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY-RUN] 以下操作将被执行："
        echo "  1. 复制文件到 ${HOME}/.claude/"
        echo "  2. 创建版本文件 ${TEMPLATE_VERSION_FILE}"
        echo "  3. 记录版本：${version}"
        log_success "演练完成"
        exit 0
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
    log_info "备份位置：${BACKUP_DIR}"
    echo ""
    echo "后续命令："
    echo "  bash install.sh --list-backups   # 查看备份"
    echo "  bash install.sh --rollback       # 回滚"
    echo "  bash install.sh --dry-run        # 演练模式"
}

# -------------------- 主流程 --------------------
main() {
    # 解析参数
    verify="true"
    dry_run="false"
    action="install"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run="true"
                ;;
            --verify)
                verify="true"
                ;;
            --no-verify)
                verify="false"
                ;;
            --rollback)
                action="rollback"
                ;;
            --list-backups)
                action="list"
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数：$1"
                show_help
                exit 1
                ;;
        esac
        shift
    done

    case "$action" in
        install)
            do_install "$verify" "$dry_run"
            ;;
        rollback)
            rollback
            ;;
        list)
            list_backups
            ;;
    esac
}

main "$@"
