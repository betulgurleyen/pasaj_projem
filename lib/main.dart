import 'package:flutter/material.dart';
import 'db_service.dart';
import 'register_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'app_styles.dart';
import 'add_product_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppStyles.lightTheme,
      initialRoute: '/', // İlk açılış sayfası Giriş olsun
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/add_product': (context) => AddProductScreen(),
      },
    ),
  );
}

class TestConnectionScreen extends StatefulWidget {
  const TestConnectionScreen({super.key});

  @override
  State<TestConnectionScreen> createState() => _TestConnectionScreenState();
}

class _TestConnectionScreenState extends State<TestConnectionScreen> {
  String status = "Henüz bağlantı testi yapılmadı.";

  Future<void> testNow() async {
    setState(() => status = "Bağlanıyor...");
    try {
      final conn = await DatabaseService.connect();

      final result = await conn.execute('SELECT version()');

      setState(() {
        status = "BAŞARILI! \nVeritabanı Cevabı: ${result[0][0]}";
      });

      await conn.close();
    } catch (e) {
      setState(() {
        status = "BAĞLANTI HATASI: \n$e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pasaj DB Test")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storage, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(status, textAlign: TextAlign.center),
            ),
            ElevatedButton(
              onPressed: testNow,
              child: const Text("Bağlantıyı Test Et"),
            ),
          ],
        ),
      ),
    );
  }
}
