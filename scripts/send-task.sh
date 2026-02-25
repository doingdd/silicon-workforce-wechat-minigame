#!/bin/bash

# 发送任务给指定角色
# Usage: ./scripts/send-task.sh <label> <message>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查参数
if [ $# -lt 2 ]; then
    echo -e "${RED}Usage: $0 <label> <message>${NC}"
    echo ""
    echo "Labels:"
    echo "  ceo          - CEO"
    echo "  game-lead    - Game Lead"
    echo "  growth-lead  - Growth Lead"
    echo "  data-lead    - Data Lead"
    echo "  game-dev     - Game Dev"
    echo "  game-qa      - Game QA"
    echo "  content      - Content"
    echo "  social       - Social"
    echo "  seo          - SEO"
    echo "  analyst      - Analyst"
    echo "  monetizer    - Monetizer"
    echo ""
    echo "Example:"
    echo "  $0 game-lead '开始开发游戏A'"
    exit 1
fi

LABEL="$1"
MESSAGE="$2"

# 检查 OpenClaw
if ! command -v openclaw &> /dev/null; then
    echo -e "${RED}Error: OpenClaw not found${NC}"
    exit 1
fi

# 发送消息
echo -e "${BLUE}[INFO]${NC} Sending message to ${GREEN}${LABEL}${NC}..."
echo ""
echo -e "Message: ${GREEN}${MESSAGE}${NC}"
echo ""

openclaw sessions_send \
    --label "$LABEL" \
    --message "$MESSAGE"

# 检查结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS]${NC} Message sent to ${LABEL}"
else
    echo -e "${RED}[ERROR]${NC} Failed to send message to ${LABEL}"
    exit 1
fi
