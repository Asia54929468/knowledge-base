---
title: 日志、认证与 API 封装
description: 脱敏日志、认证缓存、API Object 和登录测试数据设计
---

# 日志、认证与 API 封装

## 精简日志：`common/http_logging.py`

```python
import json
import logging
from typing import Any, Mapping
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from requests import Response


logger = logging.getLogger("api_test.http")
SENSITIVE = {
    "authorization", "cookie", "password", "newpassword",
    "token", "access_token", "refresh_token", "secret",
}


def _redact(value: Any) -> Any:
    """递归脱敏字典和列表；日志输出前统一调用。"""
    if isinstance(value, Mapping):
        return {
            key: "***" if str(key).lower() in SENSITIVE else _redact(item)
            for key, item in value.items()
        }
    if isinstance(value, list):
        return [_redact(item) for item in value]
    return value


def _url(value: str) -> str:
    """按参数名脱敏 URL，同时保留排障需要的路径。"""
    parts = urlsplit(value)
    query = [
        (key, "***" if key.lower() in SENSITIVE else item)
        for key, item in parse_qsl(parts.query, keep_blank_values=True)
    ]
    return urlunsplit(
        (parts.scheme, parts.netloc, parts.path, urlencode(query), parts.fragment)
    )


def _body(value: Any, limit: int = 5_000) -> str:
    if value is None:
        return "<empty>"
    if isinstance(value, bytes):
        value = value.decode("utf-8", errors="replace")
    if isinstance(value, str):
        try:
            value = json.loads(value)
        except ValueError:
            text = value
        else:
            text = json.dumps(_redact(value), ensure_ascii=False, default=str)
    else:
        text = json.dumps(_redact(value), ensure_ascii=False, default=str)
    return text if len(text) <= limit else f"{text[:limit]}...<truncated>"


def format_summary(response: Response, title: str = "") -> str:
    request = response.request
    path = urlsplit(request.url).path if request else "<unknown>"
    method = request.method if request else "HTTP"
    return (
        f"[{title}] {method} {path} -> {response.status_code} | "
        f"{response.elapsed.total_seconds():.3f}s"
    )


def format_details(response: Response, title: str = "") -> str:
    request = response.request
    try:
        response_body: Any = response.json()
    except ValueError:
        response_body = response.text

    return "\n".join(
        [
            f"--- {title or 'HTTP details'} ---",
            f"Request: {request.method} {_url(request.url)}" if request else "Request: unknown",
            f"Request headers: {_body(_redact(dict(request.headers)))}" if request else "",
            f"Request body: {_body(request.body) if request else '<empty>'}",
            f"Response: {response.status_code}",
            f"Response body: {_body(response_body)}",
        ]
    )


def log_response(response: Response, *, title: str = "") -> None:
    logger.info(format_summary(response, title))
```

该实现只保留主干。生产项目还应对 URL 参数脱敏、不记录二进制正文，并按报告容量调整截断长度。

## 认证缓存：`common/auth.py`

```python
from collections.abc import Callable
from threading import Lock
from typing import Any


class AuthManager:
    def __init__(
        self,
        login_action: Callable[[], dict[str, Any]],
        token_getter: Callable[[dict[str, Any]], str],
    ) -> None:
        # 用回调解耦具体登录 API 和 Token 响应结构。
        self._login_action = login_action
        self._token_getter = token_getter
        self._result: dict[str, Any] | None = None
        self._lock = Lock()

    def get_token(self, *, force_refresh: bool = False) -> str:
        with self._lock:
            if self._result is None or force_refresh:
                self._result = self._login_action()
            token = self._token_getter(self._result)
            if not token:
                raise RuntimeError("登录响应中没有有效 Token")
            return token

    def clear(self) -> None:
        with self._lock:
            self._result = None
```

Token 缓存用于减少重复登录，不表示 Token 永久有效。logout、改密、过期或切换账号后必须清理或刷新缓存。

## API Object：`api/example_api.py`

```python
from requests import Response

from common.http_client import HttpClient


class AuthApi:
    LOGIN_PATH = "/api/v1/login"  # 按项目替换。

    def __init__(self, client: HttpClient) -> None:
        self.client = client

    def login(self, username: str, password: str) -> Response:
        return self.client.post(
            self.LOGIN_PATH,
            json={"username": username, "password": password},
        )


class ResourceApi:
    LIST_PATH = "/api/v1/resources"              # 按项目替换。
    DETAIL_PATH = "/api/v1/resources/{item_id}" # 按项目替换。

    def __init__(self, client: HttpClient) -> None:
        self.client = client

    def list(self, page: int = 1) -> Response:
        return self.client.get(self.LIST_PATH, params={"page": page})

    def get(self, item_id: int | str) -> Response:
        return self.client.get(
            self.DETAIL_PATH,
            path_params={"item_id": item_id},
        )
```

API 层返回原始 `Response`，因为 testcase 还需要状态码、Header、正文和耗时来验证成功及异常响应。API 层不写 pytest 断言，也不接收整条 YAML case。

## 测试数据：`testdata/auth/login.yaml`

```yaml
login_cases:
  - title: 登录成功
    request:
      # 从 Settings 取值，YAML 中不保存真实凭据。
      username_setting: username
      password_setting: password
    expected:
      status_code: [200]
      business_code: 0
      token_required: true

  - title: 密码错误
    request:
      username_setting: username
      password: "invalid-password"
    expected:
      status_code: [401]       # 按真实接口契约替换。
      business_code: 10001    # 按真实业务码替换。
      message_contains: "用户名或密码错误"
```

YAML 只保存“输入和预期”，不要保存函数名、Python 表达式或多接口流程。
