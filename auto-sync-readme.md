# 🔄 Git 双向同步工具

一个功能强大的 Git 双向同步脚本，支持自动拉取、推送和智能提交信息选择。

## 📋 目录

- [功能特性](#功能特性)
- [安装使用](#安装使用)
- [提交信息选项详解](#提交信息选项详解)
- [使用场景](#使用场景)
- [配置说明](#配置说明)
- [故障排除](#故障排除)

## ✨ 功能特性

- 🔄 **双向同步**：自动拉取远程变更并推送本地变更
- 🛡️ **智能暂存**：自动处理本地未提交变更，避免冲突
- 🎯 **预设选项**：提供常用的提交信息模板
- ✏️ **自定义输入**：支持自定义详细的提交信息
- 🔐 **自动认证**：一次配置，永久使用
- 📊 **清晰反馈**：彩色输出，操作状态一目了然

## 🚀 安装使用

### 1. 下载脚本
```bash
# 下载到你的项目目录
wget https://your-gitea-host/path/to/auto-sync.sh
# 或者直接创建文件并复制内容
```

### 2. 设置权限
```bash
chmod +x auto-sync.sh
```

### 3. 配置参数
编辑脚本中的配置信息：
```bash
GITEA_USER="your-username"     # 你的 Gitea 用户名
GITEA_PASS="your-password"     # 你的 Gitea 密码
GITEA_HOST="your-host:port"    # Gitea 服务器地址
```

### 4. 运行同步
```bash
./auto-sync.sh
```

## 📝 提交信息选项详解

### 1️⃣ 更新自动化脚本
**适用场景：**
- 修改了 `.sh` 脚本文件
- 更新了自动化任务逻辑
- 改进了脚本功能
- 修复了脚本 bug

**示例文件：**
```
auto-sync.sh
backup.sh
deploy.sh
monitor.sh
cleanup.sh
```

### 2️⃣ 更新配置文件
**适用场景：**
- 修改了 `.yml/.yaml` 文件
- 更新了 `.conf/.cfg` 配置
- 改变了环境变量
- 调整了服务配置

**示例文件：**
```
docker-compose.yml
nginx.conf
config.yaml
.env
inventory
settings.json
```

### 3️⃣ 日常维护更新
**适用场景：**
- 定期的小幅调整
- 清理无用文件
- 更新项目文档
- 常规优化操作

**示例操作：**
```
- 删除临时文件
- 更新 README.md
- 整理目录结构
- 小幅度改进
- 注释更新
```

### 4️⃣ 修复问题
**适用场景：**
- 解决了具体 bug
- 修复了错误配置
- 解决了运行时问题
- 紧急修复

**示例情况：**
```
- 修复语法错误
- 解决权限问题
- 修正路径错误
- 修复依赖冲突
- 解决网络连接问题
```

### 5️⃣ 功能优化
**适用场景：**
- 添加新功能模块
- 性能改进
- 用户体验提升
- 功能增强

**示例操作：**
```
- 添加新的监控功能
- 改进错误处理机制
- 增加日志记录
- 优化执行速度
- 添加新的配置选项
```

### 0️⃣ 自定义输入
**适用场景：**
- 需要更具体的描述
- 特殊情况说明
- 详细的变更记录
- 复杂的多文件变更

**示例自定义信息：**
```
"添加 MySQL 自动备份脚本和定时任务"
"修复 Nginx 配置文件权限问题"
"集成 Prometheus 监控和 Grafana 仪表板"
"更新 Ansible playbook 变量和模板"
"重构用户认证模块，提升安全性"
```

### q 退出（不提交）
**适用场景：**
- 发现变更有问题需要修改
- 需要进一步检查代码
- 暂时不想提交变更
- 误操作了文件

## 🎯 使用场景指南

### 根据文件类型选择

| 文件类型 | 推荐选项 | 说明 |
|---------|---------|------|
| `.sh` 脚本文件 | **1** | 更新自动化脚本 |
| `.yml/.yaml` 配置 | **2** | 更新配置文件 |
| `.conf/.cfg` 配置 | **2** | 更新配置文件 |
| `README/文档` | **3** | 日常维护更新 |
| 错误修复 | **4** | 修复问题 |
| 新功能添加 | **5** | 功能优化 |
| 复杂变更 | **0** | 自定义详细描述 |

### 实际使用示例

```bash
# 场景1：修改了 docker-compose.yml 中的端口配置
选择：2 (更新配置文件)

# 场景2：添加了新的系统监控脚本
选择：5 (功能优化) 或 0 (自定义："添加系统资源监控脚本")

# 场景3：修复了文件权限导致的服务启动失败
选择：4 (修复问题)

# 场景4：更新了多个自动化脚本的逻辑
选择：1 (更新自动化脚本)

# 场景5：整理项目结构，更新了文档
选择：3 (日常维护更新)

# 场景6：重大功能更新，涉及多个模块
选择：0 (自定义："重构认证系统，添加双因子验证")
```

## ⚙️ 配置说明

### Git 配置
脚本会自动配置以下 Git 设置：
```bash
git config pull.rebase false          # 使用 merge 策略
git config credential.helper store    # 存储认证信息
```

### 认证文件
认证信息存储在 `~/.git-credentials`，格式：
```
http://username:password@host:port
```

### 安全建议
- 使用 Gitea 的 **Access Token** 替代密码
- 定期更换认证信息
- 确保 `.git-credentials` 文件权限为 600

## 🔧 故障排除

### 常见问题

#### 1. 认证失败
```bash
# 检查认证配置
cat ~/.git-credentials

# 重新配置认证
rm ~/.git-credentials
./auto-sync.sh
```

#### 2. 拉取冲突
```bash
# 脚本会自动处理，如果仍有问题：
git stash
git pull gitea master
git stash pop
```

#### 3. 推送失败
```bash
# 检查远程仓库状态
git remote -v
git status

# 强制推送（谨慎使用）
git push gitea master --force
```

#### 4. 选项不显示
确保在交互式终端中运行：
```bash
# 检查终端环境
echo $TERM
tty

# 如果在非交互环境，使用简单版本
./simple-sync.sh "提交信息"
```

### 日志调试
添加调试信息：
```bash
# 在脚本开头添加
set -x  # 显示执行的命令
set -e  # 遇到错误立即退出
```

## 📚 进阶使用

### 创建别名
```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
alias gsync='./auto-sync.sh'
alias gquick='./auto-sync.sh && echo "同步完成"'
```

### 定时同步
```bash
# 添加到 crontab
# 每小时自动同步
0 * * * * cd /path/to/your/repo && ./auto-sync.sh >/dev/null 2>&1
```

### 集成到 CI/CD
```yaml
# .gitea/workflows/sync.yml
name: Auto Sync
on:
schedule:
  - cron: '0 */6 * * *'  # 每6小时运行一次
jobs:
sync:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - name: Run sync
      run: ./auto-sync.sh
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 开发规范
- 遵循 Shell 脚本最佳实践
- 添加适当的错误处理
- 保持代码注释清晰
- 测试各种使用场景

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

感谢所有贡献者和使用者的反馈！

---

**快速开始：** `chmod +x auto-sync.sh && ./auto-sync.sh`

**问题反馈：** [Issues](../../issues)

**最后更新：** $(date '+%Y-%m-%d')
