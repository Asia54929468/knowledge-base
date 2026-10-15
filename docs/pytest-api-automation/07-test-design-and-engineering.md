---
title: 测试设计与工程化边界
description: 处理接口测试的场景覆盖、状态恢复、资源缓存、重试、并行和扩展时机
---

# 测试设计与工程化边界

<div class="section-lead">框架优先实现可稳定复用的共性能力；业务状态、缓存、重试和并行必须根据目标系统的真实约束逐项引入。</div>

## 测试设计 { #test-design }

### 场景覆盖

每个接口至少从以下角度选择与风险匹配的场景：

- 正常输入和主要成功分支。
- 必填项缺失、空值、类型错误和边界值。
- 未认证、Token 失效和权限不足。
- 路径参数不存在、格式错误或包含特殊字符。
- 重复请求、幂等性和状态冲突。
- 非 JSON 响应、超时和依赖服务异常。

不要为了“覆盖模板”机械生成无业务价值的组合。YAML 适合多组同构输入；存在分支、轮询、恢复或多接口协作的流程应留在 Python 中。

### 断言顺序

推荐从外到内：

1. HTTP 状态码。
2. 响应是否能按预期格式解析。
3. 通用业务状态。
4. 关键字段存在性和类型。
5. 与本场景直接相关的业务值或状态变化。

失败信息不得直接拼接完整敏感响应；需要上下文时依赖脱敏日志。

## 独立性与状态恢复 { #state-cleanup }

修改配置、密码、权限或资源状态时，恢复动作必须在断言失败后仍能执行：

```python
from common.logger import get_logger


cleanup_logger = get_logger("testcase.cleanup")
original_value = api.get_setting().json()["value"]
change_attempted = False
test_error: BaseException | None = None

try:
    # 请求一经发出就可能已经改变服务端状态，不能只依赖响应是否成功。
    change_attempted = True
    response = api.update_setting("temporary-value")
    assert_status_code(response, 200)
except BaseException as error:
    test_error = error
    raise
finally:
    if change_attempted:
        try:
            restore_response = api.update_setting(original_value)
            assert_status_code(restore_response, 200)
        except BaseException as restore_error:
            if test_error is None:
                # 主体成功时，恢复失败本身必须使测试失败。
                raise

            # 主体已经失败时，只追加恢复诊断，不能替换原始失败。
            try:
                cleanup_logger.error(
                    "测试失败后恢复原状态时再次发生异常：%s",
                    type(restore_error).__name__,
                    exc_info=restore_error,
                )
            except Exception:
                pass
```

代码在调用修改接口前就标记“已尝试变更”，因此超时、非 2xx 或响应解析失败后仍会尝试恢复。主体成功但恢复失败时测试失败；主体和恢复同时失败时保留主体异常，并把恢复异常作为附加诊断。多个测试共享同一种准备与恢复逻辑时，应改为 yield Fixture；只服务于一个场景时保留 `try/finally` 更直观。

破坏性测试必须使用 `@pytest.mark.destructive`，并由 `conftest.py` 同时检查环境名与 `allow_destructive` 开关。

## 通用资源缓存 { #shared-resource-cache }

现有项目中“缓存 Token 和公共资源 ID”的思路值得保留，但资源 ID 获取方式属于业务。只有满足以下条件时才扩展 Manager：

- 多个测试反复依赖同一资源。
- 获取资源需要额外接口调用或明显耗时。
- 资源在会话期间稳定，且缓存不会破坏测试隔离。
- 提供 `force_refresh` 和 `clear`，失效后能主动更新。

最小模式：

```python
class ResourceManager:
    """缓存获取成本较高且可安全复用的通用资源 ID。"""

    def __init__(self, loader):
        """注入实际项目负责获取资源 ID 的函数。"""

        self.loader = loader
        self._resource_id = None

    def get_resource_id(self, *, force_refresh=False):
        """返回缓存的资源 ID，或按需重新加载。"""

        # 首次访问或显式刷新时才调用外部资源加载逻辑。
        if self._resource_id is None or force_refresh:
            self._resource_id = self.loader()
        return self._resource_id

    def clear(self):
        """清除缓存，使下次访问重新加载资源。"""

        self._resource_id = None
```

公共资源缓存只封装资源加载、复用与清理，不把“桌面”“订单”或“租户”等具体业务流程写入框架层。

## 重试边界 { #retry-boundaries }

自动重试只适合短暂、可恢复且重复执行安全的失败，例如连接重置、明确的限流响应或最终一致性轮询。

不应自动重试：

- 断言失败或业务规则失败。
- 登录凭据错误、权限不足等确定性问题。
- 创建、扣费、删除等非幂等操作。
- 可能掩盖服务不稳定的所有失败。

框架默认不内置重试。项目确有需要时，应明确可重试方法、状态码、次数、退避和日志。

## 并行执行前置条件 { #parallel-execution }

引入 pytest-xdist 前先确认：

- 测试账号、数据和资源是否能够隔离。
- session Fixture 是否允许每个 worker 独立初始化。
- 日志文件和报告是否会发生写入冲突。
- 状态恢复是否会与其他 worker 互相覆盖。
- Manager 缓存是否只在当前进程内有效。

并行是性能优化，不是基础框架默认能力。

## 扩展模块的触发条件 { #extension-triggers }

| 模块 | 何时增加 |
| --- | --- |
| Schema / 数据模型 | 接口契约稳定，字段多且手写结构断言重复明显 |
| 数据库工具 | 必须验证持久化结果，且 API 无法提供可靠观察点 |
| 消息队列工具 | 业务结果通过异步消息产生，需要消费或追踪事件 |
| 重试工具 | 已识别短暂故障，并明确幂等与退避策略 |
| 报告插件 | 团队确实需要归档、趋势或外部展示 |
| 自定义异常 | 多个调用方需要稳定地区分配置、数据和协议错误 |
