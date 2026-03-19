# Harness Engineering

设计约束、文档、工具和反馈回路，使 AI 编码 Agent 可靠地产出高质量代码。

> **Agent = Model + Harness**
>
> Model 提供原始智力。Harness——约束、文档、工具、反馈回路和架构执行机制——让这些智力**可用**。

## 适用场景

- **新项目搭建** — 初始化时配好 AGENTS.md、pre-commit hooks 和测试基础设施
- **质量诊断** — Agent 输出不稳定时，先审计 Harness，再考虑换模型
- **CI/CD 设计** — 确保每一层反馈都是 Agent 可读的
- **架构守护** — 通过机械化强制执行防止架构漂移
- **团队入门** — 帮助团队在正确的护栏下采用 AI 辅助开发

## CIVC 框架

Harness 的职责分解为四大支柱：

| 支柱 | 核心问题 | 关键机制 |
|------|---------|---------|
| **Constrain 约束** | 要阻止什么？ | 自定义 linter 规则、依赖方向测试、pre-commit hooks |
| **Inform 告知** | 提供什么上下文？ | AGENTS.md 目录索引、渐进式披露、仓库即唯一信息源 |
| **Verify 验证** | 衡量什么？ | L1-L4 四层反馈回路（秒级→小时级） |
| **Recover 纠正** | 如何修复？ | 机器可读错误信号、修复建议内联、timeout/failure 区分 |

> 在 Markdown 里告诉 Agent "不要做 X" 只是建议。让 X 触发构建失败才是规则。

## 快速开始

### 审计现有项目

```bash
bash scripts/harness-audit.sh [project_dir]        # 人类可读输出
bash scripts/harness-audit.sh --json [project_dir]  # 机器可读 JSON
```

### 搭建新项目

1. 复制并定制 `assets/AGENTS.md.template`
2. 安装 pre-commit hooks（参考 `assets/pre-commit-hook.sh`）
3. 添加架构约束测试（参见 `assets/arch-test.example.ts`）
4. 配置 CI 输出 Agent 可解析的机器可读结果
5. 运行审计验证完备度

### 诊断质量问题

当 Agent 产出低质量代码时，按 CIVC 逐层诊断：

1. **约束** — 是否有机械化护栏？还是只有文字说明？
2. **告知** — Agent 能发现项目规范吗？AGENTS.md 是目录索引还是文字墙？
3. **验证** — Agent 能运行测试并读取结果吗？反馈是机器可读的吗？
4. **纠正** — 测试失败时，Agent 能获得可操作的错误信息吗？

## 项目结构

```
├── SKILL.md                          # Skill 入口（Agent 自动加载）
├── references/
│   ├── civc-framework.md             # CIVC 框架详解，含行业实证案例
│   ├── feedback-loops.md             # 四层反馈回路实施指南
│   ├── anti-patterns.md              # 常见 Harness 失败模式及修复方案
│   ├── checklist.md                  # Harness 完备性检查清单
│   └── interactive-diagnosis.md      # 交互式诊断问答工作流
├── assets/
│   ├── AGENTS.md.template            # 即用型 AGENTS.md 模板
│   ├── pre-commit-hook.sh            # Pre-commit hook 模板
│   └── arch-test.example.ts          # 架构约束测试示例
└── scripts/
    └── harness-audit.sh              # 自动化 Harness 完备度审计脚本
```

## 作为 Skill 使用

本项目是一个 [Cursor Agent Skill](https://docs.cursor.com/context/skills)。安装后，Agent 会在检测到相关意图时自动加载 `SKILL.md`，获取完整的工作流指导。

触发关键词：harness engineering、agent constraints、AI code quality、AGENTS.md 设计、feedback loop、架构约束、CI/CD for agents 等。

## License

MIT
