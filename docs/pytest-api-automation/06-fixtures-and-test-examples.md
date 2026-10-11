---
title: Fixture 与测试示例
description: pytest 公共 fixture、失败诊断和接口测试示例
---

# Fixture 与测试示例

## pytest 公共能力：`testcase/conftest.py`

```python
from collections.abc import Callable, Iterator
import logging

import pytest
from requests import Response

from api.example_api import AuthApi, ResourceApi
from common.auth import AuthManager
from common.config import SETTINGS
from common.http_client import HttpClient
from common.http_logging import format_details, log_response


logger = logging.getLogger("api_test.testcase")


def pytest_configure() -> None:
    # 小型项目用 basicConfig 即可；大型项目再切换为 logging.yaml。
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    )


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    report = outcome.get_result()
    # log_http fixture 在 teardown 时通过 rep_call 判断测试主体是否失败。
    setattr(item, f"rep_{report.when}", report)


@pytest.fixture
def log_http(request) -> Iterator[Callable[..., None]]:
    recorded: list[tuple[Response, str]] = []

    def _log(response: Response, *, title: str = "") -> None:
        log_response(response, title=title)
        recorded.append((response, title))

    yield _log

    try:
        report = getattr(request.node, "rep_call", None)
        if report is not None and report.failed:
            for response, title in recorded:
                logger.error(format_details(response, f"{title} - 失败详情"))
    except Exception:
        # 日志是辅助能力，不能用日志异常覆盖原始测试失败。
        logger.exception("生成失败详情时发生异常：%s", request.node.nodeid)


@pytest.fixture(scope="session")
def auth_manager() -> Iterator[AuthManager]:
    def login_action() -> dict:
        with HttpClient(
            SETTINGS.base_url,
            timeout=SETTINGS.timeout,
            verify_ssl=SETTINGS.verify_ssl,
        ) as client:
            response = AuthApi(client).login(
                SETTINGS.username,
                SETTINGS.password,
            )
            response.raise_for_status()
            result = response.json()
            if result.get("code") != SETTINGS.success_code:
                raise RuntimeError(f"测试账号登录失败：{result}")
            return result

    manager = AuthManager(
        login_action,
        # 按项目替换 Token 路径，例如 result["data"]["token"]。
        token_getter=lambda result: result.get("token", ""),
    )
    yield manager
    manager.clear()


@pytest.fixture(scope="session")
def auth_token(auth_manager: AuthManager) -> str:
    # session scope 减少重复登录；logout 测试必须使用独立 Token。
    return auth_manager.get_token()


@pytest.fixture
def http_client(auth_token: str) -> Iterator[HttpClient]:
    # 客户端使用 function scope，避免 Header 和 Session 在用例间污染。
    with HttpClient(
        SETTINGS.base_url,
        token=auth_token,
        timeout=SETTINGS.timeout,
        verify_ssl=SETTINGS.verify_ssl,
    ) as client:
        yield client


@pytest.fixture
def resource_api(http_client: HttpClient) -> ResourceApi:
    return ResourceApi(http_client)
```

## 测试示例：`testcase/test_example.py`

```python
from typing import Any

import pytest

from api.example_api import AuthApi, ResourceApi
from common.assertion import assert_business_code, assert_status
from common.config import SETTINGS
from common.data import case_id, load_cases
from common.http_client import HttpClient


def _resolve_login_request(case: dict[str, Any]) -> dict[str, str]:
    """把 YAML 中的 *_setting 引用解析为 Settings 的真实值。"""
    data = dict(case["request"])
    for field in ("username", "password"):
        setting_name = data.pop(f"{field}_setting", None)
        if setting_name:
            data[field] = getattr(SETTINGS, setting_name)
    return data


@pytest.mark.parametrize(
    "case",
    load_cases("auth/login.yaml", "login_cases"),
    ids=case_id,
)
def test_login(case: dict[str, Any], log_http) -> None:
    expected = case["expected"]

    # 登录场景使用独立无 Token 客户端，不污染共享认证状态。
    with HttpClient(
        SETTINGS.base_url,
        timeout=SETTINGS.timeout,
        verify_ssl=SETTINGS.verify_ssl,
    ) as client:
        response = AuthApi(client).login(**_resolve_login_request(case))

    log_http(response, title=case["title"])
    assert_status(response, expected["status_code"])

    result = response.json()
    assert_business_code(result, expected["business_code"])
    if expected.get("token_required"):
        assert result.get("token"), "登录成功但没有返回 Token"
    if message := expected.get("message_contains"):
        assert message in result.get("message", "")


@pytest.mark.smoke
def test_list_resources(resource_api: ResourceApi, log_http) -> None:
    response = resource_api.list(page=1)
    log_http(response, title="查询资源列表")

    assert_status(response, 200)
    result = response.json()
    assert_business_code(result, SETTINGS.success_code)
    assert isinstance(result.get("data"), list)  # 按项目替换响应字段。
```

这两个示例分别表达了“数据驱动的无鉴权测试”和“通过 fixture 注入鉴权 API”。创建、修改、删除等业务流程不应复制成大量模板，应按第 6 章的状态管理规则单独设计。
