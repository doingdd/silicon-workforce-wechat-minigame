#!/bin/bash

# 停止硅基团队
# Usage: ./scripts/stop-team.sh [all|core|executors]

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
    if ! command -v openclaw &> /dev/null; then
        print_error "OpenClaw 未安装"
        exit 1
    fi
    print_success "OpenClaw 已安装"
}

# 停止核心层（Leads + CEO）
stop_core_team() {
    print_info "停止核心层..."

    # 使用 subagents kill 命令
    print_info "停止 CEO..."
    openclaw subagents kill --target "ceo" 2>/dev/null || print_warning "CEO 未运行"

    print_info "停止 Game Lead..."
    openclaw subagents kill --target "game-lead" 2>/dev/null || print_warning "Game Lead 未运行"

    print_info "停止 Growth Lead..."
    openclaw subagents kill --target "growth-lead" 2>/dev/null || print_warning "Growth Lead 未运行"

    print_info "停止 Data Lead..."
    openclaw subagents kill --target "data-lead" 2>/dev/null || print_warning "Data Lead 未运行"

    sleep 2
    print_success "核心层已停止"
}

# 停止所有 sub-agents
stop_all_subagents() {
    print_info "停止所有 sub-agents..."

    # 停止核心层
    stop_core_team

    # 停止执行层
    print_info "停止执行层..."

    openclaw subagents kill --target "game-dev" 2>/dev/null || print_warning "Game Dev 未运行"
    openclaw subagents kill --target "game-qa" 2>/dev/null || print_warning "Game QA 未运行"
    openclaw subagents kill --target "content" 2>/dev/null || print_warning "Content 未运行"
    openclaw subagents kill --target "social" 2>/dev/null || print_warning "Social 未运行"
    openclaw subagents kill --target "seo" 2>/dev/null || print_warning "SEO 未运行"
    openclaw subagents kill --target "analyst" 2>/dev/null || print_warning "Analyst 未运行"
    openclaw subagents kill --target "monetizer" 2>/dev/null || print_warning "Monetizer 未运行"

    sleep 2
    print_success "所有 sub-agents 已停止"
}

# 显示团队状态
show_team_status() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   硅基团队已停止${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# 主函数
main() {
    local stop_type="${1:-all}"

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   停止硅基团队${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    check_openclaw

    case "$stop_type" in
        core)
            stop_core_team
            ;;
        all)
            stop_all_subagents
            ;;
        *)
            print_error "Invalid stop type: ${stop_type}"
            echo ""
            echo "Usage: $0 [all|core]"
            echo ""
            echo "Options:"
            echo "  all      - 停止所有 sub-agents (默认)"
            echo "  core     - 只停止核心层 (CEO + Leads)"
            exit 1
            ;;
    esac

    show_team_status

    print_success "硅基团队停止完成！"
}

# 执行主函数
main "$@"
