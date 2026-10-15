---
title: 日志与失败诊断
description: 实现概括日志、手动详细日志、失败自动补记、去重和敏感信息脱敏
---

# 日志与失败诊断

<div class="section-lead">正常执行保持安静，调试时主动展开，失败时自动补足上下文，同时确保诊断信息不会成为新的泄密入口。</div>

## 日志行为 { #logging-behavior }

```text
接口调用完成
    ├─ 默认：立即记录一行概括日志
    ├─ details=True：立即记录概括日志和详细日志
    └─ 用例失败且尚未输出详情：Fixture 自动补记详细日志
```

`common/http_logging.py` 负责格式化和输出，失败后的自动补记由 [`log_http` Fixture](05-pytest-orchestration-and-state.md#log-http-fixture) 负责。

### 默认报告与本地日志 { #html-report-and-local-log }

```text
pytest.ini 默认参数
    ├─ --html=reports/report.html：生成自包含 HTML 报告
    └─ --no-log-file：移除本地文件 Handler
                         ↓
                  pytest 捕获项目日志
                         ↓
                  HTML 报告展示日志
```

`--no-log-file` 不会关闭日志，也不会影响摘要、手动详情或失败自动详情；它只让 `setup_logging(write_to_file=False)` 移除文件 Handler，避免创建 `logs/` 目录。`log_cli = false` 关闭实时输出，但沿用 pytest 默认行为，失败摘要仍可能在终端展示 `Captured log`。

## 日志配置：`config/logging.yaml` { #logging-yaml }

```yaml
version: 1
disable_existing_loggers: false

formatters:
  standard:
    format: "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s"
    datefmt: "%Y-%m-%d %H:%M:%S"

handlers:
  # 是否启用该文件 Handler 由 setup_logging 的 write_to_file 决定。
  file:
    class: logging.handlers.RotatingFileHandler
    level: DEBUG
    formatter: standard
    filename: logs/api_test.log
    encoding: utf-8
    maxBytes: 10485760
    backupCount: 5

loggers:
  api_test:
    level: DEBUG
    handlers:
      - file
    propagate: true

  urllib3:
    level: WARNING
    handlers: []
    propagate: true

  requests:
    level: WARNING
    handlers: []
    propagate: true

root:
  level: WARNING
  handlers: []
```

## 日志初始化：`common/logger.py` { #logger-setup }

```python
"""根据 YAML 配置初始化项目日志，并控制可选的文件输出。"""

import copy
import logging
import logging.config
from datetime import datetime
from pathlib import Path

import yaml


BASE_DIR = Path(__file__).resolve().parents[1]
LOGGING_CONFIG = BASE_DIR / "config" / "logging.yaml"


def _remove_file_handlers(config: dict) -> None:
    """从日志配置副本中移除所有文件 Handler 及其引用。"""

    handlers = config.get("handlers", {})
    file_handler_names = {
        name
        for name, value in handlers.items()
        if "FileHandler" in str(value.get("class", ""))
    }

    for name in file_handler_names:
        handlers.pop(name, None)

    logger_configs = [
        *config.get("loggers", {}).values(),
        config.get("root", {}),
    ]
    for logger_config in logger_configs:
        configured = logger_config.get("handlers", [])
        logger_config["handlers"] = [
            name
            for name in configured
            if name not in file_handler_names
        ]


def _prepare_file_handlers(config: dict) -> None:
    """创建日志目录，并为文件日志生成带时间戳的路径。"""

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    for handler in config.get("handlers", {}).values():
        if "FileHandler" not in str(handler.get("class", "")):
            continue

        configured_path = Path(handler["filename"])
        if not configured_path.is_absolute():
            configured_path = BASE_DIR / configured_path

        configured_path.parent.mkdir(parents=True, exist_ok=True)
        handler["filename"] = str(
            configured_path.with_name(
                f"{configured_path.stem}_{timestamp}"
                f"{configured_path.suffix}"
            )
        )


def setup_logging(
    *,
    write_to_file: bool = True,
    config_file: Path = LOGGING_CONFIG,
) -> None:
    """加载日志配置，并按开关启用或禁用文件日志。"""

    with config_file.open("r", encoding="utf-8") as file:
        loaded = yaml.safe_load(file) or {}

    if not isinstance(loaded, dict):
        raise TypeError("日志配置根节点必须是对象")

    # 辅助函数会修改配置，因此先复制，避免污染原始读取结果。
    config = copy.deepcopy(loaded)
    if write_to_file:
        _prepare_file_handlers(config)
    else:
        _remove_file_handlers(config)

    logging.config.dictConfig(config)


def get_logger(name: str | None = None) -> logging.Logger:
    """返回统一位于 api_test 命名空间下的 Logger。"""

    logger_name = "api_test" if not name else f"api_test.{name}"
    return logging.getLogger(logger_name)
```

## HTTP 日志：`common/http_logging.py` { #http-logging }

```python
"""格式化 HTTP 摘要与详情，并在输出前统一执行脱敏和截断。"""

import json
import logging
import re
from typing import Any, Mapping
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from requests import Response

from common.logger import get_logger


logger = get_logger("http")

SENSITIVE_HEADERS = {
    "authorization",
    "cookie",
    "set-cookie",
    "x-api-key",
    "proxy-authorization",
}

SENSITIVE_FIELDS = {
    "password",
    "new_password",
    "token",
    "access_token",
    "refresh_token",
    "secret",
    "client_secret",
}

IMPORTANT_REQUEST_HEADERS = {
    "content-type",
    "accept",
    "user-agent",
    "x-request-id",
    "trace-id",
}

IMPORTANT_RESPONSE_HEADERS = {
    "content-type",
    "content-length",
    "x-request-id",
    "trace-id",
}

SENSITIVE_TEXT_PATTERN = re.compile(
    r"""(?ix)
    (
        ["']?
        (?:password|new_password|token|access_token|
           refresh_token|secret|client_secret)
        ["']?
        \s*[:=]\s*
        ["']?
    )
    ([^"',&\s}]+)
    """
)
BEARER_PATTERN = re.compile(
    r"(?i)(authorization\s*[:=]\s*bearer\s+)[^\s,;]+"
)


def _redact_text(text: str) -> str:
    """脱敏普通文本中可识别的敏感键值和 Bearer Token。"""

    text = SENSITIVE_TEXT_PATTERN.sub(r"\1***", text)
    return BEARER_PATTERN.sub(r"\1***", text)


def _redact_headers(
    headers: Mapping[str, Any] | None,
) -> dict[str, Any]:
    """保留全部 Header，但替换已知敏感 Header 的值。"""

    if not headers:
        return {}

    return {
        key: (
            "***"
            if str(key).lower() in SENSITIVE_HEADERS
            else value
        )
        for key, value in dict(headers).items()
    }


def _select_headers(
    headers: Mapping[str, Any] | None,
    allowed_headers: set[str],
) -> dict[str, Any]:
    """只选择允许记录的 Header，并对其中敏感值脱敏。"""

    if not headers:
        return {}

    selected: dict[str, Any] = {}
    for key, value in dict(headers).items():
        lower_key = str(key).lower()
        if lower_key not in allowed_headers:
            continue

        selected[key] = (
            "***"
            if lower_key in SENSITIVE_HEADERS
            else value
        )

    return selected


def _redact_sensitive_fields(data: Any) -> Any:
    """递归脱敏字典、列表、元组和字符串中的敏感信息。"""

    if isinstance(data, dict):
        return {
            key: (
                "***"
                if str(key).lower() in SENSITIVE_FIELDS
                else _redact_sensitive_fields(value)
            )
            for key, value in data.items()
        }

    if isinstance(data, list):
        return [_redact_sensitive_fields(item) for item in data]

    if isinstance(data, tuple):
        return tuple(_redact_sensitive_fields(item) for item in data)

    if isinstance(data, str):
        return _redact_text(data)

    return data


def _format_body(
    body: Any,
    *,
    max_chars: int = 10_000,
) -> str:
    """把请求或响应正文安全格式化，并限制最终输出长度。"""

    if body is None:
        return "<empty>"

    if isinstance(body, bytes):
        body = body.decode("utf-8", errors="replace")

    if isinstance(body, str):
        # JSON 字符串按字段递归脱敏，其他文本使用通用模式脱敏。
        try:
            data = json.loads(body)
        except (TypeError, ValueError):
            text = _redact_text(body)
        else:
            text = json.dumps(
                _redact_sensitive_fields(data),
                ensure_ascii=False,
                indent=2,
                default=str,
            )
    else:
        try:
            text = json.dumps(
                _redact_sensitive_fields(body),
                ensure_ascii=False,
                indent=2,
                default=str,
            )
        except (TypeError, ValueError):
            text = _redact_text(str(body))

    if len(text) <= max_chars:
        return text

    # 截断发生在脱敏之后，既控制日志大小，也不会暴露原始尾部。
    omitted = len(text) - max_chars
    return f"{text[:max_chars]}\n... 已省略 {omitted} 个字符"


def _format_url(
    url: str,
    *,
    include_host: bool = False,
) -> str:
    """脱敏查询参数，并按需隐藏协议、Host 和端口。"""

    if not url:
        return "<unknown>"

    parts = urlsplit(url)
    query = [
        (
            key,
            "***" if key.lower() in SENSITIVE_FIELDS else value,
        )
        for key, value in parse_qsl(
            parts.query,
            keep_blank_values=True,
        )
    ]
    redacted_query = urlencode(query, doseq=True)

    if include_host:
        return urlunsplit(
            (
                parts.scheme,
                parts.netloc,
                parts.path,
                redacted_query,
                parts.fragment,
            )
        )

    # 摘要默认只展示 path/query，避免公开环境地址。
    path = parts.path or "/"
    return f"{path}?{redacted_query}" if redacted_query else path


def _indent(text: str, spaces: int = 4) -> str:
    """为多行详情统一增加缩进。"""

    prefix = " " * spaces
    return "\n".join(f"{prefix}{line}" for line in text.splitlines())


def _business_summary(response: Response) -> str:
    """从 JSON 响应中提取少量通用业务字段作为摘要。"""

    try:
        data = response.json()
    except ValueError:
        return ""

    if not isinstance(data, dict):
        return ""

    parts: list[str] = []
    if "code" in data:
        parts.append(f"code={data['code']}")
    if "success" in data:
        parts.append(f"success={data['success']}")
    if "message" in data:
        message = _redact_text(str(data["message"]))
        message = message.replace("\r", " ").replace("\n", " ")
        # 摘要只保留消息前 100 个字符，更多正文信息由受限详情提供。
        parts.append(f"message={message[:100]}")

    return f" | {' | '.join(parts)}" if parts else ""


def format_http_summary(
    response: Response,
    *,
    title: str | None = None,
    include_host: bool = False,
) -> str:
    """生成默认记录的一行 HTTP 摘要。"""

    request = response.request
    if request is None:
        raise ValueError("Response 中不存在对应的 Request")

    title_text = f"[{title}] " if title else ""
    url = _format_url(
        str(request.url),
        include_host=include_host,
    )
    elapsed = response.elapsed.total_seconds()
    return (
        f"{title_text}{request.method} {url} "
        f"-> HTTP {response.status_code} | {elapsed:.3f}s"
        f"{_business_summary(response)}"
    )


def format_http_details(
    response: Response,
    *,
    title: str | None = None,
    include_headers: bool = False,
    include_all_headers: bool = False,
    max_body_chars: int = 10_000,
) -> str:
    """生成经过脱敏和长度限制的 HTTP 请求与响应详情。"""

    request = response.request
    if request is None:
        raise ValueError("Response 中不存在对应的 Request")

    try:
        response_body: Any = response.json()
    except ValueError:
        response_body = response.text

    lines = [
        "",
        f"========== {title or 'HTTP 请求详情'} ==========",
        "Request",
        f"  Method : {request.method}",
        f"  URL    : {_format_url(str(request.url), include_host=True)}",
    ]

    if include_headers:
        # 默认只展示诊断常用 Header；显式开启时才展示其余 Header。
        request_headers = (
            _redact_headers(request.headers)
            if include_all_headers
            else _select_headers(
                request.headers,
                IMPORTANT_REQUEST_HEADERS,
            )
        )
        lines.extend(
            [
                "  Headers:",
                _indent(_format_body(request_headers)),
            ]
        )

    lines.extend(
        [
            "  Body:",
            _indent(
                _format_body(
                    request.body,
                    max_chars=max_body_chars,
                )
            ),
            "",
            "Response",
            f"  Status : {response.status_code}",
            (
                "  Time   : "
                f"{response.elapsed.total_seconds():.3f}s"
            ),
        ]
    )

    if include_headers:
        response_headers = (
            _redact_headers(response.headers)
            if include_all_headers
            else _select_headers(
                response.headers,
                IMPORTANT_RESPONSE_HEADERS,
            )
        )
        lines.extend(
            [
                "  Headers:",
                _indent(_format_body(response_headers)),
            ]
        )

    lines.extend(
        [
            "  Body:",
            _indent(
                _format_body(
                    response_body,
                    max_chars=max_body_chars,
                )
            ),
            "=" * 40,
        ]
    )
    return "\n".join(lines)


def log_http_response(
    response: Response,
    *,
    title: str | None = None,
    details: bool = False,
    include_headers: bool = False,
    include_all_headers: bool = False,
    include_host_in_summary: bool = False,
    max_body_chars: int = 10_000,
    summary_level: int = logging.INFO,
    detail_level: int = logging.DEBUG,
) -> None:
    """按启用的日志级别记录摘要，并在 details=True 时追加详情。"""

    # 先检查级别，避免在日志被过滤时仍解析和脱敏响应正文。
    if logger.isEnabledFor(summary_level):
        logger.log(
            summary_level,
            format_http_summary(
                response,
                title=title,
                include_host=include_host_in_summary,
            ),
        )

    if details and logger.isEnabledFor(detail_level):
        logger.log(
            detail_level,
            format_http_details(
                response,
                title=title,
                include_headers=include_headers,
                include_all_headers=include_all_headers,
                max_body_chars=max_body_chars,
            ),
        )
```

摘要和详情在格式化前分别检查日志级别；被级别过滤的内容不会执行 JSON 解析、递归脱敏或正文截断，避免为不会输出的日志支付额外开销。

已知字段名可以统一脱敏，但路径片段、未知字段名、任意自然语言正文和非 JSON 私有格式仍需结合项目补充规则。最安全的做法仍是只记录诊断所需的最少信息。

## 使用方式 { #logging-usage }

默认只记录摘要：

```python
log_http(response, title="登录成功")
```

定位问题时手动打开详情：

```python
log_http(
    response,
    title="登录调试",
    details=True,
    include_headers=True,
    max_body_chars=5_000,
)
```
