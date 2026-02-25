#!/bin/bash

# 汇报状态给 Boss
# Usage: ./scripts/report-status.sh <role> [report_type]

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
if [ $# -lt 1 ]; then
    echo -e "${RED}Usage: $0 <role> [report_type]${NC}"
    echo ""
    echo "Roles:"
    echo "  ceo          - CEO"
    echo "  game-lead    - Game Lead"
    echo "  growth-lead  - Growth Lead"
    echo "  data-lead    - Data Lead"
    echo ""
    echo "Report Types (optional):"
    echo "  morning      - 早间汇报"
    echo "  afternoon    - 下午汇报"
    echo "  problem      - 问题上报"
    echo "  decision     - 决策申请"
    echo ""
    echo "Example:"
    echo "  $0 ceo morning"
    echo "  $0 game-lead problem"
    exit 1
fi

ROLE="$1"
REPORT_TYPE="${2:-auto}"

# 获取当前时间
CURRENT_HOUR=$(date +%H)
CURRENT_MINUTE=$(date +%M)
CURRENT_TIME="${CURRENT_HOUR}:${CURRENT_MINUTE}"
CURRENT_DATE=$(date +"%Y-%m-%d")

# 自动判断汇报类型
if [ "$REPORT_TYPE" = "auto" ]; then
    if [ "$CURRENT_HOUR" -ge 9 ] && [ "$CURRENT_HOUR" -lt 12 ]; then
        REPORT_TYPE="morning"
        TIME_PREFIX="早间"
    elif [ "$CURRENT_HOUR" -ge 18 ]; then
        REPORT_TYPE="afternoon"
        TIME_PREFIX="晚间"
    else
        REPORT_TYPE="update"
        TIME_PREFIX="进度更新"
    fi
else
    case "$REPORT_TYPE" in
        morning)
            TIME_PREFIX="早间"
            ;;
        afternoon)
            TIME_PREFIX="晚间"
            ;;
        problem)
            TIME_PREFIX="问题上报"
            ;;
        decision)
            TIME_PREFIX="决策申请"
            ;;
        *)
            TIME_PREFIX="汇报"
            ;;
    esac
fi

# 生成汇报标题
REPORT_TITLE="[${ROLE^^} ${TIME_PREFIX}汇报]"
REPORT_TIME="${CURRENT_DATE} ${CURRENT_TIME}"

# 生成汇报内容
case "$REPORT_TYPE" in
    morning|afternoon)
        echo -e "${BLUE}[INFO]${NC} Generating ${TIME_PREFIX}汇报 template for ${GREEN}${ROLE}${NC}..."
        REPORT_CONTENT="${REPORT_TITLE}
汇报时间：${REPORT_TIME}

1. 今日/本次完成的工作
   - [填写具体工作]
   - [填写具体工作]

2. 遇到的问题
   - 无 / [问题描述]
   - [是否已解决：是/否]

3. 需要的支持
   - 无 / [具体需求]

4. 下一步计划
   - [填写具体计划]"
        ;;
    problem)
        echo -e "${BLUE}[INFO]${NC} Generating problem escalation template for ${GREEN}${ROLE}${NC}..."
        REPORT_CONTENT="${REPORT_TITLE}
上报时间：${REPORT_TIME}

问题描述：
- [填写问题描述]

尝试解决次数：[1/2/3次]

循环情况：
- 循环1：[角色] → [角色] [时间]
- 循环2：[角色] → [角色] [时间]
- 循环3：[角色] → [角色] [时间]

标记：[触发上报：循环3次/超时/无法解决]

需要支持：
- [上级介入]"
        ;;
    decision)
        echo -e "${BLUE}[INFO]${NC} Generating decision request template for ${GREEN}${ROLE}${NC}..."
        REPORT_CONTENT="${REPORT_TITLE}
申请时间：${REPORT_TIME}

决策内容：
- [填写决策内容]

决策原因：
- [填写决策原因]

影响范围：
- [填写影响范围]

建议方案：
- [方案1]
- [方案2]

请审批。"
        ;;
    *)
        echo -e "${BLUE}[INFO]${NC} Generating generic report template for ${GREEN}${ROLE}${NC}..."
        REPORT_CONTENT="${REPORT_TITLE}
汇报时间：${REPORT_TIME}

汇报内容：
- [填写汇报内容]"
        ;;
esac

# 保存到临时文件
REPORT_FILE="/tmp/${ROLE}-report-${REPORT_TYPE}.txt"
echo "$REPORT_CONTENT" > "$REPORT_FILE"

echo -e "${GREEN}[SUCCESS]${NC} Report template generated: ${GREEN}${REPORT_FILE}${NC}"
echo ""
echo "Content:"
echo ""
cat "$REPORT_FILE"
echo ""

# 询问是否发送
echo -e "${YELLOW}Do you want to send this report to Boss? (y/n)${NC}"
read -r response

if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
    echo -e "${BLUE}[INFO]${NC} Sending report to Boss..."

    # 发送到飞书
    openclaw message send \
        --channel feishu \
        --to ou_e7eea72f7d508227dbf42b50fc63f6f9 \
        --message "$REPORT_CONTENT"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS]${NC} Report sent to Boss"
    else
        echo -e "${RED}[ERROR]${NC} Failed to send report to Boss"
        exit 1
    fi
else
    echo -e "${YELLOW}[INFO]${NC} Report saved to ${REPORT_FILE}, not sent."
fi
