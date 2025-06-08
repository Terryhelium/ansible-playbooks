#!/bin/bash
# 修复版自动认证双向 Git 同步脚本
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

# 函数：智能生成提交信息
generate_commit_message() {
  local changes=$(git status --porcelain)
  local playbook_changes=$(echo "$changes" | grep "playbooks/" | wc -l)
  local inventory_changes=$(echo "$changes" | grep "inventory/" | wc -l)
  local script_changes=$(echo "$changes" | grep -E "\.(sh|py)$" | wc -l)
  local config_changes=$(echo "$changes" | grep -E "\.(yml|yaml|conf|cfg)$" | wc -l)
  
  local suggestions=()
  
  # 根据文件类型智能建议
  if [ $script_changes -gt 0 ]; then
      suggestions+=("Add new automation scripts")
      suggestions+=("Update deployment scripts")
      suggestions+=("Fix script configuration")
  fi
  
  if [ $playbook_changes -gt 0 ]; then
      suggestions+=("Update Ansible playbooks")
      suggestions+=("Add new server automation tasks")
      suggestions+=("Fix playbook configuration")
  fi
  
  if [ $inventory_changes -gt 0 ]; then
      suggestions+=("Update server inventory")
      suggestions+=("Add new hosts configuration")
  fi
  
  if [ $config_changes -gt 0 ]; then
      suggestions+=("Update configuration files")
      suggestions+=("Improve service configuration")
  fi
  
  # 通用建议
  suggestions+=("Update project files")
  suggestions+=("Add documentation and scripts")
  suggestions+=("Improve automation tools")
  suggestions+=("General maintenance update")
  
  echo ""
  echo -e "${YELLOW}💡 提交信息选项：${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  for i in "${!suggestions[@]}"; do
      printf "   ${GREEN}%d)${NC} %s\n" $((i+1)) "${suggestions[$i]}"
  done
  printf "   ${GREEN}0)${NC} %s\n" "自定义输入"
  
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  while true; do
      read -p "💬 选择提交信息 (0-${#suggestions[@]}): " choice
      
      if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "${#suggestions[@]}" ]; then
          if [ "$choice" -eq 0 ]; then
              echo ""
              read -p "✏️  请输入自定义提交信息: " custom_msg
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
          echo -e "${RED}❌ 无效选择，请输入 0-${#suggestions[@]}${NC}"
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
  
  echo "   最近提交："
  git log --oneline -3 | sed 's/^/     /'
  echo ""
}

# 函数：显示远程状态
show_remote_status() {
  echo -e "${BLUE}🌐 远程仓库状态：${NC}"
  echo "   地址：$(git remote get-url gitea 2>/dev/null || echo '未配置')"
  
  echo "   正在获取远程信息..."
  if git fetch gitea >/dev/null 2>&1; then
      local_commit=$(git rev-parse HEAD)
      remote_commit=$(git rev-parse gitea/master 2>/dev/null)
      
      if [ "$local_commit" = "$remote_commit" ]; then
          echo -e "   状态：${GREEN}✅ 与远程同步${NC}"
      else
          ahead=$(git rev-list --count HEAD..gitea/master 2>/dev/null || echo "0")
          behind=$(git rev-list --count gitea/master..HEAD 2>/dev/null || echo "0")
          
          if [ $ahead -gt 0 ]; then
              echo -e "   状态：${YELLOW}⬇️  远程有 $ahead 个新提交${NC}"
          fi
          
          if [ $behind -gt 0 ]; then
              echo -e "   状态：${YELLOW}⬆️  本地有 $behind 个未推送提交${NC}"
          fi
      fi
  else
      echo -e "   状态：${RED}❌ 无法连接远程仓库${NC}"
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
  
  # 询问是否添加所有文件
  read -p "📦 是否添加所有变更文件？(Y/n): " add_all
  if [[ ! $add_all =~ ^[Nn]$ ]]; then
      git add .
      echo -e "${GREEN}✅ 已添加所有文件${NC}"
  else
      # 选择性添加
      echo "请选择要添加的文件类型："
      echo "1) 只添加 playbooks/ 和 inventory/"
      echo "2) 只添加脚本文件 (.sh, .py)"
      echo "3) 手动选择"
      read -p "选择 (1-3): " file_choice
      
      case $file_choice in
          1) git add playbooks/ inventory/ ;;
          2) git add *.sh *.py 2>/dev/null || true ;;
          3) 
              git status --porcelain | while read status file; do
                  read -p "添加 $file？(y/N): " add_file
                  if [[ $add_file =~ ^[Yy]$ ]]; then
                      git add "$file"
                  fi
              done
              ;;
      esac
  fi
  
  # 检查是否有文件被添加
  if [ -z "$(git diff --cached --name-only)" ]; then
      echo -e "${YELLOW}⚠️  没有文件被添加到暂存区${NC}"
      return 0
  fi
  
  # 智能生成提交信息
  commit_msg=$(generate_commit_message)
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

# 函数：快速同步
quick_sync() {
  echo -e "${GREEN}⚡ 快速双向同步开始...${NC}"
  echo ""
  
  # 检查是否需要配置认证
  if [ ! -f ~/.git-credentials ] || ! git config --get credential.helper >/dev/null; then
      setup_auto_auth
  fi
  
  pull_remote_changes
  push_local_changes
  
  echo -e "${GREEN}🎉 快速同步完成！${NC}"
}

# 函数：显示菜单
show_menu() {
  echo -e "${BLUE}📋 操作菜单：${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "   ${GREEN}1)${NC} ⚡ 快速双向同步（推荐）"
  echo -e "   ${GREEN}2)${NC} 👀 查看仓库状态"
  echo -e "   ${GREEN}3)${NC} ⬇️  只拉取远程变更"
  echo -e "   ${GREEN}4)${NC} ⬆️  只推送本地变更"
  echo -e "   ${GREEN}5)${NC} 🔐 重新配置认证"
  echo -e "   ${GREEN}6)${NC} 📚 查看提交历史"
  echo -e "   ${GREEN}7)${NC} 🚪 退出"
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
      
      read -p "🎯 请选择操作 (1-7): " choice
      echo ""
      
      case $choice in
          1) 
              quick_sync 
              ;;
          2) 
              echo -e "${BLUE}📊 状态信息已显示在上方${NC}"
              ;;
          3) 
              pull_remote_changes 
              ;;
          4) 
              push_local_changes 
              ;;
          5) 
              setup_auto_auth 
              ;;
          6) 
              echo -e "${BLUE}📚 最近10次提交历史：${NC}"
              git log --oneline --graph --decorate -10
              echo ""
              ;;
          7) 
              echo -e "${GREEN}👋 感谢使用，再见！${NC}"
              exit 0 
              ;;
          *) 
              echo -e "${RED}❌ 无效选择，请输入 1-7${NC}"
              ;;
      esac
      
      echo ""
      read -p "⏸️  按回车键继续..." 
      clear
  done
}

main "$@"
