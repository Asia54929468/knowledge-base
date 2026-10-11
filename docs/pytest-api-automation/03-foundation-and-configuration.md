---
title: 项目基础与配置管理
description: pytest 项目的基础文件、环境配置和安全配置加载方式
---

# 项目基础与配置管理


以下代码保留最小必要能力，并保持命名和调用关系一致。注释中的“按项目替换”是新项目落地时必须确认的部分。

## 项目基础文件

`requirements.txt`：

```text
pytest>=8.0,<9.0
requests>=2.31,<3.0
PyYAML>=6.0,<7.0
pytest-html>=4.1,<5.0
```

`pytest.ini`：

```ini
[pytest]
testpaths = testcase
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --tb=short --strict-markers
disable_test_id_escaping_and_forfeit_all_rights_to_community_support = True

markers =
    smoke: 核心链路冒烟测试
    regression: 完整回归测试
    destructive: 会修改或删除业务数据的测试
```

需要 HTML 报告时，在 `addopts` 中增加：

```text
--html=reports/report.html --self-contained-html
```

`main.py` 只是可选入口，命令行直接运行 `python -m pytest` 也可以：

```python
import pytest

if __name__ == "__main__":
    raise SystemExit(pytest.main())
```

`.gitignore` 至少包含：

```gitignore
.venv/
__pycache__/
.pytest_cache/
.env
logs/
reports/
allure-results/
```

## 配置：`config/config.yaml`

```yaml
# 可通过 API_TEST_ENV 覆盖，只保存非敏感配置。
env: test

environments:
  test:
    base_url: "https://test-api.example.com"
  staging:
    base_url: "https://staging-api.example.com"

request:
  timeout: 10
  verify_ssl: true

business:
  # 按项目替换：有些系统使用 0，有些使用 200 或字符串。
  success_code: 0
```

真实凭据由运行环境注入：

```text
API_TEST_ENV=test
API_BASE_URL=https://test-api.example.com
API_USERNAME=<your-username>
API_PASSWORD=<your-password>
```

## 配置加载：`common/config.py`

```python
from dataclasses import dataclass
import os
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[1]
CONFIG_FILE = ROOT / "config" / "config.yaml"


@dataclass(frozen=True)
class Settings:
    env: str
    base_url: str
    username: str
    password: str
    timeout: float
    verify_ssl: bool
    success_code: int | str


def _required_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"缺少必需环境变量：{name}")
    return value


def _load_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file) or {}
    if not isinstance(data, dict):
        raise TypeError(f"配置文件根节点必须是字典：{path}")
    return data


def load_settings() -> Settings:
    raw = _load_yaml(CONFIG_FILE)

    # 优先级：环境变量 > YAML 默认值。
    env = os.getenv("API_TEST_ENV", raw.get("env", "test"))
    environments = raw.get("environments", {})
    if env not in environments:
        raise KeyError(f"未配置测试环境：{env}")

    env_config = environments[env]
    request = raw.get("request", {})
    business = raw.get("business", {})
    base_url = os.getenv("API_BASE_URL", env_config.get("base_url", ""))
    if not base_url:
        raise RuntimeError(f"环境 {env} 缺少 base_url")

    return Settings(
        env=env,
        base_url=base_url.rstrip("/"),
        # 凭据只从环境变量获取，避免意外提交到 Git。
        username=_required_env("API_USERNAME"),
        password=_required_env("API_PASSWORD"),
        timeout=float(request.get("timeout", 10)),
        verify_ssl=bool(request.get("verify_ssl", True)),
        success_code=business.get("success_code", 0),
    )


SETTINGS = load_settings()
```

如果希望没有凭据时也能执行 `pytest --collect-only`，可在 fixture 中延迟调用 `load_settings()`，而不是在模块导入时创建 `SETTINGS`。
