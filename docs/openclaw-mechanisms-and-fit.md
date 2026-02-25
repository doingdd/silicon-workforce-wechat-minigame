# OpenClaw 机制分析与契合方案

> 分析 OpenClaw 现有机制，设计硅基团队的完美契合方案

---

## OpenClaw 核心机制

### 1. Session 机制

**命令：** `openclaw sessions`

**功能：**
- 列出所有会话
- 支持 `--active <minutes>` 过滤最近活跃的会话
- 支持 `--json` 输出 JSON 格式
- 支持多 agent 存储（`--agent <id>` 或 `--all-agents`）

**维护：**
```bash
openclaw sessions cleanup --dry-run  # 预览清理
openclaw sessions cleanup --enforce   # 执行清理
```

**配置：**
- `session.maintenance.mode`: 维护模式（warn/auto）
- `session.maintenance.maxDays`: 最大保留天数
- `session.maintenance.maxBytes`: 最大字节数

---

### 2. Sub-Agent 机制

**命令：** `openclaw subagents`

**功能：**
- `list`: 列出所有 sub-agents
- `steer`: 向 sub-agent 发送消息（引导）
- `kill`: 杀死 sub-agent

**配置限制：**
```json
{
  "agents": {
    "defaults": {
      "subagents": {
        "maxConcurrent": 8  // 最大并发 sub-agent 数量
      }
    }
  }
}
```

**关键洞察：**
- **最大并发 8 个 sub-agents**：这是硬性限制
- 我们的团队是 10 个角色，**需要优化设计**

---

### 3. Agent 机制

**命令：** `openclaw agents`

**功能：**
- `add`: 添加新 agent
- `delete`: 删除 agent
- `list`: 列出 agents
- `set-identity`: 更新 agent 身份

**配置：**
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "zai/glm-4.7",  // 默认模型
        "fallbacks": ["zai/glm-5"]
      },
      "maxConcurrent": 4,  // 最大并发 agent 数量
      "workspace": "/Users/doing/.openclaw/workspace",
      "heartbeat": {
        "every": "30m"  // 心跳频率
      }
    }
  }
}
```

**关键洞察：**
- **最大并发 4 个 agents**：这是硬性限制
- 心跳频率：30 分钟一次
- 默认模型：`zai/glm-4.7`

---

### 4. Cron 机制

**命令：** `openclaw cron`

**功能：**
- 添加、编辑、删除、列出定时任务
- 支持表达式（cron 表达式）
- 支持时区设置

**配置维护：**
- `cron.runLog.maxBytes`: 日志最大字节数
- `cron.runLog.keepLines`: 保留行数

---

### 5. Message 机制

**命令：** `openclaw message`

**功能：**
- 发送消息到各个 channel
- 支持 feishu, whatsapp, telegram 等
- 支持回复、引用等

---

### 6. Skills 机制

**命令：** `openclaw skills`

**功能：**
- 列出已安装 skills
- 管理 skills

---

## 限制与挑战

### 限制 1：最大并发 Sub-Agents = 8

**问题：** 我们的团队有 10 个角色，超过最大并发数

**解决方案：**

#### 方案 A：分组启动（推荐）

将 10 个角色分为 2 组，每组不超过 4 个：

**Group 1（启动优先）：**
- CEO
- Game Lead
- Growth Lead
- Data Lead

**Group 2（按需启动）：**
- Game Dev
- Game QA
- Content
- Social
- SEO
- Analyst
- Monetizer

**优点：**
- 不超过并发限制
- Leads 一直运行，Executors 按需启动
- 节省 token 消耗

---

#### 方案 B：Agent Workspaces

使用 `openclaw agents add` 为每个角色创建独立的 agent workspace：

```bash
openclaw agents add --id ceo --name "CEO" --emoji "👔"
openclaw agents add --id game-lead --name "Game Lead" --emoji "🎮"
openclaw agents add --id growth-lead --name "Growth Lead" --emoji "📈"
openclaw agents add --id data-lead --name "Data Lead" --emoji "📊"
# ...
```

**优点：**
- 每个 role 有独立的 session 存储
- 可以独立管理每个 role
- 更好的隔离性

---

### 限制 2：最大并发 Agents = 4

**问题：** 如果使用 Agent Workspaces 方案，最大只能同时运行 4 个 agents

**解决方案：**

使用 `subagents` 机制，而不是独立的 agents：

- 使用 `sessions_spawn` 创建 sub-agents
- sub-agents 的限制是 8 个（不是 4 个）
- 可以同时运行更多 sub-agents

---

## 完美契合方案

### 核心设计原则

1. **使用 Sub-Agents**：不使用独立的 agents，使用 sub-agents
2. **分组启动**：将 10 个角色分为 2 组，不超过并发限制
3. **按需启动**：Leads 一直运行，Executors 按需启动
4. **定期清理**：使用 `sessions cleanup` 清理过期会话

---

### 推荐架构

```
[Boss] ← 人类
    ↓
[CEO] - Sub-Agent 1 (一直运行）
    ↓
┌──────────────────┬──────────────────┬──────────────────┐
│  [Game Lead]     │  [Growth Lead]   │  [Data Lead]     │
│  Sub-Agent 2     │  Sub-Agent 3     │  Sub-Agent 4     │
│  (一直运行）      │  (一直运行）      │  (一直运行）      │
└────┬─────────────┴────┬─────────────┴────┬────────────┘
     │                   │                   │
     ↓                   ↓                   ↓
  [Game Team]      [Growth Team]     [Data Team]
  (按需启动）        (按需启动）        (按需启动）

执行层（按需启动）：
- Game Dev, Game QA: 需要 Game Lead 指令时启动
- Content, Social, SEO: 需要 Growth Lead 指令时启动
- Analyst, Monetizer: 需要 Data Lead 指令时启动
```

---

### 启动策略

#### Phase 1: 启动核心层（4 个 Sub-Agents）

```bash
# 启动 CEO
openclaw sessions_spawn \
  --task "$(cat agents/leads/ceo-persona.md)" \
  --label "ceo" \
  --mode session \
  --model "zai/glm-4.7"

# 启动 Game Lead
openclaw sessions_spawn \
  --task "$(cat agents/leads/game-lead-persona.md)" \
  --label "game-lead" \
  --mode session \
  --model "zai/glm-4.7"

# 启动 Growth Lead
openclaw sessions_spawn \
  --task "$(cat agents/leads/growth-lead-persona.md)" \
  --label "growth-lead" \
  --mode session \
  --model "zai/glm-4.7"

# 启动 Data Lead
openclaw sessions_spawn \
  --task "$(cat agents/leads/data-lead-persona.md)" \
  --label "data-lead" \
  --mode session \
  --model "zai/glm-4.7"
```

**当前并发：** 4 个 sub-agents（< 8，符合限制）

---

#### Phase 2: 按需启动执行层

当需要执行具体任务时，临时启动 Executors：

```bash
# 需要开发游戏时，启动 Game Dev
openclaw sessions_spawn \
  --task "$(cat agents/game-team/game-dev-persona.md)" \
  --label "game-dev" \
  --mode run \
  --model "zai/glm-4.7"

# 任务完成后，自动停止（mode run 是一次性运行）
```

**优点：**
- 不超过并发限制
- 节省 token 消耗
- Executors 只在需要时运行

---

### 通信机制

#### 1. 使用 `sessions_send` 进行角色间通信

```bash
# CEO 发送指令给 Game Lead
openclaw sessions_send \
  --label "game-lead" \
  --message "开始开发游戏A，优先级：高"

# Game Lead 发送任务给 Game Dev
openclaw sessions_send \
  --label "game-dev" \
  --message "开发游戏A的核心功能，参考需求文档"

# Game Dev 汇报给 Game Lead
openclaw sessions_send \
  --label "game-lead" \
  --message "游戏A核心功能已完成，通过测试"
```

---

#### 2. 使用 `cron` 进行定时汇报

```bash
# 添加每日早晚两次的汇报提醒
openclaw cron add \
  --name "早间汇报提醒" \
  --cron "0 9 * * *" \
  --tz "Asia/Shanghai" \
  --message "提醒 CEO 发送早间汇报"

openclaw cron add \
  --name "晚间汇报提醒" \
  --cron "0 18 * * *" \
  --tz "Asia/Shanghai" \
  --message "提醒 CEO 发送晚间汇报"
```

---

#### 3. 使用 `message` 向 Boss 汇报

```bash
# CEO 向 Boss 汇报
openclaw message send \
  --channel feishu \
  --to ou_e7eea72f7d508227dbf42b50fc63f6f9 \
  --message "[CEO早间汇报]

整体进度：正常
游戏开发：游戏A开发中（80%）
增长运营：小红书粉丝+200
数据分析：游戏A收益+500RMB

今日计划：
- 完成游戏A开发
- 发布游戏A宣传内容
- 分析游戏A数据"
```

---

#### 4. 使用 `subagents steer` 进行引导

```bash
# 引导 Game Lead 决策
openclaw subagents steer \
  --target "game-lead" \
  --message "请决定今天开发哪个游戏：游戏A还是游戏B？请给出决策理由。"
```

---

### 维护机制

#### 1. 定期清理过期会话

```bash
# 每天清理一次过期会话
openclaw sessions cleanup --dry-run  # 预览
openclaw sessions cleanup --enforce   # 执行
```

---

#### 2. 监控活跃会话

```bash
# 查看最近活跃的会话（120分钟内）
openclaw sessions --active 120
```

---

#### 3. 查看所有 sub-agents

```bash
# 列出所有 sub-agents
openclaw subagents list
```

---

## 完整实施计划

### Step 1: 创建核心层 Sub-Agents（4 个）

- CEO
- Game Lead
- Growth Lead
- Data Lead

**启动脚本：** `scripts/start-core-team.sh`

```bash
#!/bin/bash
openclaw sessions_spawn --task "$(cat agents/leads/ceo-persona.md)" --label "ceo" --mode session --model "zai/glm-4.7"
openclaw sessions_spawn --task "$(cat agents/leads/game-lead-persona.md)" --label "game-lead" --mode session --model "zai/glm-4.7"
openclaw sessions_spawn --task "$(cat agents/leads/growth-lead-persona.md)" --label "growth-lead" --mode session --model "zai/glm-4.7"
openclaw sessions_spawn --task "$(cat agents/leads/data-lead-persona.md)" --label "data-lead" --mode session --model "zai/glm-4.7"
```

---

### Step 2: 创建执行层 Sub-Agents（7 个）

- Game Dev, Game QA
- Content, Social, SEO
- Analyst, Monetizer

**Persona 文件：** `agents/game-team/*`, `agents/growth-team/*`, `agents/data-team/*`

---

### Step 3: 创建通信脚本

**发送任务：** `scripts/send-task.sh`

```bash
#!/bin/bash
openclaw sessions_send --label "$1" --message "$2"
```

**使用：**
```bash
./scripts/send-task.sh game-lead "开始开发游戏A"
```

---

### Step 4: 创建汇报脚本

**汇报模板：** `scripts/report-status.sh`

```bash
#!/bin/bash
# 生成汇报并发送给 Boss
openclaw message send --channel feishu --to ou_e7eea72f7d508227dbf42b50fc63f6f9 --message "$(cat report-template.md)"
```

---

### Step 5: 创建兜底机制脚本

**问题上报：** `scripts/escalate-problem.sh`

```bash
#!/bin/bash
# 向上级上报问题
openclaw sessions_send --label "$1" --message "[问题上报]
问题描述：$2
循环次数：$3
需要上级介入"
```

---

## 关键优势

### 1. 不超过并发限制

- 核心层：4 个 sub-agents（< 8）
- 执行层：按需启动，任务完成自动停止

### 2. 节省 Token 消耗

- Leads 一直运行（24/7 监控）
- Executors 按需启动（只在需要时消耗 token）

### 3. 灵活性高

- 可以随时启动新的 Executors
- 可以随时停止不需要的 Executors
- 可以动态调整资源分配

### 4. 维护简单

- 使用 `sessions cleanup` 清理过期会话
- 使用 `subagents list` 查看所有 sub-agents
- 使用 `cron` 自动化定时任务

---

## 下一步

1. ✅ 修改 `start-team.sh`，改为启动 4 个核心层 sub-agents
2. ⏳ 创建执行层 Persona 文件
3. ⏳ 创建通信脚本
4. ⏳ 创建汇报脚本
5. ⏳ 创建兜底机制脚本
6. ⏳ 测试完整流程

---

*文档生成时间：2026-02-25*
*分析 OpenClaw 现有机制，设计完美契合方案*
