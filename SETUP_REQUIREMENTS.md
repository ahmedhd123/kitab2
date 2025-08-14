# ملفات إضافية مطلوبة

أحد المتطلبات التالية مفقودة من النظام الحالي:

## 1. Flutter SDK
يبدو أن Flutter غير مثبت على النظام. لتثبيت Flutter:

### Windows
1. قم بتحميل Flutter SDK من: https://flutter.dev/docs/get-started/install/windows
2. فك الضغط في مجلد (مثال: C:\flutter)
3. أضف C:\flutter\bin إلى متغير PATH
4. أعد تشغيل VS Code

### تحقق من التثبيت
```bash
flutter doctor
```

## 2. ملفات Android الأساسية
إنشاء ملفات Android المطلوبة:

### android/app/build.gradle
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        applicationId "com.kitab.reader"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
        multiDexEnabled true
    }
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

### android/app/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.kitab.reader">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

    <application
        android:label="قارئ الكتب"
        android:icon="@mipmap/ic_launcher"
        android:theme="@style/LaunchTheme">
        
        <activity
            android:name=".MainActivity"
            android:theme="@style/LaunchTheme"
            android:exported="true"
            android:launchMode="singleTop">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

## 3. ملفات iOS الأساسية

### ios/Runner/Info.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>قارئ الكتب</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>kitab_reader</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>NSCameraUsageDescription</key>
    <string>يحتاج التطبيق للكاميرا لتصوير الكتب</string>
</dict>
</plist>
```

## 4. أوامر للبدء السريع

بعد تثبيت Flutter:

```bash
# التحقق من Flutter
flutter doctor

# تثبيت المكتبات
flutter pub get

# تشغيل التطبيق (Android)
flutter run

# بناء APK
flutter build apk

# بناء للإصدار
flutter build apk --release
```

## 5. ملفات الخطوط العربية

ضع ملفات الخطوط العربية في مجلد `assets/fonts/`:
- NotoSansArabic-Regular.ttf
- NotoSansArabic-Bold.ttf

يمكن تحميلها من: https://fonts.google.com/noto/specimen/Noto+Sans+Arabic

## 6. صور تجريبية

ضع صوراً تجريبية في:
- `assets/images/` - للصور العامة
- `assets/icons/` - للأيقونات
- `assets/books/` - لأغلفة الكتب التجريبية

## 7. اختبار التطبيق

للاختبار السريع:
1. ثبت Flutter
2. نفذ `flutter pub get`
3. أعد إعداد Firebase
4. نفذ `flutter run`

إذا واجهت أي مشاكل، تحقق من:
- تثبيت Flutter بشكل صحيح
- إعداد Android SDK
- إعداد Firebase
- صلاحيات الملفات
