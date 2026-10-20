# Asia知识库

这是一个使用 MkDocs Material 构建的本地优先技术笔记网站。目前包含“软件测试”“接口自动化”“工作资源与技巧”和“测试工程师面试”四个独立知识领域，正文直接在 `docs/` 中维护。

## 文档导航

| 需要了解 | 阅读入口 |
| --- | --- |
| Codex 新会话接手规则 | [Codex 项目指令](AGENTS.md) |
| 当前未完成任务与异常接续 | [项目交接](HANDOFF.md) |
| 项目用途、本地运行和常用操作 | 本 README |
| 项目架构、技术机制和故障排查 | [知识库项目技术指南](TECHNICAL_GUIDE.md) |

网站正文以 `docs/` 为唯一日常维护来源；内容文件约束和核验方式见技术指南的[内容文件与构建约束](TECHNICAL_GUIDE.md#内容文件与构建约束)和[本地构建与基础检查](TECHNICAL_GUIDE.md#本地构建与基础检查)。

## 本地预览

在 Windows PowerShell 中进入本目录并执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\preview.ps1
```

首次运行会在本目录创建 `.venv`，并安装 `requirements.txt` 中固定的直接依赖版本。浏览器访问 `http://127.0.0.1:8000` 即可查看。

## 严格构建

```powershell
.\.venv\Scripts\python.exe -m mkdocs build --strict
```

生成结果位于 `site/`，该目录属于构建产物，不应提交到 Git。

## 添加新笔记

1. 在 `docs/` 下添加 Markdown 文件。
2. 每篇文章只使用一个一级标题，页面间使用相对 `.md` 链接。
3. 在 `mkdocs.yml` 的 `nav` 中加入页面。
4. 本地执行严格构建，再运行 `tools/check-content.ps1`，确认导航、链接、页面结构和搜索索引均正常。

新增知识领域时，还要同步领域总览、首页入口和动态导航标题；相关技术联动见技术指南的[导航、搜索与主题覆盖](TECHNICAL_GUIDE.md#导航搜索与主题覆盖)。

## GitHub 与 Pages

项目源码保存在 [Asia54929468/knowledge-base](https://github.com/Asia54929468/knowledge-base)。仓库内已经准备好 GitHub Pages 工作流：Pull Request 只验证构建，推送到 `main` 后自动发布。

GitHub 仓库的 **Settings → Pages → Build and deployment** 使用 **GitHub Actions**。构建和部署状态可在仓库的 **Actions** 页面查看。

