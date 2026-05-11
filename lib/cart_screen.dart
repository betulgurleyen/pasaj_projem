import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'api_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> _cartItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final items = await ApiService.getCart();
      if (mounted)
        setState(() {
          _cartItems = items;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _totalPrice {
    return _cartItems.fold(0, (sum, item) {
      final price = double.tryParse(item['price'].toString()) ?? 0;
      final qty = item['quantity'] as int? ?? 1;
      return sum + price * qty;
    });
  }

  Future<void> _removeItem(int id) async {
    await ApiService.removeFromCart(id);
    _loadCart();
  }

  Future<void> _updateQuantity(int id, int quantity) async {
    await ApiService.updateCartItem(id, quantity);
    _loadCart();
  }

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
    return Scaffold(
      backgroundColor: AppStyles.softenerBlue,
      appBar: AppBar(
        title: const Text('Sepetim'),
        backgroundColor: AppStyles.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Sepeti Temizle',
              onPressed: () async {
                await ApiService.clearCart();
                _loadCart();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sepetiniz boş.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final imageBytes = _decodeImage(item['image_data']);
                      final price =
                          double.tryParse(item['price'].toString()) ?? 0;
                      final qty = item['quantity'] as int? ?? 1;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Görsel
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageBytes != null
                                    ? Image.memory(
                                        imageBytes,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              // Bilgiler
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${price.toStringAsFixed(2)} TL',
                                      style: const TextStyle(
                                        color: AppStyles.accentPeach,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      item['seller_name']?.toString() ?? '',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Miktar kontrolü
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        onPressed: () => _updateQuantity(
                                          item['id'],
                                          qty - 1,
                                        ),
                                        color: AppStyles.primaryGreen,
                                      ),
                                      Text(
                                        '$qty',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        onPressed: () => _updateQuantity(
                                          item['id'],
                                          qty + 1,
                                        ),
                                        color: AppStyles.primaryGreen,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${(price * qty).toStringAsFixed(2)} TL',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppStyles.textDeepBlue,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _removeItem(item['id']),
                                    child: const Text(
                                      'Kaldır',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Alt toplam ve ödeme butonu
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Toplam',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '${_totalPrice.toStringAsFixed(2)} TL',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppStyles.textDeepBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CheckoutScreen(),
                              ),
                            );
                            _loadCart();
                          },
                          child: const Text('Ödemeye Geç'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
