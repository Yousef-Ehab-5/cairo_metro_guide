import 'package:flutter/material.dart';
import 'app.dart';
// 1. استيراد ملف التخزين
import 'metro/storage.dart';

// 2. إضافة async هنا
void main() async { 
  WidgetsFlutterBinding.ensureInitialized();

  // 3. استدعاء دالة التهيئة
  await AppStorage.init(); 


  // // . تجربة حفظ بيانات وهمية
  // await AppStorage.saveUserSession(
  //   token: 'test_token_12345',
  //   userId: 'user_001',
  //   userName: 'Mervana',
  // );

  // // . تجربة قراءة البيانات والطباعة في الـ Console
  // String? savedToken = AppStorage.getToken();
  // bool isLoggedIn = AppStorage.isLoggedIn();

  // debugPrint('--- نتائج اختبار الـ Storage ---');
  // debugPrint('Saved Token: $savedToken');
  // debugPrint('Is Logged In: $isLoggedIn');
  // debugPrint('--------------------------------');
  
// بتاكد ان الداتا تمام او اتسجلت من ملف storage_test.dart

  runApp(const CairoMetroApp());
}