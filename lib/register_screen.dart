import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_styles.dart'; // Stil dosyamızı buraya ekledik

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  String _selectedRole = 'guest';

  // Mevcut veritabanı fonksiyonun (Aynen korundu)
  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final data = await ApiService.register(
          _nameController.text,
          _emailController.text,
          _passController.text,
          _selectedRole,
        );

        if (!mounted) return;

        if (data.containsKey('error')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error']), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kayıt Başarılı!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // SOL PANEL: Tasarımdaki Yeşil Marka Alanı
          Expanded(
            flex: 1,
            child: Container(
              color: AppStyles.primaryGreen,
              padding: const EdgeInsets.all(60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.app_registration,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Zanaatkâr topluluğumuza katılın.",
                    style: AppStyles.brandLogoStyle.copyWith(
                      fontSize: 40,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Pasaj ile yolculuğunuza bugün başlayın. Eşsiz ürünler alıp satmaya başlamak için bir hesap oluşturun.",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),

          // SAĞ PANEL: Kayıt Formu (Tasarım buraya yerleşti)
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 80,
                  vertical: 40,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hesap Olustur",
                        style: AppStyles.titleStyle.copyWith(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Başlamak için bilgileri doldurun.",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      // Ad Soyad
                      const Text(
                        "Ad",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: "Adınızı giriniz",
                        ),
                        validator: (v) => v!.isEmpty ? "Boş bırakılamaz" : null,
                      ),
                      const SizedBox(height: 20),

                      // E-posta
                      const Text(
                        "E-posta Adresi",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: "E-posta adresini giriniz",
                        ),
                        validator: (v) =>
                            !v!.contains("@") ? "Geçersiz e-posta" : null,
                      ),
                      const SizedBox(height: 20),

                      // Şifre
                      const Text(
                        "Şifre",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: "Şifrenizi giriniz",
                        ),
                        validator: (v) =>
                            v!.length < 6 ? "Şifre çok kısa" : null,
                      ),
                      const SizedBox(height: 20),

                      // Rol Seçimi (Dropdown)
                      const Text(
                        "Bir üye olarak katılın",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        items: const [
                          DropdownMenuItem(
                            value: 'guest',
                            child: Text("Alıcı/Misafir"),
                          ),
                          DropdownMenuItem(
                            value: 'seller',
                            child: Text("Satıcı"),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedRole = val!),
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Kayıt Butonu
                      ElevatedButton(
                        onPressed: _saveUser,
                        child: const Text("Üye Olun"),
                      ),
                      const SizedBox(height: 20),

                      // Geri Dönüş Linki
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(color: AppStyles.textDeepBlue),
                              children: [
                                TextSpan(text: "Zaten hesabınız var? "),
                                TextSpan(
                                  text: "Giriş Yapın",
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
          ),
        ],
      ),
    );
  }
}
