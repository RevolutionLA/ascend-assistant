---
name: ascend-assistant
description: >
  昇腾服务器助手 —— 让 AI 直接帮你操作、查询、排障华为昇腾（Ascend/NPU）智算服务器。
  覆盖四类能力：环境检测与排障、命令生成与建议、部署脚本引导、性能调优建议。
  当用户遇到昇腾装机、驱动/CANN/框架报错、想生成安装/推理/调优命令、需要把昇腾服务器跑起来，
  或需要性能调优时使用。与 AscendMate（昇腾之家）手册深度联动。
keywords:
  - 昇腾
  - Ascend
  - NPU
  - npu-smi
  - CANN
  - torch_npu
  - MindSpore
  - 环境检测
  - 排障
  - 部署
  - 推理
  - 性能调优
  - Profiling
  - 智算服务器
  - Atlas
license: MIT
metadata:
  author: AscendLA
  version: "2.0.0"
  skill-type: orchestration
  allowed-tools: Bash(*) Python3(*) Read(*) Edit(*)
---

# Ascend Assistant · 昇腾服务器助手

让 AI Agent 帮助用户操作昇腾智算服务器的一套技能（Skill）。当用户对着一台昇腾服务器提问时，AI 依据本 Skill 安全、准确地帮你：检测环境、定位报错、生成命令、引导部署、给出调优建议。

**本 Skill 是"混合模式"**：
- **内建完成**四类通用能力（覆盖绝大多数日常提问）；
- 遇到**专项深度任务**（复杂 profiling 分析、驱动自动安装、算子代码生成等），**路由到昇腾官方 `agent-skills` 中的成熟 skill**，避免重复造轮子。

配套完整手册：**[AscendMate（昇腾之家）](https://github.com/RevolutionLA/AscendMate)** —— AscendMate 负责"为什么、完整怎么做"；本 Skill 负责"你手头这台机器、现在就帮我做"。

---

## 触发场景

用户意图匹配如下任一情况即触发：

- 查看昇腾服务器当前环境：设备/驱动/CANN/框架是否装好、可用性检查。
- 遇到报错：`npu-smi` 无输出、驱动装不上、CANN 环境变量报错、`torch_npu`/`MindSpore` 起不来、推理 OOM、训练失败等。
- 想生成/确认命令：安装命令、启动推理服务命令、微调脚本、性能采集命令等。
- 想从裸机一步步把昇腾服务器跑起来（部署引导）。
- 想对推理/训练做性能调优。

> 不触发：纯硬件采购选型、商务问题 → 引导到 [AscendMate 硬件选型](/hardware/)。

---

## 四类内建能力

### 能力一：环境检测与排障

**目标**：让用户知道服务器当前状态、问题出在哪。

**标准检测流程**（让用户按序粘贴输出，AI 逐项解读）：

```bash
npu-smi info                                  # 设备与驱动
lsmod | grep npu                              # 驱动内核模块
echo $ASCEND_HOME; cat /usr/local/Ascend/ascend-toolkit/latest/version.cfg
python -c "import torch; import torch_npu; print(torch.npu.device_count())"
python -c "import mindspore; mindspore.set_device('Ascend'); mindspore.run_check()"
uname -a; cat /etc/os-release
```

**分层确定性语言（本 Skill 硬性要求）**：
- **事实层**：设备有无、驱动版本、报错文本 —— 用断言语调。
- **归因层**：问题可能原因 —— 用 `可能 / probable`；证据不足 → `insufficient_evidence`，明说"需进一步验证"。
- 绝不用确定性语气描述未经证实的原因。

**排障映射**（报错 → 方向 → 手册章节）：见 [references/troubleshooting-map.md](references/troubleshooting-map.md)。

> 详细 FAQ 见 [AscendMate /faq/](/faq/)，自检清单见 [环境自检清单](/setup/checklist)。

### 能力二：命令生成与建议

**目标**：按用户真实目标给出可直接复制命令，并解释。

生成命令固定给三段：
1. **前置**：需已装什么/变量。
2. **命令**：含可替换占位符。
3. **验证 + 报错往哪查**。

常见命令库见 [references/command-reference.md](references/command-reference.md)。

### 能力三：部署脚本引导

**目标**：从裸机到可用分步引导，按用户回答逐步推进。

按 [AscendMate 7 步走](/guide/seven-steps) 的 `上电与规划 → 操作系统 → 固件驱动 → CANN → AI框架 → 业务接入 → 自检` 逐阶段推进。原则：一次只推进一步；每步让用户贴命令输出再进入下一步；选路（PyTorch vs MindSpore、在线 vs 离线）先问清。

完整工作流模板见 [references/deployment-workflow.md](references/deployment-workflow.md)。

### 能力四：性能调优建议

**目标**：基于 profiling 数据/现象给可操作方向。

- 引导用 **Profiling** 采集，关注：算子耗时占比、通信占比、HBM 利用率、显存。
- 现象 → 建议方向表见 [references/perf-tuning.md](references/perf-tuning.md)。
- 完整工具说明见 [AscendMate 性能调优](/tools/profiling)。

---

## 官方 skill 路由表（混合模式）

当用户请求命中以下**专项深度任务**时，应优先**调用/引导到昇腾官方 `agent-skills`**（<https://github.com/Ascend/agent-skills>）中的对应 skill，而非在本 Skill 内重复实现：

| 专项场景 | 官方 skill | 备注 |
|---|---|---|
| 复杂 profiling 异常分析 / 性能 bottle-neck 归因 | `ascend-profiling-anomaly` | 深度推理，带 references/rulebook + 脚本 |
| NPU/固件自动安装 | `ascend-npu-driver-install` | 端到端自动化 + 脚本 |
| 设备管理命令大全 | `npu-smi` | health/temp/power/memory/ECC/虚拟化/证书 |
| vLLM-Ascend 服务部署 | `vllm-ascend-deploy` | 推理部署专项 |
| Docker 跑昇腾容器 | `ascend-docker` | 容器环境 |
| AscendC / Triton 算子开发 | `ascendc-operator-*` / `triton-operator-*` | 算子全流程 |
| ATB 加速 / 算子迁移 | `ascend-transformer-boost` | index skill 编排子 skills |

**路由规则**：
1. 用户请求属于上表专项 → 明确告知用户"这属于官方 `Ascend/agent-skills` 的 `X` skill 能力"，并给出仓库路径与触发方式；若用户的环境已装该 skill，直接按该 skill 执行。
2. 其余通用请求（日常环境检测、基础排障、命令确认、整体部署引导、基础调优建议）→ 由本 Skill 内建能力完成，并联动 AscendMate。
3. 拿不准 × 通用性问题 → 先做环境检测（能力一），拿到事实后再决定是否路由。

---

## Reference files 使用

| 文件 | 何时读 |
|---|---|
| [references/troubleshooting-map.md](references/troubleshooting-map.md) | 排障（能力一）时，查报错映射 |
| [references/command-reference.md](references/command-reference.md) | 命令生成时，查常用命令库 |
| [references/deployment-workflow.md](references/deployment-workflow.md) | 部署引导时，查 7 段工作流模板 |
| [references/perf-tuning.md](references/perf-tuning.md) | 性能调优时，查现象→方向表 |

---

## 与 AscendMate 手册的联动

本 Skill 尽量少重复长文，具体教程/完整命令统一指向 AscendMate 对应章节：

| 能力 | 联动章节 |
|---|---|
| 环境检测 / 自检 | [环境自检清单](/setup/checklist) |
| 排障 | [/faq/ 问题定位](/faq/) |
| 命令生成 | [训练](/training/) · [推理](/inference/) |
| 部署引导 | [7 步走](/guide/seven-steps) |
| 性能调优 | [性能调优 Profiling](/tools/profiling) |

---

## 安全与免责

- 高风险操作（驱动升级、`dd`、清空、重装、固件）**必须先解释风险、给确认步骤，不默认执行**。
- 版本配套是前提；不确定的版本/字段标注"以官方发布为准"，不编造。
- 本 Skill 基于公开资料整理，命令以官方发布为准；操作风险由使用者自行确认与承担。
