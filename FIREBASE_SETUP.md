# إعداد Firebase لتطبيق قارئ الكتب

## الخطوات المطلوبة

### 1. إنشاء مشروع Firebase
1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. انقر على "إنشاء مشروع" أو "Create a project"
3. اختر اسماً للمشروع (مثل: kitab-reader)
4. فعّل Google Analytics إذا كنت تريد

### 2. إضافة تطبيق Android
1. في صفحة المشروع، انقر على أيقونة Android
2. في package name، ضع: `com.kitab.reader`
3. حمّل ملف `google-services.json`
4. ضع الملف في: `android/app/google-services.json`

### 3. إضافة تطبيق iOS
1. في صفحة المشروع، انقر على أيقونة iOS
2. في Bundle ID، ضع: `com.kitab.reader`
3. حمّل ملف `GoogleService-Info.plist`
4. ضع الملف في: `ios/Runner/GoogleService-Info.plist`

### 4. تفعيل خدمات Firebase

#### Authentication
1. في Firebase Console، اذهب لقسم Authentication
2. اذهب لتبويب "Sign-in method"
3. فعّل "Email/Password"

#### Cloud Firestore
1. في Firebase Console، اذهب لقسم Firestore Database
2. انقر على "Create database"
3. اختر "Start in test mode" للبداية
4. اختر الموقع الأقرب لك

#### Firebase Storage
1. في Firebase Console، اذهب لقسم Storage
2. انقر على "Get started"
3. اختر "Start in test mode"
4. اختر الموقع الأقرب لك

### 5. قواعد الأمان (مؤقتة للتطوير)

#### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // القراءة والكتابة للمستخدمين المسجلين
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 6. بيانات العينة

#### مجموعة books
```json
{
  "title": "كتاب تجريبي",
  "author": "مؤلف تجريبي",
  "description": "وصف الكتاب التجريبي...",
  "category": "أدب",
  "coverImageUrl": "https://example.com/cover.jpg",
  "fileUrl": "https://example.com/book.pdf",
  "fileType": "pdf",
  "averageRating": 4.5,
  "totalReviews": 10,
  "createdAt": "2024-01-01T00:00:00Z",
  "tags": ["أدب", "رواية"],
  "pageCount": 200,
  "language": "ar"
}
```

#### مجموعة users
```json
{
  "uid": "user-id",
  "email": "user@example.com",
  "displayName": "اسم المستخدم",
  "createdAt": "2024-01-01T00:00:00Z",
  "favoriteBooks": [],
  "readingProgress": {}
}
```

#### مجموعة reviews
```json
{
  "bookId": "book-id",
  "userId": "user-id",
  "userName": "اسم المستخدم",
  "userPhotoUrl": "",
  "rating": 5.0,
  "comment": "مراجعة رائعة للكتاب...",
  "createdAt": "2024-01-01T00:00:00Z",
  "likes": [],
  "dislikes": []
}
```

## ملاحظات مهمة

1. **الأمان**: قم بتحديث قواعد الأمان قبل النشر
2. **الحدود**: راجع حدود الاستخدام المجاني لـ Firebase
3. **التكلفة**: راقب الاستخدام لتجنب التكاليف غير المتوقعة
4. **النسخ الاحتياطي**: فعّل النسخ الاحتياطي لقاعدة البيانات

## ملفات التكوين المطلوبة

تأكد من إضافة هذه الملفات بعد تحميلها من Firebase:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

لا تشارك هذه الملفات في Git لأسباب الأمان.
