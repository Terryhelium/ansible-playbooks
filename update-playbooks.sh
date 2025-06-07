#!/bin/bash

# 🔄 Semaphore Playbook 更新脚本

set -e

echo "🎛️ Semaphore Playbook 更新工具"
echo "=================================="

# 检查是否在正确目录
if [[ ! -f "docker-compose.yml" ]]; then
    echo "❌ 错误: 请在 Semaphore 项目根目录执行此脚本"
    exit 1
fi

# 检查 Docker 命令
DOCKER_CMD=""
if command -v "docker-compose" >/dev/null 2>&1; then
    DOCKER_CMD="docker-compose"
elif command -v "docker" >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    DOCKER_CMD="docker compose"
else
    echo "❌ 错误: 未找到 docker-compose 或 docker compose 命令"
    exit 1
fi

echo "🐳 使用 Docker 命令: $DOCKER_CMD"

# 检查 Git 状态
echo "🔍 检查 Git 状态..."
if git status --porcelain | grep -q .; then
    echo "📝 发现未提交的更改:"
    git status --short
    echo ""
    
    # 显示具体更改
    echo "📋 详细更改内容:"
    git diff --name-only | while read file; do
        echo "  📄 $file"
    done
    echo ""
    
    # 询问是否提交
    read -p "🤔 是否提交这些更改? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 添加所有 playbook 更改
        git add playbooks/
        git add README.md 2>/dev/null || true
        git add docker-compose.yml 2>/dev/null || true
        
        # 生成提交信息
        echo "✍️  请输入提交描述 (按 Enter 使用默认):"
        read -r commit_msg
        
        if [[ -z "$commit_msg" ]]; then
            commit_msg="🔧 更新 Playbooks - $(date '+%Y-%m-%d %H:%M')"
        fi
        
        # 提交更改
        git commit -m "$commit_msg"
        echo "✅ 更改已提交到 Git"
        
        # 如果有远程仓库，询问是否推送
        if git remote | grep -q origin; then
            read -p "🌐 是否推送到远程仓库? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git push origin main
                echo "🚀 已推送到远程仓库"
            fi
        fi
    else
        echo "⏭️  跳过提交"
    fi
else
    echo "✅ 没有未提交的更改"
fi

# 检查 Semaphore 容器状态
echo ""
echo "🐳 检查 Semaphore 服务状态..."

# 检查服务是否运行
if $DOCKER_CMD ps | grep -q "semaphore"; then
    echo "✅ Semaphore 服务正在运行"
    
    # 显示服务状态
    echo "📊 当前服务状态:"
    $DOCKER_CMD ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # 可选：重启服务以应用更改
    read -p "🔄 是否重启 Semaphore 服务以应用更改? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 重启服务中..."
        $DOCKER_CMD restart
        echo "✅ 服务重启完成"
        
        # 等待服务启动
        echo "⏳ 等待服务启动..."
        sleep 5
        
        # 显示最终状态
        echo "📊 重启后状态:"
        $DOCKER_CMD ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    fi
else
    echo "⚠️  Semaphore 服务未运行"
    
    # 检查是否有停止的容器
    if $DOCKER_CMD ps -a | grep -q "semaphore"; then
        echo "🔍 发现已停止的 Semaphore 容器"
        read -p "🚀 是否启动服务? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🚀 启动服务中..."
            $DOCKER_CMD up -d
            echo "✅ 服务启动完成"
            
            # 等待服务完全启动
            echo "⏳ 等待服务完全启动..."
            sleep 10
            
            # 显示服务状态
            echo "📊 服务状态:"
            $DOCKER_CMD ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        fi
    else
        echo "❌ 未找到 Semaphore 容器，请检查 docker-compose.yml 配置"
    fi
fi

echo ""
echo "🎉 更新完成！"
echo ""
echo "🌐 Semaphore 访问信息:"
echo "   地址: http://localhost:3003"
echo "   账号: admin"
echo "   密码: admin123456"
echo ""
echo "📚 使用提示:"
echo "   1. 修改 playbooks/ 下的文件后运行此脚本"
echo "   2. 脚本会自动处理 Git 版本控制"
echo "   3. 可选择重启服务应用更改"
echo "   4. 支持远程仓库推送"
