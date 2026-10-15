---
title: 项目基础与配置管理
description: 准备 pytest 接口自动化项目的根文件、运行配置和安全配置加载器
---

# 项目基础与配置管理

<div class="section-lead">根目录文件提供统一运行入口，配置 YAML 定义环境参数，加载器负责选择、合并与校验。</div>

## 基础文件 { #project-root-files }

### `requirements.txt`

```text
pytest>=9.0.3,<10.0
requests>=2.32,<3.0
PyYAML>=6.0,<7.0
pytest-html>=4.1,<5.0
```

依赖采用兼容版本范围，不是完整锁文件。`pytest-html` 属于默认报告能力；Allure 等其他报告插件仍按项目需要安装。

### `pytest.ini`

```ini
[pytest]
testpaths = testcase
python_files = test_*.py
python_classes = Test*
python_functions = test_*

disable_test_id_escaping_and_forfeit_all_rights_to_community_support = true
log_level = DEBUG
log_cli = false

addopts =
    -v
    --no-log-file
    --html=reports/report.html
    --self-contained-html

markers =
    smoke: 核心链路冒烟测试
    regression: 完整回归测试
    destructive: 会修改或删除服务端状态的测试
```

`--no-log-file` 由后续 `conftest.py` 注册，只关闭本地日志文件，不关闭 pytest 日志捕获。默认执行 `pytest` 时，捕获到的日志进入自包含的 `reports/report.html`，不会创建 `logs/` 目录；`log_cli = false` 只是不实时打印日志，失败时终端仍可能显示 pytest 的 `Captured log`。

需要同时保留 HTML 报告和本地时间戳日志时，覆盖默认参数并移除 `--no-log-file`：

```powershell
pytest -o addopts="-v --html=reports/report.html --self-contained-html"
```

### `main.py`

```python
"""提供可从 IDE 或脚本直接启动 pytest 的项目入口。"""

import pytest


if __name__ == "__main__":
    raise SystemExit(pytest.main())
```

直接执行 `pytest` 是主入口；`main.py` 只为 IDE 或习惯脚本启动的场景提供等价入口。

### `.gitignore`

```gitignore
__pycache__/
*.py[cod]
.pytest_cache/

.idea/
.vscode/

.venv/
venv/

.env
.env.*

logs/
reports/
allure-results/
allure-report/

.coverage
htmlcov/

.DS_Store
Thumbs.db
```

## 运行配置：`config/config.yaml` { #runtime-config-yaml }

```yaml
env: test

environments:
  test:
    base_url: https://api.example.test
    username: replace-with-local-username
    password: replace-with-local-password
    # 基础配置默认关闭；只在确认安全的受控环境中临时改为 true。
    allow_destructive: false

  production:
    base_url: https://api.example.com
    username: ""
    password: ""
    # 生产环境必须保持关闭，conftest.py 还会校验环境名。
    allow_destructive: false

request:
  timeout: 10
  verify_ssl: true
```

配置中的占位值只表达字段结构。真实地址、账号或密码不得写入受版本控制的配置文件；实际项目应使用团队认可的密钥注入方式覆盖敏感值。

## 配置加载：`common/config.py` { #config-loader }

```python
"""读取运行配置，并将选定环境整理为测试可直接使用的设置。"""

from pathlib import Path
from typing import Any

import yaml


BASE_DIR = Path(__file__).resolve().parents[1]
CONFIG_FILE = BASE_DIR / "config" / "config.yaml"


def _load_yaml(file_path: Path) -> dict[str, Any]:
    """读取 YAML 文件，并保证根节点是字典。"""

    if not file_path.exists():
        raise FileNotFoundError(f"配置文件不存在：{file_path}")

    with file_path.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file) or {}

    if not isinstance(data, dict):
        raise TypeError("配置文件根节点必须是对象")

    return data


def load_config(
    file_path: Path = CONFIG_FILE,
    *,
    env_name: str | None = None,
) -> dict[str, Any]:
    """选择运行环境，合并公共请求配置并补充安全默认值。"""

    config = _load_yaml(file_path)

    # 命令行传入的环境优先于 YAML 中的默认环境。
    selected_env = env_name or config.get("env")
    if not isinstance(selected_env, str) or not selected_env.strip():
        raise ValueError("配置项 env 必须是非空字符串")

    environments = config.get("environments")
    if not isinstance(environments, dict):
        raise TypeError("配置项 environments 必须是对象")

    env_config = environments.get(selected_env)
    if not isinstance(env_config, dict):
        raise KeyError(f"未找到运行环境：{selected_env}")

    request_config = config.get("request", {})
    if not isinstance(request_config, dict):
        raise TypeError("配置项 request 必须是对象")

    # Fixture 只需要消费一份扁平设置，不必了解 YAML 的分组结构。
    settings = {
        "env": selected_env,
        **env_config,
        **request_config,
    }

    base_url = settings.get("base_url")
    if not isinstance(base_url, str) or not base_url.strip():
        raise ValueError("当前环境必须配置非空 base_url")

    settings["base_url"] = base_url.rstrip("/")
    # 为可选项提供保守默认值，同时保留 YAML 中的显式配置。
    settings.setdefault("timeout", 10)
    settings.setdefault("verify_ssl", True)
    settings.setdefault("allow_destructive", False)

    # 安全开关只接受 YAML 布尔值，避免字符串 "false" 被当作真值。
    if not isinstance(settings["allow_destructive"], bool):
        raise TypeError("allow_destructive 必须是布尔值")

    return settings
```

模块不创建全局 `settings = load_config()`。由 Fixture 在测试执行阶段调用 `load_config()`，因此导入测试模块和 `pytest --collect-only` 不会因为缺少真实凭据而失败。

## 配置使用规则 { #configuration-rules }

- 环境地址、超时、TLS 和非敏感开关属于运行配置。
- 多组同构输入和预期结果属于测试数据，不应放入 `config.yaml`。
- 配置键引用只在 testcase 的场景编排阶段解析，`data.py` 不依赖 `config.py`。
- `verify_ssl: false` 只用于明确受控的测试环境，并应说明原因。
- 所有环境默认 `allow_destructive: false`；只有确认安全的非生产环境才显式改为 YAML 布尔值 `true`，破坏性 marker 还需要 `conftest.py` 的第二道检查。
