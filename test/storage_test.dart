// import 'package:flutter_test/flutter_test.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:cairo_metro_guide/metro/storage.dart';

// void main() {
//   TestWidgetsFlutterBinding.ensureInitialized();

//   test('اختبار حفظ واسترجاع التوكن من الـ Storage', () async {
//     // تجهيز قيم وهمية للـ SharedPreferences للاختبار
//     SharedPreferences.setMockInitialValues({});
//     await AppStorage.init();

//     // حفظ التوكن
//     await AppStorage.saveUserSession(token: 'my_secret_token');

//     // التأكد من استرجاعه بشكل صحيح
//     expect(AppStorage.getToken(), 'my_secret_token');
//     expect(AppStorage.isLoggedIn(), true);
//   });
// }