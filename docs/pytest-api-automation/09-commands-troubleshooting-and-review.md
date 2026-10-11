---
title: 命令、排障与验收
description: pytest 常用命令、接口自动化排障、复习问答和验收清单
---

# 命令、排障与验收

## 命令与排障速查

### 常用命令

```bash
python -m pytest                              # 全部测试
python -m pytest --collect-only -q            # 只检查收集
python -m pytest testcase/auth/test_login.py  # 单文件
python -m pytest -k "login and not empty"     # 名称筛选
python -m pytest -m smoke                     # 冒烟测试
python -m pytest -m "not destructive"         # 排除破坏性测试
python -m pytest -x                           # 首次失败后停止
python -m pytest --setup-show                  # 查看 fixture 生命周期
python -m pytest -o addopts="-q"               # 临时覆盖默认参数
python -m pytest -n auto                      # 并行，需 pytest-xdist
```

### 常见问题

| 问题 | 优先检查 | 处理建议 |
| --- | --- | --- |
| 用例未收集 | 文件、类、函数命名 | 使用 `--collect-only` |
| `ModuleNotFoundError` | 虚拟环境和工作目录 | 使用 `python -m pytest` |
| 环境不存在 | `API_TEST_ENV` 与 YAML key | 启动时打印非敏感环境名 |
| 后续请求 401 | Token 格式、过期、是否执行过 logout | 清缓存并独立检查 Header |
| URL 404 | base URL、公共前缀、路径变量 | 查看脱敏后的最终 URL |
| JSON 解析失败 | 状态码、Content-Type、网关错误页 | 先断言传输层 |
| SSL 错误 | 证书链、主机名、企业代理 | 配置正确 CA |
| 偶发失败 | 共享数据、异步状态、顺序依赖 | 隔离数据并使用轮询 |
| 并行冲突 | 账号、资源、日志是否共享 | 按 worker 隔离 |
| 清理失败 | 资源 ID、清理 Token 是否有效 | 独立清理凭据和兜底任务 |

### 新增接口固定步骤

1. 在对应 API Object 增加路径和方法。
2. 明确参数属于 path、query、header、form、file 还是 JSON body。
3. 设计正常、异常、边界和鉴权场景。
4. 同构数据较多时增加 YAML 数据组。
5. testcase 调用业务方法并分层断言。
6. 有副作用时先设计清理，再写主流程。
7. 添加 marker，单独执行后再做模块回归。
8. 检查日志脱敏和失败报告。

---

## 面试复习问答

### 为什么不在测试中直接调用 requests？

直接调用适合一次性脚本。项目扩大后，域名、Token、超时、SSL、异常和日志会大量重复。HttpClient 集中治理传输层，API Object 把请求细节转换成业务动作，测试只关注场景和断言。

### 为什么 API 层返回原始 Response？

测试既要验证成功，也要验证 4xx、5xx。原始 Response 保留状态码、Header、耗时和正文，避免 API 层提前丢失测试信息。

### 为什么使用 fixture？

Fixture 通过依赖注入管理配置、登录态、客户端和临时资源，并用 scope 控制生命周期。`yield` 可以把准备和清理放在同一处。

### session Token 有什么风险？

它能减少重复登录，但 logout、改密、过期和并行执行可能让共享状态失效。应提供刷新和清理能力，logout 使用独立 Token，并按账号或 worker 隔离缓存。

### 为什么使用 YAML？

YAML 适合多组同构输入和预期，使数据与逻辑分离；复杂业务流程继续放在 Python 中，否则配置会演变成难维护的流程语言。

### 如何保证可重复执行？

使用专用环境、唯一数据和独立账号；用 fixture 管理资源；在 teardown 中清理副作用；避免顺序依赖，并配置兜底清理任务。

### 自动重试越多越好吗？

不是。重试会掩盖问题并可能重复非幂等操作。只对可安全重放的短暂故障有限重试；异步业务状态使用有超时的轮询。

---

## 验收清单

- [ ] 环境变量能够切换环境并覆盖动态配置。
- [ ] 仓库中没有真实账号、密码、Token 或私钥。
- [ ] HttpClient 统一处理 URL、Token、超时、SSL 和路径参数。
- [ ] API Object 不包含 pytest 断言。
- [ ] testcase 不重复拼 URL 或公共请求逻辑。
- [ ] 正向、反向、边界和鉴权场景均有覆盖。
- [ ] 断言同时覆盖 HTTP 层、业务层和关键数据。
- [ ] 用例能够单独运行且不依赖顺序。
- [ ] 副作用测试具备清理和兜底策略。
- [ ] logout、改密不会破坏共享认证缓存。
- [ ] Header、URL 和正文中的敏感字段已脱敏。
- [ ] 成功日志简洁，失败日志包含足够上下文。
- [ ] 日志或报告异常不会覆盖原始测试失败。
- [ ] `pytest --collect-only` 能发现所有用例。
- [ ] smoke、regression 和 destructive 可以分别筛选。
- [ ] 报告、日志、缓存和虚拟环境未提交 Git。
- [ ] 并行执行前已完成账号、资源和日志隔离。

最后只需记住这条主线：

```text
配置提供环境 → HttpClient 处理传输 → API Object 表达接口
→ fixture 管理生命周期 → testcase 编排并断言 → 日志和清理保证可诊断、可重复
```

框架的目标不是堆叠工具，而是让新增接口时只需回答三个问题：**调用什么业务方法、输入什么数据、应该得到什么结果。**
