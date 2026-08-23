#!/usr/bin/env bash
# =============================================================================
# quick_troubleshoot.sh —— 昇腾常见问题快速诊断
# 依次检查最可能出问题的几个点并给出提示，用于报错时的第一步定位。
# 用法: bash quick_troubleshoot.sh
# 纯只读诊断，不改任何配置。
# =============================================================================
set -u

echo "===== 快速诊断（请逐行查看 ✗ 项）====="

# 1. npu-smi 是否可用
if command -v npu-smi >/dev/null 2>&1; then
  echo "  [OK] 找到 npu-smi"
  if ! npu-smi info >/dev/null 2>&1; then
    echo "  [✗] npu-smi info 报错 → 驱动未生效/卡未被识别。查: 驱动是否装、是否重启、lsmod | grep npu"
  else
    echo "  [OK] npu-smi info 正常"
  fi
else
  echo "  [✗] 找不到 npu-smi → 驱动可能未安装，或未 source 环境/PATH。查 AscendMate /setup/firmware-driver"
fi

# 2. 驱动内核模块
if lsmod 2>/dev/null | grep -qi 'npu'; then
  echo "  [OK] npu 内核模块已加载"
else
  echo "  [✗] 未检测到 npu 内核模块 → 驱动未加载，常需重启或查看 dmesg"
fi

# 3. CANN 环境
if [ -f /usr/local/Ascend/ascend-toolkit/latest/version.cfg ]; then
  echo "  [OK] CANN version.cfg 存在"
else
  echo "  [✗] 未找到 CANN version.cfg → CANN 未装或路径异常。查 AscendMate /setup/cann-install"
fi
if [ -z "${ASCEND_HOME:-}" ] && [ ! -f /usr/local/Ascend/ascend-toolkit/set_env.sh ]; then
  echo "  [✗] 未设置 ASCEND_HOME 且默认路径无 set_env.sh → 需 source 环境"
fi

# 4. 框架 import
echo "  ---- 框架检查(用 python3) ----"
python3 - <<'PY'
import importlib
for m, hint in [("torch","框架"),
                ("torch_npu","昇腾适配层, 需与 torch 配套"),
                ("mindspore","华为自研框架")]:
    try:
        importlib.import_module(m)
        print(f"  [OK] {m}: 可 import")
    except Exception as e:
        print(f"  [✗] {m} 不可 import -> {type(e).__name__}: {str(e)[:60]}. 提示: {hint}")
PY

echo
echo "===== 建议 ====="
echo "如有 ✗ 项，把上面输出贴给 AI 助手或查 AscendMate /faq/ 对应板块："
echo "  - 设备/驱动 → /setup/firmware-driver"
echo "  - CANN 环境 → /setup/cann-install"
echo "  - 框架问题  → /setup/torch-npu-install"
echo "完整报错映射见 AscendMate /faq/ 与 ascend-assistant references/troubleshooting-map.md"
