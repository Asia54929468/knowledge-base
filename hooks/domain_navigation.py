"""将上一篇和下一篇限制在当前顶级知识领域内。"""

from __future__ import annotations

from mkdocs.structure.nav import Navigation, Section
from mkdocs.structure.pages import Page


def _top_level_section(page: Page | None) -> Section | None:
    """返回页面所属的顶级导航分组；顶级独立页面返回 None。"""
    if page is None or page.parent is None:
        return None

    section = page.parent
    while section.parent is not None:
        section = section.parent

    return section if isinstance(section, Section) else None


def on_nav(nav: Navigation, **_: object) -> Navigation:
    """移除首页和跨领域的前后页关系，同时保留领域内部顺序。"""
    for page in nav.pages:
        section = _top_level_section(page)

        # 首页等不属于知识领域的顶级页面不参与前后翻页。
        if section is None:
            page.previous_page = None
            page.next_page = None
            continue

        if _top_level_section(page.previous_page) is not section:
            page.previous_page = None
        if _top_level_section(page.next_page) is not section:
            page.next_page = None

    return nav
