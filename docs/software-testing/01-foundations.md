---
title: 测试基础与生命周期
description: 建立软件测试、质量责任、研发模型、测试策略与生命周期的整体认知。
---

# 测试基础与生命周期

<div class="section-lead">先建立共同语言，再理解测试如何贯穿软件交付全过程。</div>

## 软件测试、软件质量与质量责任 { #testing-quality-responsibility }

软件测试的核心不是机械寻找 Bug，而是围绕需求、用户价值和风险提供质量信息。质量由整个团队共同创造，测试通过评审与执行揭示问题、建立信心并支持决策。

### 软件测试概述

<dl class="knowledge-definitions">
  <dt>软件测试（Software Testing）</dt>
  <dd>通过静态或动态手段评价软件质量，验证软件是否满足规定需求和用户期望，并发现缺陷、降低产品风险。</dd>
  <dt>测试对象</dt>
  <dd>需求、设计、代码、配置、数据、接口、文档、部署流程等可以被评价的软件工作产品。</dd>
  <dt>被测对象（Test Object）</dt>
  <dd>本次测试直接评价的工作产品，可以是函数、组件、接口、完整系统或文档。</dd>
  <dt>被测系统（System Under Test）</dt>
  <dd>正在接受测试的系统。AUT（Application Under Test）常指应用，DUT（Device Under Test）常指硬件或设备。</dd>
  <dt>测试项（Test Item）</dt>
  <dd>测试范围中需要单独管理或验证的具体对象及其版本。</dd>
  <dt>测试件（Testware）</dt>
  <dd>测试活动产生或使用的工作产品，如计划、用例、脚本、数据、桩、报告和环境配置。</dd>
  <dt>测试目的</dt>
  <dd>预防和发现缺陷、提供质量信息、降低发布风险、建立质量信心并支持发布决策。</dd>
  <dt>测试依据（Test Basis）</dt>
  <dd>设计测试和判断结果所依据的需求、设计、接口文档、业务规则和行业规范。</dd>
  <dt>测试预言（Test Oracle）</dt>
  <dd>用于判断实际结果是否正确的信息来源，如明确需求、业务规则、历史正确版本或专家判断。</dd>
  <dt>可测试性（Testability）</dt>
  <dd>系统支持被有效测试的程度，例如接口清晰、日志完整、状态可重置、数据易准备、结果易观察。</dd>
</dl>

<div class="knowledge-grid knowledge-grid--2 knowledge-compare" role="group" aria-label="测试与调试的区别">
  <section>
    <h4>测试（Testing）</h4>
    <p>负责暴露问题、评价质量并验证修复结果，主要目标是提供质量信息。</p>
  </section>
  <section>
    <h4>调试（Debugging）</h4>
    <p>负责定位根因、修改实现并确认修复，通常由开发人员完成。</p>
  </section>
</div>

### 软件质量

<div class="knowledge-grid knowledge-grid--2">
  <section><h4>软件质量</h4><p>软件满足明确需求、隐含需求以及利益相关方期望的程度。</p></section>
  <section><h4>功能适合性</h4><p>功能是否完整、正确，并适合用户完成目标。</p></section>
  <section><h4>性能效率</h4><p>规定资源条件下的响应速度、吞吐能力和资源利用表现。</p></section>
  <section><h4>兼容性</h4><p>系统与其他产品共存、交换信息和协同工作的能力。</p></section>
  <section><h4>交互能力 / 易用性</h4><p>用户能否理解、学习并有效使用系统。</p></section>
  <section><h4>可靠性</h4><p>系统在规定条件和时间内持续正确运行的能力。</p></section>
  <section><h4>信息安全性</h4><p>保护数据机密性、完整性、可用性和可追责性的能力。</p></section>
  <section><h4>可维护性</h4><p>系统被分析、修改、测试和扩展的难易程度。</p></section>
  <section><h4>灵活性 / 可移植性</h4><p>系统适应不同环境、配置或平台的能力。</p></section>
  <section><h4>安全性（Safety）</h4><p>避免对人员、财产或环境造成不可接受伤害的能力，常见于医疗、交通和工业领域。</p></section>
</div>

> 未发现明显 Bug 不等于软件质量高；软件还必须解决正确的问题，并满足真实用户需求。

### QA、QC 与 Testing

<div class="knowledge-grid knowledge-grid--3 knowledge-compare" role="group" aria-label="QA、QC 与 Testing 的关系">
  <section>
    <h4>QA · 质量保证</h4>
    <p>Quality Assurance，关注过程，通过规范、评审、审计和流程改进预防质量问题。</p>
  </section>
  <section>
    <h4>QC · 质量控制</h4>
    <p>Quality Control，关注产品，通过检查和评价工作成果发现质量问题。</p>
  </section>
  <section>
    <h4>Testing · 测试</h4>
    <p>QC 的重要组成部分，通过执行或评审测试对象发现缺陷并评价质量。</p>
  </section>
</div>

> 质量是团队共同责任。产品、设计、开发、测试和运维都会影响最终质量，测试人员不是质量的唯一负责人。

### Verification 与 Validation

<div class="knowledge-grid knowledge-grid--2 knowledge-compare" role="group" aria-label="Verification 与 Validation 的区别">
  <section>
    <h4>Verification · 验证</h4>
    <p>确认工作产品是否符合规格和设计，即“是否正确地构建了产品”。需求评审、设计评审和代码审查更偏向 Verification。</p>
  </section>
  <section>
    <h4>Validation · 确认</h4>
    <p>确认最终产品是否满足用户真实需求，即“是否构建了正确的产品”。系统测试、验收测试和用户反馈更偏向 Validation。</p>
  </section>
</div>

### 软件测试原则

<div class="knowledge-grid knowledge-grid--3">
  <section><h4>测试只能证明缺陷存在</h4><p>测试能发现问题，但不能证明软件绝对没有缺陷。</p></section>
  <section><h4>穷尽测试不可能</h4><p>除极简单场景外，无法覆盖所有输入、路径和组合，应根据风险选择重点。</p></section>
  <section><h4>尽早测试</h4><p>越早发现问题，修复成本通常越低；测试应从需求阶段开始介入。</p></section>
  <section><h4>缺陷聚集</h4><p>少数复杂、高变更或高耦合模块往往包含大部分缺陷，应重点投入资源。</p></section>
  <section><h4>杀虫剂悖论</h4><p>长期重复相同用例会降低发现新问题的能力，需要持续更新测试集。</p></section>
  <section><h4>测试依赖上下文</h4><p>业务、技术、风险和合规要求不同，测试方法也应不同。</p></section>
  <section><h4>无错谬论</h4><p>即使系统几乎没有缺陷，如果不满足用户需求，产品仍可能失败。</p></section>
  <section><h4>独立测试有价值</h4><p>适当的独立性可以减少认知偏差，但不能替代团队协作。</p></section>
  <section><h4>风险驱动</h4><p>测试深度和优先级应与故障发生概率及业务影响相匹配。</p></section>
</div>

## 研发模式与质量反馈 { #development-models-quality-feedback }

研发模式决定测试介入时间、反馈速度和协作方式。无论采用顺序式还是迭代式开发，都应让质量活动尽早发生，并将线上观察重新反馈到需求和测试。

### 软件开发模型与测试模型

<dl class="knowledge-definitions">
  <dt>瀑布模型</dt>
  <dd>各阶段顺序推进，适合需求较稳定的项目，但反馈和缺陷暴露通常较晚。</dd>
  <dt>V 模型</dt>
  <dd>把开发阶段与对应测试级别关联，强调测试设计可以和开发活动同步开展。</dd>
  <dt>W 模型</dt>
  <dd>在 V 模型基础上强调需求、设计等中间产物也需要测试，突出测试尽早介入。</dd>
  <dt>迭代模型</dt>
  <dd>通过多个周期逐步完善产品，每次迭代都包含分析、开发和测试。</dd>
  <dt>增量模型</dt>
  <dd>将系统拆成多个可交付增量，逐步增加功能并持续集成测试。</dd>
  <dt>敏捷开发</dt>
  <dd>短周期交付、快速反馈、跨职能协作，测试贯穿每个迭代。</dd>
  <dt>DevOps</dt>
  <dd>强调开发、测试和运维协作，借助自动化流水线实现持续集成、交付和反馈。</dd>
  <dt>测试金字塔</dt>
  <dd>底层单元测试数量多、速度快；中层服务或接口测试适量；顶层 UI 端到端测试少而关键。</dd>
  <dt>测试奖杯模型</dt>
  <dd>更强调静态检查和集成测试，同时保留单元测试与少量端到端测试，常见于前端工程。</dd>
</dl>

### 测试左移与测试右移

<div class="knowledge-grid knowledge-grid--2 knowledge-compare" role="group" aria-label="测试左移与测试右移">
  <section>
    <h4>测试左移（Shift Left）</h4>
    <p>将质量活动提前到需求、设计和编码阶段，例如评审、静态分析、单元测试和契约测试。</p>
  </section>
  <section>
    <h4>测试右移（Shift Right）</h4>
    <p>在发布和生产阶段继续验证与观察质量，例如灰度、监控、真实用户指标和混沌工程。</p>
  </section>
</div>

<dl class="knowledge-definitions knowledge-definitions--compact">
  <dt>生产验证</dt>
  <dd>在安全、可控前提下，通过合成监控、健康检查或少量流量验证真实环境行为。</dd>
  <dt>混沌工程</dt>
  <dd>通过受控注入故障验证系统韧性，目标是发现薄弱点，而不是无计划地破坏系统。</dd>
  <dt>可观测性驱动测试</dt>
  <dd>利用日志、指标和追踪数据判断系统行为，并指导后续测试范围。</dd>
  <dt>用户反馈闭环</dt>
  <dd>将线上问题、客服反馈和使用数据转化为新的风险、用例和回归测试。</dd>
</dl>

## 测试分类、级别与策略 { #testing-map-and-strategy }

测试可以按执行方式、内部结构、目标、依据和测试级别从不同维度观察。分类不是互斥标签，真正重要的是根据风险组合适当的测试策略。

### 测试分类

<div class="knowledge-groups">
  <section class="knowledge-group" aria-labelledby="classification-runtime">
    <h4 id="classification-runtime">按是否运行程序</h4>
    <dl class="knowledge-definitions knowledge-definitions--compact">
      <dt>静态测试</dt><dd>不运行被测程序，通过评审、审查或静态分析发现问题。</dd>
      <dt>动态测试</dt><dd>运行程序并观察实际结果，验证其行为和质量属性。</dd>
    </dl>
  </section>
  <section class="knowledge-group" aria-labelledby="classification-structure">
    <h4 id="classification-structure">按对内部结构的了解程度</h4>
    <dl class="knowledge-definitions knowledge-definitions--compact">
      <dt>黑盒测试</dt><dd>不关注内部代码结构，根据需求、输入和输出验证系统行为。</dd>
      <dt>白盒测试</dt><dd>基于代码结构、条件、分支、循环和路径设计测试。</dd>
      <dt>灰盒测试</dt><dd>了解部分内部设计或数据结构，但主要从外部行为进行验证。</dd>
    </dl>
    <p class="knowledge-group__note">“静态 / 动态”和“黑盒 / 白盒 / 灰盒”属于不同分类维度。需求评审属于静态测试，但不是代码白盒测试。</p>
  </section>
  <section class="knowledge-group" aria-labelledby="classification-execution">
    <h4 id="classification-execution">按执行方式</h4>
    <dl class="knowledge-definitions knowledge-definitions--compact">
      <dt>手工测试</dt><dd>由测试人员手动操作、观察和判断结果。</dd>
      <dt>自动化测试</dt><dd>利用代码或工具自动执行、校验结果并生成报告。</dd>
    </dl>
  </section>
  <section class="knowledge-group" aria-labelledby="classification-input">
    <h4 id="classification-input">按输入与预期行为</h4>
    <dl class="knowledge-definitions knowledge-definitions--compact">
      <dt>正向测试（Positive Testing）</dt><dd>使用合法输入并按正常流程操作，验证系统能完成预期功能。</dd>
      <dt>反向 / 负向测试（Negative Testing）</dt><dd>使用非法、异常或不符合条件的输入和操作，验证系统能正确拒绝并给出合理反馈。</dd>
    </dl>
  </section>
  <section class="knowledge-group" aria-labelledby="classification-goal">
    <h4 id="classification-goal">按测试目标</h4>
    <dl class="knowledge-definitions knowledge-definitions--compact">
      <dt>功能测试</dt><dd>验证功能是否完整、正确并符合需求。</dd>
      <dt>非功能测试</dt><dd>验证性能、安全、兼容性、可靠性和易用性等质量属性。</dd>
      <dt>结构测试</dt><dd>根据程序内部结构验证代码覆盖和逻辑正确性。</dd>
      <dt>变更相关测试</dt><dd>代码或配置变化后执行确认测试和回归测试。</dd>
    </dl>
  </section>
  <section class="knowledge-group" aria-labelledby="classification-basis">
    <h4 id="classification-basis">按测试依据</h4>
    <dl class="knowledge-definitions knowledge-definitions--compact">
      <dt>基于规格的测试</dt><dd>根据需求和业务规则设计，通常属于黑盒测试。</dd>
      <dt>基于结构的测试</dt><dd>根据代码或系统内部结构设计，通常属于白盒测试。</dd>
      <dt>基于经验的测试</dt><dd>依靠经验、直觉、缺陷历史和检查表设计测试。</dd>
    </dl>
  </section>
</div>

### 测试级别

<ol class="knowledge-flow knowledge-flow--levels" aria-label="从局部到整体的测试级别">
  <li><span class="knowledge-flow__index" aria-hidden="true">1</span><span class="knowledge-flow__label">单元测试（Unit Testing）</span><span>测试函数、方法、类等最小可测试单元，通常由开发人员完成。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">2</span><span class="knowledge-flow__label">组件测试（Component Testing）</span><span>验证可独立测试的组件或模块，必要时使用测试替身隔离依赖。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">3</span><span class="knowledge-flow__label">组件集成测试</span><span>验证同一系统内组件之间的接口和交互。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">4</span><span class="knowledge-flow__label">系统集成测试</span><span>验证多个系统、外部服务或上下游之间的协作。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">5</span><span class="knowledge-flow__label">系统测试（System Testing）</span><span>针对完整系统验证功能和非功能需求。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">6</span><span class="knowledge-flow__label">验收测试（Acceptance Testing）</span><span>确认系统是否满足业务目标、合同要求并具备交付条件。</span></li>
</ol>

<dl class="knowledge-definitions">
  <dt>集成测试（Integration Testing）</dt>
  <dd>统称验证模块、组件或系统之间接口与交互的测试。</dd>
  <dt>用户验收测试（UAT）</dt>
  <dd>由业务代表或最终用户从真实业务角度确认系统能否使用。</dd>
  <dt>运营验收测试（OAT）</dt>
  <dd>验证监控、备份、恢复、部署、权限和运维流程是否满足上线要求。</dd>
  <dt>合同 / 法规验收测试</dt>
  <dd>确认软件是否满足合同条款、法律、监管或行业标准。</dd>
</dl>

<div class="knowledge-grid knowledge-grid--2 knowledge-compare" role="group" aria-label="Alpha 测试与 Beta 测试">
  <section><h4>Alpha 测试</h4><p>正式发布前，在开发方控制的环境中由内部人员或选定用户试用。</p></section>
  <section><h4>Beta 测试</h4><p>正式发布前，由真实用户在实际环境中试用并反馈问题。</p></section>
</div>

> Alpha 与 Beta 的核心区别是测试环境、参与者和所处阶段，不应机械理解为某类人员绝对不能参与。

#### 集成策略

<dl class="knowledge-definitions">
  <dt>大爆炸集成（Big Bang Integration）</dt>
  <dd>一次性组合全部组件后测试，准备简单，但问题暴露较晚且定位困难。</dd>
  <dt>增量集成</dt>
  <dd>逐步组合组件并测试，反馈更早、定位更容易，可分为自顶向下、自底向上和混合策略。</dd>
  <dt>自顶向下集成</dt>
  <dd>从上层控制模块开始逐步接入下层模块，未完成的下层模块通常由测试桩替代。</dd>
  <dt>自底向上集成</dt>
  <dd>从底层模块开始逐步向上组合，未完成的上层调用方通常由驱动程序替代。</dd>
  <dt>三明治 / 混合集成</dt>
  <dd>同时从顶层和底层推进，最后在中间层汇合。</dd>
</dl>

### 常见测试策略

<div class="knowledge-grid knowledge-grid--2 knowledge-compare" role="group" aria-label="容易混淆的常见测试策略">
  <section><h4>冒烟测试（Smoke Testing）</h4><p>快速验证版本最核心功能，判断版本是否值得继续深入测试；通常广而浅。</p></section>
  <section><h4>健全性测试（Sanity Testing）</h4><p>针对小范围变更验证关键功能和受影响区域是否基本正常；通常窄而相对深入。</p></section>
  <section><h4>确认测试 / 重测（Confirmation Testing / Retesting）</h4><p>重新执行原失败场景，回答“这个 Bug 修好了吗？”</p></section>
  <section><h4>回归测试（Regression Testing）</h4><p>验证变更是否破坏原本正常的功能，回答“修改有没有影响其他功能？”</p></section>
</div>

<dl class="knowledge-definitions knowledge-definitions--compact">
  <dt>探索性测试</dt>
  <dd>测试人员同时学习、设计和执行，根据实时发现不断调整测试方向。</dd>
  <dt>基于会话的测试</dt>
  <dd>在限定时间内围绕测试章程开展探索，并记录覆盖、问题和后续建议。</dd>
  <dt>随机测试</dt>
  <dd>通过随机输入或随机操作寻找异常，适合发现不可预期的组合问题。</dd>
  <dt>猴子测试（Monkey Testing）</dt>
  <dd>以随机、重复或极端操作验证系统对非预期行为的承受能力。</dd>
  <dt>A/B 测试</dt>
  <dd>将不同方案提供给不同用户群，通过数据比较业务效果，不等同于传统缺陷测试。</dd>
  <dt>破坏性测试</dt>
  <dd>主动制造异常、资源不足或依赖故障，验证系统的容错和恢复能力。</dd>
</dl>

> 冒烟测试与健全性测试在实际工作中可能被混用；使用时应说明本团队定义和覆盖范围。

**相关知识：** [测试设计技术](02-analysis-and-design.md#test-design-techniques)、[自动化测试策略](06-automation-and-engineering.md#test-automation-strategy)。

## 测试生命周期 { #testing-lifecycle-overview }

测试生命周期描述从理解需求到总结收尾的一组连续活动。各阶段可以迭代或并行，但都应有明确输入、输出、责任和反馈。

<ol class="knowledge-flow knowledge-flow--lifecycle" aria-label="测试生命周期">
  <li><span class="knowledge-flow__index" aria-hidden="true">1</span><span class="knowledge-flow__label">需求分析</span><span>理解业务目标和需求，识别疑问、风险、依赖及可测试性问题。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">2</span><span class="knowledge-flow__label">测试计划</span><span>确定范围、策略、资源、角色、进度、环境、风险及准入准出标准。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">3</span><span class="knowledge-flow__label">测试分析</span><span>从测试依据中识别“需要测试什么”，形成测试条件、场景和测试点。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">4</span><span class="knowledge-flow__label">测试设计</span><span>确定“如何测试”，编写用例、准备数据并明确预期结果。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">5</span><span class="knowledge-flow__label">测试实现</span><span>整理测试套件、自动化脚本、执行顺序、环境和数据，使测试具备执行条件。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">6</span><span class="knowledge-flow__label">测试执行</span><span>运行测试、记录实际结果、比较预期结果并提交缺陷。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">7</span><span class="knowledge-flow__label">缺陷跟踪</span><span>跟进缺陷分析与修复，执行确认测试和必要的回归测试。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">8</span><span class="knowledge-flow__label">测试监控与控制</span><span>持续比较实际进展与计划，分析风险并调整范围、资源或优先级。</span></li>
  <li><span class="knowledge-flow__index" aria-hidden="true">9</span><span class="knowledge-flow__label">测试完成</span><span>评估准出条件、编写报告、归档测试资产，并总结经验和改进项。</span></li>
</ol>

---

**相关分类：** [← 软件测试知识总览](index.md) · [测试分析、设计与准备 →](02-analysis-and-design.md)


