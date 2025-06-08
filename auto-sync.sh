#!/bin/bash
# 修复输出捕获问题的同步脚本
cd /docker/semaphore

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GITEA_USER="admin"
GITEA_PASS="march23\$"
GITEA_HOST="192.168.31.217:3004"

# 修复：将显示和选择分离
show_commit_options() {
  # 直接输出到屏幕，不被捕获
  echo ""
  echo -e "${YELLOW}💡 选择提交信息：${NC}" >&2
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  echo -e "   ${GREEN}1)${NC} 更新自动化脚本" >&2
  echo -e "   ${GREEN}2)${NC} 更新配置文件" >&2
  echo -e "   ${GREEN}3)${NC} 日常维护更新" >&2
  echo -e "   ${GREEN}4)${NC} 修复问题" >&2
  echo -e "   ${GREEN}5)${NC} 功能优化" >&2
  echo -e "   ${GREEN}0)${NC} ✏️ 自定义输入" >&2
  echo -e "   ${GREEN}q)${NC} 🚪 退出（不提交）" >&2
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  echo "" >&2
}

# 只返回选择结果，不显示选项
get_commit_choice() {
  local suggestions=(
      "更新自动化脚本"
      "更新配置文件"
      "日常维护更新"
      "修复问题"
      "功能优化"
  )
  
  while true; do
      read -p "💬 请选择 (1-5/0/q): " choice >&2
      
      case "$choice" in
          [1-5])
              echo "${suggestions[$((choice-1))]}"
              return 0
              ;;
          0)
              echo "" >&2
              read -p "✏️  请输入提交信息: " custom_msg >&2
              if [ -n "$custom_msg" ]; then
                  echo "$custom_msg"
                  return 0
              else
                  echo -e "${RED}❌ 提交信息不能为空${NC}" >&2
              fi
              ;;
          [qQ])
              return 1
              ;;
          *)
              echo -e "${RED}❌ 请输入 1-5、0 或 q${NC}" >&2
              ;;
      esac
  done
}

# 选择提交信息的完整流程
choose_commit_message() {
  show_commit_options  # 显示选项（输出到 stderr，不被捕获）
  get_commit_choice    # 获取选择（返回值会被捕获）
}

setup_auto_auth() {
  echo -e "${BLUE}🔐 配置自动认证...${NC}"
  git config pull.rebase false
  git config credential.helper store
  echo "http://${GITEA_USER}:${GITEA_PASS}@${GITEA_HOST}" > ~/.git-credentials
  chmod 600 ~/.git-credentials
  echo -e "${GREEN}✅ 自动认证配置完成${NC}"
  echo ""
}

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

push_local_changes() {
  echo -e "${BLUE}⬆️  处理本地变更...${NC}"
  
  if [ -z "$(git status --porcelain)" ]; then
      echo -e "${GREEN}✅ 没有变更需要提交${NC}"
      return 0
  fi
  
  echo ""
  echo -e "${YELLOW}📁 变更文件列表：${NC}"
  git status --short
  echo ""
  
  git add .
  echo -e "${GREEN}✅ 已添加所有文件${NC}"
  echo ""
  
  echo -e "${BLUE}📋 即将提交的文件：${NC}"
  git diff --cached --name-only | sed 's/^/   /'
  
  # 修复：分离显示和选择
  commit_msg=$(choose_commit_message)
  if [ $? -ne 0 ]; then
      echo -e "${YELLOW}⚠️  操作已取消${NC}"
      return 0
  fi
  
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

sync_repo() {
  echo -e "${GREEN}🔄 开始双向同步...${NC}"
  echo ""
  
  if [ ! -f ~/.git-credentials ] || ! git config --get credential.helper >/dev/null; then
      setup_auto_auth
  fi
  
  pull_remote_changes
  push_local_changes
  
  echo -e "${GREEN}🎉 双向同步完成！${NC}"
}

main() {
  clear
  echo -e "${GREEN}🔄 Git 双向同步工具${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
      echo -e "${RED}❌ 当前目录不是 Git 仓库${NC}"
      exit 1
  fi
  
  case "$1" in
      ""|"sync")
          sync_repo
          exit 0
          ;;
  esac
}

main "$@"
