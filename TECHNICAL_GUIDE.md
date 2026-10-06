# 项目技术维护指南

本文面向第一次接触本项目的维护者，说明网站的技术架构、内容规范、本地维护方式、Git/GitHub 工作流、GitHub Pages 发布流程和信息安全边界。

首次接手项目时，应先阅读 [当前项目交接](HANDOFF.md)，确认最新状态、遗留任务和禁止操作，再使用本文了解长期维护方法。

`HANDOFF.md` 与本文只存在于仓库根目录，不属于公开网站导航。若仓库本身是公开仓库，它们仍会被公开访问，因此不得写入真实凭据或内部环境信息。

## 如何使用本指南

本指南不记录预览进程、待验收事项、当前分支等会话状态。短期状态只写入 `HANDOFF.md`；本文只在架构、规范、配置或长期流程发生变化时更新。

| 维护任务 | 按需阅读 |
| --- | --- |
| 理解架构、技术栈和目录 | [第 3～5 节](#3-整体架构与数据流) |
| 编写内容、使用模板和执行核验 | [第 6～11 节](#6-markdown-内容规范) |
| 使用 Git、GitHub 和 Pages | [第 12～18 节](#12-git-版本管理) |
| 日常维护、验收和排障 | [第 19～21 节](#19-日常维护操作) |
| 查看未来演进、命令和清单 | [第 22～23 节](#22-未来演进) |

不需要为一次普通维护完整读取本文；先从任务对应章节开始，并在需要时沿交叉链接补充上下文。

## 1. 项目概述

### 1.1 项目目标

本项目把 Markdown 技术笔记转换为可搜索、可导航的静态网站。目前软件测试知识按 7 个分类长页面组织，并提供中文界面、中英文搜索、页内目录、上一篇/下一篇、代码复制和固定深色主题。

项目采用“本地文件是唯一内容源”的方式维护：

1. 在本地编辑 Markdown。
2. 使用 MkDocs 预览和校验。
3. 使用 Git 记录版本。
4. 将源码推送到 GitHub。
5. 由 GitHub Actions 构建静态文件并发布到 GitHub Pages。

### 1.2 能力边界

本项目是纯静态网站，不包含以下能力：

- 后端服务、数据库或运行时 API；
- 用户登录、权限管理和私密内容访问控制；
- 在线编辑、评论或动态数据；
- 服务端全文检索；
- Mermaid 图表、标签聚合页或博客系统。

搜索索引和页面均在构建时生成。浏览器访问网站时，不需要 Python，也不会连接本项目自建的服务器。

### 1.3 已实现能力与可选扩展

| 类别 | 当前已实现 | 可选扩展 |
| --- | --- | --- |
| 内容 | Markdown、Front Matter、显式锚点 | 标签、模板目录、更多知识分类 |
| 编辑 | 任意文本编辑器 | VS Code、Obsidian 联合维护 |
| 构建 | MkDocs 1.6.1 + Material 9.7.7 | 评估 Zensical 或其他生成器 |
| 图表 | 普通图片、SVG favicon | Mermaid |
| 自动化 | PowerShell 预览和内容核验 | Python/Typer 笔记 CLI、链接检查器 |
| 发布 | GitHub Actions 工作流已准备 | 自定义域名、环境保护规则 |
| AI | 未接入自动提交 | ChatGPT/Codex 辅助整理，人工复核 |

## 2. 技术体系全景

### 2.1 组件职责

| 技术 | 职责 | 是否必需 |
| --- | --- | --- |
| Markdown | 保存正文、链接、代码块和元数据 | 是 |
| VS Code / Obsidian | 编辑和浏览 Markdown | 否，任选编辑器 |
| Python | 在本地或 CI 中运行 MkDocs | 是 |
| MkDocs | 将 Markdown 构建为静态 HTML | 是 |
| Material for MkDocs | 提供主题、导航、搜索和交互能力 | 是 |
| PowerShell | 启动预览和执行内容核验 | 本项目当前需要 |
| Git | 保存本地版本历史、比较和回退 | 上传前需要 |
| GitHub | 远程仓库、备份、协作和 Actions 运行平台 | 发布时需要 |
| GitHub CLI `gh` | 从命令行创建仓库、PR 和查看 Actions | 可选 |
| GitHub Actions | 在云端严格构建并触发部署 | 发布时需要 |
| GitHub Pages | 托管构建后的 HTML、CSS 和 JavaScript | 发布时需要 |
| ChatGPT / Codex | 辅助整理、改写和审查 | 可选，必须人工复核 |

### 2.2 编辑器选择

- VS Code 更适合同时维护 Markdown、YAML、CSS、PowerShell 和 Git，可安装 Markdown lint、YAML、Git 等扩展。
- Obsidian 更适合按双向链接和知识图谱浏览笔记，但应坚持使用标准 Markdown 链接，避免把 Obsidian 专有语法直接用于公开页面。
- 两者可以打开同一个仓库，但不要同时编辑同一文件；保存前确认编码为 UTF-8。

## 3. 整体架构与数据流

```text
docs/ 策划后的权威内容 + assets/* + mkdocs.yml
               │
               ├─ 本地：preview.ps1 / mkdocs build --strict / audit-content.ps1
               └─ 云端：GitHub Actions
                                  │
                                  ▼
                         site/ 静态构建产物
                                  │
                                  └─ Pages artifact
                                           │
                                           ▼
GitHub Pages 网站
```

页面结构和核验规则见[第 11 节](#11-内容结构与核验工具)。

### 3.1 文件边界

- `docs/`、`mkdocs.yml`、脚本和工作流属于源码，应进入 Git。
- `site/` 是每次构建重新生成的产物，不应进入 Git。
- `.venv/` 是本机 Python 环境，不应进入 Git。
- `docs/` 是网站正文的唯一日常维护来源，应直接编辑其中的 Markdown。
- `tools/audit-content.ps1` 只检查当前页面结构和构建后的搜索索引，不生成或覆盖正文，具体规则见[第 11 节](#11-内容结构与核验工具)。
- 浏览器只访问构建结果；修改 `site/` 会在下次构建时丢失。

### 3.2 本地与 CI 的环境差异

`preview.ps1` 使用本地可用的 Python 创建 `.venv`，实际版本应在运行时通过 `python --version` 确认；GitHub Actions 明确使用 Python 3.12。两者都安装同一份 `requirements.txt`，但操作系统、Python 小版本和路径规则可能不同：

- 本地是 Windows，脚本和路径以 PowerShell/反斜杠为主；
- CI 是 Ubuntu，文件名大小写敏感；
- Windows 上可工作的大小写错误链接，可能在 CI 或 Pages 上失败；
- 提交前必须执行严格构建，推送后仍需确认 Actions 结果。

## 4. 技术栈与版本

### 4.1 固定依赖

`requirements.txt` 固定：

```text
mkdocs==1.6.1
mkdocs-material==9.7.7
```

Material 会安装其依赖的 PyMdown Extensions 等包。当前文件只固定了两个直接依赖，并非包含哈希的完整传递依赖锁；对供应链复现要求更高时，可另行评估 `pip-tools` 和哈希锁定。

### 4.2 配置格式

- 页面正文：Markdown；
- 站点配置和工作流：YAML；
- Markdown 增强：PyMdown Extensions；
- 本地自动化：PowerShell；
- 样式：CSS；
- CI/CD：GitHub Actions YAML。

### 4.3 依赖升级原则

1. 在独立分支更新版本，不直接在 `main` 上试验。
2. 阅读 MkDocs、Material 和相关 Actions 的发行说明及安全公告。
3. 重新创建或更新 `.venv`，执行严格构建和内容核验。
4. 检查桌面端、移动端、固定深色主题、搜索和所有链接。
5. 通过 Pull Request 合并，让 CI 再验证一次。
6. 不把“能够安装”视为“兼容”；至少保留一次可回退的提交。

### 4.4 MkDocs 2.0 注意事项

本项目以 `requirements.txt` 中的 MkDocs 1.6.1 和 Material 9.7.7 作为已验证组合，不直接执行 `pip install --upgrade mkdocs`。MkDocs 2.x 属于需要单独设计、验证和回退方案的迁移，不作为普通依赖升级处理。升级前应评估：

- 继续使用 MkDocs 1.x 的维护和安全风险；
- Material for MkDocs 的维护状态；
- Zensical 的兼容程度；
- 其他静态站点生成器的迁移成本。

Material 9.7.7 在构建时会打印 MkDocs 2.0 兼容性提示。它是上游主题输出的提示，不是本项目链接或导航校验产生的 MkDocs warning，因此当前严格构建仍会以退出码 0 完成。不要因这条提示解除版本固定；如自动化日志确需隐藏，可查阅上游说明中的 `NO_MKDOCS_2_WARNING` 环境变量。

## 5. 目录结构与文件职责

```text
knowledge-base/
├─ .github/workflows/pages.yml     # GitHub Pages 构建与部署
├─ docs/
│  ├─ index.md                     # 网站首页
│  ├─ assets/
│  │  ├─ favicon.svg
│  │  └─ stylesheets/extra.css
│  └─ software-testing/
│     ├─ index.md                  # 软件测试知识体系总览
│     └─ 01-...md 至 07-...md      # 七个分类长页面
├─ tools/
│  └─ audit-content.ps1            # 页面、标题锚点和搜索核验
├─ .gitignore
├─ mkdocs.yml
├─ preview.ps1
├─ README.md
├─ requirements.txt
├─ HANDOFF.md                      # 当前状态、遗留任务和接手顺序
└─ TECHNICAL_GUIDE.md              # 本文
```

目录增长后，可在 `docs/` 下按内容类型演进：

```text
docs/
├─ bugs/          # 已脱敏的通用故障案例
├─ knowledge/     # 原理和知识点
├─ projects/      # 可公开的项目实践
├─ snippets/      # 命令和代码片段
├─ templates/     # 写作模板
└─ assets/
   ├─ images/
   └─ diagrams/
```

分类应以读者如何查找内容为依据。不要只为了“看起来整齐”一次性创建大量空目录。

## 6. Markdown 内容规范

### 6.1 页面与文件名

- 一篇 Markdown 对应一个页面。
- 每页只使用一个一级标题 `#`。
- 标题层级依次使用 `##`、`###`，不要跳级。
- 文件名使用小写英文和连字符，如 `api-testing.md`。
- 需要固定排序时使用两位数字前缀，如 `01-foundations.md`。
- 文件移动或改名后，立即更新 `mkdocs.yml` 和所有入站链接。

### 6.2 Front Matter

当前页面使用：

```yaml
---
title: 页面标题
description: 用于页面描述和搜索理解的简短说明
---
```

未来可增加：

```yaml
date: 2026-10-04
tags:
  - 软件测试
  - API
```

`date` 和 `tags` 目前没有配套插件或聚合页面，加入元数据不会自动生成标签页。启用前应先设计用途和验证构建行为。

### 6.3 锚点与链接

重要章节使用稳定、语义化的英文锚点：

```markdown
## 缺陷生命周期 { #defect-lifecycle }
```

这依赖 `attr_list` 扩展。标题文字改变时，应尽量保留旧锚点，避免已有书签和外部链接失效。

Markdown 页面之间优先使用相对 `.md` 链接：

```markdown
[接口测试](docs/software-testing/04-application-testing.md#api-and-service-integration)
```

不要写以 `/` 开头的站点绝对路径。项目站点通常部署在 `/<repository>/` 子路径，根路径链接会跳到错误位置。

### 6.4 图片、附件和代码

- 图片统一放入 `docs/assets/images/`，图表源文件可放入 `docs/assets/diagrams/`。
- 使用相对链接，不引用本机绝对路径。
- 图片文件名同样使用小写英文和连字符。
- 为图片提供有意义的替代文本。
- 代码块必须标记语言，如 `python`、`powershell`、`yaml`、`sql`。
- 示例中的域名、IP、账号、Token、数据库名和客户信息必须脱敏。

### 6.5 中英文与搜索

- 第一次出现缩写时同时写出中文或英文全称，例如“持续集成（Continuous Integration，CI）”。
- 同一概念保持统一写法，避免搜索结果分散。
- 可在正文中自然包含常用中英文关键词，不要堆砌不可读的关键词列表。
- `mkdocs.yml` 已同时启用 `zh` 和 `en` 搜索分词。

## 7. 笔记类型与模板

### 7.1 知识点笔记

```markdown
---
title: 知识点名称
description: 一句话说明本文解决的问题
---

# 知识点名称

## 背景

## 核心概念

## 工作原理

## 示例

## 常见误区

## 参考资料
```

### 7.2 Bug 排查笔记

工作 Bug 只有在完全脱敏且具备通用价值时，才适合进入公开知识库。

```markdown
---
title: 故障现象的通用描述
description: 影响、原因与解决方向的摘要
---

# 故障现象的通用描述

## 基本信息

- 影响范围：
- 环境：已脱敏的通用环境描述
- 首次发现时间：

## 现象

## 初始假设

## 排查过程

1. 检查项、证据与结论。

## 根因

## 解决方案

## 预防措施

## 参考资料
```

排查过程应记录证据和被排除的假设，而不是只保留最终答案。

### 7.3 项目实践记录

建议包含背景、约束、备选方案、决策、实施、验证、结果和复盘。内部项目名、架构、资源地址和业务数据必须替换为通用描述。

### 7.4 命令与代码片段

说明命令适用的系统、前置条件、参数含义、预期输出和风险。删除、覆盖、重置或生产操作必须显著标注，不提供真实密钥。

### 7.5 模板接入方式

模板可以先以本文附录为准。内容稳定后，再复制为 `docs/templates/` 页面并加入导航；不要仅为编辑器方便就把内部模板发布到公开站点。

## 8. 图表与可视化内容

### 8.1 静态图片

截图适合界面和异常现象，SVG 适合架构示意，PNG/JPEG 适合复杂图像。提交前应裁剪无关区域并检查窗口标题、用户名、目录、域名和通知内容。

### 8.2 Mermaid 的适用场景

Mermaid 适合版本化的文本图表，例如：

- 请求链路和系统架构；
- 数据流和状态流转；
- 时序图；
- 故障排查决策流程。

当前项目没有启用 Mermaid，直接写 `mermaid` 代码块不会自动得到预期图形。未来启用时，需要：

1. 在 `pymdownx.superfences` 中增加 Mermaid 自定义围栏配置；
2. 加载并固定 Mermaid JavaScript 版本，优先使用仓库内受控资源；
3. 验证固定深色主题、打印、移动端和无 JavaScript 场景；
4. 将外部脚本视为供应链依赖并定期升级；
5. 在 GitHub Pages 上验证子路径和内容安全策略。

表达长期稳定的架构时，可优先保留图表源文件并导出 SVG；需要频繁修改、适合文本审查的流程图可选择 Mermaid。

## 9. MkDocs 配置说明

配置入口为 `mkdocs.yml`。

### 9.1 基础信息与环境变量

```yaml
site_name: Asia知识库
site_description: 面向持续学习与查阅的个人技术知识库
site_url: !ENV [SITE_URL, ""]
repo_url: !ENV [REPO_URL, ""]
edit_uri: !ENV [EDIT_URI, ""]
```

- 本地没有设置变量时使用空值，不显示无效仓库链接。
- CI 注入 `SITE_URL`、`REPO_URL`、`EDIT_URI`，生成规范 URL、仓库入口和编辑链接。
- `SITE_URL` 必须包含项目站点的仓库子路径和结尾 `/`。

### 9.2 主题能力

Material 主题当前启用：

- 中文界面和自定义 SVG favicon；
- 固定 `slate` 深色方案，不读取系统主题偏好，也不显示主题切换按钮；
- 固定顶部标签、分节导航、独立总览入口、面包屑、返回顶部和页脚前后导航；
- 桌面端领域化左栏与跟随滚动的右侧页内目录，移动端使用 Material 原生抽屉；
- 搜索建议、高亮和分享；
- 代码复制与页面编辑入口。

项目通过 `font: false` 避免依赖远程字体，字体栈由 `docs/assets/stylesheets/extra.css` 控制。

### 9.3 导航与搜索

`nav` 是显式导航清单。新增 Markdown 但未加入 `nav` 会在严格构建中失败，因为 `validation.nav.omitted_files` 为 `warn`，而 `strict: true` 会把警告提升为构建失败。

搜索插件同时配置 `zh` 与 `en`。搜索索引位于构建目录的 `site/search/search_index.json`，不要手工修改。

### 9.4 Markdown 扩展

当前启用告示块、属性列表、Markdown-in-HTML、增强代码围栏、代码高亮和目录永久链接。删除扩展前，应搜索项目中是否使用了对应语法。

### 9.5 链接校验

导航遗漏、文件不存在、锚点不存在、绝对链接和不可识别链接当前均按 `warn` 配置；结合 `strict: true`，任何此类警告都会导致构建命令非零退出。

### 9.6 项目站点子路径

普通仓库发布为项目站点时，地址通常是：

```text
https://<owner>.github.io/<repository>/
```

当前工作流按此模式计算 `SITE_URL`。如果仓库名本身是 `<owner>.github.io`，它属于用户/组织站点，地址没有仓库子路径；此时必须修改工作流中的 `SITE_URL`，否则规范链接会多出一段仓库名。

## 10. 本地开发与预览

### 10.1 环境要求

- Windows PowerShell；
- 可从命令行调用的 Python 3；
- 首次安装依赖时可访问 Python 包索引；
- 建议使用 Git 和现代浏览器。

### 10.2 一条命令启动

在项目根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\preview.ps1
```

脚本会：

1. 找不到 `.venv\Scripts\python.exe` 时创建 `.venv`；
2. 安装或确认 `requirements.txt` 中的依赖；
3. 在 `http://127.0.0.1:8000/` 启动开发服务器。

按 `Ctrl+C` 停止。再次运行同一命令即可重新启动。MkDocs 通常会在文件保存后自动重建并刷新页面。

### 10.3 严格构建

```powershell
.\.venv\Scripts\python.exe -m mkdocs build --strict
```

如果已经激活虚拟环境，也可执行：

```powershell
python -m mkdocs build --strict
```

构建结果写入 `site/`。该命令成功结束且退出码为 0，才表示配置、导航和链接检查通过。

### 10.4 编码

- Markdown、YAML 和 CSS 统一保存为 UTF-8 无 BOM。
- 含中文的 PowerShell 脚本保存为 UTF-8 BOM，尤其必须保留 `tools/audit-content.ps1` 的 BOM，以兼容 Windows PowerShell 5.1。
- 不要使用会依 PowerShell 版本改变默认编码的临时写文件命令覆盖正文。
- 出现中文乱码时，先检查编辑器右下角的文件编码，再检查终端字体和代码页。

### 10.5 常见本地问题

- `python` 不存在：安装 Python 并勾选加入 PATH，或调整脚本为明确的 Python 路径。
- 创建虚拟环境失败：确认 Python 安装包含 `venv`。
- 依赖下载失败：检查网络、代理、证书和包索引设置。
- 8000 端口占用：停止旧预览进程，或手工运行 `mkdocs serve --dev-addr 127.0.0.1:8001`。
- 修改依赖后行为异常：删除并重建 `.venv` 前先确认其中没有需要保留的文件；`.venv` 本应可随时重建。

## 11. 内容结构与核验工具

### 11.1 权威内容

`docs/` 是网站正文的唯一来源。日常新增、删改、归类和交叉链接调整都直接编辑其中的 Markdown；项目不依赖另一份汇总文档，也不存在从历史长文重新生成正式页面的流程。

软件测试领域当前由总览页和 7 个分类长页面组成。H3 只用于帮助阅读，可以按内容需要合并、重命名或删除，不承担固定数量或历史对应关系。

### 11.2 稳定标题锚点

分类页面的每个 H2 核心主题都应使用语义清晰的显式英文锚点，例如：

```markdown
## 测试隔离与测试替身 { #test-isolation-and-doubles }
```

锚点使用小写字母、数字和连字符，全站不得重复。网站发布后，标题锚点可能被站内链接、搜索结果或外部书签引用；调整标题时优先保留原锚点。确需更换时，应同步更新所有站内链接，并评估是否需要为既有外部链接保留兼容入口。

### 11.3 `audit-content.ps1`

通用核验脚本会：

- 检查当前 7 个分类页面是否完整且没有旧分类文件残留；
- 确认每页只有一个 H1、没有 H4；
- 确认所有 H2 都有格式正确且全站唯一的稳定英文锚点；
- 检查软件测试总览包含 7 个分类入口；
- 保持“测试隔离与测试替身”的名称和内容边界，不允许新增独立的服务虚拟化核心主题；
- 确认 12 个代表关键词进入构建后的搜索索引。

必须先构建，再核验：

```powershell
.\.venv\Scripts\python.exe -m mkdocs build --strict
powershell -ExecutionPolicy Bypass -File .\tools\audit-content.ps1
```

新增普通正文不需要修改脚本。增加、删除或重命名分类页面时，需要同步修改 `mkdocs.yml`、软件测试总览入口，以及脚本中的预期页面列表。移动或重命名 H2 时，应按第 11.2 节处理锚点和站内链接。

## 12. Git 版本管理

### 12.1 首次初始化

确认当前位置是项目根目录，再执行：

```powershell
git init
git branch -M main
git status
git add .
git commit -m "docs: initialize knowledge base site"
git remote add origin https://github.com/<OWNER>/<REPOSITORY>.git
git push -u origin main
```

初始化前先运行 `git status` 和 `git check-ignore`，确认 `.venv/`、`site/` 和敏感文件没有进入暂存区。

### 12.2 日常流程

```powershell
git status
git diff
git add docs mkdocs.yml
git diff --staged
git commit -m "docs: add API testing notes"
git push
```

不要习惯性执行 `git add .` 后直接提交；先检查暂存差异。

### 12.3 提交规范

- `feat:` 新增用户可见的功能、导航或视觉能力；
- `docs:` 新增或更新笔记；
- `fix:` 修正文档、链接、脚本或样式错误；
- `refactor:` 调整目录、拆分页面或重组内容，不改变含义；
- `chore:` 更新依赖、工作流和维护工具。

提交应保持单一目的，消息描述结果，例如 `fix: preserve defect lifecycle anchor`。

### 12.4 分支和 Pull Request

较大修改建议使用分支：

```powershell
git switch -c docs/add-security-notes
```

推送分支并创建 Pull Request 后，工作流只构建、不部署。检查变更内容和 CI 通过后再合并到 `main`。

### 12.5 比较与回退

```powershell
git log --oneline --decorate -n 20
git diff <OLD_COMMIT>..<NEW_COMMIT>
git restore -- docs/path/page.md
git revert <COMMIT_SHA>
```

- `git restore` 适合撤销尚未提交的文件修改，执行前确认不需要保留这些修改。
- 已推送到共享分支的错误使用 `git revert` 创建反向提交。
- 不在共享 `main` 上使用强制推送或重写历史。

### 12.6 GitHub CLI（可选）

登录后可从当前目录创建仓库：

```powershell
gh auth login
gh repo create <REPOSITORY> --source . --public --remote origin --push
```

涉及工作笔记时优先考虑 `--private`，但私有仓库不等于 Pages 网站自动私有。执行前确认仓库名、账号和可见性。

## 13. GitHub 仓库管理

### 13.1 公开或私有

- 公开仓库适合已经脱敏、希望公开分享的通用知识。
- 私有仓库适合个人草稿或内部材料，但仍禁止提交 Secret。
- GitHub Pages 对私有仓库和私密发布的支持取决于账号、组织和套餐；创建仓库前查看 GitHub 当前官方说明。

建议把“公开知识库”和“内部工作笔记”放在不同仓库。这样比依靠目录约定更能降低误发布风险。

### 13.2 仓库名与网址

- 用户/组织站点：仓库必须命名为 `<owner>.github.io`，默认地址是 `https://<owner>.github.io/`。
- 项目站点：普通仓库名，默认地址是 `https://<owner>.github.io/<repository>/`。
- 每个账号最多有一个用户/组织站点，每个仓库最多有一个项目站点。

当前工作流默认按项目站点设计。

### 13.3 仓库文件职责

- `HANDOFF.md`：覆盖更新的当前状态快照，记录遗留任务、接手顺序和禁止操作；
- `README.md`：快速了解、运行和查找详细文档；
- `TECHNICAL_GUIDE.md`：维护、发布、安全和排障手册；
- `docs/`：最终网站内容；
- Issues：记录待办、缺陷或内容计划；
- Pull Requests：审查较大改动和执行 CI；
- Releases：本项目通常不需要，只有需要标记正式内容版本时再使用。

### 13.4 保护和权限

- 可为 `main` 设置必须通过构建检查、禁止直接强推等保护规则。
- Actions 默认权限应尽量只读；只有部署作业获得 `pages: write` 与 `id-token: write`。
- 第三方 Action 应选择可信发布者、审查升级内容；高安全要求时可固定到完整提交 SHA。
- 不向工作流授予未使用的 `contents: write`、`pull-requests: write` 或 Secret。

## 14. GitHub Pages 原理与站点类型

GitHub Pages 是静态文件托管服务。它可以直接发布仓库文件，也可以接收构建流程生成的 artifact。本项目选择后一种方式：

```text
源码分支 → GitHub Actions → site/ → Pages artifact → GitHub Pages
```

选择 Actions artifact 的原因：

- 源码和构建结果分离；
- 不需要维护 `gh-pages` 分支；
- 每次部署前执行同一套严格构建；
- Pull Request 可以验证而不发布；
- `site/` 无需进入 Git 历史。

不要把 GitHub Pages 当作需要服务端逻辑、数据库、认证或高敏感数据的托管平台。

## 15. GitHub Actions 发布流程

入口是 `.github/workflows/pages.yml`。

### 15.1 触发条件

- 推送到 `main`：构建并部署；
- 面向 `main` 的 Pull Request：只构建，不配置、上传或部署 Pages；
- `workflow_dispatch`：允许在 GitHub 界面手工运行并部署当前分支配置。

### 15.2 构建作业

当前 `build` 作业：

1. 在 `ubuntu-latest` 上运行；
2. 设置项目站点所需的三个环境变量；
3. 使用 `actions/checkout@v6` 检出源码；
4. 使用 `actions/setup-python@v6` 安装 Python 3.12 并缓存 pip；
5. 从 `requirements.txt` 安装依赖；
6. 执行 `python -m mkdocs build --strict`；
7. 非 PR 时运行 `actions/configure-pages@v5`；
8. 非 PR 时使用 `actions/upload-pages-artifact@v4` 上传 `site/`。

### 15.3 部署作业

`deploy` 仅在非 PR 事件运行，并依赖 `build` 成功。它：

- 获得 `pages: write` 和 `id-token: write`；
- 使用 `github-pages` environment；
- 通过 `actions/deploy-pages@v4` 发布；
- 把返回的页面地址记录为 environment URL。

全局权限只有 `contents: read`，部署权限只在需要的作业中提升。

### 15.4 并发控制

工作流使用：

```yaml
concurrency:
  group: pages
  cancel-in-progress: true
```

新发布会取消仍在运行的旧发布，避免过期内容后部署。短时间连续推送时看到旧任务被取消属于正常现象。

### 15.5 动态 URL

当前工作流注入：

```text
SITE_URL=https://<owner>.github.io/<repository>/
REPO_URL=https://github.com/<owner>/<repository>
EDIT_URI=edit/main/docs/
```

仓库重命名后，下一次构建会自动采用新仓库名；GitHub Pages 设置和旧外部链接仍需人工复查。若改为用户/组织站点或自定义域名，必须调整 `SITE_URL` 逻辑。

### 15.6 失败定位顺序

1. 打开仓库 **Actions**，进入失败的工作流运行。
2. 确定是 `build` 还是 `deploy` 作业失败。
3. 构建失败先看依赖安装和 MkDocs 的第一条错误。
4. 上传失败检查 `site/` 是否生成以及 artifact 大小限制。
5. 部署失败检查 Pages Source、作业权限、environment 和仓库套餐。
6. 修复后推送新提交或手工重新运行；不要只靠反复重试掩盖确定性错误。

## 16. GitHub Pages 启用与首次发布

1. 在 GitHub 创建目标仓库，确认公开/私有选择。
2. 在本地初始化 Git，将源码提交并推送到 `main`。
3. 打开仓库 **Settings → Pages**。
4. 在 **Build and deployment** 中将 Source 选择为 **GitHub Actions**。
5. 打开 **Actions**，确认 `Build and deploy notes` 成功。
6. 从部署作业或 Pages 设置进入网站。
7. 验证首页、七个分类页面、CSS、favicon、搜索和深层链接。
8. 在新标签直接打开一个深层 URL 并刷新，确认不是只有站内跳转可用。

首次发布和后续缓存更新可能需要几分钟。不要在一次刷新后就判断失败；以 Actions 部署结果和 Pages 设置中显示的 URL 为准。

首次发布常见问题：

- Pages 尚未启用，`configure-pages` 无法读取站点设置；
- Source 仍是从分支发布；
- 默认分支不是 `main`；
- 私有仓库的账号套餐不支持相应 Pages 能力；
- 组织策略禁止 Actions 或 Pages；
- URL 实际带仓库子路径，但链接按根站点编写。

## 17. 自定义域名与 HTTPS

第一版建议使用默认 `github.io` 域名，确认内容和发布链路稳定后再配置自定义域名。

### 17.1 DNS 类型

- `www.example.com` 或 `notes.example.com` 等子域名通常使用 `CNAME` 指向 `<owner>.github.io`。
- `example.com` 等根域名通常使用 GitHub 公布的 `A` 和/或 `AAAA` 记录。
- 具体记录值必须从 GitHub 当前官方文档复制，不要使用陈旧教程中的 IP。

### 17.2 配置步骤

1. 在 GitHub 验证域名所有权，降低域名劫持风险。
2. 在 DNS 服务商配置记录。
3. 在仓库 **Settings → Pages → Custom domain** 设置域名。
4. 等待 DNS 检查和 TLS 证书签发。
5. 可用后启用 **Enforce HTTPS**。
6. 将工作流的 `SITE_URL` 改为自定义域名，如 `https://notes.example.com/`。
7. 重新构建并检查规范链接、搜索和资源。

`CNAME` 文件用于在发布内容中声明自定义域名，常见于从分支发布的 Pages。采用自定义 Actions artifact 时，以 Pages 设置和 GitHub 当前文档为准；若决定保留该文件，应放在 `docs/CNAME` 使 MkDocs 将其复制到 `site/CNAME`，并确认构建后存在。

DNS 缓存和证书签发不会即时完成。回滚时，应同时处理 Pages 设置和 DNS 记录；禁用站点后不要遗留仍指向 GitHub 的未受控 DNS 记录。

## 18. 公开发布与信息安全

### 18.1 可见性不是同一件事

仓库可见性和 Pages 网站访问控制不是同一配置。私有仓库可以在支持的套餐中使用 Pages，但这不代表网站一定只有仓库成员可见。私密发布能力主要面向符合条件的 GitHub Enterprise Cloud 组织，应以账号的实际 Pages 设置和官方文档为准。

如果内容不能公开，不要仅依赖“仓库是 private”这一点。应把内部笔记保留在独立私有仓库或组织批准的内部知识库，并在发布前做实际的未登录访问测试。

### 18.2 发布前必须脱敏

- 公司域名、内网 IP、VPN 和服务器地址；
- 数据库名、连接串、云资源标识和环境地址；
- 用户名、真实姓名、客户信息和业务数据；
- 内部项目名、工单号、群聊和截图通知；
- Access Token、API Key、Cookie、私钥和密码；
- 生产配置、内部源代码和未公开架构；
- 可用于社会工程攻击的组织结构和运维流程。

脱敏不是简单把密码替换为星号。示例应改写为不可还原的占位值，如 `example.com`、`192.0.2.10`、`<TOKEN>`，并检查 Git 历史和图片元数据。

### 18.3 忽略规则

项目 `.gitignore` 已排除构建目录、虚拟环境、常见私钥、环境变量文件和凭据文件。忽略规则只能阻止未跟踪文件被意外加入，不能保护已经提交的文件，也不能替代 Secret 管理。

提交前可检查：

```powershell
git status --ignored
git check-ignore -v .env
git diff --staged
```

### 18.4 Secret 泄露处理

1. 立即在对应服务撤销并轮换凭据；不要先花时间只删除文件。
2. 删除当前分支中的 Secret 并提交修复。
3. 判断是否需要使用 `git filter-repo` 等工具清理历史。
4. 如果已推送，与所有协作者协调历史重写和重新克隆。
5. 查看 GitHub Secret scanning、Actions 日志和访问审计。
6. 记录根因并增加预防措施。

即使彻底重写 Git 历史，也不能保证外部克隆、缓存或日志中的副本消失，因此轮换凭据永远是第一步。

## 19. 日常维护操作

### 19.1 新增笔记

1. 在合适的 `docs/` 分类下创建 `.md`。
2. 添加 Front Matter、唯一 H1 和稳定锚点。
3. 在 `mkdocs.yml` 的 `nav` 中加入页面。
4. 使用相对 `.md` 链接和 `assets/` 资源。
5. 本地预览并执行严格构建。
6. 检查桌面端双层顶栏与侧栏、移动端抽屉、固定深色主题和搜索。
7. 脱敏后提交。

### 19.2 新增分类

先确定分类名称、入口页和导航位置，再创建目录。每个较大的分类建议提供 `index.md` 总览。避免让同一篇内容在多个目录复制，优先通过链接关联。

### 19.3 修改标题或文件名

- 标题文字可改，但保留旧显式锚点；
- 文件名改变时全局搜索旧路径；
- 更新 `nav` 和总览页面；
- 如已有外部链接，考虑保留兼容页面或明确迁移说明。

### 19.4 添加图片或图表

压缩文件体积、删除敏感信息、写替代文本，并在移动端检查宽度。启用 Mermaid 前遵循第 8 节的完整接入步骤。

### 19.5 修改样式

自定义样式位于 `docs/assets/stylesheets/extra.css`。同时检查：

- 固定 `slate` 深色方案的文字、边框、活动项和代码块对比度；
- 双层顶栏、面包屑、桌面端主侧栏与右侧目录的定位和间距；
- 320–390px 宽度移动端；
- 长代码和长链接是否造成横向滚动；
- 标题是否被固定顶栏遮挡；
- 更新主题后自定义选择器是否仍有效。

### 19.6 更新依赖

遵循第 4.3 节，且一次只做一类升级。不要在添加大量内容的同一提交中同时升级主题，这会让回归问题难以定位。

### 19.7 调整内容结构

直接在 `docs/` 中移动、合并或重命名内容，并同步调整 `mkdocs.yml`、总览入口和相关链接。修改 H2 时按[第 11.2 节](#112-稳定标题锚点)处理稳定锚点；分类页面发生变化时，同步更新核验脚本的预期页面列表。

### 19.8 发布

推送到 `main` 后观察 Actions。只有部署作业成功、线上抽查通过，才把修改视为已发布。

## 20. 质量检查与验收

发布前至少完成：

- [ ] `mkdocs build --strict` 退出码为 0，且没有 MkDocs 导航、链接或配置警告；
- [ ] `audit-content.ps1` 通过（修改软件测试迁移内容时）；
- [ ] 所有新增页面已进入导航；
- [ ] 文件链接、锚点和图片均可访问；
- [ ] 中文与英文关键词能在搜索中找到；
- [ ] 桌面端和手机端没有异常横向滚动或遮挡；
- [ ] 固定深色主题、双层顶栏、面包屑、桌面侧栏、移动端抽屉、页内目录、上下页和代码复制正常；
- [ ] 在项目站点子路径下资源地址正确；
- [ ] 深层 URL 可直接打开和刷新；
- [ ] `404.html` 已生成，并在实际 Pages 环境验证未找到页面；
- [ ] `site/`、`.venv/` 和缓存未进入 Git；
- [ ] 暂存差异中没有凭据、内部地址、个人信息或敏感截图；
- [ ] Pull Request 构建通过，合并后的 Pages 部署成功。

## 21. 故障排查

| 现象 | 优先检查 |
| --- | --- |
| `python` 或 `mkdocs` 找不到 | PATH、`.venv` 是否创建、是否使用虚拟环境 Python |
| 依赖安装失败 | 网络、代理、证书、Python 版本、包索引 |
| 8000 端口占用 | 是否已有预览进程；改用 8001 |
| 中文乱码 | 文件是否 UTF-8、编辑器/终端编码 |
| 页面未出现在导航 | `mkdocs.yml` 的 `nav`；缩进和文件路径 |
| 锚点失效 | 显式 ID 是否改变、链接大小写、严格构建首条警告 |
| 搜索结果未更新 | 是否重新构建、浏览器缓存、`site/search/search_index.json` |
| CSS 修改看不到 | 强制刷新、文件是否被 `extra_css` 引用、构建日志 |
| 本地正常而 Pages 样式丢失 | `SITE_URL`、项目子路径、以 `/` 开头的资源链接 |
| Actions 构建失败 | 安装步骤和 `mkdocs build --strict` 的第一条错误 |
| `configure-pages` 失败 | Pages 是否启用且 Source 为 GitHub Actions |
| artifact 缺失 | `site/` 是否生成、上传步骤条件、路径拼写 |
| 部署权限不足 | `pages: write`、`id-token: write`、组织策略和 environment |
| 自定义域名异常 | DNS 记录、域名验证、Pages 设置、证书状态和缓存 |

排障原则是先复现、再读取第一条确定性错误、最后做最小修复。不要同时修改依赖、配置和内容，否则难以判断原因。

## 22. 未来演进

建议按实际需求依次评估，而不是一次性全部引入：

1. 增加统一的 YAML `tags` 并启用标签聚合页；
2. 建立 `bugs/`、`knowledge/`、`projects/` 和 `templates/`；
3. 启用 Mermaid 并固定前端依赖；
4. 使用 VS Code 与 Obsidian 维护同一标准 Markdown 目录；
5. 增加外链检查、Markdown 格式检查和拼写检查；
6. 使用 Dependabot 或 Renovate 提交依赖升级 PR；
7. 开发 Python/Typer CLI，一条命令按模板创建笔记并更新元数据；
8. 评估 MkDocs 1.x、Material、Zensical 和替代生成器的长期路线；
9. 内容量扩大后，按读者任务重构导航和搜索标签；
10. 内容规模扩大后，将覆盖映射扩展为跨领域索引，并为各知识领域建立独立核验规则。

### 22.1 AI 辅助边界

AI 可以帮助：

- 把排查记录整理成模板；
- 建议标题、摘要、标签和章节；
- 检查术语一致性、链接和脱敏遗漏；
- 生成初始代码示例或图表文本。

AI 输出不得默认提交或发布。维护者必须核验事实、命令安全性、授权范围、版权、敏感信息和项目实际结果。含公司数据的原始材料不得上传到未经批准的外部 AI 服务。

## 23. 附录

### 23.1 常用命令

```powershell
# 本地预览
powershell -ExecutionPolicy Bypass -File .\preview.ps1

# 严格构建
.\.venv\Scripts\python.exe -m mkdocs build --strict

# 内容核验（先构建）
powershell -ExecutionPolicy Bypass -File .\tools\audit-content.ps1

# Git 提交前检查
git status
git diff
git diff --staged

# 查看远程和近期历史
git remote -v
git log --oneline --decorate -n 20
```

### 23.2 环境变量

| 变量 | 示例 | 用途 |
| --- | --- | --- |
| `SITE_URL` | `https://owner.github.io/repository/` | 站点规范地址和项目子路径 |
| `REPO_URL` | `https://github.com/owner/repository` | 主题中的仓库链接 |
| `EDIT_URI` | `edit/main/docs/` | 页面“编辑”链接相对路径 |

本地通常不设置这些变量。需要模拟线上地址时，可在当前 PowerShell 会话设置后再构建：

```powershell
$env:SITE_URL = "https://owner.github.io/repository/"
$env:REPO_URL = "https://github.com/owner/repository"
$env:EDIT_URI = "edit/main/docs/"
.\.venv\Scripts\python.exe -m mkdocs build --strict
```

### 23.3 发布前脱敏清单

- [ ] 文本中没有 Token、Key、Cookie、密码或连接串；
- [ ] 没有公司域名、内网 IP、内部项目名和客户标识；
- [ ] 代码和日志已替换真实数据；
- [ ] 截图已检查标题栏、账号、路径、通知和元数据；
- [ ] 暂存文件列表中没有 `.env`、私钥、凭据或数据库导出；
- [ ] Git 历史中没有本次先提交后删除的 Secret；
- [ ] 使用未登录浏览器确认公开页面内容符合预期。

### 23.4 GitHub Pages 首次发布清单

- [ ] 仓库名和站点类型已确定；
- [ ] 工作流中的 `SITE_URL` 与站点类型一致；
- [ ] 默认分支是 `main`；
- [ ] Pages Source 是 GitHub Actions；
- [ ] Actions 和 Pages 未被组织策略禁用；
- [ ] `build` 和 `deploy` 作业均成功；
- [ ] 首页、深层链接、搜索、CSS 和 favicon 正常；
- [ ] 仓库与网站的实际公开范围符合预期。

### 23.5 官方资料

- [MkDocs 官方文档](https://www.mkdocs.org/)
- [Material for MkDocs 入门](https://squidfunk.github.io/mkdocs-material/getting-started/)
- [Material for MkDocs：MkDocs 2.0 兼容性说明](https://squidfunk.github.io/mkdocs-material/blog/2026/02/18/mkdocs-2.0/)
- [GitHub Pages 是什么](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages)
- [使用自定义 GitHub Actions 工作流发布 Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)
- [GitHub Pages 自定义域名](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/about-custom-domains-and-github-pages)
- [GitHub Actions 部署与 environment](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments)
- [GitHub 密钥安全](https://docs.github.com/en/code-security/concepts/secret-security/secret-scanning)

GitHub 套餐、Actions 版本、Pages 权限和 DNS 地址会变化。执行首次发布、私密发布或自定义域名配置时，应以当日官方文档和仓库界面为准。

