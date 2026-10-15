---
title: 接口自动化
description: 基于 pytest、requests 和 YAML 数据驱动的接口自动化框架设计与工程实践
icon: material/api
---

# Python 接口自动化测试框架

<div class="section-lead">基于 pytest、requests 和 YAML 数据驱动，覆盖配置、请求、认证、断言、日志、报告与资源清理。</div>

> 适用版本：Python 3.10+
>
> 核心技术：pytest、requests、PyYAML、pytest-html
>
> 框架特征：分层设计、数据驱动、失败诊断、安全拦截与可重复执行。

## 主题导航 { #topic-navigation }

<div class="grid cards" markdown>

-   **1. 框架设计与项目结构**

    先理解分层、依赖方向、目录扩展规则和完整执行链路。

    [进入主题 →](01-framework-design-and-structure.md)

-   **2. 项目基础与配置管理**

    准备根目录文件，并让配置 YAML 与加载器形成闭环。

    [进入主题 →](02-foundation-and-configuration.md)

-   **3. HTTP 请求与 API Object**

    实现通用请求客户端，再用最小接口对象演示业务接入。

    [进入主题 →](03-http-and-api-object.md)

-   **4. 日志与失败诊断**

    保留摘要日志、手动详情、失败自动详情、去重和脱敏设计。

    [进入主题 →](04-logging-and-diagnostics.md)

-   **5. pytest 编排与状态管理**

    用 Manager、Fixture 和 Hook 管理认证、资源释放与安全边界。

    [进入主题 →](05-pytest-orchestration-and-state.md)

-   **6. 数据驱动、断言与测试实现**

    串起 YAML、数据加载、参数化测试、公共断言和接口调用。

    [进入主题 →](06-data-driven-assertions-and-tests.md)

-   **7. 测试设计与工程化边界**

    判断状态恢复、资源缓存、重试、并行和扩展模块何时需要。

    [进入主题 →](07-test-design-and-engineering.md)

-   **8. 运行、排障与验收**

    按固定步骤运行、定位问题、增加接口并检查框架质量。

    [进入主题 →](08-commands-troubleshooting-and-review.md)

</div>
