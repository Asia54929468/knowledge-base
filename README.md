# Asia知识库

这是一个使用 MkDocs Material 构建的本地优先技术笔记网站。软件测试内容按 7 个分类长页面组织，后续内容直接在 `docs/` 中维护。

## 文档导航

| 需要了解 | 阅读入口 |
| --- | --- |
| 当前进度、遗留任务和下一步 | [当前项目交接](HANDOFF.md) |
| 项目用途和常用操作 | 本 README |
| 架构、内容规范、Git/Pages、安全和排障 | [项目技术维护指南](TECHNICAL_GUIDE.md) |

切换会话时默认先读 `HANDOFF.md`。遇到具体维护问题时，再按其中的章节链接查阅技术指南，无需每次完整加载全部长期文档。

网站正文以 `docs/` 为唯一日常维护来源；内容结构和核验方式见技术指南的[内容结构与核验工具](TECHNICAL_GUIDE.md#11-内容结构与核验工具)。

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
4. 本地执行严格构建，确认链接、锚点和导航均无警告。

## GitHub 与 Pages

项目源码保存在 [Asia54929468/knowledge-base](https://github.com/Asia54929468/knowledge-base)。仓库内已经准备好 GitHub Pages 工作流：Pull Request 只验证构建，推送到 `main` 后自动发布。

GitHub 仓库的 **Settings → Pages → Build and deployment** 使用 **GitHub Actions**。构建和部署状态可在仓库的 **Actions** 页面查看。

