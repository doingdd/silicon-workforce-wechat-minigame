#!/bin/bash

# 问题上报 - 层层上报机制
# Usage: ./scripts/escalate-problem.sh <from_role> <to_role> <problem_description> [attempt_count]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查参数
if [ $# -lt 3 ]; then
    echo -e "${RED}Usage: $0 <from_role> <to_role> <problem_description> [attempt_count]${NC}"
    echo ""
    echo "Roles:"
    echo "  ceo, game-lead, growth-lead, data-lead"
    echo "  game-dev, game-qa, content, social, seo"
    echo "  analyst, monetizer"
    echo ""
    echo "Escalation Path:"
    echo "  game-dev → game-lead → ceo → Boss"
    echo "  game-qa → game-lead → ceo → Boss"
    echo "  content → growth-lead → ceo → Boss"
    echo "  social → growth-lead → ceo → Boss"
    echo "  seo → growth-lead → ceo → Boss"
    echo "  analyst → data-lead → ceo → Boss"
    echo "  monetizer → data-lead → ceo → Boss"
    echo ""
    echo "Example:"
    echo "  $0 game-dev game-lead '游戏无法通过审核' 3"
    exit 1
fi

FROM_ROLE="$1"
TO_ROLE="$2"
PROBLEM_DESC="$3"
ATTEMPT_COUNT="${4:-1}"

# 获取当前时间
CURRENT_DATE=$(date +"%Y-%m-%d")
CURRENT_TIME=$(date +"%H:%M")

# 检查 OpenClaw
if ! command -v openclaw &> /dev/null; then
    echo -e "${RED}Error: OpenClaw not found${NC}"
    exit 1
fi

# 生成问题上报消息
ESCALATION_MSG="[${FROM_ROLE^^}问题上报]
上报时间：${CURRENT_DATE} ${CURRENT_TIME}

问题描述：
- ${PROBLEM_DESC}

尝试解决次数：${ATTEMPT_COUNT}次

标记："

# 判断是否需要上报给 Boss
if [ "$TO_ROLE" = "boss" ]; then
    ESCALATION_MSG="${ESCALATION_MSG}[无法解决，需要Boss介入]"
    echo -e "${BLUE}[INFO]${NC} Escalating to ${GREEN}Boss${NC}..."
    echo ""

    # 发送到飞书
    openclaw message send \
        --channel feishu \
        --to ou_e7eea72f7d508227dbf42b50fc63f6f9 \
        --message "$ESCALATION_MSG"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS]${NC} Problem escalated to Boss"
    else
        echo -e "${RED}[ERROR]${NC} Failed to escalate to Boss"
        exit 1
    fi
else
    # 判断循环次数
    if [ "$ATTEMPT_COUNT" -ge 3 ]; then
        ESCALATION_MSG="${ESCALATION_MSG}[循环3次，需要上级介入]"
        NEXT_ROLE="boss"
        echo -e "${YELLOW}[WARNING]${NC} Attempt count (${ATTEMPT_COUNT}) reached limit (3), escalating to Boss..."
    else
        ESCALATION_MSG="${ESCALATION_MSG}[等待${TO_ROLE}介入]"
        NEXT_ROLE="$TO_ROLE"
        echo -e "${BLUE}[INFO]${NC} Escalating from ${GREEN}${FROM_ROLE}${NC} to ${GREEN}${TO_ROLE}${NC}..."
    fi
    echo ""

    # 发送给指定角色
    openclaw sessions_send \
        --label "$NEXT_ROLE" \
        --message "$ESCALATION_MSG"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS]${NC} Problem escalated to ${NEXT_ROLE}"
    else
        echo -e "${RED}[ERROR]${NC} Failed to escalate to ${NEXT_ROLE}"
        exit 1
    fi
fi

echo ""
echo "Escalation Message:"
echo ""
echo "$ESCALATION_MSG"
