#!/bin/bash

# 🎛️ Semaphore Playbook 最终更新脚本
# 现在文件实时同步，只需要管理 Git！

echo "🎛️ Semaphore Playbook 更新工具 v3.0"
echo "===================================="

# 检查服务状态
if docker compose ps | grep -q "semaphore.*Up"; then
    echo "✅ Semaphore 服务运行正常"
    echo "🔄 文件实时同步已启用 - 无需重启服务"
else
    echo "⚠️  Semaphore 服务未运行，启动服务..."
    docker compose up -d
    sleep 5
fi

# Git 管理
if git status --porcelain | grep -q .; then
    echo ""
    echo "📝 发现更改:"
    git status --short
    echo ""
    
    read -p "🤔 提交这些更改? (Y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        git add playbooks/ inventory/ *.md 2>/dev/null || true
        
        echo "✍️  输入提交描述 (回车使用默认):"
        read -r commit_msg
        
        if [[ -z "$commit_msg" ]]; then
            commit_msg="🔧 更新 Playbooks - $(date '+%Y-%m-%d %H:%M')"
        fi
        
        git commit -m "$commit_msg"
        echo "✅ 更改已提交到 Git"
        
        if git remote | grep -q origin; then
            read -p "🌐 推送到远程仓库? (Y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                git push 2>/dev/null && echo "🚀 推送完成" || echo "⚠️  推送失败"
            fi
        fi
    fi
else
    echo "✅ 没有未提交的更改"
fi

echo ""
echo "🎉 更新完成！"
echo ""
echo "📊 服务信息:"
echo "   🌐 访问地址: http://localhost:3003"
echo "   📁 Playbooks: $(pwd)/playbooks/"
echo "   🔄 实时同步: ✅ 已启用"
echo "   🚀 状态: 文件修改立即生效，无需重启"
