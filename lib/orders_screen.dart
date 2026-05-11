import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  late int _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = ApiService.currentUserId ?? 0;
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final data = await ApiService.getOrders();
      if (mounted)
        setState(() {
          _orders = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return AppStyles.accentPeach;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Onay Bekleniyor';
      case 'processing':
        return 'Hazırlanıyor';
      case 'shipped':
        return 'Kargoda';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  Future<void> _updateStatus(int orderId, String status) async {
    final result = await ApiService.updateOrderStatus(orderId, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? result['error'] ?? ''),
          backgroundColor: result.containsKey('error')
              ? Colors.red
              : Colors.green,
        ),
      );
      _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.softenerBlue,
      appBar: AppBar(
        title: const Text('Siparişlerim'),
        backgroundColor: AppStyles.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Henüz sipariş yok.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final status = order['status']?.toString() ?? 'pending';
                  final isSeller = order['seller_id'] == _currentUserId;
                  final items = order['items'] as List? ?? [];

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sipariş #${order['id']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _statusText(status),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isSeller
                                ? 'Alıcı: ${order['buyer_name']}'
                                : 'Satıcı: ${order['seller_name']}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Divider(),
                          // Ürünler
                          ...items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item['quantity']}x ${item['product_title']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${item['price']} TL',
                                    style: const TextStyle(
                                      color: AppStyles.accentPeach,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Toplam:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${order['total_price']} TL',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppStyles.accentPeach,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          // Satıcı için durum güncelleme butonları
                          if (isSeller &&
                              status != 'delivered' &&
                              status != 'cancelled') ...[
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (status == 'pending')
                                    _statusButton(
                                      'Onayla',
                                      'processing',
                                      Colors.blue,
                                      orderId: order['id'],
                                    ),
                                  if (status == 'processing')
                                    _statusButton(
                                      'Kargoya Ver',
                                      'shipped',
                                      AppStyles.accentPeach,
                                      orderId: order['id'],
                                    ),
                                  if (status == 'shipped')
                                    _statusButton(
                                      'Teslim Edildi',
                                      'delivered',
                                      Colors.green,
                                      orderId: order['id'],
                                    ),
                                  const SizedBox(width: 8),
                                  if (status != 'shipped' &&
                                      status != 'delivered')
                                    _statusButton(
                                      'İptal Et',
                                      'cancelled',
                                      Colors.red,
                                      orderId: order['id'],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _statusButton(
    String label,
    String status,
    Color color, {
    required int orderId,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => _updateStatus(orderId, status),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
