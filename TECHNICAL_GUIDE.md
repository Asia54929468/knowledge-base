# 知识库项目技术指南

本文说明知识库站点的架构、技术栈、配置、构建发布、导航搜索、样式和验证机制。项目用途与常用命令见 [README](README.md)。

## 项目基线与架构

### 项目目标

本项目把 Markdown 技术笔记构建为可搜索、可导航的静态网站。目前包含软件测试、接口自动化和测试工程师面试三个独立知识领域，每个领域由一个总览页和若干按学习或工作任务组织的主题页面组成。站点提供中文界面、中英文搜索、页内目录、领域内上一篇/下一篇、代码复制和固定深色主题。

### 能力边界

项目是纯静态网站，不包含后端服务、数据库、运行时 API、账号权限、在线编辑、评论、动态数据或服务端搜索。搜索索引与页面都在构建时生成；浏览器访问网站时不需要 Python，也不会连接项目自建服务。

当前未启用 Mermaid、标签聚合页或博客系统。

### 数据流

```text
docs/ + assets/ + hooks/ + overrides/ + mkdocs.yml
├─ 本地：preview.ps1 / 严格构建 / tools/check-content.ps1
└─ Git 提交并推送到 GitHub
   └─ GitHub Actions → site/ 静态产物 → GitHub Pages
```

### 文件边界与运行环境

- `docs/`、`overrides/`、`mkdocs.yml`、脚本和工作流属于源码，应进入 Git。
- `site/` 是构建产物，`.venv/` 是本机环境，两者均不得提交。
- 浏览器只访问构建结果；直接修改 `site/` 会在下次构建时丢失。
- 根目录文档不会进入网站导航，但仍可通过公开仓库访问，因此不得写入凭据或内部环境信息。
- 本地使用 Windows PowerShell 和可用的 Python 3；CI 使用 Ubuntu 与 Python 3.12。
- 两端安装同一份 `requirements.txt`，但大小写、路径和 Python 小版本仍可能不同。
- Windows 可用的大小写错误链接可能在 CI 或 Pages 失败，因此提交前必须严格构建，推送后仍需检查 Actions。

## 文件职责

### 目录与职责

```text
knowledge-base/
├─ .github/workflows/pages.yml     # GitHub Pages 构建与部署
├─ docs/
│  ├─ index.md                     # 网站首页
│  ├─ assets/
│  │  ├─ favicon.svg
│  │  └─ stylesheets/extra.css
│  ├─ software-testing/
│  │  ├─ index.md                  # 软件测试领域总览
│  │  └─ <topic>.md                # 按知识体系组织的主题页面
│  ├─ pytest-api-automation/
│  │  ├─ index.md                  # 接口自动化领域总览
│  │  └─ <topic>.md                # 按学习和实施任务组织的主题页面
│  └─ test-engineer-interview/
│     ├─ index.md                  # 测试工程师面试领域总览
│     └─ <topic>.md                # 按面试问题类型组织的主题页面
├─ hooks/
│  └─ domain_navigation.py         # 限制领域内前后翻页
├─ overrides/
│  └─ partials/nav-item.html       # 领域导航覆盖
├─ tools/
│  └─ check-content.ps1            # 全站内容冒烟检查
├─ AGENTS.md                       # AI 协作指令
├─ HANDOFF.md                      # 当前未完成任务与异常接续
├─ README.md                       # 项目介绍与本地运行入口
├─ TECHNICAL_GUIDE.md              # 长期技术基线与验收标准
├─ mkdocs.yml                      # 站点配置与导航
├─ preview.ps1                     # 本地预览入口
└─ requirements.txt                # 固定的直接依赖
```

## 技术栈与配置

### 固定依赖

`requirements.txt` 固定两个直接依赖：

```text
mkdocs==1.6.1
mkdocs-material==9.7.7
```

Material 会安装 PyMdown Extensions 等传递依赖。当前依赖文件不是带哈希的完整锁文件，不应把“能够安装”视为已验证兼容。

### 文件格式

- 正文使用 Markdown，站点配置和工作流使用 YAML。
- Markdown 增强由 PyMdown Extensions 提供。
- 本地自动化使用 PowerShell，样式使用 CSS。
- 主题覆盖使用 Jinja / HTML，CI/CD 使用 GitHub Actions YAML。
- Markdown、YAML、CSS 和 HTML 保存为 UTF-8 无 BOM。
- 含中文的 PowerShell 脚本保存为 UTF-8 BOM；必须保留 `tools/check-content.ps1` 的 BOM，以兼容 Windows PowerShell 5.1。

### 站点配置入口

`mkdocs.yml` 是站点名称、主题、插件、扩展、导航和校验级别的唯一配置入口。环境变量 `SITE_URL`、`REPO_URL` 和 `EDIT_URI` 由 CI 注入；本地为空时不显示无效仓库入口。

`SITE_URL` 必须与 Pages 站点类型匹配。普通项目站点包含 `/<repository>/` 子路径；若仓库名为 `<owner>.github.io`，则属于用户或组织站点，不能附加仓库名。

## 内容文件与构建约束

### 页面结构

- 一篇 Markdown 对应一个页面，每页只使用一个一级标题 `#`。
- 正文层级依次使用 `##`、`###`，不要跳级；确有必要时才继续使用 H4。
- 文件名使用小写英文和连字符；需要固定排序时使用两位数字前缀。
- H3 只帮助阅读，可随内容调整；H2 核心主题承担稳定锚点。
- 页面移动、重命名或删除后，立即同步 `mkdocs.yml` 和全部入站链接。

当前 Front Matter 只使用：

```yaml
---
title: 页面标题
description: 用于页面描述和搜索理解的简短说明
---
```

`title`、`description` 和领域总览使用的 `icon` 必须是非空的单行字符串。不要使用 `null`、`~`、列表、对象、多行块、行尾 YAML 注释或 Markdown 链接；当前本地内容检查器只按这一受限格式读取元数据，不提供完整 YAML 语义解析。

当前没有为 `date`、`tags` 等字段配置配套插件或聚合页。

### 锚点与链接

需要稳定引用的标题可设置由小写英文、数字和连字符组成的显式锚点；锚点在同一页面内不得重复，不强制所有标题都设置：

```markdown
## 缺陷生命周期 { #defect-lifecycle }
```

标题变化时优先保留既有锚点，避免站内链接、搜索结果和外部书签失效。确需修改锚点时，必须同步全部引用并评估外部兼容。

页面间优先使用相对于当前 Markdown 文件的 `.md` 链接。例如软件测试分类页之间引用：

```markdown
[接口测试](04-application-testing.md#api-and-service-integration)
```

不要使用本机绝对路径或以 `/` 开头的站点根路径；项目站点部署在仓库子路径时，根路径链接会跳转错误。

### 图片、附件与代码

- 图片放入 `docs/assets/images/`，可维护的图表源文件放入 `docs/assets/diagrams/`。
- 文件名使用小写英文和连字符，引用使用相对路径，并提供有意义的替代文本。
- 截图提交前裁剪无关区域，检查用户名、目录、域名、窗口标题和通知内容。
- 域名、IP、账号、Token、数据库名、客户信息和内部架构必须脱敏。

当前未启用 Mermaid。简单的架构或调用链优先复用 `.execution-flow` 原生 HTML/CSS 组件：节点必须保留可见文字和语义化列表，桌面端横向排列、移动端纵向排列，不能只依赖箭头或颜色传达含义。面试领域的回答思路使用 `.interview-answer` 组件：有先后关系的内容使用流程型列表，并列检查面使用维度型列表，观点题先给核心结论再列支撑依据；节点数量由内容决定，说明保持简短。需要复杂图表时使用受控的 PNG、JPEG 或 SVG 文件；引入新的渲染能力属于依赖和主题变更，需单独设计与完整回归。

### 结构变更联动

- 新增普通页面：创建 Markdown、加入 `nav`、补充必要交叉链接，严格构建后运行 `tools/check-content.ps1`。
- 新增知识领域：使用 `docs/<domain>/index.md` 作为总览和分组首项，并同步首页、正式导航和搜索入口。
- 增删或重命名领域分类：同步领域总览、首页入口、`mkdocs.yml` 和全部入站链接，再运行全站内容检查。
- 移动或重命名 H2：保留原锚点；必须换锚点时同步站内链接。
- 添加资源：确认文件进入 `docs/assets/`、链接使用相对路径且构建产物可访问。

## 导航、搜索与主题覆盖

### 主题与导航基线

Material 当前启用：

- 中文界面、自定义 SVG favicon 和固定 `slate` 深色方案。
- 固定顶部标签、分节导航、面包屑、返回顶部和页脚前后导航。
- 搜索建议、高亮与分享，代码复制及页面编辑入口。
- 桌面端领域化左栏和跟随滚动的右侧目录；移动端使用同层级的 Material 原生抽屉。

`font: false` 禁用远程字体，字体栈由 `docs/assets/stylesheets/extra.css` 控制。

`navigation.indexes` 将领域总览识别为分组索引，`theme.custom_dir: overrides` 启用项目模板覆盖。`overrides/partials/nav-item.html` 基于 Material 9.7.7：

- 首页只展示可直接访问的知识领域，不展示领域内部分类。
- 进入任一领域后，领域标题为非链接标识，并动态显示当前领域名称。
- 标题下依次显示该领域的独立总览和主题页面；实际数量必须与当前导航和领域总览一致。
- 桌面端和移动抽屉保持相同导航逻辑。

领域名称和数量均来自 `mkdocs.yml` 的导航数据；模板、样式和检查脚本不写死具体领域。

该覆盖与主题版本绑定；升级 Material 时必须与上游 `partials/nav-item.html` 逐段比较。

`hooks/domain_navigation.py` 在 MkDocs 生成导航后按顶级分组调整前后页关系：

- 首页不参与前后翻页。
- 领域总览只有下一页，领域末页只有上一篇。
- 领域内部保持 `mkdocs.yml` 的正式导航顺序，不跨到相邻领域。
- 可见页脚与 HTML `rel=prev/next` 使用同一组构建结果。

新增领域时必须继续使用顶级导航分组，才能自动继承这一翻页边界。

### 显式导航与搜索

`mkdocs.yml` 的 `nav` 是正式导航清单。新增 Markdown 未加入 `nav` 时，`validation.nav.omitted_files: warn` 会在严格构建中转为失败。

首页负责选择知识领域，领域页负责内部导航。新增领域时，总览作为分组首项；未形成完整内容的领域不进入正式导航。

搜索插件同时配置 `zh` 与 `en`。搜索索引由构建生成在 `site/search/search_index.json`，不得手工修改。修改导航、标题、锚点或关键词后，应使用代表关键词复查搜索结果。

### Markdown 与链接校验

当前启用告示块、属性列表、Markdown-in-HTML、增强代码围栏、代码高亮和目录永久链接。删除扩展前必须搜索其语法使用情况。

导航遗漏、文件不存在、锚点不存在、绝对链接和不可识别链接均按 `warn` 校验；结合 `strict: true`，任何此类警告都会使构建失败。

## 本地构建与基础检查

### 预览与严格构建

在项目根目录启动预览：

```powershell
powershell -ExecutionPolicy Bypass -File .\preview.ps1
```

脚本会在缺少 `.venv` 时创建环境、安装固定依赖，并固定在 `http://127.0.0.1:8000/` 启动开发服务器。任一原生命令返回非零退出码时，脚本会立即报告失败阶段并以该退出码结束。`preview.ps1` 不提供端口参数；8000 端口被占用时，应停止占用进程，或直接使用其他端口启动 MkDocs：

```powershell
.\.venv\Scripts\python.exe -m mkdocs serve --dev-addr 127.0.0.1:<PORT>
```

提交前执行：

```powershell
.\.venv\Scripts\python.exe -m mkdocs build --strict
```

只有命令退出码为 0，才表示配置、导航和链接检查通过。构建结果写入 `site/`，不得提交。

### 全站内容冒烟检查

`tools/check-content.ps1` 面向所有知识领域，递归检查 `docs/**/*.md`：

- 所有页面具有非空的 `title` 和 `description`，领域总览还具有 `icon`。
- 自动发现一级知识领域，确认每个领域至少包含一个主题页。
- 站点首页覆盖全部领域入口，领域总览覆盖各自的全部主题页。
- 导航模板与主题样式通过导航数据动态显示当前领域名称，不包含具体领域名常量。
- 每个页面在代码围栏之外恰好包含一个 H1。
- 已设置的显式锚点格式合法，并且在同一页面内不重复。
- HTML 注释中的链接、标题和锚点不计入正文，未闭合的 HTML 注释会使检查失败。
- 构建后的搜索索引是有效 JSON，且每个 Markdown 页面都有对应入口。

脚本会动态输出领域、主题页和页面总数，但不会因主题页数量或单页行数直接失败。导航遗漏、链接与锚点目标不存在和文件缺失继续由 MkDocs 严格构建检查，不在脚本中重复实现。普通文字修改只需严格构建；新增、删除或重命名页面，或修改标题、显式锚点、导航、搜索时，严格构建后再运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\check-content.ps1
```

脚本默认读取 `site/`。预览占用默认目录或使用临时构建目录时，通过参数指定构建结果：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\check-content.ps1 -SiteDir <TEMP_SITE_DIR>
```

内容检查只作为本地提交前校验，不在 GitHub Actions 中执行；Front Matter 校验采用当前约定的受限格式，不进行完整 YAML 语义解析。

## 依赖升级

依赖、主题模板和 GitHub Actions 升级会同时影响构建环境、主题覆盖或发布流程，必须保留可回退提交并完成对应验证。

升级时：

1. 阅读 MkDocs、Material 和相关 Actions 的发行说明与安全公告。
2. 更新固定版本并重新创建或刷新 `.venv`。
3. 执行严格构建；页面结构、导航、锚点或搜索受影响时再运行 `tools/check-content.ps1`。
4. 检查首页、总览页、分类页、搜索、链接、固定深色主题和移动端。
5. 将 `overrides/partials/nav-item.html` 与新版本上游模板逐段比较。
6. 推送后确认 Actions 与 Pages，不以本地安装成功代替兼容性验证。

本项目已验证 MkDocs 1.6.1 与 Material 9.7.7。MkDocs 2.x 或更换生成器应作为单独迁移处理，不执行无评估的 `pip install --upgrade`。

Material 9.7.7 构建时可能输出 MkDocs 2.0 兼容性提示；该提示不是本项目导航或链接 warning，严格构建仍可正常返回 0。不要仅为消除提示解除版本固定。

## GitHub Actions 与发布

### 工作流行为

`.github/workflows/pages.yml` 的 `Build and deploy notes` 工作流支持：

- Pull Request 指向 `main`：安装固定依赖并严格构建，不上传或部署 Pages。
- 推送到 `main`：严格构建、配置 Pages、上传 `site/` artifact 并部署。
- `workflow_dispatch`：允许手动触发完整构建与部署。

构建作业使用 Ubuntu、Python 3.12、`actions/checkout@v6`、`actions/setup-python@v6`、`actions/configure-pages@v5` 和 `actions/upload-pages-artifact@v4`；部署作业使用 `actions/deploy-pages@v4`。

工作流仅授予构建所需的 `contents: read`，部署作业单独获得 `pages: write` 和 `id-token: write`。并发组为 `pages`，新运行会取消同组中仍在进行的旧工作流运行，包括尚未完成的构建或部署。

CI 根据仓库所有者和仓库名设置项目站点 `SITE_URL`，并注入仓库地址和 `edit/main/docs/` 编辑入口。仓库改为用户站点或默认分支变化时，必须同步这些值。

### 发布流程与验证

发布前：

1. 查看 Git 状态和最终差异，确认不包含生成目录、临时文件或敏感信息。
2. 执行与变更范围匹配的本地构建、内容检查和人工验收。

推送后必须确认 Actions 构建和部署作业成功，并在线抽查首页、各领域总览、代表主题页、锚点、搜索和 404 页面。部署失败时先定位失败步骤，不通过重复推送掩盖问题。

GitHub Pages 必须在 **Settings → Pages → Build and deployment** 中选择 **GitHub Actions**。工作流原理和平台配置参考 [Using custom workflows with GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)。

### 发布安全边界

- 公开仓库、Pages 站点和 Actions 日志是不同的可见面，但都不得出现凭据或未脱敏信息。
- 不提交 `.env`、私钥、证书、Token、`credentials.json`、`.venv/` 或 `site/`；以 `.gitignore` 为准。
- 示例只使用占位符，截图和日志检查用户名、绝对路径、内部域名、客户信息和业务数据。
- 发现 Secret 泄露时立即撤销或轮换凭据，再清理历史并复查 Actions 日志；仅删除当前文件不足以消除风险。
- Actions 使用最小权限，第三方 Action 固定明确版本；重大升级按依赖升级流程验证。

## 样式维护与视觉验收

自定义样式集中在 `docs/assets/stylesheets/extra.css`。调整布局或主题时必须同时检查首页、总览页、分类页、移动抽屉和键盘焦点，不能只验证当前桌面页面。

### 布局基线

- 首页知识领域卡片在 45em 及以上视口固定为两列，奇数项在末行左对齐；低于 45em 时切换为单列。
- 全局 `.md-grid` 以 `86rem` 为最大宽度，并动态扣除纵向滚动条占用宽度；首页与可滚动页面的顶栏、主布局和左侧导航必须保持相同左侧基准。
- 正文最大宽度保持 `52rem`，左侧导航宽度和内容层级不随右侧目录调整而改变。
- 桌面端从 `76.25em` 断点起，右侧目录宽度使用 `clamp(9.5rem, 16.8vw, 14.5rem)`，右边缘保持稳定。
- 桌面目录链接字号为 `0.64rem`，目录标题为 `0.68rem`；平板和移动端保留主题原有布局。
- 长目录标题自然换行，不截断、不覆盖正文，也不得产生横向滚动。
- 固定 `slate` 深色方案下，文字、链接、活动项、边框和代码块必须保持足够对比。

当前紧凑布局清除了 `.md-main__inner` 的默认上边距，因此 `extra.css` 同时维护正文锚点的 `scroll-margin-top`：移动端和平板对应顶部栏，桌面端对应顶部栏与标签栏总高度。改变固定栏高度时必须同步验证目录点击后的 URL、当前高亮项和标题位置，避免高亮落后一个章节或标题被遮挡。

### 响应式与交互验收

至少检查 320px、390px、1024px、1220px、1440px 和 1912px 视口，并确认：

- 双层顶栏、面包屑、左右侧栏和正文间距协调。
- 首页左栏只出现当前导航配置的知识领域，每个入口均可聚焦并可直接访问。
- 每个领域均显示来自导航数据的非链接领域标题和独立总览项，主题数量与当前导航及领域总览一致。
- 当前左栏分类和右侧目录条目高亮正确。
- 移动抽屉无无效展开按钮、点击死区、内容溢出或层级重复。
- 长代码、表格、链接和图片不会导致页面异常横向滚动。
- 搜索、领域内上下页导航、代码复制、返回顶部和键盘导航正常，领域边界不得出现跨领域链接。

主题升级或修改覆盖模板后，还要检查自定义选择器是否匹配新 DOM，并与上游导航模板比较差异。

## 验证基线与故障排查

### 通用验证底线

- 所有变更执行 `git diff --check`，并检查最终差异与修改范围。
- 影响站点源码、配置或构建链路的变更执行 MkDocs 严格构建。
- 页面结构、导航或搜索变化时运行 `tools/check-content.ps1`；样式和发布流程变化时分别执行视觉回归或发布验证。
- 确认 `site/`、`.venv/`、缓存、临时文件和敏感信息未进入提交范围。

### 故障定位

| 现象 | 优先检查 |
| --- | --- |
| 页面未进入导航 | `mkdocs.yml` 的 `nav`、缩进和文件路径 |
| 锚点失效或目录高亮错误 | 显式 ID、链接大小写、`scroll-margin-top`、严格构建首条警告 |
| 搜索结果未更新 | 是否重新构建、浏览器缓存、搜索索引内容 |
| CSS 修改无效 | 强制刷新、`extra_css` 引用、选择器与当前 DOM |
| 本地正常而 Pages 资源丢失 | `SITE_URL`、仓库子路径、是否使用根路径链接 |
| Actions 构建失败 | 依赖安装和严格构建的第一条确定性错误 |
| Pages 配置或 artifact 失败 | Pages Source、步骤条件、`site/` 路径和上传结果 |
| 部署权限不足 | `pages: write`、`id-token: write`、环境和组织策略 |

排障时先稳定复现，再读取第一条确定性错误并做最小修复；不要同时修改依赖、配置、样式和内容。

### 官方资料

- [MkDocs 官方文档](https://www.mkdocs.org/)
- [Material for MkDocs 入门](https://squidfunk.github.io/mkdocs-material/getting-started/)
- [Material for MkDocs：MkDocs 2.0 兼容性说明](https://squidfunk.github.io/mkdocs-material/blog/2026/02/18/mkdocs-2.0/)
- [GitHub Actions 部署与 environment](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments)
- [GitHub Secret scanning](https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning)

外部平台版本、权限和界面会变化；执行依赖升级或发布故障处理时，以当日官方文档和仓库界面为准。
