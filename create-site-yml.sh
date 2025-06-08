#!/bin/bash

echo "📄 创建主入口文件..."

cat > playbooks/site.yml << 'YAML'
---
# 🎯 Semaphore 主 Playbook 入口文件
# 统一管理所有 playbook 的执行

- name: "🔍 系统信息收集"
  import_playbook: system/system-info.yml
  tags: [system, info]
  when: "'system' in ansible_run_tags or 'all' in ansible_run_tags"

- name: "🌐 网络连接测试"
  import_playbook: network/ping.yml
  tags: [network, test]
  when: "'network' in ansible_run_tags or 'all' in ansible_run_tags"

- name: "🐳 Docker 管理"
  import_playbook: docker/docker-management-fixed.yml
  tags: [docker, management]
  when: "'docker' in ansible_run_tags or 'all' in ansible_run_tags"

- name: "📦 系统包更新"
  import_playbook: system/package-update.yml
  tags: [system, update]
  when: "'update' in ansible_run_tags or 'all' in ansible_run_tags"
YAML

echo "✅ 主入口文件创建完成: playbooks/site.yml"
