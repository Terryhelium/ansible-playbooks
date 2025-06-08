#!/bin/bash
# 自动认证双向 Git 同步脚本
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
  
  # 配置凭证存储
  git config credential.helper store
  
  # 创建凭证文件
  echo "http://${GITEA_USER}:${GITEA_PASS}@${GITEA_HOST}" > ~/.git-credentials
  
  # 设置权限
  chmod 600 ~/.git-credentials
  
  echo -e "${GREEN}✅ 自动认证配置完成${NC}"
  echo ""
}

# 函数：智能生成提交信息
generate_commit_message() {
  local changes=$(git status --porcelain)
  local playbook_changes=$(echo "$changes" | grep "playbooks/" | wc -l)
  local inventory_changes=$(echo "$changes" | grep "inventory/" | wc -l)
  local other_changes=$(echo "$changes" | grep -v "playbooks/" | grep -v "inventory/" | wc -l)
  
  local suggestions=()
  
  if [ $playbook_changes -gt 0 ]; then
      suggestions+=("Update playbooks configuration")
      suggestions+=("Add new automation playbook")
      suggestions+=("Fix playbook tasks and handlers")
      suggestions+=("Improve playbook error handling")
  fi
  
  if [ $inventory_changes -gt 0 ]; then
      suggestions+=("Update server inventory")
      suggestions+=("Add new hosts to inventory")
      suggestions+=("Modify inventory groups")
  fi
  
  if [ $other_changes -gt 0 ]; then
      suggestions+=("Update configuration files")
      suggestions+=("Add documentation")
      suggestions+=("Fix general configuration")
  fi
  
  # 默认建议
  suggestions+=("Update Ansible configuration")
  suggestions+=("Improve automation scripts")
  suggestions+=("Add new server management tasks")
  suggestions+=("Update deployment configuration")
  
  echo -e "${YELLOW}💡 提交信息建议：${NC}"
  for i in "${!suggestions[@]}"; do
      echo "   $((i+1))) ${suggestions[$i]}"
  done
  echo "   0) 自定义输入"
  echo ""
  
  while true; do
      read -p "选择提交信息 (0-${#suggestions[@]}): " choice
      
      if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "${#suggestions[@]}" ]; then
          if [ "$choice" -eq 0 ]; then
              read -p "💬 请输入自定义提交信息: " custom_msg
              if [ -n "$custom_msg" ]; then
                  echo "$custom_msg"
                  return 0
              else
                  echo -e "${RED}❌ 提交信息不能为空${NC}"
                  continue
              fi
          else
              echo "${suggestions[$((choice-1))]}"
              return 0
          fi
      else
          echo -e "${RED}❌ 无效选择，请输入 0-${#suggestions[@]}${NC}"
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
  
  echo "   最近提交："
  git log --oneline -3 | sed 's/^/     /'
  echo ""
}

# 函数：显示远程状态
show_remote_status() {
  echo -e "${BLUE}🌐 远程仓库状态：${NC}"
  echo "   地址：$(git remote get-url gitea)"
  
  echo "   正在获取远程信息..."
  git fetch gitea >/dev/null 2>&1
  
  local_commit=$(git rev-parse HEAD)
  remote_commit=$(git rev-parse gitea/master)
  
  if [ "$local_commit" = "$remote_commit" ]; then
      echo -e "   状态：${GREEN}✅ 与远程同步${NC}"
  else
      ahead=$(git rev-list --count HEAD..gitea/master)
      behind=$(git rev-list --count gitea/master..HEAD)
      
      if [ $ahead -gt 0 ]; then
          echo -e "   状态：${YELLOW}⬇️  远程有 $ahead 个新提交${NC}"
      fi
      
      if [ $behind -gt 0 ]; then
          echo -e "   状态：${YELLOW}⬆️  本地有 $behind 个未推送提交${NC}"
      fi
  fi
  echo ""
}

# 函数：拉取远程变更
pull_remote_changes() {
  echo -e "${BLUE}⬇️  拉取远程变更...${NC}"
  
  if [ -n "$(git status --porcelain)" ]; then
      echo -e "${YELLOW}⚠️  暂存本地变更...${NC}"
      git stash push -m "Auto-stash before pull $(date)"
      stashed=true
  else
      stashed=false
  fi
  
  if git pull gitea master; then
      echo -e "${GREEN}✅ 远程变更拉取成功${NC}"
      
      if [ "$stashed" = true ]; then
          echo -e "${BLUE}📦 恢复暂存的变更...${NC}"
          git stash pop
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
  
  echo "变更文件："
  git status --short | sed 's/^/   /'
  echo ""
  
  # 添加主要文件
  git add playbooks/ inventory/
  
  # 检查其他文件
  other_files=$(git status --porcelain | grep -v "^A" | grep -v "playbooks/" | grep -v "inventory/")
  if [ -n "$other_files" ]; then
      echo -e "${YELLOW}⚠️  其他变更文件：${NC}"
      echo "$other_files" | sed 's/^/   /'
      read -p "是否也要添加？(y/N): " add_others
      if [[ $add_others =~ ^[Yy]$ ]]; then
          git add .
      fi
  fi
  
  # 智能生成提交信息
  commit_msg=$(generate_commit_message)
  echo ""
  echo -e "${GREEN}📝 使用提交信息：$commit_msg${NC}"
  
  if git commit -m "$commit_msg"; then
      echo -e "${GREEN}✅ 提交成功${NC}"
      
      echo -e "${BLUE}🚀 推送到 Gitea...${NC}"
      if git push gitea master; then
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

# 函数：快速同步
quick_sync() {
  echo -e "${GREEN}⚡ 快速双向同步...${NC}"
  echo ""
  
  # 检查是否需要配置认证
  if [ ! -f ~/.git-credentials ]; then
      setup_auto_auth
  fi
  
  pull_remote_changes
  push_local_changes
  
  echo -e "${GREEN}✅ 快速同步完成！${NC}"
}

# 函数：显示菜单
show_menu() {
  echo -e "${BLUE}📋 选择操作：${NC}"
  echo "   1) 快速双向同步（推荐）"
  echo "   2) 查看状态"
  echo "   3) 只拉取远程"
  echo "   4) 只推送本地"
  echo "   5) 配置自动认证"
  echo "   6) 查看提交历史"
  echo "   7) 退出"
  echo ""
}

# 主程序
main() {
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
      echo -e "${RED}❌ 当前目录不是 Git 仓库${NC}"
      exit 1
  fi
  
  # 命令行参数处理
  case "$1" in
      "sync"|"")
          quick_sync
          exit 0
          ;;
      "status")
          show_local_status
          show_remote_status
          exit 0
          ;;
      "pull")
          pull_remote_changes
          exit 0
          ;;
      "push")
          push_local_changes
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
      show_remote_status
      show_menu
      
      read -p "请选择 (1-7): " choice
      echo ""
      
      case $choice in
          1) quick_sync ;;
          2) ;; # 状态已显示
          3) pull_remote_changes ;;
          4) push_local_changes ;;
          5) setup_auto_auth ;;
          6) git log --oneline --graph -10 ;;
          7) echo -e "${GREEN}👋 再见！${NC}"; exit 0 ;;
          *) echo -e "${RED}❌ 无效选择${NC}" ;;
      esac
      
      read -p "按回车键继续..."
      clear
  done
}

main "$@"
