# Ascend Assistant · 昇腾服务器助手

> v3.0.0

> 让 AI 助手直接帮你操作/查询/排障华为昇腾（Ascend/NPU）智算服务器的 **Agent Skill**。
> 与 [AscendMate（昇腾之家）](https://github.com/RevolutionLA/AscendMate) 深度配套：AscendMate 是完整手册，本 Skill 负责"遇到问题怎么一步步操作"。

## 这是什么

`ascend-assistant` 是一个 **Skill（系统提示词 / 操作指南）**，不是独立程序。把它装进你的 AI 编程/助手工具后，当你对着一台昇腾服务器提问，AI 会按照本 Skill 的规范，安全、准确地帮你：

| 能力 | 干什么用 |
|---|---|
| **环境检测 + 排障** | 检测设备/驱动/CANN/框架状态，定位并解释报错 |
| **命令生成与建议** | 生成安装、推理、微调等可直接复制的命令，并说明验证方法 |
| **部署脚本引导** | 从裸机到跑起，step-by-step 引导 |
| **性能调优建议** | 基于 Profiling 数据给调优方向 |
| **集群巡检与报告** | 批量检查多台服务器健康状态，生成巡检报告 |
| **算力利用率分析** | 采集NPU利用率数据，分析低效原因，给出优化建议 |

## 安装（3 种方式）

### 方式一：skill 命令（推荐，适用于支持 skills 的 Agent）
```bash
# 从 GitHub 仓库安装
skills add https://github.com/RevolutionLA/ascend-assistant
# 或
skills install RevolutionLA/ascend-assistant
```

### 方式二：clone 到你的 skills 目录
```bash
git clone https://github.com/RevolutionLA/ascend-assistant.git
# 然后把 ascend-assistant/SKILL.md 放入你的 Agent 的 skills 目录
# 例如 .agents/skills/ 或 .claude/skills/ascend-assistant/SKILL.md
```

### 方式三：手动复制
把本仓库根目录的 `SKILL.md` 放到你的技能/系统提示词目录即可（SKILL.md 已自包含触发条件、能力和操作规范）。

## 使用示例

给 AI 助手这些提示词即可触发能力：

- "检查这台昇腾服务器的环境是否正常" （→ 环境检测）
- "torch_npu 装不上，报 driver not initialized，帮我看看" （→ 排障）
- "在 openEuler + CANN 8.3.RC2 上给我安装 torch_npu 的命令" （→ 命令生成）
- "按 7 步带我把这台裸机昇腾服务器跑起来" （→ 部署引导）
- "推理吞吐低，帮我分析怎么调优" （→ 性能调优）
- "帮我批量检查这10台昇腾服务器的状态" （→ 集群巡检）
- "最近一周算力利用率怎么样，有没有优化建议" （→ 利用率分析）

## 端到端用例演示

### 用例 A：新到一台裸机，让它跑起推理

```
你：这是一台 Atlas 800I A3，8 卡，帮我从零装好并跑起 Qwen 推理。
AI：好的。先确认系统和目标：
   1) 你先跑 uname -a、npu-smi info 看当前状态（可能还没装驱动）
   2) 我们按 7 步走推进：OS → 固件驱动 → CANN → 框架 → 推理
   （逐步引导，每步给命令 + 验证，报错即回到排障）
```

### 用例 B：torch_npu 报错排障

```
你：python -c "import torch, torch_npu" 报 driver not initialized
AI：先确认事实（断言语调）：
   - 让我先看你的 npu-smi info 和驱动版本。
   （若设备未被识别 → 查驱动/内核匹配；若识别但框架报错 → 查 torch/torch_npu 配套）
   给一条命令验证，确凿后再给修复方向（用"可能"，不臆断）。
```

### 用例 C：性能太慢，要调优

```
你：推理吞吐很低，帮我看看。
AI：先用 Profiling 采集（引导命令），拿到四个指标：
   算子耗时 / 通信占比 / HBM 利用 / 显存。
   然后按现象给方向（用"可能/建议"）。
   （如果是复杂 profiling 异常 → 建议路由到官方 ascend-profiling-anomaly skill）
```

> 完整分步见 [references/deployment-workflow.md](references/deployment-workflow.md)、[references/perf-tuning.md](references/perf-tuning.md)。

### 实战：先用脚本跑一步（推荐）

配合仓库里的 `scripts/`，让 AI 先让用户快速拿到"事实"：

```
你：帮我看看这台昇腾服务器正常不。
AI：请先在服务器上跑这条只读检测脚本（不装不改）：
   bash scripts/check_env.sh      # 或 curl 下载后运行
然后把输出贴给我，我逐项解读设备/驱动/CANN/框架状态。
```

遇到报错可直接跑快速诊断：
```bash
bash scripts/quick_troubleshoot.sh    # ✗ 项即问题点 + 指向手册章节
```

> 脚本只读、无危险操作。见 [scripts/](scripts/)。

## 混合模式：何时用官方 agent-skills

本 Skill 采用混合模式：

- **通用请求**：由本 Skill 内建完成（环境检测/基础排障/命令确认/整体部署引导/基础调优）。
- **专项请求**：自动路由到昇腾官方 [Ascend/agent-skills](https://github.com/Ascend/agent-skills) 里更成熟的专项 skill，例如：
  - 复杂 Profiling 异常分析 → `ascend-profiling-anomaly`
  - NPU/固件自动安装 → `ascend-npu-driver-install`
  - 设备管理命令大全 → `npu-smi`
  - vLLM-Ascend 部署 → `vllm-ascend-deploy`
  - 算子开发 → `ascendc-operator-*` / `triton-operator-*`

> 路由规则见 [SKILL.md](SKILL.md) 的「官方 skill 路由表」。这样既吸收官方成熟能力，又避免重复造轮子。

## 🔗 与 AscendMate 联动

本 Skill 的新增能力与 AscendMate（昇腾之家）文档站深度联动：

| 能力 | 联动文档 |
|---|---|
| 集群巡检 | → AscendMate [/monitoring/inspection](https://revolutionla.github.io/AscendMate/monitoring/inspection) |
| 利用率分析 | → AscendMate [/operations/utilization](https://revolutionla.github.io/AscendMate/operations/utilization) |

> Skill 负责"怎么一步步操作"，AscendMate 提供"背景知识 / SOP / 配置模板 / 最佳实践"。

## 能力详解 & 配套手册

完整能力说明见 [SKILL.md](SKILL.md)（含 `references/` 参考文件：报错映射/命令库/部署工作流/调优方向）。
详细教程与 FAQ 见 **AscendMate（昇腾之家）**：
- 环境搭建 / 7 步走：<https://github.com/RevolutionLA/AscendMate>
- 在线文档站：<https://revolutionla.github.io/AscendMate/>

## 相关链接

- AscendMate 首页：<https://github.com/RevolutionLA/AscendMate>
- 昇腾文档中心：<https://www.hiascend.com/document>
- 昇腾软件下载：<https://www.hiascend.com/developer/download>

## 同作者的其他项目

- **[adversarial-review](https://github.com/RevolutionLA/adversarial-review)** —— 三方对抗式代码评审 Agent Skill。蓝军（敌意审查）→ 第三方（独立审计）→ 中立裁定。**写 skill、发版前把关时特别有用。**

## 许可

[MIT](LICENSE)。本 Skill 基于公开资料整理，命令与版本以官方发布为准；高风险操作请谨慎并自行担责。
