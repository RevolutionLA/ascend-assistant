# 性能调优建议（Perf Tuning）

基于现象/Profiling 输出给可操作方向。原则：**先从采集的数据看事实，再给方向；证据不足时明说"需进一步采集"。**

## 现象 → 建议方向

| 现象 | 建议方向 | 参考 |
|---|---|---|
| 单算子慢 | 换融合算子 / Ascend C 自研 / 核对并行策略 | [算子开发](/ops/) |
| 通信占比高 | 调张量/流水并行、减小通信频率、HCCL | [MindSpeed](/training/mindspeed) |
| 显存/HBM 不足 | 减 batch、重计算、优化器切分、KV cache 管理 | [性能与精度](/faq/perf-precision-issues) |
| 推理吞吐低 | 连续批处理、增大并发、批量、KV cache 调优 | [推理](/inference/) |
| 推理延迟高(decode) | 小 batch、低延迟模式、KV 策略 | [推理](/inference/) |
| 精度不对 | 先 fp32 对比、固定随机种子、精度调试工具 | [精度调试](/tools/precision-debug) |

## Profiling 采集与解读

1. 让用户用 **Profiling** 采集（见 [AscendMate Profiling](/tools/profiling)）。
2. 关注四个指标：
   - **算子耗时占比**（哪些算子是热点）
   - **通信占比**（HCCL 是否拖累）
   - **HBM 利用率**（内存是否吃紧）
   - **显存/内存占用**（是否 OOM 风险）
3. 基于数据给方向，不给未经数据的猜测。

## 分层确定性
- 事实层（哪个算子最慢、通信占比 X%）→ 断言语调。
- 方向层（"可能是通信拖累，建议 X"）→ 用"可能/建议"。
- 数据不足 → `insufficient_evidence`，建议补采 `with_stack` / `record_shapes`。

> 完整工具见 [AscendMate 工具链](/tools/)。深度 Profiling 异常分析可路由到官方 `ascend-profiling-anomaly` skill。
