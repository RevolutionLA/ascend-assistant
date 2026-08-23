#!/usr/bin/env bash
# =============================================================================
# check_env.sh —— 昇腾服务器环境一键检测
# 输出设备/驱动/CANN/框架/系统的关键状态，供人工或 AI 助手快速定位。
# 用法: bash check_env.sh
# 仅做只读检测，无任何修改；部分项需要 root 才能看到完整信息。
# =============================================================================
set -u

echo "===== 1. 系统 ====="
echo "OS:    $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"
echo "Kernel: $(uname -r 2>/dev/null)"
echo "Arch:  $(uname -m 2>/dev/null)"

echo
echo "===== 2. NPU 设备与驱动 ====="
if command -v npu-smi >/dev/null 2>&1; then
  echo "npu-smi 存在:"
  npu-smi info 2>&1 | head -n 20
  echo "---- 设备数 ----"
  npu-smi info -l 2>&1 | grep -iE 'device|npu' | head -n 5 || true
else
  echo "[WARN] 未找到 npu-smi（驱动可能未安装，或 PATH 未配置）"
fi

echo
echo "===== 3. 驱动内核模块 ====="
modprobe_cmd=$(lsmod 2>/dev/null | grep -iE 'npu|cann' || echo "  (未发现 npu/cann 模块)")
echo "$modprobe_cmd"

echo
echo "===== 4. CANN ====="
for p in /usr/local/Ascend/ascend-toolkit/latest/version.cfg \
         /usr/local/Ascend/ascend-toolkit/set_env.sh; do
  [ -e "$p" ] && echo "  found: $p"
done
echo "ASCEND_HOME=${ASCEND_HOME:-<未设置>}"
cat /usr/local/Ascend/ascend-toolkit/latest/version.cfg 2>/dev/null | head -n 3 || echo "  (未找到 version.cfg)"

echo
echo "===== 5. 框架可用性 ====="
if python3 -c "import torch" 2>/dev/null; then
  echo "torch:   $(python3 -c "import torch;print(torch.__version__)" 2>/dev/null)"
  if python3 -c "import torch_npu" 2>/dev/null; then
    echo "torch_npu: $(python3 -c "import torch_npu;print(torch.npu.device_count(),'devices')" 2>&1)"
  else
    echo "[WARN] torch 已装但 torch_npu 未装或不可 import"
  fi
else
  echo "  (torch 未装或多解释器问题)"
fi
if python3 -c "import mindspore" 2>/dev/null; then
  echo "mindspore: $(python3 -c "import mindspore;print(mindspore.__version__)" 2>/dev/null)"
else
  echo "  (mindspore 未装)"
fi

echo
echo "===== 6. 磁盘/内存（简要）====="
echo "Memory: $(free -h 2>/dev/null | awk '/Mem/{print $2}')"
echo "Disk:   $(df -h / 2>/dev/null | awk 'NR==2{print $4}')"

echo
echo "===== 提示 ====="
echo "本脚本输出仅供检测。若报错，请把关键输出贴给 AI 助手或查 AscendMate /faq/。"
