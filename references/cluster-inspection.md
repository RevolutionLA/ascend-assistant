# 集群巡检参考

## 批量巡检流程

### 1. 准备服务器列表

创建 `servers.txt`，每行一个 IP：

```
192.168.1.101
192.168.1.102
192.168.1.103
```

### 2. 运行批量巡检

```bash
# 方式一：从文件读取服务器列表
bash scripts/cluster_inspection.sh servers.txt

# 方式二：直接指定 IP
bash scripts/cluster_inspection.sh 192.168.1.101 192.168.1.102
```

### 3. 查看巡检报告

巡检完成后，报告保存在 `inspection-report-YYYYMMDD-HHMMSS.md`。

## 巡检检查项

| 序号 | 检查项 | 命令 | 正常状态 |
|------|--------|------|----------|
| 1 | 设备识别 | `npu-smi info` | 所有 NPU 可见 |
| 2 | 设备健康 | `npu-smi info -t health` | Normal |
| 3 | 驱动版本 | `npu-smi info -t board` | 集群一致 |
| 4 | CANN 版本 | `cat /usr/local/Ascend/ascend-toolkit/latest/version.cfg` | 集群一致 |
| 5 | 温度状态 | `npu-smi info -t board` | < 85°C |
| 6 | 功耗状态 | `npu-smi info -t board` | 正常范围 |
| 7 | HCCS 链路 | `npu-smi info -t topo` | Link up |
| 8 | ECC 错误 | `npu-smi info -t ecc` | 无错误 |
| 9 | 框架可用 | `python -c "import torch_npu"` | 无报错 |
| 10 | 磁盘空间 | `df -h` | 使用率 < 80% |

## 巡检报告模板

```markdown
# 昇腾集群巡检报告

- 巡检时间：YYYY-MM-DD HH:MM:SS
- 巡检机器数：N 台
- 巡检结论：✅ 通过 / ❌ 不通过

## 汇总

| 机器 IP | NPU 数量 | 健康状态 | 驱动版本 | CANN 版本 | 异常项 |
|---------|---------|---------|---------|----------|--------|
| 192.168.1.101 | 8 | Normal | 25.1.0 | 8.3.RC2 | 无 |
| 192.168.1.102 | 8 | Normal | 25.1.0 | 8.3.RC2 | 无 |

## 异常详情

（如有异常项，逐条列出机器 IP、异常项、建议处理方式）

## 版本一致性

- 驱动版本：全部一致 / 不一致（列出差异）
- CANN 版本：全部一致 / 不一致（列出差异）

## 建议

（根据巡检结果给出维护建议）
```

## 常见巡检异常处理

| 异常 | 可能原因 | 处理方式 |
|------|---------|---------|
| NPU 不可见 | 驱动未加载/掉卡 | 检查 `lsmod \| grep npu`，必要时重启驱动 |
| Health 非 Normal | 硬件故障/温度过高 | 查看 `npu-smi info -t health` 详情 |
| 版本不一致 | 未统一升级 | 制定升级计划，统一版本 |
| HCCS Link down | 链路异常 | 检查物理连接，必要时重启 |
| ECC 错误 | 内存故障 | 记录并联系厂商更换 |
