---
title: 测试执行与质量管理
description: 组织测试执行、缺陷闭环、质量度量、风险评价与发布决策。
---

# 测试执行与质量管理

<div class="section-lead">让每个测试结论都有证据，让缺陷和风险能够被跟踪、分析和决策。</div>

## 测试执行、结果与证据 { #test-execution-and-evidence }

测试执行不只是把用例标记为通过或失败，还要记录版本、环境、数据和客观证据。无法判断或无法执行的情况也必须使用清晰状态表达。

### 测试执行与结果

<div class="knowledge-grid knowledge-grid--3">
  <section><h4>Pass（通过）</h4><p>实际结果符合预期结果。</p></section>
  <section><h4>Fail（失败）</h4><p>实际结果与预期结果不一致。</p></section>
  <section><h4>Blocked（阻塞）</h4><p>因环境、依赖或其他缺陷导致用例无法继续执行。</p></section>
  <section><h4>Not Run（未执行）</h4><p>用例尚未运行。</p></section>
  <section><h4>Skipped（跳过）</h4><p>根据计划或条件主动不执行该用例。</p></section>
  <section><h4>Not Applicable（不适用）</h4><p>用例不适用于当前版本、平台或范围。</p></section>
</div>

<dl class="knowledge-definitions">
  <dt>测试结果 / 测试结论（Test Result / Outcome）</dt>
  <dd>某次执行产生的实际输出，以及依据预期作出的通过、失败或阻塞判断。</dd>
  <dt>测试事件（Test Incident）</dt>
  <dd>测试过程中需要进一步调查的异常，不一定最终都会被确认为软件缺陷。</dd>
  <dt>假阳性（False Positive）</dt>
  <dd>测试报告失败或告警，但被测系统实际没有对应问题，常由错误断言、环境或工具造成。</dd>
  <dt>假阴性（False Negative）</dt>
  <dd>测试显示通过或没有告警，但系统实际存在问题，风险通常高于假阳性。</dd>
  <dt>执行证据</dt>
  <dd>截图、视频、日志、请求响应、数据库记录等能支持测试结论的材料。</dd>
  <dt>测试日志</dt>
  <dd>记录执行时间、人员、环境、版本、结果和异常，便于追踪和复现。</dd>
  <dt>测试重现性</dt>
  <dd>失败场景应能在明确条件下重复触发；偶现问题也需记录频率和上下文。</dd>
</dl>

## 缺陷管理 { #defect-management }

缺陷管理将异常现象转化为可复现、可分派、可验证的工作项。概念、报告质量、影响分级和状态流转共同决定缺陷协作效率。

### 缺陷基本概念

<ol class="knowledge-flow" aria-label="从人为错误到软件失效">
  <li><span class="knowledge-flow__index" aria-hidden="true">1</span><span class="knowledge-flow__label">Error / Mistake（人为错误）</span><span>人在需求、设计、编码或操作中产生错误。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">2</span><span class="knowledge-flow__label">Defect / Fault / Bug（缺陷）</span><span>错误被引入工作产品，形成不符合需求、规范或合理期望的问题。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">3</span><span class="knowledge-flow__label">缺陷触发条件</span><span>特定输入、状态、环境或操作使潜在缺陷被触发。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">4</span><span class="knowledge-flow__label">Failure（失效）</span><span>软件运行时表现出错误行为。</span></li>
</ol>

<dl class="knowledge-definitions">
  <dt>根本原因（Root Cause）</dt>
  <dd>导致缺陷产生或未被及时发现的深层原因。</dd>
  <dt>潜伏缺陷（Latent Defect）</dt>
  <dd>已经存在于系统中，但因触发条件尚未出现而没有表现为失效的缺陷。</dd>
  <dt>缺陷屏蔽</dt>
  <dd>一个缺陷阻止另一个缺陷暴露，前者修复后后者才可能出现。</dd>
  <dt>偶现缺陷</dt>
  <dd>只在特定时序、环境、负载或数据下出现，需加强上下文和日志记录。</dd>
  <dt>已知问题（Known Issue）</dt>
  <dd>团队已经确认并记录、但当前版本仍未解决的问题，可能附带规避方案。</dd>
</dl>

### 缺陷报告

**常见字段**

<ul class="knowledge-compact-list">
  <li>Bug 编号</li><li>Bug 标题</li><li>所属项目 / 模块</li>
  <li>发现版本</li><li>测试环境</li><li>前置条件</li>
  <li>复现步骤</li><li>测试数据</li><li>预期结果</li>
  <li>实际结果</li><li>严重程度</li><li>优先级</li>
  <li>复现概率</li><li>截图 / 视频</li><li>日志 / 请求响应</li>
  <li>提交人</li><li>负责人</li><li>Bug 状态</li><li>修复版本</li>
</ul>

**高质量缺陷报告**

<div class="knowledge-grid knowledge-grid--3">
  <section><h4>标题准确</h4><p>用“位置 / 条件 + 操作 + 异常结果”概括问题。</p></section>
  <section><h4>步骤最小且完整</h4><p>删除无关操作，但保留稳定复现所需的全部条件。</p></section>
  <section><h4>预期与实际明确</h4><p>避免只写“有问题”“结果不对”。</p></section>
  <section><h4>一次聚焦一个问题</h4><p>不同根因或不同现象通常应分别提交。</p></section>
  <section><h4>证据充分</h4><p>附带时间、账号、版本、日志、截图、视频和请求信息。</p></section>
  <section><h4>客观描述</h4><p>陈述事实和影响，避免情绪化或对责任作主观判断。</p></section>
  <section><h4>先查重再提交</h4><p>确认不是已有问题，并在重复缺陷中关联原记录。</p></section>
</div>

### 缺陷严重程度与优先级

<div class="knowledge-grid knowledge-grid--2 knowledge-compare" role="group" aria-label="严重程度与优先级对比">
  <section>
    <h4>严重程度（Severity）</h4>
    <p>衡量缺陷对系统、业务、数据或用户造成的影响。</p>
    <p><strong>常见严重程度</strong></p>
    <dl class="knowledge-definitions">
      <dt>Blocker / 致命</dt><dd>系统不可用、核心流程完全阻塞，且没有可接受的绕行方案。</dd>
      <dt>Critical / 严重</dt><dd>核心功能异常、数据丢失、安全风险或大面积用户受影响。</dd>
      <dt>Major / 主要</dt><dd>重要功能存在明显问题，但影响范围有限或存在替代方案。</dd>
      <dt>Minor / 次要</dt><dd>非核心功能异常，对主要业务影响较小。</dd>
      <dt>Trivial / 轻微</dt><dd>文案、样式、易用性等轻微问题或改进建议。</dd>
    </dl>
  </section>
  <section>
    <h4>优先级（Priority）</h4>
    <p>衡量缺陷需要多快处理，由业务影响、发布时间和修复成本等共同决定。</p>
    <p><strong>常见优先级</strong></p>
    <dl class="knowledge-definitions">
      <dt>P0</dt><dd>必须立即处理，通常会阻止发布或需要紧急修复。</dd>
      <dt>P1</dt><dd>高优先级，应在当前版本尽快解决。</dd>
      <dt>P2</dt><dd>正常优先级，按计划安排修复。</dd>
      <dt>P3</dt><dd>低优先级，可在后续版本处理。</dd>
    </dl>
  </section>
</div>

> 严重程度和优先级并不完全对应。例如首页公司名称拼写错误可能严重程度低，但因影响品牌而优先级高。

### 缺陷生命周期

<ol class="knowledge-flow" aria-label="缺陷主生命周期">
  <li><span class="knowledge-flow__index" aria-hidden="true">1</span><span class="knowledge-flow__label">New</span><span>新提交，尚未完成确认或分派。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">2</span><span class="knowledge-flow__label">Assigned / Open</span><span>缺陷已确认并分派处理。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">3</span><span class="knowledge-flow__label">In Progress</span><span>负责人正在分析或修复。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">4</span><span class="knowledge-flow__label">Fixed / Resolved</span><span>开发认为问题已经解决，等待验证。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">5</span><span class="knowledge-flow__label">Retest</span><span>测试人员正在执行确认测试。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">6</span><span class="knowledge-flow__label">Verified</span><span>修复结果已验证通过。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">7</span><span class="knowledge-flow__label">Closed</span><span>缺陷流程完成并关闭。</span></li>
</ol>

<dl class="knowledge-definitions">
  <dt>Reopened</dt>
  <dd>验证未通过或问题再次出现，重新打开并回到处理流程。</dd>
  <dt>Rejected / Not a Bug</dt>
  <dd>经评估不属于缺陷。</dd>
  <dt>Duplicate</dt>
  <dd>与已有缺陷重复。</dd>
  <dt>Deferred</dt>
  <dd>确认存在，但延期到后续版本处理。</dd>
  <dt>Cannot Reproduce</dt>
  <dd>当前条件下无法复现，需要补充信息或继续观察。</dd>
  <dt>Won't Fix</dt>
  <dd>团队明确决定不修复，通常需要记录理由和风险接受者。</dd>
</dl>

## 缺陷分析与过程改进 { #defect-analysis-and-improvement }

缺陷分析关注的不只是数量，而是缺陷为何产生、为何逃逸以及如何预防。指标应服务于趋势判断和过程改进，不能脱离上下文评价个人。

### 缺陷分析

<dl class="knowledge-definitions">
  <dt>缺陷分类</dt><dd>可按模块、类型、来源、原因、严重程度、阶段和状态分类。</dd>
  <dt>根因分析（RCA）</dt><dd>寻找缺陷产生以及逃逸到后续阶段的根本原因，并制定预防措施。</dd>
  <dt>五问法（5 Whys）</dt><dd>连续追问“为什么”，逐步从表面现象定位深层原因。</dd>
  <dt>鱼骨图</dt><dd>从人员、流程、工具、环境、需求、技术等维度分析可能原因。</dd>
  <dt>缺陷密度</dt><dd>单位规模中发现的缺陷数量，可用于趋势分析，但不能脱离复杂度和风险单独评价质量。</dd>
  <dt>缺陷逃逸</dt><dd>应在较早阶段发现的缺陷直到后续阶段或生产环境才被发现。</dd>
  <dt>缺陷泄漏（Defect Leakage）</dt><dd>缺陷未在某测试阶段被发现而流入下一阶段；生产环境发现通常称为生产缺陷或线上逃逸。</dd>
  <dt>缺陷拒绝率</dt><dd>被拒绝、判为非缺陷或重复的缺陷占提交缺陷的比例，只能辅助分析需求理解和报告质量，不能脱离上下文评价个人。</dd>
  <dt>缺陷趋势</dt><dd>观察新增、修复、重开和遗留缺陷随时间的变化，判断质量是否趋于稳定。</dd>
  <dt>缺陷老化</dt><dd>缺陷从提交到当前或关闭所经历的时间，用于识别长期未处理问题。</dd>
  <dt>缺陷清除效率（DRE）</dt><dd>衡量发布前发现缺陷占发布前后已知缺陷总量的比例。</dd>
</dl>

## 覆盖、风险、度量与发布决策 { #coverage-risk-metrics-release }

覆盖率说明测试触达范围，风险说明测试投入优先级，准入准出和报告则把证据转化为发布判断。任何单一数字都不能独立证明质量。

### 测试覆盖率与追踪

<dl class="knowledge-definitions">
  <dt>需求覆盖率</dt><dd>被至少一个测试用例覆盖的需求占全部需求的比例。</dd>
  <dt>风险覆盖率</dt><dd>已被测试的已识别风险占全部关键风险的程度。</dd>
  <dt>功能覆盖率</dt><dd>测试涉及的功能点占计划功能点的比例。</dd>
  <dt>用例执行率</dt><dd>已执行用例占计划执行用例的比例。</dd>
  <dt>用例通过率</dt><dd>通过用例占已执行用例的比例。</dd>
  <dt>代码覆盖率</dt><dd>测试执行期间被运行的代码结构比例，如语句、分支和条件覆盖。</dd>
  <dt>接口覆盖率</dt><dd>被验证的接口、方法、参数和业务场景的覆盖程度。</dd>
  <dt>平台覆盖率</dt><dd>测试涉及的操作系统、浏览器、设备和配置占目标组合的程度。</dd>
  <dt>需求追踪矩阵（RTM）</dt><dd>建立需求、测试用例、执行结果和缺陷之间的对应关系。</dd>
</dl>

> 覆盖率说明“测到了多少”，不直接说明“测得有多好”。覆盖对象、断言质量和风险选择同样重要。

### 测试准入与准出

<dl class="knowledge-definitions">
  <dt>准入标准（Entry Criteria）</dt><dd>开始测试前应满足的条件，如需求基线确定、版本部署成功、环境和数据准备完成。</dd>
  <dt>暂停标准</dt><dd>当环境不可用、阻塞缺陷过多或版本质量过低时，暂时停止测试的条件。</dd>
  <dt>恢复标准</dt><dd>暂停问题解决后重新开始测试需要满足的条件。</dd>
  <dt>准出标准（Exit Criteria）</dt><dd>结束测试所需条件，如核心用例通过、重大缺陷关闭、风险被接受和报告完成。</dd>
  <dt>完成定义（Definition of Done）</dt><dd>团队对工作项“完成”的共同标准，通常包含开发、评审、测试和文档要求。</dd>
  <dt>发布标准</dt><dd>综合质量、业务、运维、安全和合规信息判断版本是否可以上线。</dd>
</dl>

### 测试风险

<div class="knowledge-grid knowledge-grid--2 knowledge-compare" role="group" aria-label="产品风险与项目风险对比">
  <section><h4>产品风险</h4><p>软件可能在功能、性能、安全、可靠性等方面失效，从而影响用户或业务。</p></section>
  <section><h4>项目风险</h4><p>人员、进度、预算、环境、工具和依赖问题可能影响测试活动完成。</p></section>
</div>

<dl class="knowledge-definitions">
  <dt>风险等级</dt><dd>常根据“发生概率 × 影响程度”评估，也可考虑可检测性和暴露频率。</dd>
  <dt>风险识别</dt><dd>从需求复杂度、技术新颖性、变更频率、缺陷历史、业务价值和用户规模等方面识别。</dd>
  <dt>风险缓解</dt><dd>增加评审、提高测试深度、提前搭建环境、自动化回归或准备替代方案。</dd>
  <dt>风险规避</dt><dd>改变设计、范围或计划，消除风险来源。</dd>
  <dt>风险转移</dt><dd>通过合同、保险或第三方服务转移部分责任，但无法转移全部质量责任。</dd>
  <dt>风险接受</dt><dd>明确了解风险后决定承担，应记录理由、影响和批准人。</dd>
  <dt>剩余风险</dt><dd>采取措施后仍然存在的风险，需要在测试报告和发布决策中说明。</dd>
</dl>

### 测试报告与测试度量

<dl class="knowledge-definitions">
  <dt>测试进度</dt><dd>计划与实际的用例设计、执行和缺陷处理进展。</dd>
  <dt>测试结果</dt><dd>通过、失败、阻塞、未执行和不适用用例数量及比例。</dd>
  <dt>缺陷情况</dt><dd>按严重程度、优先级、模块和状态统计缺陷。</dd>
  <dt>覆盖情况</dt><dd>需求、风险、功能、环境和代码等覆盖程度。</dd>
  <dt>遗留问题</dt><dd>未解决缺陷、已知限制、绕行方案和潜在影响。</dd>
  <dt>质量风险</dt><dd>说明已经降低、仍然存在以及需要业务接受的风险。</dd>
  <dt>测试结论</dt><dd>基于证据说明是否达到准出标准，并给出发布建议。</dd>
  <dt>经验总结</dt><dd>记录有效实践、过程问题和后续改进措施。</dd>
  <dt>度量原则</dt><dd>指标用于支持判断和改进，不应脱离上下文，也不应简单用于个人绩效排名。</dd>
  <dt>常见误区</dt><dd>用例数量多、Bug 数量多或代码覆盖率高，都不能单独证明测试质量高。</dd>
</dl>

**相关知识：** [测试计划](02-analysis-and-design.md#test-planning-and-resources)、[测试生命周期](01-foundations.md#testing-lifecycle-overview)。

---

**相关分类：** [← 测试分析、设计与准备](02-analysis-and-design.md) · [应用、接口与业务测试 →](04-application-testing.md)


