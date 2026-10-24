# Changelog

本文件记录 ascend-assistant 的版本变化。版本号与 `SKILL.md` 保持一致。

## [3.0.0] - 2026-09-17

### 新增
- **集群巡检能力**：`scripts/cluster_inspection.sh`（230 行），批量检查多台昇腾服务器健康状态并生成巡检报告。
- **算力利用率分析**：采集 NPU 利用率数据，分析低效原因并给出优化建议。
- **可执行脚本层**：`scripts/check_env.sh`、`scripts/quick_troubleshoot.sh`，把「让 AI 生成命令」升级为「先跑脚本拿到事实，再让 AI 解释」。

### 改进
- 增强官方路由表：何时用本 Skill、何时转官方 `Ascend/agent-skills` 的混合模式说明。
- 吸收官方 Ascend/agent-skills 精华，补充 `references/` 五份手册（命令速查、部署流程、性能调优、排障地图、集群巡检）。

## [2.0.0] - 2026-09 之前

### 新增
- 环境检测 + 排障能力（设备 / 驱动 / CANN / 框架状态）。
- 命令生成与验证方法说明。

## [1.0.0] - 初版

- 基础 Skill 骨架：触发条件、能力清单、安全操作规范。
