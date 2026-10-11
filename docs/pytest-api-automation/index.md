---
title: 接口自动化
description: 使用 pytest、requests 和 PyYAML 搭建可维护的 Python 接口自动化测试框架
icon: material/api
---

# Python 接口自动化测试框架搭建手册

> 适用版本：Python 3.10+
>
> 核心技术：pytest、requests、PyYAML
>
> 用途：个人复习，以及从零搭建可维护的接口自动化项目。

<div class="section-lead">围绕框架设计、核心代码、测试实践和工程化维护组织内容。既可以按顺序搭建完整项目，也可以根据当前任务直接进入对应主题。</div>

## 主题导航

<div class="grid cards" markdown>

-   **设计原则与技术选型**

    明确框架目标、分层边界、核心依赖和扩展能力。

    [开始阅读 →](01-principles-and-stack.md)

-   **项目结构与执行链路**

    了解推荐目录、文件职责、架构分层和用例生命周期。

    [开始阅读 →](02-project-structure-and-flow.md)

-   **项目基础与配置管理**

    准备基础文件、环境配置和安全的配置加载方式。

    [开始阅读 →](03-foundation-and-configuration.md)

-   **HTTP、数据与断言**

    实现请求客户端、YAML 数据加载和公共断言。

    [开始阅读 →](04-http-data-and-assertions.md)

-   **日志、认证与 API 封装**

    建立脱敏日志、认证缓存、API Object 和登录测试数据。

    [开始阅读 →](05-logging-auth-and-api.md)

-   **Fixture 与测试示例**

    组合 pytest 公共能力，完成数据驱动和鉴权用例。

    [开始阅读 →](06-fixtures-and-test-examples.md)

-   **测试设计与项目搭建**

    规划场景、断言、状态清理、最小闭环和 CI 流程。

    [开始阅读 →](07-test-design-and-bootstrap.md)

-   **特色设计与工程化**

    处理缓存、加密、恢复、重试、并行和报告追溯。

    [开始阅读 →](08-reusable-patterns-and-engineering.md)

-   **命令、排障与验收**

    快速定位运行问题，复习关键设计并完成项目验收。

    [开始阅读 →](09-commands-troubleshooting-and-review.md)

</div>

!!! tip "阅读和搜索"
    左侧导航用于按框架搭建顺序阅读，右侧目录用于定位当前页面内容。需要快速查找实现时，可以直接搜索类名、fixture、marker 或命令。
