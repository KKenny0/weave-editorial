# Smoke test

## 仓库检查

```powershell
pwsh -File scripts/check.ps1
```

预期：必需文件、frontmatter、6 个 eval、双模式契约和 skills CLI 发现性检查全部通过。

## fixture 对照

对每个 `evals/files/*.md` 生成对应的 `*-editorial.md` 后运行：

```powershell
pwsh -File scripts/check.ps1 -SkipInstall -Mode faithful -SourceArticle evals/files/survey.md -OutputArticle path/to/survey-editorial.md
```

预期：URL、图片和代码块集合一致；一个 H1；frontmatter title 与 H1 一致；status 为 draft；无 thread 或平台分版标记；正文非空白字符比例不低于 85%。

publication 输出使用：

```powershell
pwsh -File scripts/check.ps1 -SkipInstall -Mode publication -SourceArticle evals/files/survey.md -OutputArticle path/to/survey-publication.md
```

预期：输出 URL、图片和代码块是源稿子集；不新增事实材料；一个 H1；frontmatter title 与 H1 一致；status 为 draft；无 thread 或平台分版；低于源稿 60% 时警告而不单独失败。

## Publication Gate

每个 faithful 和 publication 成稿都人工确认：

1. 标题、开头、正文和结尾回答同一个具体问题；
2. 开头六段内给出问题、常见理解缺口和核心观察；
3. 全文只有一条主叙事；
4. 一至两句内部复述同时包含改变的判断和失效边界；
5. 自然传播理由指向具体读者用途，不是号召；
6. 至少一个稳定问题、可复用区分、机制、决策框架或清楚的时间边界构成检索锚点；
7. 没有新增事实，publication 删减没有扩大主张。

内部内容账本、承重账本、复述和传播理由不得出现在成稿或额外文件中。

## 真实成稿验收

源稿：

```text
<vault>/02_Articles/AI_Agent/agent-memory-systems-survey_2026-07-10.md
```

输出：

```text
<vault>/02_Articles/AI_Agent/agent-memory-systems-survey_2026-07-10-editorial.md
```

除自动检查外，人工确认：四个控制面仍是主线；评测、成本、安全和程序性记忆迁移作为次叙事完整存在；“未竟”“入门”“覆盖度声明”、全部来源和图片仍在。
