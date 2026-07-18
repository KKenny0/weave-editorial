# weave-editorial

`weave-editorial` 是 [weave](https://github.com/KKenny0/weave) 的下游编辑 skill：把已经完成研究与引用核验的中文 Markdown 长文，按 `faithful` 或 `publication` 模式改写为一篇可同时发布到微信公众号和 X 长文的完整成稿。

`faithful` 解决“让主线更强，同时保留全部独立信息”；`publication` 解决“保留承重判断、证据、反例和边界，同时允许公共文章进行真正的编辑选择”。两种模式都通过 Publication Gate 检查标题兑现、开头、主线、准确复述、自然传播理由和长期检索锚点。

## 适用场景

- weave 成稿需要进入发布状态；
- 需要重写标题、开头、章节顺序和结尾；
- 希望提高阅读完成度与传播力；
- 明确不接受删减时使用 `faithful`，允许删除不承重材料时使用 `publication`；
- 需要一篇同时适配微信公众号和 X 长文的稿子。

不适用于新增研究、事实核验、摘要、翻译、X thread、短帖、卡片、多平台变体或自动发布。

## 安装

推荐直接通过 NPX Skills 从 GitHub 安装到 Codex 与 Claude Code：

```powershell
npx -y skills@1.5.17 add https://github.com/KKenny0/weave-editorial --skill weave-editorial -g -a codex -a claude-code -y
```

如果已经克隆仓库，也可以在仓库目录安装：

```powershell
npx -y skills@1.5.17 add . --skill weave-editorial -g -a codex -a claude-code -y
```

开发期间可以用复制模式做隔离验证：

```powershell
npx -y skills@1.5.17 add . --skill weave-editorial -g -a codex --copy -y
```

## 使用

给出一篇已完成研究的 Markdown 文件，例如：

> 把这篇 weave 成稿平台化改写成一篇完整文章，可同时发公众号和 X 长文。不要删次要材料，把它们放到较弱的叙事位置。不要输出 thread 或多个版本。

默认输出到源文件同目录：

```text
{source-stem}-editorial.md
```

源文件永远不会被覆盖。

## 两种模式

- `faithful`：默认和向后兼容模式。保留全部独立信息、URL、图片、表格和代码块，正文不得低于源稿的 85%。
- `publication`：面向公众号、X 长文和公共读者。保留核心判断、最强证据、改变结论的反例、边界与不确定性；允许删除不承重背景、重复例子和旁支事实。

用户同时要求传播和无损保留时，选择 `faithful`。publication 不是“越短越好”，删减不能让结论比源稿更强、更广或更确定。

## 验证

仓库静态与发现性检查：

```powershell
pwsh -File scripts/check.ps1
```

对照源稿验证成稿：

```powershell
pwsh -File scripts/check.ps1 -Mode faithful -SourceArticle path/to/source.md -OutputArticle path/to/output.md
pwsh -File scripts/check.ps1 -Mode publication -SourceArticle path/to/source.md -OutputArticle path/to/output.md
```

验证器检查 URL、图片、代码块、标题、frontmatter、单稿形态和模式化长度变化。faithful 要求集合一致和至少 85%；publication 要求输出材料来自源稿，低于 60% 时警告。机械通过不能替代 Publication Gate 的语义判断。

## 仓库结构

```text
weave-editorial/
├── SKILL.md
├── README.md
├── references/editorial-protocol.md
├── scripts/check.ps1
└── evals/
```
