# 交互式 Harness 诊断工作流

当用户请求"诊断"、"评估"或"引导"时，Agent 应加载此文件，按以下 6 个阶段逐步提问并生成个性化改进路线图。

> **使用方式**：每个阶段使用 `AskQuestion` 工具收集信息，根据回答决定后续建议。完成全部 6 个阶段后，综合生成改进路线图。

---

## 阶段 1: 项目基础信息

**目的**: 了解项目技术栈和团队背景，确定后续诊断的语境和工具建议方向。

**问题**:

```
prompt: "你的项目主要使用什么语言/框架？"
options:
  - id: "ts" | label: "TypeScript / JavaScript"
  - id: "go" | label: "Go"
  - id: "python" | label: "Python"
  - id: "rust" | label: "Rust"
  - id: "java" | label: "Java / Kotlin"
  - id: "other" | label: "其他"
allow_multiple: true
```

```
prompt: "团队规模（使用 AI 编码 Agent 的开发者数量）？"
options:
  - id: "solo" | label: "1 人（个人项目）"
  - id: "small" | label: "2-5 人"
  - id: "medium" | label: "6-20 人"
  - id: "large" | label: "20+ 人"
allow_multiple: false
```

```
prompt: "你正在使用哪些 AI 编码工具？"
options:
  - id: "cursor" | label: "Cursor"
  - id: "claude-code" | label: "Claude Code (CLI)"
  - id: "copilot" | label: "GitHub Copilot"
  - id: "windsurf" | label: "Windsurf"
  - id: "other" | label: "其他 Agent 工具"
allow_multiple: true
```

**根据回答的后续动作**:
- 记录技术栈，后续所有工具建议将针对该语言生态
- 团队 > 5 人 → 在约束层建议中增加"跨成员一致性"权重
- 使用多个 Agent 工具 → 在告知层中优先建议 AGENTS.md（跨工具通用）

---

## 阶段 2: 约束层诊断

**目的**: 评估项目是否通过机械化手段（而非文字说明）阻止不良模式。

**问题**:

```
prompt: "你的项目有哪些机械化约束？"
options:
  - id: "linter" | label: "Linter 配置（ESLint/golangci-lint/ruff 等）"
  - id: "custom-rules" | label: "针对项目的自定义 lint 规则"
  - id: "formatter" | label: "格式化工具（Prettier/gofmt/Black 等）"
  - id: "type-check" | label: "类型检查（TypeScript strict/mypy/编译器）"
  - id: "pre-commit" | label: "Pre-commit hooks"
  - id: "arch-test" | label: "架构约束测试（依赖方向检查）"
  - id: "none" | label: "以上都没有"
allow_multiple: true
```

**根据回答的后续动作**:
- 选择 "none" → 约束层评分为 🔴，优先建议添加 linter + formatter + pre-commit
- 缺少 "pre-commit" → 建议安装，提供 `assets/pre-commit-hook.sh` 模板
- 缺少 "arch-test" → 建议添加，提供 `assets/arch-test.example.ts` 示例
- 缺少 "custom-rules" → 提示：通用 lint 规则无法捕获项目特定约定，建议编写自定义规则
- 有 "linter" + "formatter" + "pre-commit" → 约束层基础良好

---

## 阶段 3: 告知层诊断

**目的**: 评估 Agent 是否能自主发现项目的规范、架构和常见错误。

**问题**:

```
prompt: "你的项目有哪些 Agent 可用的文档？"
options:
  - id: "agents-md" | label: "AGENTS.md / CLAUDE.md / .cursorrules"
  - id: "arch-doc" | label: "架构文档（docs/architecture.md 或等价物）"
  - id: "api-doc" | label: "API 规范文档"
  - id: "cmd-doc" | label: "构建/测试/部署命令文档"
  - id: "dir-doc" | label: "目录结构约定文档"
  - id: "none" | label: "以上都没有"
allow_multiple: true
```

```
prompt: "如果有 AGENTS.md，它大约有多少行？"
options:
  - id: "no-file" | label: "没有这个文件"
  - id: "short" | label: "< 100 行"
  - id: "medium" | label: "100-200 行"
  - id: "long" | label: "200-500 行"
  - id: "very-long" | label: "500+ 行"
allow_multiple: false
```

**根据回答的后续动作**:
- 选择 "none" → 告知层评分为 🔴，优先建议创建 AGENTS.md（提供 `assets/AGENTS.md.template`）
- AGENTS.md 500+ 行 → 反模式 2（百科全书式），建议重构为 100 行目录索引
- 缺少架构文档 → 建议创建，Agent 无法理解依赖方向
- 缺少命令文档 → Agent 无法自主运行测试和构建

---

## 阶段 4: 验证层诊断

**目的**: 评估项目是否有 Agent 可以自主运行和解读的自动化验证。

**问题**:

```
prompt: "你的项目有哪些自动化验证？"
options:
  - id: "unit" | label: "单元测试"
  - id: "integration" | label: "集成测试"
  - id: "e2e" | label: "E2E 测试（Playwright/Cypress 等）"
  - id: "ci" | label: "CI 流水线（GitHub Actions/GitLab CI 等）"
  - id: "json-output" | label: "测试结果为机器可读格式（JSON/JUnit XML）"
  - id: "none" | label: "以上都没有"
allow_multiple: true
```

```
prompt: "Agent 能直接看到测试结果吗？"
options:
  - id: "direct" | label: "能——Agent 可以运行测试命令并解析输出"
  - id: "manual" | label: "不能——需要人工复制粘贴结果给 Agent"
  - id: "ci-only" | label: "仅在 CI 中——本地没有配置"
  - id: "unsure" | label: "不确定"
allow_multiple: false
```

**根据回答的后续动作**:
- 选择 "none" → 验证层评分为 🔴（反模式 3：氛围测试），最高优先级建议
- 缺少 "json-output" → 建议配置机器可读输出（参见 `references/feedback-loops.md`）
- "manual" → 反模式 4（人在回路中的瓶颈），建议直接连接 Agent 到测试结果
- 缺少 "ci" → 建议搭建基础 CI 流水线

---

## 阶段 5: 纠正层诊断

**目的**: 评估当验证失败时，Agent 能否获得可操作的信息来自行修复。

**问题**:

```
prompt: "当测试或构建失败时，Agent 获得的信息质量如何？"
options:
  - id: "file-line" | label: "包含文件路径和行号"
  - id: "fix-hint" | label: "包含修复建议"
  - id: "error-code" | label: "有结构化的错误代码"
  - id: "timeout-vs-fail" | label: "能区分超时和代码错误"
  - id: "vague" | label: "信息模糊——只有 'something went wrong' 级别"
  - id: "unsure" | label: "不确定"
allow_multiple: true
```

```
prompt: "Agent 在遇到失败时的行为？"
options:
  - id: "self-fix" | label: "能自行修复并重试"
  - id: "gives-up" | label: "经常说'我已尽力'然后放弃"
  - id: "loop" | label: "陷入修复循环，反复尝试同样的修法"
  - id: "wrong-fix" | label: "修复了错误的地方（误诊问题）"
  - id: "na" | label: "不适用 / 没有观察过"
allow_multiple: true
```

**根据回答的后续动作**:
- "vague" → 纠正层评分低，建议改善错误信息（内联修复建议、结构化格式）
- "gives-up" → 建议实施 Ralph Loop（参见 `references/civc-framework.md`）
- "loop" → 可能是非幂等环境（反模式 5）或错误信息缺乏定位信息
- "wrong-fix" → 错误信息缺少位置信息（文件 + 行号），需要改善信号清晰度

---

## 阶段 6: 生成改进路线图

**目的**: 综合前 5 个阶段的诊断结果，生成按优先级排序的个性化改进计划。

**输出格式**:

```markdown
# Harness 改进路线图

## 当前评分

| 支柱 | 状态 | 关键发现 |
|------|------|---------|
| 约束 | 🔴/🟡/🟢 | [基于阶段 2 的发现] |
| 告知 | 🔴/🟡/🟢 | [基于阶段 3 的发现] |
| 验证 | 🔴/🟡/🟢 | [基于阶段 4 的发现] |
| 纠正 | 🔴/🟡/🟢 | [基于阶段 5 的发现] |

## 优先级 1（快速见效，1-2 天）

1. [最高影响的改进项 + 具体操作步骤]
2. [第二项 + 具体操作步骤]
3. [第三项 + 具体操作步骤]

## 优先级 2（验证体系，3-5 天）

4. [改进项 + 步骤]
5. [改进项 + 步骤]

## 优先级 3（深化，持续）

6. [改进项 + 步骤]
7. [改进项 + 步骤]

## 参考资源

- [根据诊断结果推荐的具体参考文件]
```

**评分规则**:
- 🔴 = 该支柱基本缺失（0-1 项就位）
- 🟡 = 有基础但不完整（2-3 项就位）
- 🟢 = 较为完善（4+ 项就位）

**路线图生成原则**:
1. 优先级 1 始终从影响最大、成本最低的项目开始
2. 所有建议必须包含具体的操作步骤（不是泛泛而谈）
3. 工具建议必须匹配阶段 1 中收集的技术栈信息
4. 如果检测到明显的反模式，在相应改进项中引用 `references/anti-patterns.md`
5. 提供审计脚本命令作为后续验证手段：`bash /path/to/harness-engineering/scripts/harness-audit.sh`
