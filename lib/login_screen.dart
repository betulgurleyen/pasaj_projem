import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'api_service.dart'; // db_service yerine bu

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        final data = await ApiService.login(
          _emailController.text,
          _passController.text,
        );

        if (!mounted) return;

        if (data.containsKey('error')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error']), backgroundColor: Colors.red),
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: {'role': data['role'], 'userId': data['userId']},
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hoş geldin, ${data['fullName']}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // build metodu aynı kalıyor, sadece _handleLogin değişti
  @override
  Widget build(BuildContext context) {
    // mevcut build kodun aynen kalacak
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              color: AppStyles.primaryGreen,
              padding: const EdgeInsets.all(60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.local_mall, color: Colors.white, size: 48),
                  const SizedBox(height: 24),
                  Text(
                    "Geleceğin satış platformunu keşfedin..",
                    style: AppStyles.brandLogoStyle.copyWith(
                      fontSize: 40,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Güvenli ve sorunsuz bir ortamda bağlantı kurun..",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const Spacer(),
                  const Text(
                    "Her ay giderek büyüyen bir platform.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tekrar Hoşgeldin",
                      style: AppStyles.titleStyle.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Lütfen devam etmek için giriş yapın.",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "E-posta Adresi",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: "E-posta adresinizi giriniz",
                      ),
                      validator: (v) =>
                          v!.contains("@") ? null : "Geçersiz e-posta",
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Parola",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: "Parolanızı giriniz",
                      ),
                      validator: (v) =>
                          v!.isEmpty ? "Şifre boş bırakılamaz" : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handleLogin,
                      child: const Text("Giriş Yap"),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: AppStyles.textDeepBlue),
                            children: [
                              TextSpan(text: "Hesabınız yok mu? "),
                              TextSpan(
                                text: "Kayıt Ol",
                                style: TextStyle(
                                  color: AppStyles.accentPeach,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
