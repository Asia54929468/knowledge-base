---
title: 运行、排障与验收
description: 接口自动化框架的运行命令、故障定位、接口扩展步骤、设计决策和验收标准
---

# 运行、排障与验收

<div class="section-lead">使用固定命令运行和验证框架，按确定顺序定位故障，并将接口扩展收敛为可重复的工程步骤。</div>

## 常用命令 { #common-commands }

PowerShell：

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt

pytest --collect-only
pytest
pytest --env test
pytest -m smoke
pytest testcase/test_example.py -k test_login
```

macOS / Linux：

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt

pytest --collect-only
pytest --env test
```

`pytest --collect-only` 只应读取测试模块和 YAML 测试数据，不应登录、访问接口或要求真实凭据。默认参数会生成或覆盖自包含的 `reports/report.html`，日志由 pytest 捕获进入报告，不会创建本地 `logs/` 目录。

需要在保留 HTML 报告的同时写入本地时间戳日志时，覆盖 `addopts` 并移除 `--no-log-file`：

```powershell
pytest -o addopts="-v --html=reports/report.html --self-contained-html"
```

失败用例仍可能在终端失败摘要中显示 pytest 的 `Captured log`；这与实时日志关闭和本地日志文件禁用不冲突。

## 常见问题 { #troubleshooting }

### 收集阶段就报配置或网络错误

检查是否在模块顶层执行了 `load_config()`、创建 HttpClient、登录或读取 Token。运行配置应由 Fixture 在测试执行阶段加载。

### 表单或文件上传被服务端识别为 JSON

检查 Session 是否全局设置了 `Content-Type: application/json`。基础客户端只设置 `Accept`，让 requests 按 `json`、`data` 和 `files` 自动生成请求头。

### YAML 场景组找不到

核对 `load_data("example.yaml", "test_login")` 的文件名和顶层键。数据文件根节点必须是对象，场景组必须是列表。

### 参数化标题不可读

确认每条用例都有字符串 `title`，并使用 `ids=lambda case: case["title"]`。

### 失败时没有 HTTP 详情

确认在断言前调用了 `log_http(response, ...)`，并且 `pytest_runtest_makereport` 已把 `rep_call` 保存到测试节点。

### 详细日志重复

确认 `details=True` 后同步记录了 `details_logged`；teardown 只应为尚未记录详情的最后一个 Response 补记。

### HTML 报告未生成或没有日志

确认已经按 `requirements.txt` 安装 `pytest-html`，且没有通过 `-o addopts=...` 意外移除 `--html` 和 `--self-contained-html`。报告中的日志依赖项目 Logger 向上传播并由 pytest 捕获。

### 默认运行没有生成 `logs/` 目录

这是 `pytest.ini` 中 `--no-log-file` 的预期行为：日志进入 HTML 报告，但文件 Handler 不会初始化。需要本地日志时使用上面的覆盖命令。

### 日志中仍出现敏感信息

补充项目使用的 Header、查询参数和正文键名；同时缩小记录范围。路径、未知字段名、自然语言正文和私有非 JSON 格式不能只依靠通用规则保证安全。

### destructive 测试被拒绝

检查当前环境名和 `allow_destructive`。所有环境默认关闭，只有确认安全的非生产环境可以显式设置 YAML 布尔值 `true`；`"true"`、`1` 等其他类型属于配置错误，生产环境始终拒绝。

## 新增接口固定步骤 { #adding-an-endpoint }

1. 在对应 API Object 增加路径常量和方法，只完成参数到 HTTP 调用的映射。
2. 若有多组同构输入，在对应 testdata YAML 增加场景组。
3. 在 testcase 中加载数据或直接编排单一场景。
4. 复用已有 Fixture 获取客户端、认证状态和 API Object。
5. 在断言前调用 `log_http`。
6. 按 HTTP、格式、业务状态、关键字段和业务值的顺序断言。
7. 若修改服务端状态，添加 marker、恢复逻辑和环境限制。
8. 先运行 `--collect-only`，再运行目标测试，最后执行相关回归。

出现第二个稳定业务域时，再将 `api/`、`testcase/` 和 `testdata/` 按相同领域名同步分目录。

## 设计决策 { #review-questions }

### 为什么不在 testcase 中直接调用 requests？

集中请求共性可以统一 Session、认证、路径参数、超时和 TLS，并避免每个测试重复底层细节。

### 为什么 API Object 返回原始 Response？

状态码、Header、耗时、原始正文和请求对象都是测试与日志需要观察的证据，过早转换会丢失信息。

### 为什么配置 YAML 和数据 YAML 分开？

配置描述“在哪个环境、以什么参数运行”；测试数据描述“输入什么、期望什么”。两者生命周期和敏感级别不同。

### Manager 与 Fixture 有什么区别？

Manager 封装可缓存状态的获取、刷新和清理；Fixture 决定何时创建 Manager、如何注入测试以及何时释放。

### 为什么默认只记摘要？

成功请求数量通常远多于失败请求。摘要便于扫描，详细内容只在主动调试或失败时输出，兼顾可读性、性能和安全。

### 为什么默认没有本地日志文件？

HTML 报告已经保存 pytest 捕获的日志。默认禁用本地文件可以避免重复产物；需要独立归档或持续追踪时，再显式启用本地日志。

### 为什么不能依赖重试让测试通过？

无边界重试会延迟反馈、掩盖真实缺陷，并可能重复非幂等操作。只有明确的短暂故障才适合有限重试。

## 验收清单 { #acceptance-checklist }

- [ ] 项目依赖、配置、模块引用和 pytest 收集形成可运行闭环。
- [ ] Python 文件可以编译，`pytest --collect-only` 不访问网络。
- [ ] 默认运行生成自包含 HTML 报告，报告包含捕获日志且不创建本地日志文件。
- [ ] YAML 数据能够生成可读的参数化用例名称。
- [ ] HttpClient 支持 JSON、表单、上传和路径参数。
- [ ] 默认摘要、手动详情和失败自动详情行为一致，日志辅助异常不会改变测试结果。
- [ ] 已知敏感字段在 URL、Header 和正文中均被脱敏。
- [ ] Manager 只缓存 Token，且缓存可刷新、可清理，Fixture 能关闭客户端。
- [ ] destructive 测试默认关闭，只能由非生产环境的布尔值 `true` 显式开启。
- [ ] API Object 只负责接口映射，testcase 只负责编排与断言，不重复 URL 和公共请求逻辑。
