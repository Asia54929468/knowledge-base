---
title: HTTP 请求与 API Object
description: 实现支持多种请求体、路径参数和认证状态的通用 HTTP 客户端与最小 API Object
---

# HTTP 请求与 API Object

<div class="section-lead">请求层处理 HTTP 共性，API Object 只表达接口路径和参数映射；两层都不读取测试数据，也不执行测试断言。</div>

## 请求层：`common/http_client.py` { #http-client }

```python
"""封装接口测试共用的 Session、认证、路径参数和请求默认值。"""

import re
from typing import Any
from urllib.parse import quote

import requests


class HttpClient:
    """提供与具体业务无关的 HTTP 请求能力。"""

    def __init__(
        self,
        base_url: str,
        *,
        timeout: int | float = 10,
        verify_ssl: bool = True,
        token: str | None = None,
    ) -> None:
        """创建可复用 Session，并保存请求级默认配置。"""

        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.verify_ssl = verify_ssl
        self.session = requests.Session()
        # 不预设 JSON Content-Type，让 requests 按每次请求体自动选择。
        self.session.headers.update({"Accept": "application/json"})

        if token:
            self.set_token(token)

    def set_token(
        self,
        token: str,
        *,
        scheme: str = "Bearer",
    ) -> None:
        """为后续请求设置认证 Token。"""

        value = f"{scheme} {token}".strip()
        self.session.headers["Authorization"] = value

    def clear_token(self) -> None:
        """移除 Session 中已有的认证信息。"""

        self.session.headers.pop("Authorization", None)

    @staticmethod
    def _replace_path_params(
        path: str,
        path_params: dict[str, Any] | None = None,
    ) -> str:
        """校验并安全替换 URL 中的路径参数占位符。"""

        values = path_params or {}
        placeholders = re.findall(r"\{([^{}]+)\}", path)
        missing = [name for name in placeholders if name not in values]

        if missing:
            raise ValueError(
                f"URL 路径参数缺失：{missing}，请求路径：{path}"
            )

        for name in placeholders:
            value = values[name]
            if value is None:
                raise ValueError(f"URL 路径参数 {name!r} 不能为 None")

            # 路径参数必须编码，避免空格、斜杠等字符改变 URL 结构。
            path = path.replace(
                f"{{{name}}}",
                quote(str(value), safe=""),
            )

        return path

    def request(
        self,
        method: str,
        path: str,
        *,
        path_params: dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> requests.Response:
        """组装完整 URL，并使用统一默认值发送请求。"""

        resolved_path = self._replace_path_params(path, path_params)
        url = f"{self.base_url}/{resolved_path.lstrip('/')}"

        # setdefault 允许单次调用覆盖全局超时和 TLS 校验设置。
        kwargs.setdefault("timeout", self.timeout)
        kwargs.setdefault("verify", self.verify_ssl)

        return self.session.request(
            method=method,
            url=url,
            **kwargs,
        )

    def get(self, path: str, **kwargs: Any) -> requests.Response:
        """发送 GET 请求。"""

        return self.request("GET", path, **kwargs)

    def post(self, path: str, **kwargs: Any) -> requests.Response:
        """发送 POST 请求。"""

        return self.request("POST", path, **kwargs)

    def put(self, path: str, **kwargs: Any) -> requests.Response:
        """发送 PUT 请求。"""

        return self.request("PUT", path, **kwargs)

    def patch(self, path: str, **kwargs: Any) -> requests.Response:
        """发送 PATCH 请求。"""

        return self.request("PATCH", path, **kwargs)

    def delete(self, path: str, **kwargs: Any) -> requests.Response:
        """发送 DELETE 请求。"""

        return self.request("DELETE", path, **kwargs)

    def close(self) -> None:
        """关闭 Session 并释放连接资源。"""

        self.session.close()

    def __enter__(self) -> "HttpClient":
        """进入上下文管理器并返回当前客户端。"""

        return self

    def __exit__(self, *args: object) -> None:
        """离开上下文管理器时关闭客户端。"""

        self.close()
```

### 请求体由单次调用决定

```python
client.post("/api/items", json={"name": "demo"})
client.post("/api/login", data={"username": "demo"})
client.post(
    "/api/files",
    files={"file": ("demo.txt", file_object, "text/plain")},
)
```

Session 只预设 `Accept`，不全局设置 `Content-Type: application/json`。requests 会根据 `json`、`data` 或 `files` 自动生成正确请求头，避免表单和上传被错误声明为 JSON。

## API Object：`api/example_api.py` { #example-api-object }

```python
"""用最少业务代码演示 API Object 的职责和写法。"""

import requests

from common.http_client import HttpClient


class ExampleApi:
    """封装示例接口路径以及参数到 HTTP 请求的映射。"""

    LOGIN_PATH = "/api/login"
    CURRENT_USER_PATH = "/api/users/me"
    ITEM_DETAIL_PATH = "/api/items/{item_id}"

    def __init__(self, client: HttpClient) -> None:
        """注入由 Fixture 管理生命周期的 HTTP 客户端。"""

        self.client = client

    def login(
        self,
        username: str,
        password: str,
    ) -> requests.Response:
        """使用 JSON 请求体调用登录接口。"""

        return self.client.post(
            self.LOGIN_PATH,
            json={
                "username": username,
                "password": password,
            },
        )

    def get_current_user(self) -> requests.Response:
        """查询当前认证用户的信息。"""

        return self.client.get(self.CURRENT_USER_PATH)

    def get_item(
        self,
        item_id: int | str,
    ) -> requests.Response:
        """使用路径参数查询单个对象。"""

        return self.client.get(
            self.ITEM_DETAIL_PATH,
            path_params={"item_id": item_id},
        )
```

这是教学占位模块，不代表真实业务协议。新项目接入时只需要仿照三个动作：

<ol class="knowledge-flow">
  <li><span class="knowledge-flow__index" aria-hidden="true">1</span><span class="knowledge-flow__label">定义路径</span><span>把接口路径定义为类常量。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">2</span><span class="knowledge-flow__label">声明输入</span><span>用方法参数表达调用方必须提供的数据。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">3</span><span class="knowledge-flow__label">映射请求</span><span>将参数映射为 <code>json</code>、<code>data</code>、<code>params</code>、<code>files</code> 或 <code>path_params</code> 后返回原始 Response。</span></li>
</ol>

认证加密、公钥获取、签名和设备信息属于具体协议；只有目标系统确实需要时，才在对应项目中增加。

## 层间边界 { #http-api-boundaries }

- HttpClient 不知道“登录”“用户”或“订单”等业务概念。
- API Object 不读取 YAML、不依赖 pytest、不执行断言。
- testcase 决定输入、预期结果、日志标题和场景步骤。
- Manager 可以调用 API Object 获取 Token，但不得把完整敏感响应写入异常。
