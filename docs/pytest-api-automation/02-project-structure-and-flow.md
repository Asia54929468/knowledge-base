---
title: 项目结构与执行链路
description: 接口自动化项目的推荐目录、文件职责、架构分层和用例生命周期
---

# 项目结构与执行链路

## 推荐目录结构

只维护一套结构。标注“可选”的模块可以在项目需要时再加入。

```text
api-test/
├── api/                       # 业务接口对象
│   ├── __init__.py
│   ├── auth_api.py
│   └── resource_api.py
├── common/                    # 与业务无关的公共能力
│   ├── __init__.py
│   ├── config.py
│   ├── http_client.py
│   ├── data.py
│   ├── assertion.py
│   ├── auth.py               # 可选：认证缓存
│   └── http_logging.py       # 可选：请求响应日志
├── config/
│   └── config.yaml
├── testcase/
│   ├── conftest.py
│   ├── auth/
│   │   └── test_login.py
│   └── resource/
│       └── test_resource.py
├── testdata/
│   ├── auth/
│   │   └── login.yaml
│   └── resource/             # 可选：大量同构数据时使用
├── schemas/                  # 可选：JSON Schema
├── logs/                     # 运行产物，不提交 Git
├── reports/                  # 运行产物，不提交 Git
├── main.py                   # 可选：IDE/脚本入口
├── pytest.ini
├── requirements.txt
└── .gitignore
```

### 文件职责

| 路径 | 职责 | 必需性 |
| --- | --- | --- |
| `api/*_api.py` | 一个文件封装一个业务域的路径、方法和参数映射 | 必需 |
| `common/config.py` | 加载环境配置，并用环境变量覆盖敏感值 | 必需 |
| `common/http_client.py` | Session、URL、Token、超时、SSL、路径参数 | 必需 |
| `common/data.py` | 读取并校验 YAML 测试数据 | 按需 |
| `common/assertion.py` | 统一常见断言及失败信息 | 推荐 |
| `common/auth.py` | 登录结果缓存、刷新和清理 | 多鉴权用例时推荐 |
| `common/http_logging.py` | 摘要、失败详情、脱敏和截断 | 推荐 |
| `config/config.yaml` | 环境地址和非敏感默认配置 | 必需 |
| `testcase/conftest.py` | 公共 fixture、命令行参数和 pytest hook | 必需 |
| `testcase/test_*.py` | 业务场景编排与断言 | 必需 |
| `testdata/**/*.yaml` | 多组同构输入和预期结果 | 按需 |
| `schemas/` | 响应结构契约 | 按需 |
| `pytest.ini` | 测试发现、默认参数和 markers | 推荐 |
| `requirements.txt` | 直接依赖及兼容版本 | 必需 |
| `.gitignore` | 排除凭据、虚拟环境、缓存和运行产物 | 必需 |

---

## 架构与执行链路

```text
pytest → Testcase → API Object → HttpClient → 被测服务
           ↑                              │
           └─────────── 响应 ────────────┘

config → HttpClient
testdata → Testcase
fixture / AuthManager → Testcase
日志与报告 ──观察──→ Testcase
```

一条用例的生命周期：

1. pytest 根据 `pytest.ini` 发现测试。
2. `conftest.py` 初始化 fixture 和日志。
3. YAML 数据通过 `parametrize` 生成测试实例。
4. 鉴权 fixture 获取或复用 Token。
5. testcase 调用 API Object，不直接拼 URL。
6. API Object 将业务参数映射为 path、query、header 或 JSON body。
7. HttpClient 注入公共配置并发送请求。
8. testcase 按“HTTP → 业务码 → 结构 → 业务数据”顺序断言。
9. 失败时输出脱敏详情；teardown 关闭 Session 并清理测试数据。
10. pytest 汇总结果并生成报告。

这里需要区分四类职责：

- **数据流**：配置和 YAML 只提供输入、期望值。
- **控制流**：fixture 决定依赖的创建与释放。
- **业务流**：testcase 决定多个接口如何组合。
- **传输流**：HttpClient 决定请求如何发送。
