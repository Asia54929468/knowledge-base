---
title: 质量属性与专项测试
description: 评价性能、安全、兼容性、易用性、可靠性及交付适应能力。
---

# 质量属性与专项测试

<div class="section-lead">功能正确只是质量的一部分，还要验证系统在真实约束、故障和多样环境下的表现。</div>

## 性能与容量测试 { #performance-and-capacity }

性能测试用响应时间、吞吐量、并发量和资源利用率评价系统在不同负载下的行为。有效结论需要真实场景模型、稳定环境和监控数据共同支撑。

### 性能测试

<dl class="knowledge-definitions">
  <dt>响应时间</dt><dd>从请求发出到收到完整响应所经历的时间，常关注平均值和 P90、P95、P99 等分位数。</dd>
  <dt>吞吐量</dt><dd>单位时间内系统完成的请求数、事务数或数据量。</dd>
  <dt>并发用户数</dt><dd>同一时间与系统交互或保持会话的用户数量。</dd>
  <dt>TPS / QPS</dt><dd>每秒处理的事务数 / 查询数，口径必须在测试前明确。</dd>
  <dt>资源利用率</dt><dd>CPU、内存、磁盘、网络、线程、连接池等资源使用情况。</dd>
</dl>

<div class="knowledge-grid knowledge-grid--2 knowledge-compare" role="group" aria-label="负载测试与压力测试对比">
  <section><h4>负载测试</h4><p>在预期或逐步增加的负载下评价性能目标和容量。</p></section>
  <section><h4>压力测试</h4><p>超过正常负载，寻找系统极限、观察失败方式并验证恢复能力。</p></section>
</div>

<dl class="knowledge-definitions">
  <dt>峰值 / 尖峰测试</dt><dd>验证负载突然上升或下降时系统的适应能力。</dd>
  <dt>稳定性 / 耐久测试</dt><dd>长时间运行以发现内存泄漏、资源耗尽和性能衰减。</dd>
  <dt>容量测试</dt><dd>确定系统可支持的数据量、用户量或事务量上限。</dd>
  <dt>可伸缩性测试</dt><dd>验证增加或减少资源后，系统性能能否合理变化。</dd>
  <dt>基准测试</dt><dd>在固定条件下建立性能基线，用于版本或方案比较。</dd>
  <dt>性能场景</dt><dd>模型应尽量接近真实业务比例、用户行为、数据量和思考时间。</dd>
  <dt>性能瓶颈</dt><dd>可能出现在客户端、网络、应用、数据库、缓存、消息队列或外部依赖。</dd>
  <dt>常见工具</dt><dd>JMeter、k6、Locust、Gatling 等；监控数据与压测结果需要联合分析。</dd>
</dl>

## 安全与隐私测试 { #security-and-privacy }

安全测试围绕身份、权限、会话、输入、敏感数据和配置验证防护能力。攻击性测试必须在明确授权和范围内开展，自动扫描结果也需要人工确认。

### 安全测试

<div class="knowledge-grid knowledge-grid--3">
  <section><h4>身份认证</h4><p>验证账号识别、密码策略、多因素认证、验证码和登录保护。</p></section>
  <section><h4>授权控制</h4><p>验证用户只能访问被允许的功能和数据，防止水平与垂直越权。</p></section>
  <section><h4>会话安全</h4><p>验证 Token / Session 的生成、过期、撤销、固定攻击防护和安全存储。</p></section>
  <section><h4>输入安全</h4><p>关注 SQL 注入、命令注入、XSS、路径遍历和不安全反序列化等问题。</p></section>
  <section><h4>敏感数据保护</h4><p>检查传输加密、存储加密、脱敏、日志泄露和密钥管理。</p></section>
  <section><h4>文件安全</h4><p>验证文件类型、大小、内容、扩展名、存储位置和访问权限。</p></section>
  <section><h4>业务安全</h4><p>验证防刷、防重放、防薅羊毛、交易限额和关键操作二次确认。</p></section>
  <section><h4>安全配置</h4><p>检查默认账号、调试模式、错误信息、跨域策略、开放端口和依赖版本。</p></section>
  <section><h4>审计与追踪</h4><p>关键操作应有完整、可靠且受保护的审计日志。</p></section>
  <section><h4>漏洞扫描</h4><p>使用自动化工具识别常见漏洞，但扫描结果需要人工确认。</p></section>
  <section><h4>渗透测试</h4><p>在明确授权和范围内模拟攻击者，验证系统防护能力。</p></section>
  <section><h4>安全测试边界</h4><p>不得在未授权的系统、账号或数据上进行攻击性测试。</p></section>
</div>

## 兼容、部署与本地化测试 { #compatibility-deployment-localization }

软件需要适应不同平台、版本、配置、安装升级路径和区域文化。测试组合应依据用户分布、支持范围与失败影响确定优先级。

### 兼容性测试

<dl class="knowledge-definitions">
  <dt>浏览器兼容</dt><dd>验证不同浏览器、内核和版本下的功能与展示。</dd>
  <dt>操作系统兼容</dt><dd>验证不同桌面或移动操作系统及其版本。</dd>
  <dt>设备兼容</dt><dd>验证不同品牌、型号、分辨率、硬件和外设。</dd>
  <dt>版本兼容</dt><dd>验证客户端与服务端、新旧数据格式、API 版本之间的兼容。</dd>
  <dt>前向兼容</dt><dd>旧系统或旧版本能否处理新版本产生的数据或交互。</dd>
  <dt>后向兼容</dt><dd>新系统或新版本能否继续支持旧版本的数据或客户端。</dd>
  <dt>共存性</dt><dd>验证软件与其他应用同时运行时是否互相影响。</dd>
  <dt>配置兼容</dt><dd>验证不同语言、时区、网络、数据库和中间件配置。</dd>
  <dt>兼容矩阵</dt><dd>根据用户占比、业务风险和官方支持范围确定优先测试组合。</dd>
</dl>

### 安装、升级与配置测试

<dl class="knowledge-definitions">
  <dt>安装测试</dt><dd>验证全新安装、默认路径、自定义路径、依赖检查和安装失败处理。</dd>
  <dt>卸载测试</dt><dd>验证程序、服务、快捷方式和数据是否按设计移除或保留。</dd>
  <dt>升级测试</dt><dd>验证版本升级、跨版本兼容、数据迁移和配置继承。</dd>
  <dt>回滚测试</dt><dd>升级失败或上线异常时，验证程序、配置和数据能否安全恢复。</dd>
  <dt>补丁测试</dt><dd>验证补丁安装、覆盖范围、依赖、回退和对现有功能的影响。</dd>
  <dt>配置测试</dt><dd>验证默认值、合法 / 非法配置、动态生效、重启生效和配置组合。</dd>
  <dt>部署测试</dt><dd>验证部署脚本、顺序、权限、依赖、健康检查和多节点一致性。</dd>
  <dt>重复执行</dt><dd>安装或部署脚本重复执行时应保持可预测结果，避免产生重复资源。</dd>
</dl>

### 国际化与本地化测试

<dl class="knowledge-definitions">
  <dt>国际化（i18n）</dt><dd>验证产品架构是否支持多语言、多地区和不同文化规则。</dd>
  <dt>本地化（l10n）</dt><dd>验证产品针对特定语言和地区的翻译与适配质量。</dd>
  <dt>文本显示</dt><dd>检查截断、重叠、换行、占位符、复数和从右到左文字。</dd>
  <dt>字符编码</dt><dd>验证 Unicode、多语言输入、存储、搜索和导入导出。</dd>
  <dt>区域格式</dt><dd>验证日期、时间、时区、数字、货币、单位、地址和电话号码格式。</dd>
  <dt>文化适配</dt><dd>检查图片、颜色、符号、排序和表达是否符合当地习惯。</dd>
  <dt>语言切换</dt><dd>验证运行时切换、默认语言、回退语言和语言持久化。</dd>
  <dt>伪本地化</dt><dd>使用扩展或变形文本提前发现硬编码、布局和字符支持问题。</dd>
</dl>

## 易用性与无障碍测试 { #usability-and-accessibility }

易用性关注用户能否理解并高效完成目标，无障碍关注不同能力用户能否使用核心功能。两者都需要从真实任务和反馈出发，而不只是检查视觉效果。

> 本节的易用性对应 Usability，关注用户是否容易使用；可靠性中的可用性对应 Availability，关注系统需要服务时是否处于可工作状态。

<div class="knowledge-grid knowledge-grid--2">
  <section><h4>易学性</h4><p>新用户是否容易理解并学会使用系统。</p></section>
  <section><h4>操作效率</h4><p>用户能否用合理步骤快速完成目标。</p></section>
  <section><h4>防错性</h4><p>系统能否预防误操作，并在出错时提供清晰恢复方式。</p></section>
  <section><h4>一致性</h4><p>相同元素、术语和操作在不同页面应保持一致。</p></section>
  <section><h4>反馈及时性</h4><p>加载、提交、成功、失败和进度状态应得到明确反馈。</p></section>
  <section><h4>帮助与提示</h4><p>说明、占位符、错误信息和帮助内容应准确且有行动指引。</p></section>
  <section><h4>键盘可操作性</h4><p>核心功能应支持合理的焦点顺序和键盘操作。</p></section>
  <section><h4>屏幕阅读器支持</h4><p>界面应具有合适的语义、标签和替代文本。</p></section>
  <section><h4>视觉可达性</h4><p>关注颜色对比度、缩放、字号和闪烁，不能只依赖颜色传达信息。</p></section>
  <section><h4>用户测试</h4><p>邀请真实或代表性用户执行任务，观察成功率、耗时和困惑点。</p></section>
</div>

## 可靠性、韧性与容灾测试 { #reliability-resilience-recovery }

可靠性测试关注系统持续服务、容忍局部失败和恢复数据与状态的能力。验证对象包括降级、熔断、重试、故障转移、备份恢复和灾难预案。

### 可靠性、恢复与容灾测试

<dl class="knowledge-definitions">
  <dt>成熟性</dt><dd>系统在正常运行中避免故障的能力。</dd>
  <dt>可用性（Availability）</dt><dd>系统在需要时处于可工作状态的比例。</dd>
  <dt>容错性</dt><dd>部分组件或依赖失败时，系统仍能保持必要服务的能力。</dd>
  <dt>可恢复性</dt><dd>发生故障后恢复服务、状态和数据的能力。</dd>
  <dt>故障转移</dt><dd>主节点失效后能否自动或手动切换到备用节点。</dd>
  <dt>降级</dt><dd>部分功能不可用时保留核心服务，并向用户提供合理反馈。</dd>
  <dt>熔断</dt><dd>依赖持续失败时暂时停止调用，避免故障扩散。</dd>
  <dt>重试</dt><dd>临时故障后再次请求，应控制次数、间隔，并避免重复副作用。</dd>
  <dt>备份恢复测试</dt><dd>验证备份文件不仅存在，而且能够在目标时间内正确恢复。</dd>
  <dt>灾难恢复测试</dt><dd>模拟机房、区域或关键基础设施故障，验证应急预案和恢复流程。</dd>
</dl>

<div class="knowledge-grid knowledge-grid--2 knowledge-compare" role="group" aria-label="RTO 与 RPO 对比">
  <section><h4>RTO</h4><p>恢复时间目标（Recovery Time Objective）：发生灾难后，业务允许的最长恢复时间。</p></section>
  <section><h4>RPO</h4><p>恢复点目标（Recovery Point Objective）：发生灾难时，业务允许丢失的最大数据时间范围。</p></section>
</div>

**相关知识：** [环境工程化与可观测性](06-automation-and-engineering.md#environment-engineering-observability)。

---

**相关分类：** [← 应用、接口与业务测试](04-application-testing.md) · [自动化与测试工程 →](06-automation-and-engineering.md)


