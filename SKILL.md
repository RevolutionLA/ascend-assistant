---
name: ascend-assistant
description: 昇腾服务器助手 —— 帮助用户在本地用 AI 直接操作、查询、排障华为昇腾（Ascend/NPU）智算服务器。覆盖环境检测与排障、命令生成与建议、部署脚本引导、性能调优建议四类能力。当用户遇到昇腾装机、驱动/CANN/框架报错、想生成安装/推理/调优命令，或需要把昇腾服务器跑起来时使用。与其配套的完整手册是 AscendMate（昇腾之家）。
license: MIT
---

# Ascend Assistant · 昇腾服务器助手

让 AI Agent 帮助用户操作昇腾智算服务器的一套技能（Skill）。它不是一个独立的程序，而是**给 AI 助手的操作指南**：当用户对着一台昇腾服务器提问时，触发本 Skill 后，AI 能安全、准确地帮你检测环境、定位报错、生成命令、引导部署、给出调优建议。

本 Skill 与 **[AscendMate（昇腾之家）](https://github.com/RevolutionLA/AscendMate)** 深度配套：AscendMate 是完整手册（环境搭建/训练/推理/算子/工具链/FAQ），本 Skill 负责"遇到具体问题时怎么一步步操作"，两者互相引用。

---

## 触发场景

当用户的**意图**匹配下面任一情况时，应主动激活本 Skill：

- 想查看昇腾服务器当前环境：设备/驱动/CANN/框架是否装好、可用性检查。
- 遇到报错：`npu-smi` 无输出、驱动装不上、CANN 环境变量报错、`torch_npu`/`MindSpore` 起不来、推理 OOM、训练失败等。
- 想生成/确认命令：安装命令、启动推理服务命令、微调脚本、性能采集命令等。
- 想从裸机一步步把昇腾服务器跑起来（部署引导）。
- 想对推理/训练做性能调优。

> 何时不触发：纯硬件采购选型、商务问题，应引导到 [AscendMate 硬件选型](/hardware/)。

---

## 核心原则

1. **先检测，再建议**：先让用户跑关键命令（如 `npu-smi info`）拿到真实状态，基于输出定位，不凭空猜。
2. **安全第一**：涉及 `dd`、驱动升级、清空、重装等高风险操作，一律先解释风险、给确认步骤，不默认执行。
3. **版本配套是前提**：昇腾最大的坑是版本不配套（驱动/CANN/框架/OS 互相匹配）。任何方案先确认配套表。
4. **给可照做的命令**：给出命令的同时给"怎么验证成功"和"失败往哪查"。
5. **诚实**：不确定的版本/命令标注"以官方发布为准"，不编造参数字段。
6. **联动手册**：具体步骤/完整教程指向 AscendMate 对应章节，避免本 Skill 重复长文。

---

## 四类能力

### 能力一：环境检测与排障

**目标**：让用户知道服务器现在是什么状态、问题出在哪。

**标准检测流程**（让用户按序粘贴输出，AI 逐项解读）：

```bash
# 1. 设备与驱动
npu-smi info                          # 是否列出设备、Driver 版本、NPU 健康状态
# 2. 驱动内核模块
lsmod | grep npu
# 3. CANN 环境
echo $ASCEND_HOME; cat /usr/local/Ascend/ascend-toolkit/latest/version.cfg
# 4. 框架可用性
python -c "import torch; import torch_npu; print(torch.npu.device_count())"
python -c "import mindspore; mindspore.set_device('Ascend'); mindspore.run_check()"
# 5. 系统
uname -a; cat /etc/os-release
```

**排障映射**（报错 → 常见方向）：

| 现象/报错 | 优先排查 | AscendMate 章节 |
|---|---|---|
| `npu-smi: command not found` / 无设备 | 驱动是否装、内核模块是否加载、是否 root | [固件驱动](/setup/firmware-driver) |
| `driver not initialized` | 版本配套、驱动 vs 内核 | [环境搭建类问题](/faq/setup-issues) |
| `source ...set_env.sh` 路径错 | `ascend-toolkit` vs `ascend_toolkit` 拼写/路径 | [CANN 安装](/setup/cann-install) |
| `import torch_npu` 失败 | torch 与 torch_npu 版本配套 | [torch_npu 安装](/setup/torch-npu-install) |
| 推理 OOM / 起不来 | batch/seq/KV 显存策略 | [推理类问题](/faq/inference-issues) |
| 训练 loss NaN / 精度不对 | 混合精度、随机种子 | [性能与精度问题](/faq/perf-precision-issues) |

> 详细 FAQ 与自检清单见 [AscendMate 问题定位 /faq/](/faq/) 与 [环境自检清单](/setup/checklist)。

### 能力二：命令生成与建议

**目标**：根据用户真实目标，给出可直接复制的命令，并解释。

- **安装类**：根据操作系统/架构/CANN 版本，生成固件驱动、CANN Toolkit/Kernels、torch_npu、MindSpore 的安装命令与脚本。
- **推理类**：生成 MindIE / vLLM-Ascend / SGLang 拉起推理服务的命令。
- **微调类**：生成 LLaMA-Factory 的微调命令（LoRA/QLoRA/全参、单机/多机）。
- **运行类**：转译用户想法为可执行 shell/python。

生成命令时固定给出三段：
1. 前置（需已装什么 / 变量）
2. 命令本身（含可替换占位符）
3. 验证（如何确认成功）+ 报错往哪查

**示例**（装 torch_npu 前的配套确认）：

```bash
# 先确认 CANN 版本
cat /usr/local/Ascend/ascend-toolkit/latest/version.cfg
# 再对照官方 torch_npu 配套表选对应 torch 版本（以官方发布为准）
```

> 完整命令参考见 [AscendMate](/training/llama-factory)、[推理](/inference/)。

### 能力三：部署脚本引导

**目标**：从裸机到可用的分步引导，让 AI 按用户回答逐步推进。

按 **[AscendMate 7 步走](/guide/seven-steps)** 逐阶段引导，每步先询问、再给命令、再验证：

```
上电与规划 → 操作系统 → 固件驱动 → CANN → AI框架 → 业务接入 → 自检
```

引导原则：一次只推进一步；每步结束让用户贴关键命令输出再进入下一步；遇到岔路（选 PyTorch 还是 MindSpore、在线还是离线）先问清。

### 能力四：性能调优建议

**目标**：基于 profiling 数据/现象给出可操作建议。

- 引导用户用 **Profiling** 采集（见 [AscendMate 性能调优](/tools/profiling)），关注：算子耗时占比、通信占比、HBM 利用率、显存。
- 按现象给方向：

| 现象 | 建议方向 |
|---|---|
| 单算子慢 | 换融合算子、Ascend C 自研、核对并行策略 |
| 通信占比高 | 调张量/流水并行、减小通信、HCCL |
| HBM/显存不足 | 减 batch、重计算、优化器切分、KV 策略 |
| 推理吞吐低 | 连续批处理、增大并发、KV cache 调优 |
| 精度不对 | 先 fp32 对比、固定随机种子、精度调试工具 |

> 详见 [AscendMate 性能与精度问题](/faq/perf-precision-issues)。

---

## 参考文件

本 Skill 用到的昇腾资料索引（避免重复大段搬运，统一指向权威源）：

- **AscendMate（昇腾之家）**：一站式中文章节手册 → <https://github.com/RevolutionLA/AscendMate>
- 昇腾文档中心：<https://www.hiascend.com/document>
- 昇腾软件/驱动/CANN 下载：<https://www.hiascend.com/developer/download>
- 兼容性查询：<https://www.hiascend.com/hardware/compatibility>

## 许可 & 免责

MIT。本 Skill 基于公开资料整理，命令与版本以官方发布为准。高风险操作请谨慎并自行担责。
