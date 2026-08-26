#!/bin/bash
# ==============================================================================
# AscendMate 集群巡检脚本
# 批量检查多台昇腾服务器的健康状态，生成 Markdown 巡检报告
# 仅只读操作，无任何修改
# ==============================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 巡检报告文件名
REPORT_FILE="inspection-report-$(date +%Y%m%d-%H%M%S).md"
SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"
SSH_TIMEOUT=10

# 检查项计数
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
TOTAL_MACHINES=0
ERROR_DETAILS=""

usage() {
    echo "Usage: $0 <servers.txt | ip1 ip2 ip3 ...>"
    echo "  从文件读取服务器列表：$0 servers.txt"
    echo "  直接指定 IP：$0 192.168.1.101 192.168.1.102"
    echo ""
    echo "环境变量："
    echo "  SSH_USER  SSH 用户名（默认 root）"
    echo "  SSH_PORT  SSH 端口（默认 22）"
    exit 1
}

# 获取服务器列表
get_servers() {
    if [ $# -eq 0 ]; then
        usage
    fi

    if [ -f "$1" ]; then
        grep -v '^#' "$1" | grep -v '^$' | tr -d ' '
    else
        echo "$@" | tr ' ' '\n'
    fi
}

# 远程执行命令
remote_exec() {
    local ip="$1"
    local cmd="$2"
    ssh -o ConnectTimeout=${SSH_TIMEOUT} -o StrictHostKeyChecking=no -p ${SSH_PORT} ${SSH_USER}@${ip} "${cmd}" 2>/dev/null
}

# 巡检单台机器
inspect_machine() {
    local ip="$1"
    local npu_count="N/A"
    local health="N/A"
    local driver_ver="N/A"
    local cann_ver="N/A"
    local hccs="N/A"
    local temp="N/A"
    local ecc="N/A"
    local disk="N/A"
    local framework="N/A"
    local issues=""

    echo -e "${YELLOW}[巡检] ${ip} ...${NC}"

    # 1. 设备识别
    if npu_output=$(remote_exec "$ip" "npu-smi info 2>/dev/null"); then
        npu_count=$(echo "$npu_output" | grep -c "Atlas" || echo "0")
        if [ "$npu_count" -gt 0 ]; then
            ((PASSED_CHECKS++))
        else
            issues="${issues}NPU不可见; "
            ((FAILED_CHECKS++))
        fi
    else
        issues="${issues}SSH连接失败; "
        ((FAILED_CHECKS++))
        ((TOTAL_CHECKS))
        echo "| ${ip} | N/A | ❌ SSH失败 | N/A | N/A | SSH连接失败 |" >> "$REPORT_FILE.tmp_body"
        return
    fi
    ((TOTAL_CHECKS++))

    # 2. 设备健康
    health_output=$(remote_exec "$ip" "npu-smi info -t health 2>/dev/null" || echo "N/A")
    if echo "$health_output" | grep -qi "Normal"; then
        health="Normal"
        ((PASSED_CHECKS++))
    else
        health="Abnormal"
        issues="${issues}健康状态异常; "
        ((FAILED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))

    # 3. 驱动版本
    driver_ver=$(remote_exec "$ip" "npu-smi info -t board 2>/dev/null | head -5" | grep -oP 'Version\s*:\s*\K[\d.]+' | head -1 || echo "N/A")

    # 4. CANN 版本
    cann_ver=$(remote_exec "$ip" "cat /usr/local/Ascend/ascend-toolkit/latest/version.cfg 2>/dev/null" || echo "N/A")

    # 5. 温度
    temp_output=$(remote_exec "$ip" "npu-smi info -t board 2>/dev/null" || echo "")
    if echo "$temp_output" | grep -oP 'Temp\s*:\s*\K\d+' | head -1 > /dev/null 2>&1; then
        temp=$(echo "$temp_output" | grep -oP 'Temp\s*:\s*\K\d+' | head -1)
        if [ "$temp" -gt 85 ]; then
            issues="${issues}温度过高(${temp}C); "
        fi
    fi

    # 6. HCCS 链路
    hccs_output=$(remote_exec "$ip" "npu-smi info -t topo 2>/dev/null" || echo "")
    if echo "$hccs_output" | grep -qi "Link.*up\|OK"; then
        hccs="up"
    elif echo "$hccs_output" | grep -qi "down\|Error"; then
        hccs="down"
        issues="${issues}HCCS链路异常; "
    else
        hccs="N/A"
    fi

    # 7. ECC 错误
    ecc_output=$(remote_exec "$ip" "npu-smi info -t ecc 2>/dev/null" || echo "")
    if echo "$ecc_output" | grep -qi "0\|N/A\|none" ; then
        ecc="无错误"
    else
        ecc="有错误"
        issues="${issues}ECC错误; "
    fi

    # 8. 框架可用
    framework_output=$(remote_exec "$ip" "python3 -c 'import torch_npu; print(\"OK\")' 2>/dev/null" || echo "FAIL")
    if echo "$framework_output" | grep -q "OK"; then
        framework="OK"
    else
        framework="未安装/异常"
    fi

    # 9. 磁盘空间
    disk_output=$(remote_exec "$ip" "df -h / 2>/dev/null | tail -1" || echo "")
    disk_usage=$(echo "$disk_output" | awk '{print $5}' | tr -d '%' || echo "N/A")
    if [ "$disk_usage" != "N/A" ] && [ "$disk_usage" -gt 80 ]; then
        issues="${issues}磁盘空间不足(${disk_usage}%); "
    fi

    # 输出到报告
    local status_icon="✅"
    if [ -n "$issues" ]; then
        status_icon="⚠️"
    fi

    echo "| ${ip} | ${npu_count} | ${status_icon} ${health} | ${driver_ver} | ${cann_ver} | ${issues:-无} |" >> "$REPORT_FILE.tmp_body"
}

# 主流程
main() {
    echo "=============================================="
    echo "  AscendMate 集群巡检工具"
    echo "  时间：$(date '+%Y-%m-%d %H:%M:%S')"
    echo "=============================================="
    echo ""

    servers=$(get_servers "$@")
    server_count=$(echo "$servers" | wc -l)

    echo "巡检机器数：${server_count} 台"
    echo "SSH 用户：${SSH_USER}"
    echo ""

    # 初始化报告
    echo "# 昇腾集群巡检报告" > "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "- 巡检时间：$(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
    echo "- 巡检机器数：${server_count} 台" >> "$REPORT_FILE"
    echo "- 巡检结论：待定" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "## 汇总" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "| 机器 IP | NPU 数量 | 健康状态 | 驱动版本 | CANN 版本 | 异常项 |" >> "$REPORT_FILE"
    echo "|---------|---------|---------|---------|----------|--------|" >> "$REPORT_FILE"

    # 清空临时报告体
    > "$REPORT_FILE.tmp_body"

    # 逐台巡检
    for ip in $servers; do
        TOTAL_MACHINES=$((TOTAL_MACHINES + 1))
        inspect_machine "$ip"
    done

    # 合并报告
    cat "$REPORT_FILE.tmp_body" >> "$REPORT_FILE"
    rm -f "$REPORT_FILE.tmp_body"

    # 补充结论
    echo "" >> "$REPORT_FILE"
    if [ "$FAILED_CHECKS" -eq 0 ]; then
        echo "- 巡检结论：✅ 全部通过" >> "$REPORT_FILE"
    else
        echo "- 巡检结论：❌ 有 ${FAILED_CHECKS} 项异常，请查看异常项列" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    echo "## 建议" >> "$REPORT_FILE"
    echo "- 如有版本不一致，建议统一升级" >> "$REPORT_FILE"
    echo "- 如有温度过高，建议检查散热" >> "$REPORT_FILE"
    echo "- 如有 HCCS 链路异常，建议检查物理连接" >> "$REPORT_FILE"
    echo "- 完整巡检 SOP 见 AscendMate /monitoring/inspection" >> "$REPORT_FILE"

    echo ""
    echo "=============================================="
    echo -e "${GREEN}巡检完成！${NC}"
    echo "  机器数：${TOTAL_MACHINES}"
    echo "  检查项：${TOTAL_CHECKS}"
    echo "  通过：${PASSED_CHECKS}"
    echo "  异常：${FAILED_CHECKS}"
    echo "  报告：${REPORT_FILE}"
    echo "=============================================="
}

main "$@"
