# weave-editorial

`weave-editorial` 是 `weave` 的下游编辑 skill：把已经完成研究与引用核验的中文 Markdown 长文，改写为一篇可同时发布到微信公众号和 X 长文的完整成稿。

它解决的不是“把长文变短”，而是“让主线更强，同时保留全部有独立价值的材料”。次要内容会被后移、合并到较弱位置或缩短过渡，但不会被删掉。

## 适用场景

- weave 成稿需要进入发布状态；
- 需要重写标题、开头、章节顺序和结尾；
- 希望提高阅读完成度与传播力，但不接受删减材料；
- 需要一篇同时适配微信公众号和 X 长文的稿子。

不适用于新增研究、事实核验、摘要、翻译、X thread、短帖、卡片、多平台变体或自动发布。

## 安装

在仓库目录运行：

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

## 验证

仓库静态与发现性检查：

```powershell
pwsh -File scripts/check.ps1
```

对照源稿验证成稿：

```powershell
pwsh -File scripts/check.ps1 -SourceArticle path/to/source.md -OutputArticle path/to/output.md
```

验证器检查 URL、图片、代码块、标题、frontmatter、单稿形态和正文长度变化。它能发现材料遗失，但不能替代人工判断叙事是否更强。

## 仓库结构

```text
weave-editorial/
├── SKILL.md
├── README.md
├── references/editorial-protocol.md
├── scripts/check.ps1
└── evals/
```
