---
title: HTTP、数据与断言
description: 统一 HTTP 请求、YAML 测试数据加载和公共断言的实现方式
---

# HTTP、数据与断言

## 请求层：`common/http_client.py`

```python
import re
from typing import Any
from urllib.parse import quote

import requests


class HttpRequestError(RuntimeError):
    """没有获得 HTTP 响应，例如连接失败或超时。"""


class HttpClient:
    def __init__(
        self,
        base_url: str,
        *,
        token: str | None = None,
        timeout: float = 10,
        verify_ssl: bool = True,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.verify_ssl = verify_ssl
        self.session = requests.Session()
        self.session.headers.update(
            {"Accept": "application/json", "Content-Type": "application/json"}
        )
        if token:
            self.set_token(token)

    def set_token(self, token: str, *, scheme: str = "Bearer") -> None:
        # 按项目替换认证格式；部分系统不需要 Bearer 前缀。
        self.session.headers["Authorization"] = f"{scheme} {token}".strip()

    @staticmethod
    def _replace_path_params(
        path: str,
        params: dict[str, Any] | None,
    ) -> str:
        params = params or {}
        names = re.findall(r"\{([^{}]+)\}", path)
        missing = [name for name in names if name not in params]
        if missing:
            raise ValueError(f"路径参数缺失：{missing}；path={path}")

        for name in names:
            value = params[name]
            if value is None:
                raise ValueError(f"路径参数 {name!r} 不能为 None")
            # 只编码参数值，不对整条 URL 重复编码。
            path = path.replace(f"{{{name}}}", quote(str(value), safe=""))
        return path

    def request(
        self,
        method: str,
        path: str,
        *,
        path_params: dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> requests.Response:
        path = self._replace_path_params(path, path_params)
        url = f"{self.base_url}/{path.lstrip('/')}"

        try:
            response = self.session.request(
                method=method.upper(),
                url=url,
                timeout=kwargs.pop("timeout", self.timeout),
                verify=kwargs.pop("verify", self.verify_ssl),
                **kwargs,
            )
        except requests.RequestException as exc:
            raise HttpRequestError(f"请求失败：{method.upper()} {url}") from exc

        # 不在此处调用 raise_for_status：测试需要检查预期的 4xx/5xx 响应。
        return response

    def get(self, path: str, **kwargs: Any) -> requests.Response:
        return self.request("GET", path, **kwargs)

    def post(self, path: str, **kwargs: Any) -> requests.Response:
        return self.request("POST", path, **kwargs)

    def delete(self, path: str, **kwargs: Any) -> requests.Response:
        return self.request("DELETE", path, **kwargs)

    def close(self) -> None:
        self.session.close()

    def __enter__(self) -> "HttpClient":
        return self

    def __exit__(self, exc_type, exc_value, traceback) -> None:
        # 即使测试失败也释放连接池资源。
        self.close()
```

PUT、PATCH 等方法与 GET/POST 相同，按实际接口补充即可。自动重试不放进最小骨架，重试边界见[重试边界](08-reusable-patterns-and-engineering.md#retry-boundaries)。

## 测试数据：`common/data.py`

```python
from pathlib import Path
from typing import Any

import yaml


DATA_DIR = Path(__file__).resolve().parents[1] / "testdata"


def load_cases(relative_path: str, group: str) -> list[dict[str, Any]]:
    path = (DATA_DIR / relative_path).resolve()
    # 防止 ../../ 跳出 testdata 目录读取任意文件。
    if DATA_DIR.resolve() not in path.parents:
        raise ValueError(f"测试数据路径越界：{relative_path}")

    with path.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file) or {}

    cases = data.get(group)
    if not isinstance(cases, list):
        raise TypeError(f"{relative_path} 中的 {group} 必须是列表")
    if any(not isinstance(case, dict) or "title" not in case for case in cases):
        raise ValueError(f"{group} 中每条数据都必须是带 title 的字典")
    return cases


def case_id(case: dict[str, Any]) -> str:
    return str(case["title"])
```

## 公共断言：`common/assertion.py`

```python
from collections.abc import Iterable, Mapping
from typing import Any

from requests import Response


def assert_status(response: Response, expected: int | Iterable[int]) -> None:
    values = {expected} if isinstance(expected, int) else set(expected)
    assert response.status_code in values, (
        f"HTTP 状态码错误：actual={response.status_code}, "
        f"expected={sorted(values)}, body={response.text[:500]}"
    )


def assert_business_code(
    payload: Mapping[str, Any],
    expected: int | str,
    *,
    field: str = "code",  # 按项目替换业务码字段名。
) -> None:
    assert field in payload, f"响应缺少业务码字段：{field}"
    assert payload[field] == expected, (
        f"业务码错误：actual={payload[field]!r}, expected={expected!r}"
    )


def assert_required_fields(
    payload: Mapping[str, Any],
    fields: Iterable[str],
) -> None:
    missing = [field for field in fields if field not in payload]
    assert not missing, f"响应缺少字段：{missing}"
```

Schema 校验是补充手段，不能替代业务断言。需要时可在 `schemas/` 保存契约，并调用 `jsonschema.validate(instance=payload, schema=schema)`。
