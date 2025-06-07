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
if docker-compose ps | grep -q "Up"; then
    echo "✅ Semaphore 服务正在运行"
    
    # 可选：重启服务以应用更改
    read -p "🔄 是否重启 Semaphore 服务以应用更改? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 重启服务中..."
        docker-compose restart semaphore_ui
        echo "✅ 服务重启完成"
    fi
else
    echo "⚠️  Semaphore 服务未运行，是否启动?"
    read -p "🚀 启动服务? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose up -d
        echo "✅ 服务启动完成"
    fi
fi

echo ""
echo "🎉 更新完成！"
echo "🌐 访问地址: http://localhost:3003"
echo "👤 默认账号: admin / admin123456"
