# الدليل الإرشادي الصارم للذكاء الاصطناعي (AI Agent Core Rules)
**مشروع: المتتبع المالي الذكي (Smart Financial Tracker)**

> [!IMPORTANT]
> **تنبيه هام لأي وكيل ذكاء اصطناعي (AI Agent) يعمل على هذا المشروع:**
> هذا المستند هو "الدستور البرمجي والفلسفي" للمشروع. يمنع منعاً باتاً كتابة أي كود أو اقتراح أي تصميم أو تعديل يخالف المبادئ المعمارية وتصميم تجربة المستخدم المذكورة هنا.

---

## 1. الفلسفة الأساسية (Core Philosophy)
1. **Invisible Design (التصميم غير المرئي):** التطبيق يعمل كمراقب صامت في الخلفية. لا يُطالب المستخدم بإدخال بيانات يدوية أبداً إلا كخيار ثانوي (لتسجيل النقد/الكاش).
2. **Zero-Touch Automation:** يجب أن تُصمم جميع ميزات التطبيق لتعمل بأقل عدد ممكن من النقرات (Zero Clicks إن أمكن).
3. **Local-First & Privacy (الأولوية للمحلية والخصوصية):** يُمنع إرسال أي بيانات مالية أو نصوص إشعارات أو رسائل خاصة بالمستخدم إلى أي خوادم خارجية للتحليل. تتم معالجة النصوص وتصنيف المعاملات محلياً بنسبة 100% داخل الهاتف باستخدام قاعدة البيانات المحلية (Room DB).

---

## 2. قواعد نظام التصميم (Design System Rules)
يجب الامتثال الكامل لنظام التصميم البرمجي الموحد للتطبيق، ويُحظر تماماً كتابة ألوان Hex أو أحجام وأبعاد يدوية مبعثرة:
1. **الألوان (Colors):** يجب الاستيراد من [`AppColors`](file:///E:/Smartfinancialtracker/app/src/main/java/com/shehabgo/smartfinancialtracker/ui/theme/AppColors.kt) دائماً.
   - اللون الرئيسي للتطبيق: `AppColors.Primary` (اللون الأحمر المعتمد).
   - ألوان الحالات: `AppColors.Success` (الأخضر)، `AppColors.Warning` (البرتقالي)، `AppColors.Error` (الأحمر الناري/الخطأ)، `AppColors.Info` (الأزرق).
   - يُمنع استخدام `Color(0xFF...)` بشكل مباشر في الشاشات.
2. **الأبعاد والمسافات (Spacing):** يجب استخدام الثوابت من [`AppSpacing`](file:///E:/Smartfinancialtracker/app/src/main/java/com/shehabgo/smartfinancialtracker/ui/theme/AppSpacing.kt) لتنظيم الفراغات والحواف والمسافات:
   - الفراغات القياسية: `AppSpacing.xs` (4.dp), `AppSpacing.sm` (8.dp), `AppSpacing.md` (12.dp), `AppSpacing.base` (16.dp), `AppSpacing.lg` (20.dp), `AppSpacing.xl` (24.dp).
   - حواف الشاشات: استخدام `AppSpacing.ScreenH` و `AppSpacing.ScreenV`.
   - أحجام الأيقونات: استخدام `AppSpacing.IconSm` أو `AppSpacing.Icon` أو `AppSpacing.IconMd` أو `AppSpacing.IconLg`.
3. **الأشكال والزوايا (Shapes):** يجب استخدام أشكال الزوايا الدائرية المحددة في [`AppShapes`](file:///E:/Smartfinancialtracker/app/src/main/java/com/shehabgo/smartfinancialtracker/ui/theme/AppShapes.kt):
   - البطاقات: `AppShapes.Card` (14.dp) أو `AppShapes.CardLg` (20.dp).
   - الأزرار وحقول النصوص: `AppShapes.Button` (12.dp) و `AppShapes.Field` (12.dp).
   - القوائم المنبثقة السفلية: `AppShapes.Sheet`.
4. **الظلال (Elevation):** استخدام قيم الظلال الموحدة من `AppElevation` مثل `AppElevation.xs` للبطاقات العادية و `AppElevation.sheet` للقوائم السفلية.

---

## 3. منهجية موديول الالتقاط (Capture Module Methodology)
يعتبر موديول الالتقاط [`financial_tracker`](file:///E:/Smartfinancialtracker/financial_tracker) هو القلب النابض للتطبيق المسؤول عن قراءة وتفسير الإشعارات وحفظها تفاعلياً.

1. **التطوير الموجه بالإعدادات (Config-Driven Development):**
   - يُمنع كتابة أي شروط تحليل (If-Else) أو تعبيرات نمطية (Regex) لمعالجة الرسائل البنكية أو رسائل المحافظ الإلكترونية داخل كود Kotlin.
   - يجب كتابة وتعديل كافة شروط المعالجة حصرياً في ملف الإعدادات المركزي [`financial_tracker_config.json`](file:///E:/Smartfinancialtracker/financial_tracker/src/main/assets/financial_tracker_config.json).
2. **فصل المكونات التام (Decoupling):**
   - موديول `financial_tracker` مستقل تماماً عن واجهة مستخدم التطبيق الرئيسية (`app`).
   - يقوم الموديول بالتقاط الإشعار عبر [`FinancialNotificationListener`](file:///E:/Smartfinancialtracker/financial_tracker/src/main/java/com/financial/tracker/module/FinancialNotificationListener.kt)، وتفسيره عبر `DynamicParser` ثم بث البيانات تفاعلياً كتدفقات.
   - يجب على واجهة المستخدم الاستماع للتدفقات عبر `StateFlow/SharedFlow` باستخدام `collectAsStateWithLifecycle` لتحديث الشاشة فوراً دون الحاجة إلى سحب الشاشة للتحديث (No Pull-to-Refresh).
3. **توافق تصنيفات المعاملات (Transaction Types):**
   - يدعم المحلل الافتراضي أنواع المعاملات الأساسية التالية:
     * `Transfer Out` (تحويل صادر)
     * `Transfer In` (تحويل وارد)
     * `Purchase` (مشتريات)
     * `Refund` (عكس عملية / استرداد)
     * `Payment` (سداد خدمات / فواتير)
     * `Donation` (تبرعات)
     * `Withdraw` (سحب نقدي)
   - يجب أن ترتبط هذه الأنواع مباشرة بالفئات المعروضة في واجهة المستخدم لضمان اتساق البيانات.

---

## 4. ميكانيكية النجاة والتعافي من الأخطاء (Resilience & Error Recovery)
1. **فخ الاحتجاز (The Fallback Trap):**
   - عند التقاط إشعار من تطبيق محفظة مستهدفة وفشل قواعد الـ Regex في تفسيره، يُمنع تجاهله أو حذفه.
   - يجب حفظ الإشعار كرسالة خام في جدول `UnparsedNotification`.
2. **إعادة المعالجة الارتدادية (Retroactive Reprocessing):**
   - يجب توفير خيار واجهة يتيح للمستخدم أو المطور استدعاء دالة `reprocessUnparsedLogs()`.
   - عند تحديث ملف JSON المركزي بالقواعد الجديدة، تمكن هذه الدالة النظام من إعادة تحليل جميع الرسائل غير المفسرة مسبقاً وتحويلها إلى معاملات صحيحة بأثر رجعي.
3. **إدارة استهلاك البطارية (Battery Optimization):**
   - يجب توجيه المستخدم بوضوح لتعطيل ميزة "تحسين البطارية" (Ignore Battery Optimizations) لخدمة الاستماع لضمان عدم قتل النظام للخدمة في الخلفية.

---

## 5. العلاقات الاجتماعية والديون (Social FinTech Ledger)
1. **سياق النية الذكي (Intent-Aware Prompts):**
   - عند التقاط حوالة شخصية صادرة لجهة اتصال، يجب إظهار بطاقة تفاعلية خفيفة تسأل المستخدم: *"هل الحوالة سلفة له 🤝 أم سداد لدين سابق ↩️؟"* لتصنيف المعاملة بنقرة واحدة.
   - دمج كافة المعاملات الآلية واليدوية في جدول زمني موحد (Unified Timeline).
2. **التسوية بالسحب والإسقاط (Drag & Drop Settlement):**
   - دعم سحب العمليات والتحويلات لإسقاطها فوق الديون والالتزامات المفتوحة لتسويتها وتصفيتها بصرياً وبرمجياً بشكل فوري.

---
**إقرار الذكاء الاصطناعي (AI Acknowledgement):**
يجب على أي وكيل ذكاء اصطناعي (AI Agent) يقرأ هذا المستند الالتزام التام ببنوده وتطبيقها بصرامة في أي اقتراح برمجي، تصميمي، أو نقاش تقني، واعتبارها خطوطاً حمراء لا يجوز تجاوزها.
