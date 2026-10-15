---
title: 数据驱动、断言与测试实现
description: 用 YAML、数据加载器、公共断言和简洁 testcase 组成完整的数据驱动接口测试链路
---

# 数据驱动、断言与测试实现

<div class="section-lead">YAML 提供输入与预期，data.py 校验结构，testcase 显式解析配置键并通过公共断言验证 Response。</div>

## 测试数据：`testdata/example.yaml` { #example-testdata }

```yaml
test_login:
  - title: 登录成功
    request:
      # *_key 表示从运行配置取值，不把真实凭据写入测试数据。
      username_key: username
      password_key: password
    expected:
      status_code: [200]
      code: 200
      token_required: true

  - title: 密码错误
    request:
      username_key: username
      password: wrong-password
    expected:
      status_code: [400, 401]
      token_required: false

  - title: 用户名为空
    request:
      username: ""
      password: any-password
    expected:
      status_code: [400]
      token_required: false

test_get_item:
  - title: 查询普通对象
    request:
      item_id: demo-item-001
    expected:
      status_code: [200]
      required_fields:
        - id
```

顶层键对应测试方法或场景组；每条用例固定包含 `title`、`request` 和 `expected`。具体状态码、业务码和字段名应按新项目协议替换。

## 数据加载：`common/data.py` { #data-loader }

```python
"""读取 YAML 测试数据，并校验参数化场景的基础结构。"""

from pathlib import Path
from typing import Any

import yaml


BASE_DIR = Path(__file__).resolve().parents[1]
TESTDATA_DIR = BASE_DIR / "testdata"


def load_yaml(file_path: str) -> dict[str, Any]:
    """从 testdata 目录读取 YAML，并保证根节点是字典。"""

    path = TESTDATA_DIR / file_path
    if not path.exists():
        raise FileNotFoundError(f"测试数据文件不存在：{path}")

    with path.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file) or {}

    if not isinstance(data, dict):
        raise TypeError(f"{file_path} 的根节点必须是对象")

    return data


def load_data(
    file_path: str,
    case_name: str,
) -> list[dict[str, Any]]:
    """读取指定场景组，并校验每条用例的必要字段和类型。"""

    data = load_yaml(file_path)
    cases = data.get(case_name)

    if cases is None:
        raise KeyError(
            f"数据文件 {file_path} 中不存在场景组：{case_name}"
        )
    if not isinstance(cases, list):
        raise TypeError(
            f"{file_path} 中的 {case_name} 必须是列表"
        )

    # 在参数化收集阶段尽早报告结构错误，避免执行时才难以定位。
    for index, case in enumerate(cases):
        if not isinstance(case, dict):
            raise TypeError(
                f"{case_name}[{index}] 必须是对象"
            )

        missing = {
            "title",
            "request",
            "expected",
        } - case.keys()
        if missing:
            raise ValueError(
                f"{case_name}[{index}] 缺少字段：{sorted(missing)}"
            )

        if not isinstance(case["title"], str):
            raise TypeError(
                f"{case_name}[{index}].title 必须是字符串"
            )
        if not isinstance(case["request"], dict):
            raise TypeError(
                f"{case_name}[{index}].request 必须是对象"
            )
        if not isinstance(case["expected"], dict):
            raise TypeError(
                f"{case_name}[{index}].expected 必须是对象"
            )

    return cases
```

`data.py` 不读取运行配置，也不把 `username_key` 自动替换成敏感值。显式解析发生在 testcase，使配置值的来源和使用位置可追踪，并避免数据层与运行环境耦合。

## 公共断言：`common/assertion.py` { #common-assertions }

```python
"""提供不泄露完整响应内容的通用分层断言。"""

from collections.abc import Collection, Mapping
from typing import Any

from requests import Response


def assert_status_code(
    response: Response,
    expected: int | Collection[int],
) -> None:
    """断言 HTTP 状态码属于允许范围。"""

    allowed = (
        {expected}
        if isinstance(expected, int)
        else set(expected)
    )
    assert response.status_code in allowed, (
        f"HTTP 状态码不符合预期，"
        f"期望范围：{sorted(allowed)}，"
        f"实际：{response.status_code}"
    )


def assert_business_code(
    data: Mapping[str, Any],
    expected: Any,
    *,
    field: str = "code",
) -> None:
    """断言响应包含指定业务字段且值符合预期。"""

    assert field in data, f"响应中缺少业务字段：{field}"
    assert data[field] == expected, (
        f"业务字段 {field} 与预期不一致"
    )


def assert_has_fields(
    data: Mapping[str, Any],
    *fields: str,
) -> None:
    """断言响应包含全部必要字段。"""

    missing = [field for field in fields if field not in data]
    assert not missing, f"响应中缺少字段：{missing}"


def assert_field_type(
    data: Mapping[str, Any],
    field: str,
    expected_type: type,
) -> None:
    """断言响应字段存在且类型正确。"""

    assert field in data, f"响应中缺少字段：{field}"
    assert isinstance(data[field], expected_type), (
        f"字段 {field} 类型错误，"
        f"期望：{expected_type.__name__}"
    )
```

断言失败信息只描述结构和预期，不拼接完整响应、Token、密码或 Cookie。项目需要查看响应时，由已经脱敏的 HTTP 日志提供上下文。

## 测试示例：`testcase/test_example.py` { #example-testcase }

```python
"""演示 YAML 参数化、Fixture 注入、日志登记和分层断言。"""

from typing import Any

import pytest

from api.example_api import ExampleApi
from common.assertion import (
    assert_business_code,
    assert_field_type,
    assert_has_fields,
    assert_status_code,
)
from common.data import load_data


def _resolve_request(
    request_data: dict[str, Any],
    settings: dict[str, Any],
) -> dict[str, Any]:
    """把请求数据中的配置键引用解析为实际运行配置值。"""

    resolved = dict(request_data)

    # 只有显式使用 *_key 的字段才读取配置，普通值保持原样。
    for field in ("username", "password"):
        key_field = f"{field}_key"
        if key_field not in resolved:
            continue

        config_key = resolved.pop(key_field)
        if config_key not in settings:
            raise KeyError(f"配置中不存在键：{config_key}")
        resolved[field] = settings[config_key]

    return resolved


class TestExampleApi:
    """验证参数化登录、鉴权查询和路径参数三类调用。"""

    @pytest.mark.parametrize(
        "case",
        load_data("example.yaml", "test_login"),
        ids=lambda case: case["title"],
    )
    def test_login(
        self,
        case: dict[str, Any],
        settings: dict[str, Any],
        example_api: ExampleApi,
        log_http,
    ) -> None:
        """按 YAML 场景验证登录接口的成功与失败分支。"""

        request_data = _resolve_request(
            case["request"],
            settings,
        )
        expected = case["expected"]

        response = example_api.login(**request_data)
        # 先登记响应，后续断言失败时 Fixture 才能自动补记详情。
        log_http(response, title=case["title"])

        assert_status_code(
            response,
            expected["status_code"],
        )

        result = response.json()
        assert isinstance(result, dict), "响应 JSON 必须是对象"

        if "code" in expected:
            assert_business_code(result, expected["code"])

        if expected.get("token_required"):
            assert_has_fields(result, "token")
            assert_field_type(result, "token", str)

    def test_get_current_user(
        self,
        authenticated_api: ExampleApi,
        log_http,
    ) -> None:
        """使用认证 Fixture 验证当前用户查询。"""

        response = authenticated_api.get_current_user()
        log_http(response, title="查询当前用户")

        assert_status_code(response, 200)
        result = response.json()
        assert isinstance(result, dict), "响应 JSON 必须是对象"
        assert_has_fields(result, "id")

    @pytest.mark.parametrize(
        "case",
        load_data("example.yaml", "test_get_item"),
        ids=lambda case: case["title"],
    )
    def test_get_item(
        self,
        case: dict[str, Any],
        authenticated_api: ExampleApi,
        log_http,
    ) -> None:
        """验证路径参数替换，并演示手动开启详细日志。"""

        expected = case["expected"]
        response = authenticated_api.get_item(
            item_id=case["request"]["item_id"],
        )
        log_http(
            response,
            title=case["title"],
            details=True,
        )

        assert_status_code(
            response,
            expected["status_code"],
        )
        result = response.json()
        assert isinstance(result, dict), "响应 JSON 必须是对象"
        assert_has_fields(
            result,
            *expected.get("required_fields", []),
        )
```

`test_example.py` 覆盖 YAML 参数化登录、鉴权查询和路径参数查询三类调用。增加业务接口时应替换路径与字段，并继续保持请求映射、场景编排和断言职责分离。
