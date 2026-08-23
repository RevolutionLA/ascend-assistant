# 常用命令参考（Command Reference）

按典型目标给可直接复制命令。**以官方发布为准确认版本配套**。

## 一、环境检测

```bash
npu-smi info                              # 设备 + 驱动 + 状态
npu-smi info -l                           # 列出设备
npu-smi info -t health -i 0               # 健康状态
npu-smi info -t memory -i 0 -c 0          # 内存
npu-smi info -m                           # 列出所有 chip
```

## 二、安装（固件驱动 → CANN → 框架）

```bash
# 驱动/固件（先查配套，run 包在昇腾下载站）
chmod +x Ascend-hdk-<版本>-<os>-<arch>.run
./Ascend-hdk-<版本>-<os>-<arch>.run --upgrade

# CANN Toolkit + Kernels
chmod +x Ascend-cann-toolkit_<版本>_linux-<arch>.run
./Ascend-cann-toolkit_<版本>_linux-<arch>.run --install

# 环境变量（每次使用前 source）
source /usr/local/Ascend/ascend-toolkit/set_env.sh
```

```bash
# PyTorch + torch_npu（严格配套）
conda create -n torch_npu python=3.10 -y && conda activate torch_npu
pip install torch==<与torch_npu配套的版本>
pip install torch_npu-<版本>-cp3xx-...-linux_<arch>.whl

# MindSpore
pip install mindspore==<版本> -i https://repo.mindspore.cn/pypi/simple --trusted-host repo.mindspore.cn
# 若之前装过 CANN 的 te/topi/hccl，先卸载
pip uninstall te topi hccl -y
```

## 三、验证框架可用

```bash
python -c "import torch; import torch_npu; print(torch.npu.device_count())"
python -c "import mindspore; mindspore.set_device('Ascend'); mindspore.run_check()"
```

## 四、推理部署（示例）

```bash
# vLLM-Ascend（版本配套以官方为准）
pip install vllm-ascend
vllm serve <模型路径> --trust-remote-code

# 验证 OpenAI 兼容服务
curl http://127.0.0.1:8000/v1/chat/completions -H "Content-Type: application/json" \
  -d '{"model":"<模型名>","messages":[{"role":"user","content":"你好"}]}'
```

> MindIE / SGLang 拉取见 [AscendMate 推理](/inference/)。

## 五、微调（LLaMA-Factory）

```bash
export ASCEND_RT_VISIBLE_DEVICES=0,1        # NPU 上指定卡片
llamafactory-cli train examples/train_lora/qwen3_lora_sft.yaml
# 合并 LoRA
llamafactory-cli export examples/merge_lora/qwen3_lora_sft.yaml
```

> 完整命令见 [AscendMate LLaMA-Factory](/training/llama-factory)。

## 六、性能采集（Profiling）

按 [AscendMate Profiling](/tools/profiling) 引导采集，关注算子耗时/通信占比/HBM 利用/显存。

## 配套确认
- 装机前先查 [兼容性查询](https://www.hiascend.com/hardware/compatibility)。
- 软件包下载：[昇腾下载中心](https://www.hiascend.com/developer/download)。
