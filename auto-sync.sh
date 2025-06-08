#!/bin/bash
# 简化中文双向 Git 同步脚本
# 文件名：auto-sync.sh

cd /docker/semaphore

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Git 配置
GITEA_USER="admin"
GITEA_PASS="march23\$"
GITEA_HOST="192.168.31.217:3004"
GITEA_REPO="admin/ansible-playbooks"

# 函数：配置自动认证
setup_auto_auth() {
  echo -e "${BLUE}🔐 配置自动认证...${NC}"
  
  # 配置 Git 拉取策略（消除警告）
  git config pull.rebase false
  
  # 配置凭证存储
  git config credential.helper store
  
  # 创建凭证文件
  echo "http://${GITEA_USER}:${GITEA_PASS}@${GITEA_HOST}" > ~/.git-credentials
  
  # 设置权限
  chmod 600 ~/.git-credentials
  
  echo -e "${GREEN}✅ 自动认证配置完成${NC}"
  echo ""
}

# 函数：选择提交信息
choose_commit_message() {
  local suggestions=(
      "更新自动化脚本"
      "更新配置文件"
      "日常维护更新"
      "修复问题"
      "功能优化"
  )
  
  # 显示选项
  echo ""
  echo -e "${YELLOW}💡 选择提交信息：${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  for i in "${!suggestions[@]}"; do
      printf "   ${GREEN}%d)${NC} %s\n" $((i+1)) "${suggestions[$i]}"
  done
  printf "   ${GREEN}0)${NC} ✏️ 自定义输入\n"
  
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # 获取用户选择
  while true; do
      read -p "💬 请选择 (0-${#suggestions[@]}): " choice
      
      if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "${#suggestions[@]}" ]; then
          if [ "$choice" -eq 0 ]; then
              echo ""
              read -p "✏️  请输入提交信息: " custom_msg
              if [ -n "$custom_msg" ]; then
                  echo "$custom_msg"
                  return 0
              else
                  echo -e "${RED}❌ 提交信息不能为空，请重新选择${NC}"
                  echo ""
                  continue
              fi
          else
              echo "${suggestions[$((choice-1))]}"
              return 0
          fi
      else
          echo -e "${RED}❌ 请输入 0-${#suggestions[@]}${NC}"
          echo ""
      fi
  done
}

# 函数：显示本地状态
show_local_status() {
  echo -e "${BLUE}📍 本地仓库状态：${NC}"
  echo "   路径：$(pwd)"
  echo "   分支：$(git branch --show-current)"
  
  local_changes=$(git status --porcelain)
  if [ -z "$local_changes" ]; then
      echo -e "   状态：${GREEN}✅ 工作区干净${NC}"
  else
      echo -e "   状态：${YELLOW}⚠️  有未提交的变更${NC}"
      echo "   变更文件："
      git status --short | sed 's/^/     /'
  fi
  echo ""
}

# 函数：拉取远程变更
pull_remote_changes() {
  echo -e "${BLUE}⬇️  拉取远程变更...${NC}"
  
  if [ -n "$(git status --porcelain)" ]; then
      echo -e "${YELLOW}⚠️  暂存本地变更...${NC}"
      git stash push -m "Auto-stash before pull $(date)" >/dev/null 2>&1
      stashed=true
  else
      stashed=false
  fi
  
  if git pull gitea master >/dev/null 2>&1; then
      echo -e "${GREEN}✅ 远程变更拉取成功${NC}"
      
      if [ "$stashed" = true ]; then
          echo -e "${BLUE}📦 恢复暂存的变更...${NC}"
          git stash pop >/dev/null 2>&1
      fi
  else
      echo -e "${RED}❌ 拉取失败${NC}"
      return 1
  fi
  echo ""
}

# 函数：推送本地变更
push_local_changes() {
  echo -e "${BLUE}⬆️  处理本地变更...${NC}"
  
  if [ -z "$(git status --porcelain)" ]; then
      echo -e "${GREEN}✅ 没有变更需要提交${NC}"
      return 0
  fi
  
  echo ""
  echo -e "${YELLOW}📁 变更文件列表：${NC}"
  git status --short | while read line; do
      echo "   $line"
  done
  echo ""
  
  # 直接添加所有文件
  git add .
  echo -e "${GREEN}✅ 已添加所有文件${NC}"
  echo ""
  
  # 显示即将提交的文件
  echo -e "${BLUE}📋 即将提交的文件：${NC}"
  git diff --cached --name-only | sed 's/^/   /'
  
  # 选择提交信息
  commit_msg=$(choose_commit_message)
  echo ""
  echo -e "${GREEN}📝 使用提交信息：${BLUE}$commit_msg${NC}"
  echo ""
  
  if git commit -m "$commit_msg" >/dev/null 2>&1; then
      echo -e "${GREEN}✅ 提交成功${NC}"
      
      echo -e "${BLUE}🚀 推送到 Gitea...${NC}"
      if git push gitea master >/dev/null 2>&1; then
          echo -e "${GREEN}✅ 推送成功${NC}"
      else
          echo -e "${RED}❌ 推送失败${NC}"
          return 1
      fi
  else
      echo -e "${RED}❌ 提交失败${NC}"
      return 1
  fi
  echo ""
}

# 函数：双向同步
sync_repo() {
  echo -e "${GREEN}🔄 开始双向同步...${NC}"
  echo ""
  
  # 检查是否需要配置认证
  if [ ! -f ~/.git-credentials ] || ! git config --get credential.helper >/dev/null; then
      setup_auto_auth
  fi
  
  pull_remote_changes
  push_local_changes
  
  echo -e "${GREEN}🎉 双向同步完成！${NC}"
}

# 函数：显示菜单
show_menu() {
  echo -e "${BLUE}📋 操作菜单：${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "   ${GREEN}1)${NC} 🔄 双向同步"
  echo -e "   ${GREEN}2)${NC} 🚪 退出"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# 主程序
main() {
  # 清屏
  clear
  
  echo -e "${GREEN}🔄 Git 双向同步工具${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
      echo -e "${RED}❌ 当前目录不是 Git 仓库${NC}"
      exit 1
  fi
  
  # 命令行参数处理
  case "$1" in
      ""|"sync")
          sync_repo
          exit 0
          ;;
      "setup")
          setup_auto_auth
          exit 0
          ;;
  esac
  
  # 交互式菜单
  while true; do
      show_local_status
      show_menu
      
      read -p "🎯 请选择操作 (1-2): " choice
      echo ""
      
      case $choice in
          1) 
              sync_repo 
              ;;
          2) 
              echo -e "${GREEN}👋 感谢使用，再见！${NC}"
              exit 0 
              ;;
          *) 
              echo -e "${RED}❌ 请输入 1 或 2${NC}"
              ;;
      esac
      
      echo ""
      read -p "⏸️  按回车键继续..." 
      clear
  done
}

main "$@"
