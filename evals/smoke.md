# Smoke test

## 仓库检查

```powershell
pwsh -File scripts/check.ps1
```

预期：必需文件、frontmatter、3 个 eval 和 skills CLI 发现性检查全部通过。

## fixture 对照

对每个 `evals/files/*.md` 生成对应的 `*-editorial.md` 后运行：

```powershell
pwsh -File scripts/check.ps1 -SkipInstall -SourceArticle evals/files/survey.md -OutputArticle path/to/survey-editorial.md
```

预期：URL、图片和代码块集合一致；一个 H1；frontmatter title 与 H1 一致；status 为 draft；无 thread 或平台分版标记；正文非空白字符比例不低于 85%。

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
