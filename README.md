# Claude 规则体系

一键安装脚本，用于在任意开发环境中快速部署统一的 Claude Code 配置规则。

## 功能特性

- **一键安装**：一行命令即可完成安装
- **完整性校验**：SHA256 校验和验证，确保文件未被篡改
- **原始备份**：安装前可备份当前配置，支持完全恢复
- **版本化备份**：保留最近 5 个版本的备份，支持随时回滚
- **幂等性设计**：已安装时提示确认，避免意外覆盖
- **演练模式**：支持 `--dry-run` 预览安装操作

## 安装方式

### 方式 1：curl 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/user/rules-template/main/install.sh | bash
```

### 方式 2：clone 后安装

```bash
git clone https://github.com/xmxtyn/claude-rules.git ~/rules-template
bash ~/rules-template/install.sh
```

## 使用说明

### 安装选项

| 选项 | 说明 |
|------|------|
| `--backup` | 安装前备份当前配置到 .original_backup.tar.gz |
| `--uninstall` | 卸载并恢复原始配置（使用备份文件） |
| `--dry-run` | 演练模式，显示将要执行的操作，不实际安装 |
| `--verify` | 校验完整性（默认强制） |
| `--no-verify` | 跳过校验（应急用） |
| `--rollback` | 回滚到上一版本 |
| `--list-backups` | 列出所有可用备份（含原始备份） |
| `--help` | 显示帮助信息 |

### 常用命令

```bash
# 备份当前配置（安装前必做）
bash install.sh --backup

# 标准安装
bash install.sh

# 先看看会做什么
bash install.sh --dry-run

# 查看可用备份（含原始备份）
bash install.sh --list-backups

# 回滚到上一版本
bash install.sh --rollback

# 恢复原始配置（卸载）
bash install.sh --uninstall

# 跳过校验安装（不推荐）
bash install.sh --no-verify
```

## 备份与恢复

### 原始备份

安装前建议先备份当前配置：

```bash
bash install.sh --backup
```

这会将 `~/.claude/` 打包保存到 `~/.claude/.original_backup.tar.gz`。

### 恢复原始配置

卸载规则体系，恢复到安装前的状态：

```bash
bash install.sh --uninstall
```

### 版本备份

备份存储在 `~/.claude/.backup/` 目录。

每个备份目录命名格式：`版本号_时间戳_校验和前8位`

例如：
```
~/.claude/.backup/
├── v1.0.0_20260501_120000_abc123de/
├── v1.1.0_20260502_140000_def456ab/
└── v1.2.0_20260503_160000_789ghij/
```

### 回滚

```bash
# 查看可用备份
bash install.sh --list-backups

# 回滚到上一版本
bash install.sh --rollback
```

### 备份策略

- 最多保留 5 个版本
- 超出时自动清理最旧的版本
- 每次安装都会创建新备份

## 目录结构

```
rules-template/
├── CLAUDE.md                 # 全局规则
├── rules/
│   ├── testing.md            # 测试规范
│   ├── agent-teams.md        # AI Agent Teams 规范
│   └── context-switch.md     # 多项目上下文切换
├── templates/
│   └── project-rules-template.md  # 项目规则模板
├── skills/
│   └── template-sync.md      # 规则同步 Skill
├── sha256sums.txt            # 校验和文件
└── install.sh                # 安装脚本
```

## 完整性校验

安装脚本默认会校验所有文件的 SHA256 校验和。

校验失败时显示：
```
可能原因：
  1. 网络劫持（公共 WiFi 下常见）
  2. 下载损坏
  3. 仓库被篡改

解决方案：
  1. 重试：再次运行 install.sh
  2. 跳过校验：bash install.sh --no-verify
  3. 报告问题：https://github.com/xmxtyn/claude-rules/issues
```

## 常见问题

### Q: 安装失败怎么办？

A: 尝试以下步骤：
1. 检查网络连接
2. 重试安装：`bash install.sh`
3. 跳过校验（不推荐）：`bash install.sh --no-verify`
4. 查看备份并回滚：`bash install.sh --list-backups`

### Q: 如何升级到最新版本？

A: 重新运行安装脚本即可自动升级，旧版本会作为备份保留。

### Q: 可以安装指定版本吗？

A: 目前 V1 支持最新版本，V2 将支持 `--version` 参数指定版本。

## 反馈问题

发现问题或有功能建议？请提交 [Issue](https://github.com/xmxtyn/claude-rules/issues)。

## CHANGELOG

### 2026-05-01
- 初始版本发布
- 支持一键安装
- 支持 SHA256 完整性校验
- 支持 5 版版本化备份
- 支持回滚和演练模式
