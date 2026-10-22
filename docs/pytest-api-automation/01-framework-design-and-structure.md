---
title: 框架设计与项目结构
description: 理解通用 pytest 接口自动化框架的分层、目录、依赖方向和执行链路
---

# 框架设计与项目结构

<div class="section-lead">明确各层职责和依赖方向，使配置、请求、业务映射、测试编排与诊断保持单向协作。</div>

## 设计目标与原则 { #framework-goals }

接口自动化框架需要让配置、数据、请求、认证状态、断言、日志与清理组成稳定、可维护的测试执行闭环。

<div class="knowledge-grid knowledge-grid--2">
  <section><h4>请求复用</h4><p><code>HttpClient</code> 统一处理 Base URL、Session、Header、Token、超时、TLS、路径参数和传输异常。</p></section>
  <section><h4>分层解耦</h4><p>Testcase 负责编排场景与断言，API Object 负责接口路径和参数映射，HTTP 层负责协议传输。</p></section>
  <section><h4>环境隔离</h4><p>通过运行配置切换地址、凭据和请求默认值，不在测试代码中编写环境判断。</p></section>
  <section><h4>数据驱动</h4><p>使用 YAML 为同一测试逻辑提供正常、异常和边界场景，避免复制测试流程。</p></section>
  <section><h4>状态管理</h4><p>Manager 和 Fixture 负责 Token 的复用、刷新与清理，以及公共资源的准备和释放。</p></section>
  <section><h4>失败可诊断</h4><p>通过时记录简洁摘要，失败时补充经过脱敏和截断的请求响应详情，同时保留原始测试异常。</p></section>
  <section><h4>可重复执行</h4><p>用例不依赖执行顺序；状态修改必须恢复，Session 和缓存必须在作用域结束后释放。</p></section>
  <section><h4>安全可控</h4><p>真实凭据不进入版本库，敏感信息不直接写入日志，生产环境禁止执行破坏性测试。</p></section>
</div>

数据库、消息队列、Schema、通知和加密等能力只在测试链路确实需要时引入。

## 基础目录 { #base-project-tree }

```text
api-test/
├─ api/
│  └─ example_api.py          # API 层示例：接口路径、请求方法和参数映射
├─ common/
│  ├─ assertion.py            # 统一常用断言及安全的失败信息
│  ├─ config.py               # 读取并校验当前环境的运行配置
│  ├─ data.py                 # 读取并校验 YAML 测试数据
│  ├─ http_client.py          # HTTP 层：Session、URL、Token、超时、SSL 和路径参数
│  ├─ http_logging.py         # HTTP 摘要、失败详情、脱敏和截断
│  ├─ logger.py               # 初始化日志，并控制是否写入本地日志文件
│  └─ manager.py              # 缓存、刷新和清理跨用例 Token
├─ config/
│  ├─ config.yaml             # 环境地址和非敏感运行默认值
│  └─ logging.yaml            # 日志格式、级别和 Handler 配置
├─ testcase/
│  ├─ conftest.py             # 公共 Fixture、命令行参数和 pytest Hook
│  └─ test_example.py         # 场景编排、API 调用、日志登记和断言
├─ testdata/
│  └─ example.yaml            # 数据驱动输入、预期结果和场景标题
├─ .gitignore                 # 忽略环境、缓存、日志和报告等生成内容
├─ main.py                    # IDE 或脚本方式启动 pytest 的入口
├─ pytest.ini                 # 收集规则、marker、默认 HTML 报告和日志模式
└─ requirements.txt           # 基础依赖及其兼容版本范围
```

基础版不预建空领域目录。出现多个稳定业务域后，再保持 API、测试和数据的目录镜像：

```text
api/<domain>/
testcase/<domain>/
testdata/<domain>/
```

例如增加订单域时，三个目录同时增加 `order/`，而不是把所有接口继续堆进一个文件。

## 分层职责 { #layer-responsibilities }

| 层级 | 应该负责 | 不应该负责 |
| --- | --- | --- |
| 配置层 | 环境地址、超时、SSL 和非敏感默认值 | 保存明文密码、编写业务断言 |
| HTTP 层 | URL、Session、Header、Token、路径参数和传输异常 | 判断具体业务码 |
| API 层 | 以 API Object 封装接口路径、请求方法和参数映射 | 编写 pytest 用例、保存跨用例状态 |
| 数据层 | 输入、预期结果、场景标题和 YAML 结构校验 | 执行请求和复杂流程控制 |
| Fixture/Manager | 依赖注入、认证缓存、资源准备与释放 | 制造用例顺序依赖 |
| Testcase | 编排场景、调用 API、分层断言和场景专属清理 | 重复拼接 URL 和公共请求逻辑 |
| 日志/报告 | 脱敏记录、失败诊断和结果展示 | 覆盖原始测试异常 |

## 架构与执行链路 { #execution-flows }

四条泳道分别说明运行配置、测试数据、请求调用和结果处理如何进入一条用例；箭头只表示当前泳道内的执行方向。

<div class="execution-flow" aria-label="接口自动化框架执行链路">
  <section class="execution-flow__lane" aria-labelledby="execution-flow-config">
    <p class="execution-flow__title" id="execution-flow-config">运行配置</p>
    <ol class="execution-flow__steps">
      <li class="execution-flow__step"><code>config/config.yaml</code><span>维护环境与非敏感默认值</span></li>
      <li class="execution-flow__step"><code>common/config.py</code><span>加载并校验当前环境配置</span></li>
      <li class="execution-flow__step"><code>settings Fixture</code><span>在运行期注入配置</span></li>
      <li class="execution-flow__step"><code>Manager / HttpClient</code><span>获得认证与请求默认值</span></li>
    </ol>
  </section>
  <section class="execution-flow__lane" aria-labelledby="execution-flow-data">
    <p class="execution-flow__title" id="execution-flow-data">测试数据</p>
    <ol class="execution-flow__steps">
      <li class="execution-flow__step"><code>testdata/example.yaml</code><span>提供输入、预期结果和标题</span></li>
      <li class="execution-flow__step"><code>common/data.py</code><span>读取数据并校验结构</span></li>
      <li class="execution-flow__step"><code>parametrize</code><span>生成参数化测试实例</span></li>
      <li class="execution-flow__step"><code>Testcase</code><span>接收数据并编排场景</span></li>
    </ol>
  </section>
  <section class="execution-flow__lane" aria-labelledby="execution-flow-request">
    <p class="execution-flow__title" id="execution-flow-request">请求调用</p>
    <ol class="execution-flow__steps">
      <li class="execution-flow__step"><code>Testcase</code><span>发起当前场景调用</span></li>
      <li class="execution-flow__step"><code>API Object</code><span>映射路径、方法和业务参数</span></li>
      <li class="execution-flow__step"><code>HttpClient</code><span>注入公共配置并发送请求</span></li>
      <li class="execution-flow__step"><code>被测服务</code><span>处理请求并返回响应</span></li>
    </ol>
  </section>
  <section class="execution-flow__lane" aria-labelledby="execution-flow-result">
    <p class="execution-flow__title" id="execution-flow-result">结果处理</p>
    <ol class="execution-flow__steps">
      <li class="execution-flow__step"><code>Response</code><span>将请求结果交回用例</span></li>
      <li class="execution-flow__step"><code>log_http</code><span>登记摘要或失败详情</span></li>
      <li class="execution-flow__step"><code>assertion.py</code><span>执行安全的分层断言</span></li>
      <li class="execution-flow__step"><code>pytest / HTML 报告</code><span>汇总结果与捕获日志</span></li>
    </ol>
  </section>
</div>

### 一条用例的生命周期

<ol class="knowledge-flow">
  <li><span class="knowledge-flow__index" aria-hidden="true">1</span><span class="knowledge-flow__label">收集</span><span>pytest 按 <code>pytest.ini</code> 收集 testcase，并加载 <code>conftest.py</code> 中的 Hook 与 Fixture 定义。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">2</span><span class="knowledge-flow__label">生成实例</span><span><code>data.py</code> 在收集阶段读取 YAML，<code>parametrize</code> 生成带 <code>title</code> 的测试实例；此时不访问真实接口，也不要求真实凭据。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">3</span><span class="knowledge-flow__label">准备依赖</span><span>用例开始执行后，Fixture 加载配置、初始化日志和客户端，Manager 按需获取或复用 Token。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">4</span><span class="knowledge-flow__label">发送请求</span><span>Testcase 调用 API Object，HttpClient 处理 URL、路径参数、认证、超时和 TLS 后发送请求。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">5</span><span class="knowledge-flow__label">记录与断言</span><span>Response 返回 Testcase；先登记摘要日志，再按 HTTP 状态、业务码、结构和业务数据分层断言，失败时补记经过脱敏和截断的详情。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">6</span><span class="knowledge-flow__label">清理与汇总</span><span><code>yield</code> Fixture 关闭 Session、清理缓存或恢复状态，pytest 汇总结果并生成自包含 HTML 报告。</span></li>
</ol>
