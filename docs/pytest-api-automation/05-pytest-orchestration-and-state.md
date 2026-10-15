---
title: pytest 编排与状态管理
description: 使用 Manager、Fixture 和 pytest Hook 管理认证缓存、日志补记、资源释放与执行安全
---

# pytest 编排与状态管理

<div class="section-lead">把昂贵状态交给 Manager，把创建与清理交给 Fixture，把失败上下文交给 Hook，testcase 只保留场景本身。</div>

## 认证缓存：`common/manager.py` { #auth-manager }

```python
"""缓存最小认证状态，并提供 Token 的获取、刷新和清理能力。"""

from api.example_api import ExampleApi


class AuthManager:
    """管理可在测试会话内复用的登录状态。"""

    def __init__(
        self,
        api: ExampleApi,
        *,
        username: str,
        password: str,
    ) -> None:
        """保存认证依赖，但不在构造阶段访问真实接口。"""

        self.api = api
        self.username = username
        self.password = password
        self._token: str | None = None

    def get_token(
        self,
        *,
        force_refresh: bool = False,
    ) -> str:
        """返回缓存的 Token，或按需重新登录并刷新 Token。"""

        # 默认复用已校验 Token；强制刷新先清除旧值，失败后不能回退使用。
        if self._token is not None and not force_refresh:
            return self._token
        if force_refresh:
            self._token = None

        response = self.api.login(
            username=self.username,
            password=self.password,
        )
        response.raise_for_status()

        # 缓存前先验证最小协议，避免把无效响应传播给其他测试。
        result = response.json()
        if not isinstance(result, dict):
            raise TypeError("登录响应必须是 JSON 对象")
        token = result.get("token")
        if not isinstance(token, str) or not token.strip():
            raise RuntimeError("登录响应中缺少有效 token")

        # 只缓存后续请求必需的 Token，不延长完整登录响应的驻留时间。
        self._token = token
        return token

    def clear_auth(self) -> None:
        """清除会话内缓存的 Token。"""

        self._token = None
```

Manager 只缓存获取成本较高且能安全复用的最小状态。当前实现仅保留 Token，不保存完整登录响应，也不把项目特有业务码写入公共状态管理模块。

## pytest 公共能力：`testcase/conftest.py` { #pytest-conftest }

```python
"""集中编排 pytest 选项、Fixture、Hook、资源清理和执行安全。"""

import logging
from collections.abc import Callable, Generator
from typing import Any

import pytest
from requests import Response

from api.example_api import ExampleApi
from common.config import load_config
from common.http_client import HttpClient
from common.http_logging import (
    format_http_details,
    log_http_response,
)
from common.logger import get_logger, setup_logging
from common.manager import AuthManager


logger = get_logger("testcase")
http_logger = get_logger("http")
LogHttp = Callable[..., None]


def pytest_addoption(parser: pytest.Parser) -> None:
    """注册环境选择和文件日志控制选项。"""

    parser.addoption(
        "--env",
        action="store",
        default=None,
        help="覆盖 config/config.yaml 中的 env",
    )
    parser.addoption(
        "--no-log-file",
        action="store_true",
        default=False,
        help="不生成本地日志文件，日志由 pytest 捕获并进入 HTML 报告",
    )


def pytest_configure(config: pytest.Config) -> None:
    """初始化日志，并按命令行开关控制是否写入本地文件。"""

    # 默认 --no-log-file 仍保留日志事件，交给 pytest 和 HTML 报告捕获。
    setup_logging(
        write_to_file=not config.getoption("--no-log-file"),
    )


def pytest_runtest_setup(item: pytest.Item) -> None:
    """在执行前阻止破坏性测试进入生产或未授权环境。"""

    if item.get_closest_marker("destructive") is None:
        return

    settings = load_config(
        env_name=item.config.getoption("--env"),
    )
    env_name = str(settings["env"]).strip().lower()
    blocked_envs = {"prod", "production"}

    # 只有非生产环境显式使用布尔值 True 时才允许执行。
    if (
        env_name in blocked_envs
        or settings["allow_destructive"] is not True
    ):
        pytest.fail(
            "当前环境禁止执行 destructive 测试",
            pytrace=False,
        )


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(
    item: pytest.Item,
    call: pytest.CallInfo[Any],
) -> Generator[None, None, None]:
    """把各执行阶段的报告保存到测试节点，供 Fixture teardown 使用。"""

    outcome = yield
    # yield 之后 pytest 已生成报告，此时再按 setup/call/teardown 分类保存。
    report = outcome.get_result()
    setattr(item, f"rep_{report.when}", report)


@pytest.fixture(scope="session")
def settings(pytestconfig: pytest.Config) -> dict[str, Any]:
    """按命令行环境选项加载一次运行配置。"""

    return load_config(
        env_name=pytestconfig.getoption("--env"),
    )


@pytest.fixture(scope="session")
def http_client(
    settings: dict[str, Any],
) -> Generator[HttpClient, None, None]:
    """提供会话级普通客户端，并在结束时关闭 Session。"""

    client = HttpClient(
        base_url=settings["base_url"],
        timeout=settings["timeout"],
        verify_ssl=settings["verify_ssl"],
    )
    yield client
    # yield 后执行统一清理，即使用例失败也会关闭连接。
    client.close()


@pytest.fixture(scope="session")
def example_api(http_client: HttpClient) -> ExampleApi:
    """构造使用普通客户端的 API Object。"""

    return ExampleApi(http_client)


@pytest.fixture(scope="session")
def auth_manager(
    example_api: ExampleApi,
    settings: dict[str, Any],
) -> Generator[AuthManager, None, None]:
    """创建认证管理器，并在会话结束时清除认证缓存。"""

    manager = AuthManager(
        example_api,
        username=str(settings.get("username", "")),
        password=str(settings.get("password", "")),
    )
    yield manager
    manager.clear_auth()


@pytest.fixture(scope="session")
def token(auth_manager: AuthManager) -> str:
    """获取可由认证客户端复用的会话级 Token。"""

    return auth_manager.get_token()


@pytest.fixture(scope="session")
def authenticated_client(
    settings: dict[str, Any],
    token: str,
) -> Generator[HttpClient, None, None]:
    """提供已设置 Token 的客户端，并在结束时关闭 Session。"""

    client = HttpClient(
        base_url=settings["base_url"],
        timeout=settings["timeout"],
        verify_ssl=settings["verify_ssl"],
        token=token,
    )
    yield client
    client.close()


@pytest.fixture(scope="session")
def authenticated_api(
    authenticated_client: HttpClient,
) -> ExampleApi:
    """构造使用认证客户端的 API Object。"""

    return ExampleApi(authenticated_client)


@pytest.fixture
def log_http(request: pytest.FixtureRequest) -> Generator[LogHttp, None, None]:
    """记录 HTTP 摘要，并在用例失败后按需自动补记详情。"""

    # 每个测试只保留最近一次登记的响应，供失败诊断使用。
    recorded_response: Response | None = None
    recorded_title: str | None = None
    details_logged = False
    recorded_max_body_chars = 10_000

    def _report_logging_error(stage: str, error: Exception) -> None:
        """尽力记录日志辅助异常，Handler 再次失败时保持测试结果不变。"""

        try:
            logger.error(
                "HTTP 日志辅助异常（%s）：%s [%s]",
                stage,
                request.node.nodeid,
                type(error).__name__,
            )
        except Exception:
            pass

    def _log(
        response: Response,
        *,
        title: str | None = None,
        details: bool = False,
        include_headers: bool = False,
        max_body_chars: int = 10_000,
    ) -> None:
        """输出本次响应日志，并保存失败补记所需的上下文。"""

        nonlocal recorded_response
        nonlocal recorded_title
        nonlocal details_logged
        nonlocal recorded_max_body_chars

        # 先保存上下文；即使即时日志失败，断言失败后仍可尝试补记详情。
        recorded_response = response
        recorded_title = title
        details_logged = False
        recorded_max_body_chars = max_body_chars

        try:
            log_http_response(
                response,
                title=title,
                details=details,
                include_headers=include_headers,
                max_body_chars=max_body_chars,
            )
        except Exception as error:
            _report_logging_error("即时记录", error)
        else:
            # DEBUG 详情确实启用并成功返回后才去重，避免遗漏失败诊断。
            details_logged = details and http_logger.isEnabledFor(logging.DEBUG)

    yield _log

    try:
        report = getattr(request.node, "rep_call", None)
        # 仅 call 阶段失败且未手动输出详情时，补记最后一次响应。
        if (
            report is not None
            and report.failed
            and recorded_response is not None
            and not details_logged
        ):
            detail_message = format_http_details(
                recorded_response,
                title=f"{recorded_title or 'HTTP 请求'} - 失败详情",
                include_headers=True,
                max_body_chars=recorded_max_body_chars,
            )
            logger.error(
                "用例执行失败：%s\n%s",
                request.node.nodeid,
                detail_message,
            )
    except Exception as error:
        # 日志辅助能力失败时只做尽力记录，不能覆盖原始测试失败。
        _report_logging_error("失败详情", error)
```

## `log_http` Fixture 的三种路径 { #log-http-fixture }

默认模式：

```python
log_http(response, title="登录成功")
```

立即记录一行摘要；如果后续断言失败，Fixture 在 teardown 阶段自动补记该响应的详情。

手动调试：

```python
log_http(
    response,
    title="登录调试",
    details=True,
    include_headers=True,
)
```

在 DEBUG 详情级别启用且输出成功后，将 `details_logged` 标记为真；即使用例随后失败，也不会重复输出相同详情。详情级别未启用或即时日志异常时不标记，失败后仍可尝试补记。

即时日志或 teardown 详情自身异常时，只尽力记录简短的日志处理错误，不中断 testcase，也不替换已经产生的原始失败。

## Fixture scope 与状态 { #fixture-scope-and-state }

- 配置、普通客户端、认证客户端、API Object 和 Token 缓存使用 session scope。
- `log_http` 保存单个测试最近一次登记的 Response，使用 function scope。
- Token 失效时由测试显式调用 `auth_manager.get_token(force_refresh=True)`。
- 只有跨多个测试重复使用且获取成本较高的前置资源，才值得加入 Manager。
- 状态修改后的恢复优先放在 yield Fixture；仅与单个场景强相关时使用 testcase 的 `finally`。
