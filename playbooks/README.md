# 📚 Semaphore Playbooks 集合

## 🎯 项目概述

这是一个为 Semaphore UI 优化的 Ansible Playbook 集合，提供了完整的系统管理、监控和维护自动化解决方案。

## 📁 目录结构


# 📄 创建主入口文件

echo ""
echo "📄 创建主入口文件..."

cat > playbooks/site.yml << 'EOF'
---
# 🎯 Semaphore 主 Playbook 入口文件
# 这个文件可以作为所有 playbook 的统一入口

- name: "🔍 系统信息收集"
  import_playbook: system/system-info.yml
  tags: [system, info]
  when: "'system' in ansible_run_tags or ansible_run_tags == ['all']"

- name: "🌐 网络连接测试"  
  import_playbook: network/ping.yml
  tags: [network, test]
  when: "'network' in ansible_run_tags or ansible_run_tags == ['all']"

- name: "🐳 Docker 管理"
  import_playbook: docker/docker-management-fixed.yml
  tags: [docker, management]
  when: "'docker' in ansible_run_tags or ansible_run_tags == ['all']"

- name: "📦 系统包更新"
  import_playbook: system/package-update.yml
  tags: [system, update]
  when: "'update' in ansible_run_tags or ansible_run_tags == ['all']"
