# 部署工作流模板（Deployment Workflow）

从裸机到跑起昇腾服务器的分步引导模板。**一次只推进一步**，每步让用户贴关键输出再进入下一步。

## 7 段流程

```
[0] 上电与规划 → [1] 操作系统 → [2] 固件驱动 → [3] CANN → [4] AI框架 → [5] 业务接入 → [6] 自检
```

### 阶段 0：上电与规划
- 确认机型（A2/A3、服务器/板卡）、NPU 数量、OS 与 CANN 框架配套规划。
- 产出：一张"版本配套表"（OS / 驱动 / CANN / 框架 / Python）。

### 阶段 1：操作系统
- 装受支持 OS（如 openEuler 24.03 LTS），验证 `uname -m`、网络、基本工具。
- 引导：让用户跑 `uname -m; lscpu; free -h`。

### 阶段 2：固件驱动
- 下载配套 run 包，安装，`npu-smi info` 验证识别设备。
- 引导：装完必须确认 `npu-smi info` 能列出设备；否则回到排障。

### 阶段 3：CANN
- 装 Toolkit + Kernels，source 环境变量，`version.cfg` 验证。

### 阶段 4：AI 框架
- 问清选 PyTorch + torch_npu 还是 MindSpore，再装对应框架并验证 import。

### 阶段 5：业务接入
- 跑通一个小验证；按意图进入推理或训练。

### 阶段 6：自检
- 用 [AscendMate 环境自检清单](/setup/checklist) 逐项验收。

## 引导要点
- **选路闸口**：阶段 4 前必须问清"PyTorch 还是 MindSpore"、"在线还是离线（内网）"。
- **失败兜底**：任一步报错 → 回到"能力一环境检测"，收集 `npu-smi`/日志再继续，不硬闯。
- **Docker 离线**：内网场景引导优先用官方镜像（见 [AscendMate Docker 离线](/setup/docker-offline)）。

> 完整步骤见 [AscendMate 7 步走](/guide/seven-steps)。
