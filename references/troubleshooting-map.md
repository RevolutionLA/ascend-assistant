# 报错映射表（Troubleshooting Map）

昇腾环境搭建/使用中最常见的报错与排查方向。**事实由用户命令输出确认，归因用"可能"。**

## 一、设备 / 驱动

| 现象 / 报错 | 优先排查 | 归因 | AscendMate |
|---|---|---|---|
| `npu-smi: command not found` | 驱动是否安装、PATH | 驱动未装或未 source 环境 | [固件驱动](/setup/firmware-driver) |
| `npu-smi info` 列出为空/无设备 | `lsmod | grep npu`、是否 root、PCIe 枚举 | 驱动内核模块未加载 / 板卡未识别 | [环境搭建类](/faq/setup-issues) |
| `driver not initialized` | 驱动 vs 内核版本、是否重启 | 版本不配套 / 驱动未生效（需重启） | [固件驱动](/setup/firmware-driver) |

## 二、CANN

| 现象 / 报错 | 优先排查 | 归因 | AscendMate |
|---|---|---|---|
| `source ...set_env.sh` 找不到 | 路径拼写 `ascend-toolkit` vs `ascend_toolkit` | 路径/版本安装位置不同 | [CANN 安装](/setup/cann-install) |
| `ASCEND_HOME` 为空 | `cat .../version.cfg` 是否存在 | 未 source / CANN 未装全 | [CANN 安装](/setup/cann-install) |
| 框架找不到 CANN 库 | `ldd`、环境变量 | source 顺序 / 版本不配套 | [环境搭建类](/faq/setup-issues) |

## 三、框架（torch_npu / MindSpore）

| 现象 / 报错 | 优先排查 | 归因 | AscendMate |
|---|---|---|---|
| `import torch_npu` 失败 | torch 与 torch_npu 版本配套 | 版本不配套 | [torch_npu 安装](/setup/torch-npu-install) |
| `torch.npu.device_count()` 为 0 | `npu-smi` 是否识别、环境变量 | 驱动/CANN 未就绪 | [环境自检](/setup/checklist) |
| `mindspore.run_check()` 报错 | CANN 配套、Python 版本 | 版本不配套 | [MindSpore 安装](/setup/mindspore-install) |

## 四、推理

| 现象 / 报错 | 优先排查 | 归因 | AscendMate |
|---|---|---|---|
| 推理服务起不来 / 加载失败 | 模型路径、权重格式、显存 | 权重/显存/引擎版本 | [推理全景](/inference/) |
| OOM / 请求失败 | batch/seq/KV 显存策略 | 显存超限 | [推理类问题](/faq/inference-issues) |
| 吞吐低 / 延迟高 | Profiling 看 prefill/decode | 并发/KV/调度 | [性能调优](/tools/profiling) |

## 五、训练

| 现象 | 优先排查 | 归因 | AscendMate |
|---|---|---|---|
| loss = NaN / 不收敛 | 混合精度、随机种子、lr | 精度/收敛设置 | [性能与精度](/faq/perf-precision-issues) |
| OOM | batch/重计算/优化器切分 | 显存策略 | [训练类问题](/faq/training-issues) |
| 多卡通信报错 | HCCL、拓扑 | 并行/通信配置 | [MindSpeed](/training/mindspeed) |

## 通用排查顺序
1. 版本配套（驱动/CANN/框架/OS）—— 最高频根因。
2. `npu-smi info` 是否识别设备。
3. 是否 `source` 环境变量。
4. 日志：`dmesg | grep -i npu`、`/var/log/npu/`。
5. 最小复现缩小范围。

> 详细见 [AscendMate 问题定位 FAQ](/faq/)。
