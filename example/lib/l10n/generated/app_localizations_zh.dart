// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'AOPD 示例';

  @override
  String get routeNotFound => '未找到页面';

  @override
  String get commonRun => '运行';

  @override
  String get commonReset => '重置';

  @override
  String get commonClear => '清空';

  @override
  String get commonTarget => '目标代码';

  @override
  String get commonAspect => '切面代码';

  @override
  String get resultLogTitle => '结果日志';

  @override
  String get resultLogEmpty => '运行一个示例后，这里会显示目标代码和切面的事件。';

  @override
  String get homeSubtitle => '面向 AOPD 注解和编译期织入的 Flutter 示例。';

  @override
  String get homeHeroPill => '编译扩展示例';

  @override
  String get homeHeroTitle => '通过可见的应用行为观察 AOPD 织入。';

  @override
  String get homeHeroBody =>
      '每个示例都有目标代码、切面、运行按钮和实时结果日志，方便继续扩展示例，也不会隐藏 AOP 的运行机制。';

  @override
  String get languageSystem => '系统';

  @override
  String get languageEnglish => 'EN';

  @override
  String get languageChinese => '中文';

  @override
  String get languageTooltip => '语言';

  @override
  String get basicPageSubtitle => '一次选择一个注解。每个详情页会把示例和结果日志放在一起。';

  @override
  String get basicExecuteDescription => '包裹目标方法体，并且可以修改返回值。';

  @override
  String get basicExecuteDetail => '切面运行在原方法体周围，然后调用 proceed。';

  @override
  String get basicCallDescription => '改写调用点，让切面能在 proceed 前检查参数。';

  @override
  String get basicCallDetail => '目标方法保持不变，调用点会被重定向到切面。';

  @override
  String get basicFieldGetDescription => '拦截字段读取，并替换观察到的值。';

  @override
  String get basicFieldGetDetail => '字段本身仍是原始值，但匹配调用点读取时会看到切面返回的值。';

  @override
  String get basicInjectDescription => '在目标函数的稳定行号处插入语句。';

  @override
  String get basicInjectDetail => '插入语句会出现在目标函数的标记行。';

  @override
  String get basicInjectClassTitle => '@Inject（类字段）';

  @override
  String get basicInjectClassDescription => '向类方法注入语句；注入代码引用目标类字段，并在注入时完成重映射。';

  @override
  String get basicInjectClassDetail =>
      'InjectClassTarget.compute() 会在 return 前注入 value = value + 100；value 引用会映射到目标字段。';

  @override
  String get basicInjectScopeTitle => '@Inject（库范围）';

  @override
  String get basicInjectScopeDescription =>
      '两个库声明同名类和方法；@Inject 只命中其中一个，并遵守 importUri。';

  @override
  String get basicInjectScopeDetail =>
      'inject_dedup_a 和 inject_dedup_b 都声明 DedupTarget.compute；只有 inject_dedup_a 被指定，所以只有它会被织入。';

  @override
  String get basicAddDescription => '向目标类追加新方法，并通过 dynamic dispatch 调用它。';

  @override
  String get basicAddDetail => '这个方法在源码里不存在；AOPD 会在编译期间添加它。';

  @override
  String get basicExecuteResult => 'Execute 结果';

  @override
  String get basicCallResult => 'Call 结果';

  @override
  String get basicFieldGetResult => 'FieldGet 结果';

  @override
  String get basicInjectResult => 'Inject 结果';

  @override
  String get basicInjectClassResult => 'Inject（类字段）结果';

  @override
  String get basicInjectScopeResult => 'Inject（库范围）结果';

  @override
  String get basicAddResult => 'Add 结果';

  @override
  String get advancedMatrixTitle => 'PointCut 矩阵';

  @override
  String get advancedMatrixDescription =>
      '运行每一种切点形式，并记录 source、target、members、annotations 和 arguments。';

  @override
  String get advancedMatrixResult => '进阶结果';

  @override
  String get argSendDirtyInput => '发送脏输入';

  @override
  String get argSendDirtyInputBody => '每个按钮都会用原始输入调用方法。切面会在方法体看到参数之前改写它们。';

  @override
  String get argLogPii => '记录含 PII 的日志';

  @override
  String get argRegisterMessy => '注册混乱输入';

  @override
  String get argNoRewrites => '还没有改写记录。';

  @override
  String get argBefore => '改写前';

  @override
  String get argAfter => '改写后';

  @override
  String get argReceivedTitle => '方法实际收到的内容';

  @override
  String get argReceivedBody => '证明输入真的被改了，而不只是被记录：方法体会报告改写后的值。';

  @override
  String get argNothingReceived => '还没有收到内容。';

  @override
  String get coverageExerciseUnits => '运行覆盖单元';

  @override
  String get coverageExerciseUnitsBody =>
      '每个按钮都会运行真实 catalog 代码。织入的切面会先记录命中，再继续执行，行为不变。';

  @override
  String get coverageUseCart => '使用购物车';

  @override
  String get coverageRunCheckout => '运行结账';

  @override
  String get coverageOnboardingStart => '开始引导';

  @override
  String get coverageOnboardingFinish => '完成引导';

  @override
  String get coverageFormatPrice => '格式化价格';

  @override
  String get coverageRunAll => '运行所有可达项';

  @override
  String get coverageExportJson => '导出 JSON';

  @override
  String get coverageUploadPayload => '上传载荷';

  @override
  String get coverageClose => '关闭';

  @override
  String get coverageCatalogUnits => 'Catalog 单元';

  @override
  String get coverageNeverInvoked => '从未调用 - 可能是死代码';

  @override
  String get coverageCovered => '已覆盖';

  @override
  String get coverageUnitsHit => '个单元命中';

  @override
  String get aroundTimingTitle => '耗时统计 + 慢调用告警';

  @override
  String aroundTimingSubtitle(int thresholdMs) {
    return 'Stopwatch 包裹 proceed()。更大的输入会超过 $thresholdMs ms 阈值并被标记；ReportService 自己没有任何计时代码。';
  }

  @override
  String get aroundFastReport => '快速报表（1）';

  @override
  String get aroundHeavyReport => '重型报表（12）';

  @override
  String get aroundTimingEmpty => '运行一个报表后，这里会显示测量到的耗时。';

  @override
  String get aroundSlowBadge => '慢';

  @override
  String get aroundCacheTitle => '短路缓存';

  @override
  String get aroundCacheSubtitle =>
      '缓存命中时，切面不调用 proceed() 直接返回，所以真正的 quote() 不会执行。计数器就是证明：只有原方法体执行时才会增加。';

  @override
  String get aroundQuoteSkuA => '报价 SKU-A';

  @override
  String get aroundQuoteSkuB => '报价 SKU-B';

  @override
  String get aroundCacheEmpty => '连续报价同一个 SKU：第一次 MISS 会运行方法体，第二次 HIT 会跳过它。';

  @override
  String get aroundRealComputations => '真实计算次数';

  @override
  String get guardTriggerTitle => '触发失败';

  @override
  String get guardTriggerBody =>
      '每个按钮都会调用一个会抛异常的方法。没有 guard 时点击处理会抛出；有 guard 时会得到下面的 fallback 值。';

  @override
  String get guardParseThrows => '解析 \"12x\" -> 抛异常';

  @override
  String get guardDivideThrows => '除以 0 -> 抛异常';

  @override
  String get guardFeedThrows => '不稳定 feed -> 首次抛异常';

  @override
  String get guardParseOk => '解析 \"42\" -> 成功';

  @override
  String guardReturnedValue(String value) {
    return '返回给 UI 的值：$value';
  }

  @override
  String get guardCaughtTitle => '已捕获并恢复';

  @override
  String get guardCaughtEmpty => '还没有失败。触发一个失败后，它会在这里被捕获，而不是抛到 UI。';

  @override
  String get guardThrew => '抛出';

  @override
  String get guardFallback => 'fallback';

  @override
  String get jsonModelPanelTitle => '模型（没有 toJson 逻辑）';

  @override
  String get jsonOutputTitle => 'sampleUser.toJson() - 由 AOP 生成';

  @override
  String jsonWovenStatus(int count) {
    return '已织入：从 stub 序列化了 $count 个字段。';
  }

  @override
  String get jsonUnwovenStatus => '未织入：toJson() 返回了空 map（请运行一次完整构建）。';

  @override
  String get jsonNote =>
      '反序列化（写字段）是相反方向；AOPD 的 members 捕获偏向读取，所以 fromJson 通常会使用 factory 或支持写入的 transformer。这里已经自动完成了读取侧，也就是通常需要 mirrors 或代码生成的部分。';

  @override
  String get patchEnableTitle => '启用框架 Patch';

  @override
  String patchActiveSubtitle(String factor) {
    return '已启用：缩放尺寸被限制在字体大小的 ${factor}x。';
  }

  @override
  String get patchOffSubtitle => '关闭：切面直接 proceed，保持纯 Flutter 行为。';

  @override
  String patchSystemScale(String scale) {
    return '系统字体缩放：${scale}x';
  }

  @override
  String patchCap(String scale) {
    return 'Patch 上限：${scale}x（布局开始崩坏前允许的最大无障碍放大）';
  }

  @override
  String get patchPreviewTitle => '实时预览';

  @override
  String get patchPreviewBody =>
      '同一个 Text 会经过织入后的 scaler 渲染。把系统缩放调高：没有 patch 时会溢出；打开后会停在上限。';

  @override
  String get patchPreviewText => '结账';

  @override
  String get patchNoClamps => '还没有发生限制。';

  @override
  String patchClampsApplied(int count) {
    return '限制次数（来自织入的 SDK 方法）：$count';
  }

  @override
  String patchScaleReturned(double size) {
    return 'scale($size) 返回';
  }

  @override
  String get patchPatched => '已 patch';

  @override
  String get patchPureFlutter => '纯 Flutter';

  @override
  String get analyticsBriefTitle => '业务代码零埋点的完整追踪';

  @override
  String get analyticsBriefBody =>
      '切面会 hook HitTestTarget.handleEvent 和 GestureRecognizer.invokeCallback。点击任意卡片、按钮或弹窗动作，就能生成带 AOPD widget 创建位置的统一埋点事件。';

  @override
  String get analyticsClearLog => '清空日志';

  @override
  String get analyticsProductNotesSubtitle => '用于编译器实验的便携笔记本';

  @override
  String get analyticsProductMugSubtitle => '陪伴 dill dump 长夜的热饮杯';

  @override
  String get analyticsConfirmPurchase => '确认购买';

  @override
  String get analyticsDialogBody => '这个弹窗里也没有埋点代码。点击动作后观察日志即可。';

  @override
  String get analyticsCancel => '取消';

  @override
  String get analyticsConfirmOrder => '确认下单';

  @override
  String get analyticsBuyNow => '立即购买';

  @override
  String get analyticsApplyCoupon => '使用优惠券';

  @override
  String get analyticsContactSupport => '联系支持';

  @override
  String get wildcardDemoTitle => '一个切点，三个类';

  @override
  String get wildcardDemoDescription =>
      '每个按钮都会运行不同类里的真实代码。它们都没有单独标注；一个 @Execute 正则就能全部覆盖。';

  @override
  String get wildcardWhyTitle => '为什么这里没有百分比？';

  @override
  String get wildcardWhyBody =>
      '通配切点可以织入预先没有声明的类，而 Flutter 运行时又没有反射可以枚举它们。所以这个示例会在代码运行时发现单元。生产环境里的分母来自构建期类列表；覆盖率由上传的命中和那份列表离线计算。';

  @override
  String get wildcardCollectorNote => '收集器故意放在被匹配目录之外；否则切面会织入自己并递归。';

  @override
  String wildcardDiscoveredUnits(int count) {
    return '已发现单元（$count）';
  }

  @override
  String get wildcardEmpty => '还没有记录。运行示例后，织入的切面会记录并显示命中的单元。';

  @override
  String get sectionCoreTitle => '核心注解';

  @override
  String get sectionCoreSubtitle => '用小闭环展示每一种织入原语。';

  @override
  String get sectionObservabilityTitle => '可观测性';

  @override
  String get sectionObservabilitySubtitle => '埋点、链路追踪、性能监控和覆盖率。';

  @override
  String get sectionBehaviorTitle => '运行时行为';

  @override
  String get sectionBehaviorSubtitle => '异常保护、灰度开关、缓存和输入控制。';

  @override
  String get sectionCompilerTitle => '编译期方案';

  @override
  String get sectionCompilerSubtitle => '框架 patch 和生成式能力示例。';

  @override
  String get sectionOtherTitle => '其它示例';

  @override
  String get sectionOtherSubtitle => '更多 AOPD 示例。';

  @override
  String get routeAdvancedRecipesTitle => '进阶用法';

  @override
  String get routeAdvancedRecipesDescription =>
      '实例、静态、构造函数、库函数、正则切点和 PointCut 数据。';

  @override
  String get routeArgumentRewriteTitle => '参数改写';

  @override
  String get routeArgumentRewriteDescription => '切面在方法执行前改写输入，可用于 PII 脱敏和输入清洗。';

  @override
  String get routeAroundAdviceTitle => '环绕增强';

  @override
  String get routeAroundAdviceDescription => '统计方法耗时、标记慢调用，并通过跳过原方法实现缓存。';

  @override
  String get routeAutoAnalyticsTitle => '自动埋点';

  @override
  String get routeAutoAnalyticsDescription => '贴近真实点击埋点的完整追踪示例。';

  @override
  String get routeBasicAnnotationsTitle => '基础注解';

  @override
  String get routeBasicAnnotationsDescription =>
      '用小闭环展示 Aspect、Execute、Call、FieldGet、Inject 和 Add。';

  @override
  String get routeCodeCoverageTitle => '代码覆盖率';

  @override
  String get routeCodeCoverageDescription => '通过织入命中记录实现方法级覆盖率。';

  @override
  String get routeExceptionGuardTitle => '异常保护';

  @override
  String get routeExceptionGuardDescription =>
      '织入 try/catch，把抛异常的方法降级为安全 fallback，避免应用崩溃。';

  @override
  String get routeFeatureFlagsTitle => '灰度开关';

  @override
  String get routeFeatureFlagsDescription => '通过切面承载灰度行为，业务方法保持稳定。';

  @override
  String get routeFrameworkPatchTitle => '框架 Patch';

  @override
  String get routeFrameworkPatchDescription =>
      '无需 fork SDK，直接 patch Flutter 私有方法来限制字体缩放。';

  @override
  String get routeJsonModelTitle => 'JSON 模型';

  @override
  String get routeJsonModelDescription =>
      '不用 dart:mirrors，通过 AOP 自动序列化模型，toJson 不写字段代码。';

  @override
  String get routeNetworkTracingTitle => '网络追踪';

  @override
  String get routeNetworkTracingDescription =>
      '不在请求代码里写日志，也能记录 traceId、耗时和状态码。';

  @override
  String get routePerformanceBuildTitle => '构建追踪';

  @override
  String get routePerformanceBuildDescription =>
      '统计 performRebuild 产生的慢 widget rebuild。';

  @override
  String get routePerformanceFrameTitle => '帧阶段';

  @override
  String get routePerformanceFrameDescription =>
      '统计帧耗时以及 build/layout/paint 阶段成本。';

  @override
  String get routePerformanceImageTitle => '图片加载';

  @override
  String get routePerformanceImageDescription => '统计图片缓存 miss 和解码行为。';

  @override
  String get routePerformanceMonitoringTitle => '性能监控';

  @override
  String get routePerformanceMonitoringDescription =>
      '展示 widget rebuild、帧阶段和图片加载监控的实用 AOP 示例。';

  @override
  String get routeWildcardCoverageTitle => '通配覆盖率';

  @override
  String get routeWildcardCoverageDescription => '一个正则切点覆盖整个包子树，不需要逐类标注。';

  @override
  String get networkTitle => '网络追踪';

  @override
  String get networkSubtitle =>
      '一个实用的可观测性模式：API 方法只返回业务数据，织入的切面负责追加 traceId、耗时、状态码和结果日志。';

  @override
  String get networkRunApiCalls => '运行 API 调用';

  @override
  String get networkRunApiCallsBody =>
      '每个按钮都会调用一个普通 service 方法。trace 来自 @Execute 的包裹，而不是目标方法自己写日志。';

  @override
  String get networkFetchOrder => '查询订单';

  @override
  String get networkSubmitPayment => '提交支付';

  @override
  String get networkPaymentReview => '支付复核';

  @override
  String get networkSearch => '搜索';

  @override
  String get networkTraceRecords => '追踪记录';

  @override
  String get networkTraceEmpty => '还没有 trace。运行一次 API 调用后会看到织入的元数据。';

  @override
  String get featureTitle => '灰度开关';

  @override
  String get featureSubtitle => 'AOP 常用于灰度发布：业务方法保持稳定，实验、路由或短路逻辑放到切面里。';

  @override
  String get featureToggleExperiments => '切换实验';

  @override
  String get featureToggleExperimentsBody =>
      '目标 service 里只有 legacy 规则。切面读取开关，然后决定 proceed、增强返回值或直接短路。';

  @override
  String get featureCheckoutV2Title => 'checkout_v2 折扣';

  @override
  String get featureCheckoutV2Subtitle => '增强 proceed() 的结果';

  @override
  String get featureGatewayV2Title => 'gateway_v2 路由';

  @override
  String get featureGatewayV2Subtitle => '可以不执行 proceed() 直接返回';

  @override
  String get featureVipDiscount => 'VIP 折扣';

  @override
  String get featureLargeCart => '大额购物车';

  @override
  String get featureEuGateway => '欧盟网关';

  @override
  String get featureUsGateway => '美国网关';

  @override
  String get featureFlagDecisions => '开关决策';

  @override
  String get featureFlagEmpty => '还没有决策。切换开关并运行一个 service 方法。';

  @override
  String get featureFlagOn => '开启';

  @override
  String get featureFlagOff => '关闭';
}
