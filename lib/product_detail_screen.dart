import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'chat_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  final int currentUserId;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.currentUserId,
  });

  Uint8List? _decodeImage(dynamic imageData) {
    if (imageData == null) return null;
    if (imageData is Uint8List) return imageData;
    if (imageData is String && imageData.isNotEmpty) {
      try {
        // Önce direkt decode dene
        final bytes = base64Decode(imageData);
        // Eğer geçerli görsel formatı değilse tekrar decode et
        return bytes;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String title = product['title']?.toString() ?? "Başlıksız Ürün";
    final String price = product['price']?.toString() ?? "0";
    final String description =
        product['description']?.toString() ?? "Açıklama bulunmuyor.";
    final Uint8List? imageBytes = _decodeImage(product['image_data']);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            imageBytes != null
                ? Image.memory(
                    imageBytes,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$price TL",
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppStyles.accentPeach,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Ürün Açıklaması",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final sellerId = product['seller_id'] as int?;
                        final sellerName =
                            product['seller_name']?.toString() ?? 'Satıcı';

                        if (sellerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Satıcı bilgisi bulunamadı.'),
                            ),
                          );
                          return;
                        }

                        if (sellerId == currentUserId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Kendi ürününüze mesaj gönderemezsiniz.',
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              currentUserId: currentUserId,
                              otherUserId: sellerId,
                              otherUserName: sellerName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Satıcıya Mesaj Gönder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.accentPeach,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
