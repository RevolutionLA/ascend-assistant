---
name: ascend-assistant
description: >
  昇腾服务器助手 —— 让 AI 直接帮你操作、查询、排障华为昇腾（Ascend/NPU）智算服务器。
  覆盖六类能力：环境检测与排障、命令生成与建议、部署脚本引导、性能调优建议、集群巡检与报告、算力利用率分析。
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
  version: "3.0.0"
  skill-type: orchestration
  allowed-tools: Bash(*) Python3(*) Read(*) Edit(*)
---

# Ascend Assistant · 昇腾服务器助手

让 AI Agent 帮助用户操作昇腾智算服务器的一套技能（Skill）。当用户对着一台昇腾服务器提问时，AI 依据本 Skill 安全、准确地帮你：检测环境、定位报错、生成命令、引导部署、给出调优建议。

**本 Skill 是"混合模式"**：
- **内建完成**六类通用能力（覆盖绝大多数日常提问）；
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
- 想批量检查多台服务器的健康状态（集群巡检）。
- 想了解算力利用率情况并获取优化建议（利用率分析）。

> 不触发：纯硬件采购选型、商务问题 → 引导到 [AscendMate 硬件选型](/hardware/)。

---

## 六类内建能力

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

**快速检测（推荐）**：若用户可在服务器上跑脚本，优先让 AI 提供并运行：

```bash
# 环境一键检测
bash <(curl -sL https://raw.githubusercontent.com/RevolutionLA/ascend-assistant/master/scripts/check_env.sh)
# 或上手后本地跑
bash scripts/check_env.sh

# 常见问题快速诊断
bash scripts/quick_troubleshoot.sh
```

> AI 助手应主动把脚本取到本地（或让用户 wget/curl 下载再 bash 运行），基于脚本输出做事实判读；脚本仅只读，无危险操作。见仓库 `scripts/`。

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

### 能力五：集群巡检与报告

**目标**：批量检查多台昇腾服务器，生成巡检报告。

**批量巡检流程**：
1. 用户提供服务器 IP 列表（或 SSH 配置）
2. AI 生成批量巡检脚本，通过 SSH 到每台机器运行只读检测
3. 收集结果并汇总为 Markdown 巡检报告

**巡检脚本使用**：

```bash
# 批量巡检（需提供服务器列表）
bash scripts/cluster_inspection.sh servers.txt
# 或手动指定
bash scripts/cluster_inspection.sh 192.168.1.101 192.168.1.102 192.168.1.103
```

**巡检报告解读要点**：
- **设备健康**：每台机器 NPU 数量、Health 状态（Normal/Warning/Critical）
- **版本一致性**：驱动版本、CANN 版本是否集群一致
- **异常项汇总**：温度过高、掉卡、ECC 错误、链路异常
- **巡检结论**：通过/不通过 + 不通过项的修复建议

> 巡检脚本仅只读，无危险操作。完整巡检 SOP 见 [AscendMate 巡检与应急 SOP](/monitoring/inspection)。

### 能力六：算力利用率分析

**目标**：采集 NPU 利用率数据，给出优化建议。

**利用率采集方法**：

```bash
# 方法一：npu-smi 定时采集（简单）
watch -n 5 'npu-smi info | grep -E "Chip|Utilization"'

# 方法二：通过 Prometheus 查询（推荐，需已部署监控）
# 查询近7天平均算力利用率
avg_over_time(npu_utilization_ratio[7d])
# 查询空闲时长占比
avg_over_time(npu_utilization_ratio{ratio<10}[7d])
```

**关键指标**：
- **算力利用率**：NPU 计算单元使用率，健康范围 40%-85%
- **显存利用率**：HBM 使用率，关注是否持续 100%（OOM 风险）
- **空闲时长**：利用率 <10% 的时间占比
- **碎片率**：单卡被小任务占满但未充分利用的比例

**利用率低常见原因与建议**：
- **任务排队空窗** → 建议引入作业调度系统（Slurm/KubeSphere）
- **批次太小** → 建议增大 batch size 或使用梯度累积
- **数据加载瓶颈** → 建议增加 DataLoader workers 或使用共享存储
- **闲置卡未分配** → 建议启用 vNPU 分片或资源池化

> 完整利用率优化方案见 [AscendMate 算力利用率监控与优化](/operations/utilization)，监控搭建见 [运维监控](/monitoring/)。

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
| AscendC 算子开发全流程 | `ascendc-operator-*` | code-gen / design / dev / performance-optim / precision-eval 等 |
| Triton 算子开发全流程 | `triton-operator-*` | code-gen / design / dev / env-config 等 |
| CATLASS 算子优化 | `catlass-operator-*` | 高性能模板 |
| ATB 加速 / 算子迁移 | `ascend-transformer-boost` | index skill 编排子 skills |
| 模型转换 | `atc-model-converter` | 模型转 OM |
| MindSpeed-LLM 大规模训练/迁移 | `mindspeed-*` / `megatron-*` | 训练加速与迁移 |
| CANN/算子环境配置 | `cann-operator-env-config` / `cann-nnal-installer` | 环境就绪 |
| 分布式/集合通信 | `hccl-test` | HCCL 验证 |
| Kubernetes 昇腾 | `k8s-check-fix` | 容器调度 |
| 模型/代码评审 | `npu-adapter-reviewer` / `security-code-review` / `skill-auditor` | 质量把关 |

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
| [references/cluster-inspection.md](references/cluster-inspection.md) | 集群巡检时，查批量检查流程与报告模板 |

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
| 集群巡检 | [巡检与应急 SOP](/monitoring/inspection) |
| 利用率分析 | [算力利用率监控与优化](/operations/utilization) |
| 监控告警 | [运维监控](/monitoring/) |

---

## 安全与免责

- 高风险操作（驱动升级、`dd`、清空、重装、固件）**必须先解释风险、给确认步骤，不默认执行**。
- 版本配套是前提；不确定的版本/字段标注"以官方发布为准"，不编造。
- 本 Skill 基于公开资料整理，命令以官方发布为准；操作风险由使用者自行确认与承担。
