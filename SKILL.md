---
name: harness-engineering
description: 设计约束、文档、工具和反馈回路，使 AI 编码 Agent 可靠地产出高质量代码。适用于新项目搭建、质量诊断、CI/CD 设计、AGENTS.md 编写和 Harness 完备度审计。
metadata:
  author: brook
  version: "1.0"
---

# Harness Engineering

让 AI 编码 Agent 可靠、规模化地产出高质量代码的工程方法论。

> 仅在需要时加载 `references/` 中的详细文档，优先使用本文件中的概览信息。

## 核心原则

```
Agent = Model + Harness
```

Model 提供原始智力。Harness——约束、文档、工具、反馈回路和架构执行机制——让这些智力**可用**。没有设计良好的 Harness，同一个在基准测试中名列前茅的模型，也会写出无法维护的代码。

> **试金石**：一个全新的 Agent，在除了仓库内容外没有任何上下文的情况下，能否找到所需信息、遵守架构规则并交付可工作的代码？如果不能，差距就是待办清单。

## 何时适用

- **新项目搭建**：初始化时就配好 AGENTS.md、pre-commit hooks 和测试基础设施
- **质量诊断**：Agent 输出不稳定时，先审计 Harness，再考虑换模型
- **CI/CD 设计**：确保每一层反馈都是 Agent 可读的
- **架构守护**：通过机械化强制执行来防止架构漂移，而非靠书面说明
- **团队入门**：帮助团队在正确的护栏下采用 AI 辅助开发

## CIVC 框架概览

Harness 的职责分解为四大支柱（详见 `references/civc-framework.md`）：

| 支柱 | 代号 | 核心问题 | 关键机制 |
|------|------|---------|---------|
| **约束 Constrain** | C | 要阻止什么？ | 自定义 linter 规则、依赖方向测试、pre-commit hooks |
| **告知 Inform** | I | 提供什么上下文？ | AGENTS.md 目录索引、渐进式披露、仓库即唯一信息源 |
| **验证 Verify** | V | 衡量什么？ | L1-L4 四层反馈回路（秒级→小时级） |
| **纠正 Correct** | R | 如何修复？ | 机器可读错误信号、修复建议内联、timeout/failure 区分 |

> 注：在清单和审计脚本中，"纠正" 使用代号 **R**（Recovery）以避免与 "约束" 的 **C** 混淆。

**黄金法则**：在 Markdown 里告诉 Agent "不要做 X" 只是建议。让 X 触发构建失败才是规则。

## 工作流：审计项目

评估项目的 Harness 完备度：

```bash
bash scripts/harness-audit.sh [project_dir]        # 人类可读输出
bash scripts/harness-audit.sh --json [project_dir]  # 机器可读 JSON
```

> 上述路径相对于本 skill 目录。Agent 应自动解析 skill 的实际安装路径。

脚本自动检测技术栈，执行约 16 项基础检查（覆盖 AGENTS.md、hooks、CI、linter、测试等），输出完备度评分和建议。完整审计请使用 `references/checklist.md` 中的 32 项清单。

## 工作流：新项目搭建

1. **复制并定制 AGENTS.md** —— 模板在 `assets/AGENTS.md.template`
2. **安装 pre-commit hooks** —— 参考 `assets/pre-commit-hook.sh`
3. **添加架构约束测试** —— 参见 `assets/arch-test.example.ts` 中的模式
4. **配置 CI** 使其输出 Agent 可解析的机器可读结果
5. **运行审计** 验证完备度

## 工作流：诊断质量问题

当 Agent 产出低质量代码时，按 CIVC 逐层诊断：

1. **检查约束**：是否有机械化护栏？还是只有 Agent 可能忽略的文字说明？
2. **检查告知**：Agent 能发现项目规范吗？AGENTS.md 是目录索引还是文字墙？
3. **检查验证**：Agent 能运行测试并读取结果吗？反馈是机器可读的吗？
4. **检查纠正**：测试失败时，Agent 能获得可操作的错误信息吗？

常见 Harness 失败模式及修复方案见 `references/anti-patterns.md`。

## 工作流：交互式引导

对于不确定从何入手的项目，使用交互式诊断工作流。Agent 将通过 6 个阶段的结构化问答，评估项目现状并生成个性化的改进路线图。

详见 `references/interactive-diagnosis.md`。

## 熵管理

AI 会放大现有模式——好的和坏的都会。第一行坏代码会变成一万行。

- 定期安排 **清扫任务**：后台 Agent 扫描模式漂移
- 监控 **架构侵蚀**：依赖方向违规、命名约定偏移
- 维护 **文档一致性**：保持 AGENTS.md 与实际项目结构同步
- 采用 **"吐槽墙"模式**：允许 Agent 标记可疑的现有模式供人工审查

## 使用示例

- "帮我检查这个项目的 Harness 完备度" → 运行 `scripts/harness-audit.sh` 或使用 `references/checklist.md` 手动审计
- "为新项目搭建 AI 辅助开发基础设施" → 按"新项目搭建"工作流执行，从 AGENTS.md 模板开始
- "Agent 总是写出违反架构的代码" → 按"诊断质量问题"工作流逐层排查，重点看约束层
- "帮我设计 AGENTS.md" → 使用 `assets/AGENTS.md.template`，按项目实际情况定制
- "我不确定从哪里开始改进" → 使用交互式引导工作流（`references/interactive-diagnosis.md`）

## 触发条件

以下关键词或意图应激活本 skill：harness engineering、agent constraints、AI code quality、AI 编码质量、AGENTS.md 设计、feedback loop、架构约束、agent guardrails、development infrastructure、CI/CD for agents、诊断 Agent 质量。

## 关键参考文件

| 文件 | 内容 |
|------|------|
| `references/civc-framework.md` | CIVC 框架详解，含行业实证案例 |
| `references/feedback-loops.md` | 四层反馈回路实施指南 |
| `references/anti-patterns.md` | 常见 Harness 失败模式及修复方案 |
| `references/checklist.md` | Harness 完备性检查清单（审计工具） |
| `references/interactive-diagnosis.md` | 交互式诊断问答工作流 |
| `assets/AGENTS.md.template` | 即用型 AGENTS.md 模板 |
| `assets/pre-commit-hook.sh` | Pre-commit hook 模板 |
| `assets/arch-test.example.ts` | 架构约束测试示例 |
| `scripts/harness-audit.sh` | 自动化 Harness 完备度审计脚本 |
