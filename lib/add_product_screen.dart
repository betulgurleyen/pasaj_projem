import 'dart:convert'; // base64Encode için
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_styles.dart';
import 'api_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  Uint8List? _selectedImageBytes;
  int _selectedCategoryId = 1; // Varsayılan kategori: Aksesuar

  // Galeriden görsel seçme
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Performans için %50 sıkıştırma
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes; //seçilen görseli kaydediyor.
      });
    }
  }

  // Ürünü Veritabanına Kaydetme
  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen bir görsel seçin!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      try {
        // Görseli Base64'e çevir
        final base64Image = base64Encode(_selectedImageBytes!);

        final data = await ApiService.addProduct({
          'title': _titleController.text,
          'description': _descController.text,
          'price': double.parse(_priceController.text),
          'category_id': _selectedCategoryId,
          'image_data': base64Image,
        });

        if (!mounted) return;

        if (data.containsKey('error')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error']), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ürün başarıyla kaydedildi!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //ekran tasarım kısmı (sol form paneli)
    return Scaffold(
      backgroundColor: AppStyles.softenerBlue,
      appBar: AppBar(title: const Text("Ürün Yönetim Paneli")),
      body: Row(
        children: [
          // Sol Sidebar
          Expanded(
            flex: 1,
            child: Container(
              color: AppStyles.primaryGreen,
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  const Icon(Icons.storefront, color: Colors.white, size: 40),
                  const SizedBox(height: 20),
                  _sidebarItem(Icons.add_box, "Ürün Ekle", true),
                  _sidebarItem(Icons.list_alt, "Ürünlerim", false),
                ],
              ),
            ),
          ),

          // Sağ Form Paneli
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Yeni Ürün Yayını", style: AppStyles.titleStyle),
                    const SizedBox(height: 30),

                    _inputLabel("Ürün Görseli"),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _selectedImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text("Görsel Seçmek İçin Tıklayın"),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _inputLabel("Ürün Başlığı"),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: "Örn: El Yapımı Bileklik",
                      ),
                      validator: (v) => v!.isEmpty ? "Başlık gerekli" : null,
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _inputLabel("Fiyat (₺)"),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: "0.00",
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? "Fiyat gerekli" : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _inputLabel("Kategori"),
                              DropdownButtonFormField<int>(
                                value: _selectedCategoryId,
                                items: const [
                                  DropdownMenuItem(
                                    value: 1,
                                    child: Text("Aksesuar"),
                                  ),
                                  DropdownMenuItem(
                                    value: 2,
                                    child: Text("Doğal Taş"),
                                  ),
                                  DropdownMenuItem(
                                    value: 3,
                                    child: Text("Tasarım"),
                                  ),
                                ],
                                onChanged: (val) =>
                                    setState(() => _selectedCategoryId = val!),
                                decoration: const InputDecoration(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _inputLabel("Açıklama"),
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Ürün detaylarını yazın...",
                      ),
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _addProduct,
                        child: const Text("Ürünü Kaydet"),
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

  Widget _inputLabel(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppStyles.textDeepBlue,
      ),
    ),
  );

  Widget _sidebarItem(IconData icon, String label, bool active) => ListTile(
    leading: Icon(icon, color: active ? AppStyles.accentPeach : Colors.white70),
    title: Text(
      label,
      style: TextStyle(color: active ? AppStyles.accentPeach : Colors.white70),
    ),
  );
}
