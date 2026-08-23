# Ascend Assistant · 昇腾服务器助手

> 让 AI 助手直接帮你操作/查询/排障华为昇腾（Ascend/NPU）智算服务器的 **Agent Skill**。
> 与 [AscendMate（昇腾之家）](https://github.com/RevolutionLA/AscendMate) 深度配套：AscendMate 是完整手册，本 Skill 负责"遇到问题怎么一步步操作"。

## 这是什么

`ascend-assistant` 是一个 **Skill（系统提示词 / 操作指南）**，不是独立程序。把它装进你的 AI 编程/助手工具后，当你对着一台昇腾服务器提问，AI 会按照本 Skill 的规范，安全、准确地帮你：

| 能力 | 干什么用 |
|---|---|
| **环境检测 + 排障** | 检测设备/驱动/CANN/框架状态，定位并解释报错 |
| **命令生成与建议** | 生成安装、推理、微调等可直接复制的命令，并说明验证方法 |
| **部署脚本引导** | 从裸机到跑起，step-by-step 引导 |
| **性能调优建议** | 基于 Profiling 数据给调优方向 |

## 安装（3 种方式）

### 方式一：skill 命令（推荐，适用于支持 skills 的 Agent）
```bash
# 从 GitHub 仓库安装
skills add https://github.com/RevolutionLA/ascend-assistant
# 或
skills install RevolutionLA/ascend-assistant
```

### 方式二：clone 到你的 skills 目录
```bash
git clone https://github.com/RevolutionLA/ascend-assistant.git
# 然后把 ascend-assistant/SKILL.md 放入你的 Agent 的 skills 目录
# 例如 .agents/skills/ 或 .claude/skills/ascend-assistant/SKILL.md
```

### 方式三：手动复制
把本仓库根目录的 `SKILL.md` 放到你的技能/系统提示词目录即可（SKILL.md 已自包含触发条件、能力和操作规范）。

## 使用示例

给 AI 助手这些提示词即可触发能力：

- "检查这台昇腾服务器的环境是否正常" （→ 环境检测）
- "torch_npu 装不上，报 driver not initialized，帮我看看" （→ 排障）
- "在 openEuler + CANN 8.3.RC2 上给我安装 torch_npu 的命令" （→ 命令生成）
- "按 7 步带我把这台裸机昇腾服务器跑起来" （→ 部署引导）
- "推理吞吐低，帮我分析怎么调优" （→ 性能调优）

## 能力详解 & 配套手册

完整能力说明见 [SKILL.md](SKILL.md)。
详细教程与 FAQ 见 **AscendMate（昇腾之家）**：
- 环境搭建 / 7 步走：<https://github.com/RevolutionLA/AscendMate>
- 在线文档站：<https://revolutionla.github.io/AscendMate/>

## 相关链接

- AscendMate 首页：<https://github.com/RevolutionLA/AscendMate>
- 昇腾文档中心：<https://www.hiascend.com/document>
- 昇腾软件下载：<https://www.hiascend.com/developer/download>

## 许可

[MIT](LICENSE)。本 Skill 基于公开资料整理，命令与版本以官方发布为准；高风险操作请谨慎并自行担责。
