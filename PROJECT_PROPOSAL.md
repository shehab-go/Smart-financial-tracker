# إعلان مشروع: Smart Financial Tracker (مُتتبع البيانات المالية الذكي)

[English Version Below](#english)

---

## 🇾🇪 مقدمة للمجتمع اليمني للمصادر المفتوحة
أود مشاركة مشروع **Smart Financial Tracker** مع زملائي المطورين في منظمة **Yemen Open Source**. هذا المشروع هو مكتبة أندرويد متكاملة تهدف إلى تسهيل تتبع وإدارة الأحداث المالية عبر تحليل الإشعارات والرسائل النصية البنكية بشكل تلقائي وآمن.

### ✨ لماذا هذا المشروع؟
في ظل التحول الرقمي المتسارع في اليمن واعتمادنا الكبير على المحافظ الإلكترونية، برزت الحاجة لأداة برمجية تسهل على المطورين بناء تطبيقات مالية ذكية. هذا المشروع يوفر "المحرك" الأساسي لذلك، مع التركيز التام على **خصوصية المستخدم وأمان بياناته**.

### 🛠 المميزات التقنية:
- **تكنولوجيا حديثة**: مبني بالكامل باستخدام **Kotlin 2.1** و **Jetpack Compose** و **Material 3**.
- **أمان فائق**: تشفير البيانات باستخدام **AES-256 GCM** مدعوم بنظام Android KeyStore لضمان عدم تسريب البيانات المالية حتى لو فُقد الهاتف.
- **محرك تحليل ديناميكي**: يعتمد على نظام Regex مرن يسمح بإضافة قواعد تحليل لبنوك جديدة دون الحاجة لتغيير الكود.
- **دعم المحافظ اليمنية**: نهدف إلى دعم كافة المحافظ والبنوك اليمنية. تم بالفعل الانتهاء من دعم محفظة **جيب (Jeeb)** بالكامل ✅، ونحن بصدد استكمال بقية المحافظ (الكريمي، ONE Cash، موبايل موني، إلخ).
- **توثيق كامل**: موقع توثيق (API Reference) مولد بواسطة Dokka ومنشور على GitHub Pages.
- **أتمتة احترافية**: نظام CI/CD متكامل لفحص جودة الكود وبناء النسخ تلقائياً.

### 🔗 روابط المشروع:
- **المستودع (Repository)**: [Smart Financial Tracker](https://github.com/shehab-go/Smart-financial-tracker)
- **التوثيق البرمجي**: [API Reference](https://shehab-go.github.io/Smart-financial-tracker/)
- **نسخة تجريبية (APK)**: متاحة في قسم [Releases](https://github.com/shehab-go/Smart-financial-tracker/releases).

يسعدني جداً تلقي ملاحظاتكم، مراجعاتكم للكود، أو مساهماتكم لتطوير محرك التحليل ليشمل كافة الخدمات المالية في اليمن والخليج.

---

<a name="english"></a>
## 🚀 Project Announcement: Smart Financial Tracker

I am excited to introduce **Smart Financial Tracker** to the **Yemen Open Source** community. This is a professional Android library designed to simplify financial event tracking by automatically and securely parsing transaction notifications and SMS messages.

### 🌟 Vision
With the rise of digital wallets in Yemen and the region, there is a growing need for tools that help developers build smarter fintech applications. This project provides the core engine for such apps, prioritizing **user privacy and data security** above all else.

### 🔧 Technical Highlights:
- **Modern Stack**: Built with **Kotlin 2.1**, **Jetpack Compose**, and **Material 3**.
- **Bank-Grade Security**: Implements **AES-256 GCM** encryption backed by Android KeyStore.
- **Dynamic Parsing**: A flexible Regex-based engine that allows adding new bank patterns without code changes.
- **Yemeni First**: Our goal is to support every financial institution in Yemen. **Jeeb (جيب)** is already fully integrated ✅, with mFloos, ONE Cash, and others in active development.
- **DevOps Ready**: Automated CI/CD pipelines for linting, testing, and releases.

### 🔗 Useful Links:
- **Repository**: [GitHub Link](https://github.com/shehab-go/Smart-financial-tracker)
- **Documentation**: [API Reference Site](https://shehab-go.github.io/Smart-financial-tracker/)

I invite you to review the codebase, try the sample app, and contribute to making this the standard financial tracking tool for the Yemeni developer ecosystem.
