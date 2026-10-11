---
title: 测试设计与项目搭建
description: 接口测试覆盖、断言、状态清理、项目搭建和 CI 基础流程
---

# 测试设计与项目搭建

## 测试设计规范

### 场景覆盖

| 类别 | 关注点 | 示例 |
| --- | --- | --- |
| 正向 | 合法输入、核心路径 | 正确账号登录成功 |
| 反向 | 明确错误输入 | 错误密码返回认证失败 |
| 边界 | 空值、长度、分页边界 | 名称超长、页码为 0 |
| 鉴权 | 无 Token、过期、越权 | 普通用户访问管理接口 |
| 幂等 | 重复提交、重复删除 | 相同幂等键重复创建 |
| 状态流转 | 前置状态、操作、最终状态 | 异步任务最终完成 |
| 数据一致性 | 接口与数据库或下游一致 | 创建后查询字段一致 |

### 断言顺序

1. HTTP 状态码。
2. 响应是否能按预期解析。
3. 业务码和业务消息。
4. 必需字段、类型或 Schema。
5. 具体业务数据。
6. 必要时验证数据库、缓存或下游一致性。

不要只断言 `status_code == 200`，也不要用 `[200, 400, 401, 500]` 之类宽泛集合掩盖契约变化。Schema 校验只证明结构合法，不能替代业务断言。

### Fixture scope

| Scope | 适用对象 | 注意事项 |
| --- | --- | --- |
| `function` | HTTP Session、临时数据 | 隔离最好，推荐默认使用 |
| `class` / `module` | 同一模块的只读前置数据 | 仍不能依赖执行顺序 |
| `session` | 配置、昂贵登录结果 | 状态失效会影响整次运行 |

### 独立性与状态清理

每条测试应能单独运行、改变顺序后运行、在其他测试失败后继续运行。不要把上一个测试产生的 ID 存到类变量供下一个测试使用。

有副作用的接口应遵循：

1. 使用专用账号和隔离环境。
2. 先设计清理，再实现主流程。
3. 使用唯一测试数据并记录本次创建的资源 ID。
4. 在 `yield fixture` teardown 或 `finally` 中清理。
5. 清理失败应记录告警，但要避免覆盖主流程异常。
6. 使用 `destructive` marker，并禁止对生产环境运行。
7. 异步状态使用“有超时的轮询”，不要用固定长时间 `sleep`。

### 数据驱动边界

YAML 适合存放多组结构一致的输入、边界值和预期结果；多接口分支、数据库操作、动态函数调用和清理流程应保留在 Python 中。不要为了“零代码”把 YAML 设计成难以调试的流程语言。

---

## 从零搭建步骤

### 创建环境

PowerShell：

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Bash：

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

### 最小闭环

按以下顺序搭建，任何一步失败都先解决再继续扩展：

1. 创建 `api/`、`common/`、`config/`、`testcase/` 和 `testdata/`。
2. 完成配置加载，并验证环境变量能覆盖 YAML。
3. 完成 HttpClient，并用 Mock 验证 URL、Token、超时和路径参数。
4. 选择健康检查或资源列表等无副作用接口，创建第一个 API Object。
5. 编写第一条测试，打通“配置 → HTTP → API → 断言”。
6. 出现多组同构场景后再引入 YAML 参数化。
7. 增加认证 fixture，确认 Token 失效后能够刷新。
8. 增加摘要日志和失败详情，验证敏感字段不会泄露。
9. 增加报告，再接入 CI。

### CI 基础流程

```text
检出代码
  → 安装锁定依赖
  → 注入测试环境 Secret
  → 框架单元测试
  → smoke
  → regression
  → 上传报告和脱敏日志
  → 兜底清理测试数据
```

建议 PR 运行框架单元测试和 smoke，主分支或定时任务运行完整 regression。
