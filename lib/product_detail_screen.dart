import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'api_service.dart';
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
        return base64Decode(imageData);
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
    final sellerId = product['seller_id'] as int?;
    final sellerName = product['seller_name']?.toString() ?? 'Satıcı';
    final bool isOwnProduct = sellerId == currentUserId;

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
                  if (sellerName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.store, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          sellerName,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
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

                  // Sepete Ekle butonu (kendi ürününe ekleme)
                  if (!isOwnProduct)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final result = await ApiService.addToCart(
                              product['id'] as int,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['message'] ?? result['error'] ?? '',
                                ),
                                backgroundColor: result.containsKey('error')
                                    ? Colors.red
                                    : Colors.green,
                                action: result.containsKey('message')
                                    ? SnackBarAction(
                                        label: 'Sepete Git',
                                        textColor: Colors.white,
                                        onPressed: () => Navigator.pushNamed(
                                          context,
                                          '/cart',
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Hata: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Sepete Ekle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Satıcıya Mesaj Gönder butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (sellerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Satıcı bilgisi bulunamadı.'),
                            ),
                          );
                          return;
                        }

                        if (isOwnProduct) {
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
