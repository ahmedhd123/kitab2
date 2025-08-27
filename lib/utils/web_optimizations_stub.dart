import 'package:flutter/foundation.dart';

/// بديل خامد لا يقوم بأي شيء على الأنظمة غير الويب حتى لا يفشل البناء
class WebOptimizations {
  static void initialize() {
    if (kIsWeb) return; // لا شيء على غير الويب
  }
}
