#!/bin/bash
# 双向 Git 同步脚本
# 文件名：sync-bidirectional.sh

cd /docker/semaphore

echo "🔄 ===== Git 双向同步工具 ====="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
  
  # 显示最近的提交
  echo "   最近提交："
  git log --oneline -3 | sed 's/^/     /'
  echo ""
}

# 函数：显示远程状态
show_remote_status() {
  echo -e "${BLUE}🌐 远程仓库状态：${NC}"
  echo "   地址：$(git remote get-url gitea)"
  
  # 获取远程信息
  echo "   正在获取远程信息..."
  git fetch gitea >/dev/null 2>&1
  
  # 比较本地和远程
  local_commit=$(git rev-parse HEAD)
  remote_commit=$(git rev-parse gitea/master)
  
  if [ "$local_commit" = "$remote_commit" ]; then
      echo -e "   状态：${GREEN}✅ 与远程同步${NC}"
  else
      # 检查是否有新的远程提交
      ahead=$(git rev-list --count HEAD..gitea/master)
      behind=$(git rev-list --count gitea/master..HEAD)
      
      if [ $ahead -gt 0 ]; then
          echo -e "   状态：${YELLOW}⬇️  远程有 $ahead 个新提交${NC}"
          echo "   远程新提交："
          git log --oneline HEAD..gitea/master | sed 's/^/     /'
      fi
      
      if [ $behind -gt 0 ]; then
          echo -e "   状态：${YELLOW}⬆️  本地有 $behind 个未推送提交${NC}"
          echo "   本地新提交："
          git log --oneline gitea/master..HEAD | sed 's/^/     /'
      fi
  fi
  echo ""
}

# 函数：拉取远程变更
pull_remote_changes() {
  echo -e "${BLUE}⬇️  拉取远程变更...${NC}"
  
  # 检查是否有本地未提交的变更
  if [ -n "$(git status --porcelain)" ]; then
      echo -e "${YELLOW}⚠️  检测到本地未提交的变更，先暂存...${NC}"
      git stash push -m "Auto-stash before pull $(date)"
      stashed=true
  else
      stashed=false
  fi
  
  # 拉取变更
  if git pull gitea master; then
      echo -e "${GREEN}✅ 远程变更拉取成功${NC}"
      
      # 如果之前暂存了变更，恢复它们
      if [ "$stashed" = true ]; then
          echo -e "${BLUE}📦 恢复暂存的变更...${NC}"
          if git stash pop; then
              echo -e "${GREEN}✅ 暂存变更恢复成功${NC}"
          else
              echo -e "${RED}❌ 暂存变更恢复失败，可能有冲突${NC}"
              echo "请手动解决冲突后运行：git stash drop"
          fi
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
  
  # 检查是否有变更需要提交
  if [ -z "$(git status --porcelain)" ]; then
      echo -e "${GREEN}✅ 没有变更需要提交${NC}"
      return 0
  fi
  
  # 显示将要添加的文件
  echo "将要添加的文件："
  git status --short | sed 's/^/   /'
  echo ""
  
  # 添加 playbooks 和 inventory 目录
  git add playbooks/ inventory/
  
  # 检查是否有其他文件需要添加
  other_files=$(git status --porcelain | grep -v "^A" | grep -v "playbooks/" | grep -v "inventory/")
  if [ -n "$other_files" ]; then
      echo -e "${YELLOW}⚠️  发现其他变更文件：${NC}"
      echo "$other_files" | sed 's/^/   /'
      read -p "是否也要添加这些文件？(y/N): " add_others
      if [[ $add_others =~ ^[Yy]$ ]]; then
          git add .
      fi
  fi
  
  # 获取提交信息
  echo ""
  read -p "💬 请输入提交信息: " commit_msg
  
  if [ -z "$commit_msg" ]; then
      echo -e "${RED}❌ 提交信息不能为空${NC}"
      return 1
  fi
  
  # 提交变更
  if git commit -m "$commit_msg"; then
      echo -e "${GREEN}✅ 提交成功${NC}"
      
      # 推送到远程
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

# 函数：显示菜单
show_menu() {
  echo -e "${BLUE}📋 选择操作：${NC}"
  echo "   1) 查看状态（本地 + 远程）"
  echo "   2) 拉取远程变更"
  echo "   3) 提交并推送本地变更"
  echo "   4) 完整双向同步（推荐）"
  echo "   5) 查看提交历史"
  echo "   6) 退出"
  echo ""
}

# 函数：查看提交历史
show_commit_history() {
  echo -e "${BLUE}📚 提交历史（最近10条）：${NC}"
  git log --oneline --graph --decorate -10
  echo ""
}

# 函数：完整双向同步
full_sync() {
  echo -e "${GREEN}🔄 开始完整双向同步...${NC}"
  echo ""
  
  # 1. 先拉取远程变更
  pull_remote_changes
  
  # 2. 再推送本地变更
  push_local_changes
  
  echo -e "${GREEN}✅ 双向同步完成！${NC}"
  echo ""
}

# 主程序
main() {
  # 检查是否在 git 仓库中
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
      echo -e "${RED}❌ 当前目录不是 Git 仓库${NC}"
      exit 1
  fi
  
  # 如果有参数，直接执行对应操作
  case "$1" in
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
      "sync")
          full_sync
          exit 0
          ;;
  esac
  
  # 交互式菜单
  while true; do
      show_local_status
      show_remote_status
      show_menu
      
      read -p "请选择 (1-6): " choice
      echo ""
      
      case $choice in
          1)
              # 状态已经在上面显示了
              ;;
          2)
              pull_remote_changes
              ;;
          3)
              push_local_changes
              ;;
          4)
              full_sync
              ;;
          5)
              show_commit_history
              ;;
          6)
              echo -e "${GREEN}👋 再见！${NC}"
              exit 0
              ;;
          *)
              echo -e "${RED}❌ 无效选择，请输入 1-6${NC}"
              ;;
      esac
      
      read -p "按回车键继续..."
      clear
  done
}

# 运行主程序
main "$@"
