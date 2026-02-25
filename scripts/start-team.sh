#!/bin/bash

# 启动硅基团队 - 微信小游戏项目
# 三层架构：Boss → CEO → Leads → Executors

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 OpenClaw
check_openclaw() {
    print_info "检查 OpenClaw..."
    if ! command -v openclaw &> /dev/null; then
        print_error "OpenClaw 未安装"
        exit 1
    fi
    print_success "OpenClaw 已安装"
}

# 检查 Persona 文件
check_personas() {
    print_info "检查 Persona 文件..."

    local personas=(
        "agents/leads/ceo-persona.md"
        "agents/leads/game-lead-persona.md"
        "agents/leads/growth-lead-persona.md"
        "agents/leads/data-lead-persona.md"
    )

    for persona in "${personas[@]}"; do
        if [ ! -f "$WORKSPACE_DIR/$persona" ]; then
            print_error "Persona 文件不存在: $persona"
            exit 1
        fi
    done

    print_success "所有 Persona 文件存在"
}

# 启动 CEO
start_ceo() {
    print_info "启动 CEO（项目总负责人）..."

    openclaw sessions_spawn \
        --task "$(cat "$WORKSPACE_DIR/agents/leads/ceo-persona.md")" \
        --label "ceo" \
        --mode session \
        --model "zai/glm-4.7" > /dev/null 2>&1 &

    sleep 2
    print_success "CEO 已启动 (label: ceo)"
}

# 启动 Game Lead
start_game_lead() {
    print_info "启动 Game Lead（游戏团队负责人）..."

    openclaw sessions_spawn \
        --task "$(cat "$WORKSPACE_DIR/agents/leads/game-lead-persona.md")" \
        --label "game-lead" \
        --mode session \
        --model "zai/glm-4.7" > /dev/null 2>&1 &

    sleep 2
    print_success "Game Lead 已启动 (label: game-lead)"
}

# 启动 Growth Lead
start_growth_lead() {
    print_info "启动 Growth Lead（增长团队负责人）..."

    openclaw sessions_spawn \
        --task "$(cat "$WORKSPACE_DIR/agents/leads/growth-lead-persona.md")" \
        --label "growth-lead" \
        --mode session \
        --model "zai/glm-4.7" > /dev/null 2>&1 &

    sleep 2
    print_success "Growth Lead 已启动 (label: growth-lead)"
}

# 启动 Data Lead
start_data_lead() {
    print_info "启动 Data Lead（数据团队负责人）..."

    openclaw sessions_spawn \
        --task "$(cat "$WORKSPACE_DIR/agents/leads/data-lead-persona.md")" \
        --label "data-lead" \
        --mode session \
        --model "zai/glm-4.7" > /dev/null 2>&1 &

    sleep 2
    print_success "Data Lead 已启动 (label: data-lead)"
}

# 显示团队状态
show_team_status() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   硅基团队启动成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "团队架构："
    echo "  Boss (你)"
    echo "    ↓"
    echo "  CEO (项目总负责人）"
    echo "    ↓"
    echo "  ┌──────────────────┬──────────────────┬──────────────────┐"
    echo "  │  Game Lead       │  Growth Lead     │  Data Lead        │"
    echo "  │  游戏团队负责人  │  增长团队负责人  │  数据团队负责人  │"
    echo "  └──────────────────┴──────────────────┴──────────────────┘"
    echo ""
    echo "Agent 统计："
    echo "  - CEO: 1 (mode: session, 一直运行）"
    echo "  - Leads: 3 (mode: session, 一直运行）"
    echo "  - Executors: 0 (mode: run, 按需启动）"
    echo "  - 总计: 4 个 Sub-Agents (当前）"
    echo ""
    echo "并发限制："
    echo "  - 最大并发 Sub-Agents: 8"
    echo "  - 当前并发: 4 (✅ 符合限制）"
    echo ""
    echo "下一步操作："
    echo "  1. 查看 Agents: openclaw subagents list"
    echo "  2. 发送任务: ./scripts/send-task.sh <label> <message>"
    echo "  3. 汇报状态: ./scripts/report-status.sh <role> [type]"
    echo "  4. 停止团队: ./scripts/stop-team.sh"
    echo ""
}

# 主函数
main() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   启动硅基团队 - 微信小游戏项目${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    check_openclaw
    check_personas

    print_info "启动第 1 层：CEO..."
    start_ceo

    print_info "启动第 2 层：Leads..."
    start_game_lead
    start_growth_lead
    start_data_lead

    show_team_status

    print_success "硅基团队启动完成！"
}

# 执行主函数
main "$@"
