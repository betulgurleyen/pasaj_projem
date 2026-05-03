import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_styles.dart';
import 'api_service.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descController;

  Uint8List? _selectedImageBytes;
  dynamic _existingImageData;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product['title']);
    _priceController = TextEditingController(
      text: widget.product['price'].toString(),
    );
    _descController = TextEditingController(
      text: widget.product['description'],
    );
    _existingImageData = widget.product['image_data'];
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Uint8List? _decodeExistingImage() {
    if (_existingImageData == null) return null;
    if (_existingImageData is Uint8List) return _existingImageData;
    if (_existingImageData is String && _existingImageData.isNotEmpty) {
      try {
        return base64Decode(_existingImageData);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Yeni görsel seçildiyse onu, yoksa mevcutu kullan
        String? imageBase64;
        if (_selectedImageBytes != null) {
          imageBase64 = base64Encode(_selectedImageBytes!);
        } else if (_existingImageData is String) {
          imageBase64 = _existingImageData;
        } else if (_existingImageData != null) {
          imageBase64 = base64Encode(_decodeExistingImage()!);
        }

        final data = await ApiService.updateProduct(widget.product['id'], {
          'title': _titleController.text,
          'description': _descController.text,
          'price': double.parse(_priceController.text),
          'image_data': imageBase64,
        });

        if (!mounted) return;

        if (data.containsKey('error')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error']), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ürün başarıyla güncellendi!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
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
    final existingImageBytes = _decodeExistingImage();

    return Scaffold(
      appBar: AppBar(title: const Text("Ürünü Düzenle")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Görsel seçici
              const Text(
                "Ürün Görseli",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
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
                      : existingImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            existingImageBytes,
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
              const SizedBox(height: 16),
              _buildInput("Ürün Adı", _titleController),
              _buildInput("Fiyat", _priceController, isNumber: true),
              _buildInput("Açıklama", _descController, maxLines: 3),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _updateProduct,
                child: const Text("Değişiklikleri Kaydet"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (v) => v!.isEmpty ? "Boş bırakılamaz" : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
