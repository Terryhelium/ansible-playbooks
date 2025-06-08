#!/bin/bash

echo "🎯 Playbook 目录结构优化工具"
echo "============================="

# 创建标准目录结构
echo "📁 创建标准目录结构..."
mkdir -p playbooks/system
mkdir -p playbooks/network  
mkdir -p playbooks/docker
mkdir -p playbooks/monitoring
mkdir -p playbooks/security
mkdir -p playbooks/backup
mkdir -p playbooks/maintenance

echo "✅ 标准目录创建完成"

# 移动现有文件到合适位置
echo "🔄 整理现有文件..."

# 系统相关
if [ -f "playbooks/system-info.yml" ]; then
    mv playbooks/system-info.yml playbooks/system/
    echo "  📄 移动 system-info.yml → system/"
fi

if [ -f "playbooks/package-update.yml" ]; then
    mv playbooks/package-update.yml playbooks/system/
    echo "  📄 移动 package-update.yml → system/"
fi

# 网络相关  
if [ -f "playbooks/connection-test.yml" ]; then
    mv playbooks/connection-test.yml playbooks/network/
    echo "  📄 移动 connection-test.yml → network/"
fi

if [ -f "playbooks/ping.yml" ]; then
    mv playbooks/ping.yml playbooks/network/
    echo "  📄 移动 ping.yml → network/"
fi

# Docker 相关
if [ -f "playbooks/docker-management.yml" ]; then
    mv playbooks/docker-management.yml playbooks/docker/
    echo "  📄 移动 docker-management.yml → docker/"
fi

if [ -f "playbooks/docker-management-fixed.yml" ]; then
    mv playbooks/docker-management-fixed.yml playbooks/docker/
    echo "  📄 移动 docker-management-fixed.yml → docker/"
fi

# 构建部署相关
if [ -f "playbooks/build.yml" ]; then
    mv playbooks/build.yml playbooks/maintenance/
    echo "  📄 移动 build.yml → maintenance/"
fi

if [ -f "playbooks/deploy.yml" ]; then
    mv playbooks/deploy.yml playbooks/maintenance/
    echo "  📄 移动 deploy.yml → maintenance/"
fi

# 处理嵌套的 playbooks 目录
if [ -d "playbooks/playbooks" ]; then
    echo "🔄 处理嵌套目录..."
    
    # 移动嵌套目录中的文件
    if [ -d "playbooks/playbooks/monitoring" ]; then
        cp -r playbooks/playbooks/monitoring/* playbooks/monitoring/ 2>/dev/null || true
        echo "  📁 复制 monitoring/ 内容"
    fi
    
    if [ -d "playbooks/playbooks/network" ]; then
        cp -r playbooks/playbooks/network/* playbooks/network/ 2>/dev/null || true
        echo "  📁 复制 network/ 内容"
    fi
    
    if [ -d "playbooks/playbooks/docker" ]; then
        cp -r playbooks/playbooks/docker/* playbooks/docker/ 2>/dev/null || true
        echo "  📁 复制 docker/ 内容"
    fi
    
    if [ -d "playbooks/playbooks/system" ]; then
        cp -r playbooks/playbooks/system/* playbooks/system/ 2>/dev/null || true
        echo "  📁 复制 system/ 内容"
    fi
    
    if [ -d "playbooks/playbooks/test" ]; then
        cp -r playbooks/playbooks/test/* playbooks/maintenance/ 2>/dev/null || true
        echo "  📁 复制 test/ 内容 → maintenance/"
    fi
    
    # 删除嵌套目录
    rm -rf playbooks/playbooks/
    echo "  🗑️  删除嵌套目录"
fi

# 处理 system-maintenance 目录
if [ -d "playbooks/system-maintenance" ]; then
    cp -r playbooks/system-maintenance/* playbooks/maintenance/ 2>/dev/null || true
    rm -rf playbooks/system-maintenance/
    echo "  📁 合并 system-maintenance/ → maintenance/"
fi

echo "✅ 文件整理完成"

# 显示新的目录结构
echo ""
echo "📊 优化后的目录结构:"
if command -v tree >/dev/null 2>&1; then
    tree playbooks/
else
    echo "playbooks/"
    find playbooks/ -type d | sed 's|[^/]*/|  |g;s|^  ||' | sort
    echo ""
    echo "📄 Playbook 文件:"
    find playbooks/ -type f -name "*.yml" | sort
fi
