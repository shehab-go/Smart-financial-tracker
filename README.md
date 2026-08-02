# Smart Financial Tracker

[English](#english) | [العربية](#arabic)

---

<a name="english"></a>
## English

**Smart Financial Tracker** is a powerful Android library designed to simplify financial event tracking and parsing. It provides seamless integration for capturing transaction notifications and managing financial data securely.

### 🚀 Features
- **Notification Listener**: Automatically capture and parse financial SMS and app notifications.
- **Secure Storage**: Built-in AES encryption for sensitive financial data.
- **Flutter Support**: Ready-to-use Flutter plugin bridge for cross-platform integration.
- **Modular Design**: Easy to extend with custom parsers and data models.

### 📦 Installation
Add the following to your `build.gradle` (Module level):

```kotlin
dependencies {
    implementation("com.github.shehab-go:wallet-events:1.1.0")
}
```

### 🛠️ Quick Start
```kotlin
// Initialize the tracker client
val client = FinancialTrackerClient(context)
client.startListening()
```

---

<a name="arabic"></a>
## العربية

**مُتتبع البيانات المالية الذكي (Smart Financial Tracker)** هي مكتبة أندرويد قوية مصممة لتسهيل تتبع وإدارة الأحداث المالية. توفر المكتبة تكاملاً سهلاً لالتقاط إشعارات المعاملات وإدارة البيانات المالية بأمان.

### 🚀 المميزات
- **مستمع الإشعارات**: التقاط وتحليل الرسائل القصيرة وإشعارات التطبيقات المالية تلقائياً.
- **تخزين آمن**: تشفير AES مدمج لحماية البيانات المالية الحساسة.
- **دعم فلاتر (Flutter)**: جسر برمجى جاهز للتكامل مع تطبيقات فلاتر.
- **تصميم معياري**: سهولة التوسع عبر إضافة أدوات تحليل (Parsers) ونماذج بيانات مخصصة.

### 📦 التثبيت
أضف الكود التالي إلى ملف `build.gradle` الخاص بالتطبيق:

```kotlin
dependencies {
    implementation("com.github.shehab-go:wallet-events:1.1.0")
}
```

### 🛠️ تشغيل سريع
```kotlin
// تهيئة العميل المتتبع
val client = FinancialTrackerClient(context)
client.startListening()
```

## 📄 License
This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
