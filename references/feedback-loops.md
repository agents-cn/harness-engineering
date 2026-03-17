# 四层反馈回路实施指南

本指南为每一层反馈回路提供具体的实施步骤。

## 架构概览

```
┌──────────────────────────────────────────────────┐
│                  Agent 工作流                      │
│                                                    │
│  编写代码 → L1 检查 → 提交 → L2 检查              │
│      │                    │                        │
│      │ (失败: 修复)        │ (失败: 修复)            │
│      ↓                    ↓                        │
│  创建 PR → L3 检查 → 合并 → L4 检查               │
│      │                    │                        │
│      │ (失败: 修复)        │ (失败: 回滚/修复)       │
│                                                    │
│  在每一层：Agent 读取结果，自行修复                  │
└──────────────────────────────────────────────────┘
```

## L1：即时反馈（秒级）

**目标**：在代码编写的瞬间捕获语法、类型和风格错误。

### 各语言生态工具

| 能力 | TypeScript/JS | Go | Python | Rust | Java/Kotlin |
|------|--------------|-----|--------|------|-------------|
| 热重载 | `tsx watch` / `vite` | `air` | `uvicorn --reload` | `cargo-watch` | Spring DevTools |
| 类型检查 | `tsc --watch --noEmit` | 编译器内置 | `dmypy` / `pyright` | 编译器内置 | 编译器内置 |
| Lint | `eslint` / `biome` | `golangci-lint` | `ruff` | `clippy` | `ktlint` / Checkstyle |
| 格式化 | `prettier` / `biome` | `gofmt` | `ruff format` / `black` | `rustfmt` | `ktfmt` / google-java-format |

### 面向 Agent 的自定义 Linter 规则

编写带有 Agent 友好错误信息的 linter 规则（适配你的技术栈）：

```javascript
// 示例：ESLint 自定义规则 no-cross-layer-import
// 其他语言可用对应工具实现同等效果（Go: go vet, Python: pylint, Rust: clippy）
module.exports = {
  create(context) {
    return {
      ImportDeclaration(node) {
        const source = node.source.value;
        const currentLayer = getLayer(context.getFilename());
        const importLayer = getLayer(source);
        if (!isAllowedDirection(currentLayer, importLayer)) {
          context.report({
            node,
            message: `❌ ${currentLayer} 不能从 ${importLayer} 导入。`
              + `修复方法: 将共享代码移至更低的层，或使用依赖注入。`
          });
        }
      }
    };
  }
};
```

### 核心原则

L1 反馈必须**即时**（1 秒以内）且**具体**（精确到文件、行号、修复建议）。这是捕获错误成本最低的层级。

---

## L2：预提交验证（分钟级）

**目标**：阻止破坏业务逻辑或现有测试的提交。

### 各语言生态工具

| 能力 | TypeScript/JS | Go | Python | Rust |
|------|--------------|-----|--------|------|
| Pre-commit 管理 | `simple-git-hooks` / `lefthook` | `lefthook` / `pre-commit` | `pre-commit` | `lefthook` / `pre-commit` |
| 单元测试 | `jest` / `vitest` | `go test` | `pytest` | `cargo test` |
| 相关测试发现 | `jest --findRelatedTests` | `go test ./...` | `pytest --co -q` | `cargo test` |
| 架构测试 | `dependency-cruiser` | `depguard` | `import-linter` | `cargo-deny` |

### 机器可读输出

配置测试运行器输出结构化结果（适配你的技术栈）：

| 语言 | 命令 | 输出格式 |
|------|------|---------|
| TypeScript/JS | `jest --json --outputFile=test-results.json` | JSON |
| Go | `go test -json ./...` | JSON (ndjson) |
| Python | `pytest --tb=short --junitxml=test-results.xml` | JUnit XML |
| Rust | `cargo test -- -Z unstable-options --format json` | JSON |

Agent 应能解析这些结果，精确识别哪些测试失败以及失败原因。

---

## L3：集成验证（约 10 分钟）

**目标**：在创建 PR 时验证多模块交互。

### CI 配置示例（GitHub Actions）

```yaml
# 适配你的 CI 平台（GitLab CI、Jenkins、CircleCI 等结构类似）
name: PR Integration Check
on: [pull_request]

jobs:
  integration:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: npm ci  # 替换为你的包管理器命令

      - name: Full lint
        run: npx eslint src/ --format json -o lint-results.json
        continue-on-error: true

      - name: Full test suite
        run: npx jest --ci --json --outputFile=test-results.json
        continue-on-error: true

      - name: E2E tests
        run: npx playwright test --reporter=json
        continue-on-error: true

      - name: Architecture validation
        run: npx dependency-cruiser --validate --output-type json src/ > arch-results.json
        continue-on-error: true

      - name: Summarize results
        run: |
          node scripts/summarize-ci.js \
            lint-results.json \
            test-results.json \
            arch-results.json \
            > ci-summary.json

      - name: Comment on PR
        uses: actions/github-script@v7
        with:
          script: |
            const summary = require('./ci-summary.json');
            // 将机器可读的摘要作为 PR 评论发布
            // Agent 可以读取并自行修复
```

### Agent 代码审查

在 L3 层，可选添加 Agent 互审步骤：

1. 总结 diff 内容
2. 对照 AGENTS.md 中的项目规范检查
3. 标记潜在问题
4. 将审查结果作为 PR 评论发布

---

## L4：全量回归（小时级）

**目标**：合并到主分支前的完整验证。

### L4 相比 L3 增加的内容

- 全量测试套件（不仅是受影响的测试）
- 多平台/多环境构建
- 性能回归检测
- 安全扫描
- 许可证合规
- 栈层端到端测试（浏览器 + 服务器 + 数据库）

### 栈层测试

最彻底的验证层——测试完整技术栈：

```
浏览器（Playwright/Cypress）
    ↕
Web 服务器（真实的，非 mock）
    ↕
数据库（真实的，非内存数据库）
    ↕
外部服务（真实的或契约测试）
```

这可以捕获：
- 网络时序问题
- 并发竞争条件
- 数据库迁移问题
- 跨服务集成 bug

---

## 反馈信号标准

所有层级产出的信号应满足以下要求：

### 格式

```json
{
  "layer": "L2",
  "status": "FAIL",
  "timestamp": "2026-03-16T10:30:00Z",
  "total_checks": 42,
  "passed": 40,
  "failed": 2,
  "failures": [
    {
      "test": "user-auth.login-flow",
      "file": "src/auth/handler.ts",
      "line": 42,
      "error": "Expected status 200, got 401",
      "fix_hint": "JWT 过期逻辑变更——更新 beforeEach 中的 token 刷新"
    },
    {
      "test": "arch.no-circular-deps",
      "file": "src/services/orderService.ts",
      "line": 5,
      "error": "Circular dependency: orderService → userService → orderService",
      "fix_hint": "将共享类型提取到 src/types/order-user.ts"
    }
  ]
}
```

### 要求

1. **机器可解析**：JSON 或结构化格式，而非自由文本日志
2. **位置明确**：每个失败都有文件路径 + 行号
3. **修复建议**：尽可能包含修复提示
4. **分类清晰**：通过/失败/超时/间歇性——每种对应不同的 Agent 行为
5. **分层输出**：每层独立输出，Agent 按顺序处理

## 实施优先级

从零开始时，按以下顺序实施以获得最大收益：

1. **L1**（1 小时）：配置 watch 模式的 lint 和类型检查
2. **L2**（2 小时）：安装 pre-commit hooks 和测试运行器
3. **L3**（半天）：配置 CI 并输出机器可读结果
4. **L4**（1-2 天）：添加 E2E 测试和全量回归套件

ROI 随层级递减，但**跳过任何一层都会创建盲区**，Agent 最终会（无意中）利用这些盲区。
