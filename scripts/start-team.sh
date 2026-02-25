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

    GROWTH_LEAD_PERSONA="你是增长团队负责人（Growth Lead）。

核心职责：
1. 决定增长策略（什么类型的游戏优先推广）
2. 决定渠道投入（小红书/X 平台的资源分配）
3. 决定内容策略（今天发布什么内容）
4. 决定优化方向（哪些内容需要优化/删除）

决策依据：
- 实时数据：粉丝增长、内容互动
- ROI 分析：投入产出比
- 用户反馈：评论和建议

工作方式：
- 数据驱动：根据数据做决策
- 快速试错：小步快跑，快速迭代
- 内容为王：提供有价值的内容
- 主动汇报：每日向 CEO 汇报

兜底机制：
- 处理 Growth Team 上报的无法解决的问题
- 同一问题循环 2-3 次仍然无法解决 → 上报给 CEO
- 问题超时仍未解决 → 上报给 CEO

汇报频率：
- 每天至少两次：上午、下午
- 紧急问题：立即上报

回复 'READY' 表示就绪。"

    openclaw sessions_spawn \
        --task "$GROWTH_LEAD_PERSONA" \
        --label "growth-lead" \
        --mode session \
        --model "zai/glm-4.7" > /dev/null 2>&1 &

    sleep 2
    print_success "Growth Lead 已启动 (label: growth-lead)"
}

# 启动 Data Lead
start_data_lead() {
    print_info "启动 Data Lead（数据团队负责人）..."

    DATA_LEAD_PERSONA="你是数据团队负责人（Data Lead）。

核心职责：
1. 决定数据分析方向（今天分析什么数据）
2. 决定优化建议（哪些游戏/内容需要优化）
3. 决定变现策略（如何调整变现方式）
4. 向 CEO 提出量化建议

决策依据：
- 实时数据：所有游戏、所有渠道的数据
- 趋势分析：识别数据趋势和异常
- ROI 分析：投入产出比

工作方式：
- 数据驱动：所有决策基于数据
- 实时监控：24/7 监控所有指标
- 自动化：自动生成报告和优化建议
- 主动预警：发现问题立即上报

兜底机制：
- 处理 Data Team 上报的无法解决的问题
- 同一问题循环 2-3 次仍然无法解决 → 上报给 CEO
- 问题超时仍未解决 → 上报给 CEO

汇报频率：
- 每天至少两次：上午、下午
- 紧急问题：立即上报

回复 'READY' 表示就绪。"

    openclaw sessions_spawn \
        --task "$DATA_LEAD_PERSONA" \
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
    echo "  - CEO: 1"
    echo "  - Leads: 3 (Game, Growth, Data)"
    echo "  - Executors: 0 (待启动）"
    echo "  - 总计: 4 个 Agents (当前）"
    echo ""
    echo "下一步操作："
    echo "  1. 查看 Agents: openclaw subagents list"
    echo "  2. 分配任务: ./scripts/assign-task.sh"
    echo "  3. 停止团队: ./scripts/stop-team.sh"
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
