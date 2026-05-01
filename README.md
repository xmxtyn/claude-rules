# Claude 规则体系

一键安装脚本，用于在任意开发环境中快速部署统一的 Claude Code 配置规则。

## 功能特性

- **交互式菜单**：运行后直接显示菜单，选择编号即可操作
- **完整性校验**：SHA256 校验和验证，确保文件未被篡改
- **原始备份**：安装前可备份当前配置，支持完全恢复
- **版本化备份**：保留最近 5 个版本的备份，支持随时回滚
- **幂等性设计**：已安装时提示确认，避免意外覆盖

## 安装方式

### 方式 1：clone 后安装（推荐）

```bash
# Gitee（国内推荐）
git clone https://gitee.com/xmxtyn/claude-rules.git ~/rules-template

# 或 GitHub
git clone https://github.com/xmxtyn/claude-rules.git ~/rules-template

bash ~/rules-template/install.sh
```

### 方式 2：下载单个脚本

```bash
# 下载 install.sh 到本地
curl -fsSL https://gitee.com/xmxtyn/claude-rules/raw/main/install.sh -o install.sh
chmod +x install.sh
bash install.sh
```

## 使用说明

运行 `bash install.sh` 后会显示交互式菜单：

```
╔════════════════════════════════════════════════╗
║      Claude 规则体系 - 安装管理               ║
╠════════════════════════════════════════════════╣
║  1.  安装/升级                               ║
║  2.  备份当前配置                            ║
║  3.  卸载（恢复原始配置）                    ║
║  4.  回滚到上一版本                          ║
║  5.  查看备份列表                            ║
║  0.  退出                                   ║
╚════════════════════════════════════════════════╝
```

输入编号即可执行对应功能。

## 菜单功能说明

| 编号 | 功能 | 说明 |
|------|------|------|
| 1 | 安装/升级 | 安装或升级规则体系，首次安装会自动备份当前配置 |
| 2 | 备份当前配置 | 将当前 ~/.claude/ 打包备份为 .original_backup.tar.gz |
| 3 | 卸载 | 恢复原始配置（使用备份文件），慎用 |
| 4 | 回滚 | 回滚到上一版本（需要至少 2 个版本备份） |
| 5 | 查看备份列表 | 显示所有可用备份（含版本、时间、校验和） |
| 0 | 退出 | 退出脚本 |

## 备份与恢复

### 原始备份

安装前会提示备份当前配置到 `~/.claude/.original_backup.tar.gz`。

### 版本备份

每次安装都会自动创建版本备份，存储在 `~/.claude/.backup/`。

命名格式：`版本号_时间戳_校验和前8位`

```
~/.claude/.backup/
├── v1.0.0_20260501_120000_abc123de/
├── v1.1.0_20260502_140000_def456ab/
└── v1.2.0_20260503_160000_789ghij/
```

### 恢复原始配置

选择菜单「3. 卸载」即可恢复安装前的状态。

### 回滚

选择菜单「4. 回滚」可回滚到上一版本。

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
└── install.sh                # 安装管理脚本
```

## 完整性校验

安装时会自动校验所有文件的 SHA256 校验和。

校验失败时显示友好错误消息和解决方案。

## 常见问题

### Q: 安装失败怎么办？

A: 尝试以下步骤：
1. 检查网络连接
2. 重新选择菜单「1. 安装/升级」
3. 查看备份并回滚：菜单「5. 查看备份列表」→「4. 回滚」

### Q: 如何升级到最新版本？

A: 选择菜单「1. 安装/升级」即可自动升级，旧版本会作为备份保留。

## 反馈问题

发现问题或有功能建议？请提交 [Issue](https://gitee.com/xmxtyn/claude-rules/issues)。

## CHANGELOG

### 2026-05-01
- 初始版本发布
- 支持交互式菜单
- 支持 SHA256 完整性校验
- 支持 5 版版本化备份
- 支持回滚
