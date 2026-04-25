import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'db_service.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product; // Düzenlenecek ürün verileri

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    // Kutucukları mevcut verilerle dolduruyoruz
    _titleController = TextEditingController(text: widget.product['title']);
    _priceController = TextEditingController(
      text: widget.product['price'].toString(),
    );
    _descController = TextEditingController(
      text: widget.product['description'],
    );
    _imageUrlController = TextEditingController(
      text: widget.product['image_url'],
    );
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        final conn = await DatabaseService.connect();
        await conn.execute(
          r'UPDATE products SET title = $1, price = $2, description = $3, image_url = $4 WHERE id = $5',
          parameters: [
            _titleController.text,
            double.parse(_priceController.text),
            _descController.text,
            _imageUrlController.text,
            widget.product['id'], // Ürünün ID'si değişmez
          ],
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Geri dönerken 'true' döndür ki liste yenilensin
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ürünü Düzenle")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildInput("Ürün Adı", _titleController),
              _buildInput("Fiyat", _priceController, isNumber: true),
              _buildInput("Görsel URL", _imageUrlController),
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
