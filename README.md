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

## 使用示例

### 1. 审计项目 Harness 完备度

> 用户："帮我检查这个项目的 AI 开发基础设施是否完善"

```bash
$ bash scripts/harness-audit.sh /path/to/my-project

🔍 Harness Audit: /path/to/my-project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ AGENTS.md 存在且 < 100 行
✅ pre-commit hooks 已配置
❌ 未检测到架构约束测试
❌ CI 配置缺少机器可读输出
✅ Linter 已配置
⚠️  测试覆盖率命令未找到

得分: 8/16 (50%)
建议: 优先补充架构约束测试和 CI 机器可读输出
```

### 2. 为新项目生成 AGENTS.md

> 用户："帮我为这个 Vue + Node.js 项目设计 AGENTS.md"

Agent 会基于 `assets/AGENTS.md.template` 模板，根据项目实际技术栈生成定制化的 AGENTS.md，包含：
- 项目概览与技术栈声明
- 常用命令（安装/开发/测试/构建）
- 架构规则与目录结构索引
- 代码规范与约定
- 指向详细文档的链接（而非内联所有内容）

### 3. 诊断 Agent 产出质量问题

> 用户："Agent 总是写出违反分层架构的代码，service 层直接导入了 UI 组件"

Agent 按 CIVC 框架逐层诊断：

```
诊断结果:

❌ 约束层缺失
  问题: "不要在 service 层导入 UI 组件" 只写在 AGENTS.md 中，属于概率性建议
  修复: 添加 dependency-cruiser 规则或自定义 ESLint 规则，将违规变为构建失败

⚠️ 告知层不足
  问题: AGENTS.md 有 500+ 行，Agent 容易遗漏关键规则
  修复: 精简为 ~100 行目录索引，详细规则拆分到子文档

✅ 验证层正常
  测试可运行，输出机器可读

✅ 纠正层正常
  错误信息包含文件路径和修复建议
```

### 4. 将 Markdown 规则转化为机械化约束

> 用户："我的 AGENTS.md 里写了很多规则但 Agent 经常不遵守"

| 你写的规则 | 应转化为 |
|-----------|---------|
| "不要从 Y 导入 X" | dependency-cruiser 规则 → 构建失败 |
| "所有 API 使用 ResponseWrapper" | ESLint 规则检查返回类型 |
| "新函数要写测试" | pre-commit hook 中的覆盖率门禁 |
| "遵循命名约定" | 文件名/函数名自定义 lint 规则 |

### 5. 交互式引导（不确定从何入手）

> 用户："我想改善团队的 AI 辅助开发体验，但不知道从哪里开始"

Agent 会启动 6 阶段的结构化问答诊断：

1. **项目基础信息** — 技术栈、团队规模
2. **当前工具使用** — 使用哪些 AI 编码工具、频率
3. **约束层评估** — 自动化检查覆盖度
4. **告知层评估** — 文档结构与可发现性
5. **验证层评估** — 反馈回路完整性
6. **纠正层评估** — 错误信息可操作性

完成后生成个性化的改进路线图，按优先级排列待办事项。

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
