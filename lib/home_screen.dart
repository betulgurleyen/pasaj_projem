import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'api_service.dart';
import 'edit_product_screen.dart';
import 'product_detail_screen.dart';
import 'inbox_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _debounce;
  String _currentSearch = "";
  int? _selectedCategoryId;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _currentSearch = query;
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      final products = await ApiService.getProducts(
        search: _currentSearch.isNotEmpty ? _currentSearch : null,
        categoryId: _selectedCategoryId,
      );
      return products.map((p) => Map<String, dynamic>.from(p)).toList();
    } catch (e) {
      throw Exception('Ürünler yüklenemedi: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    await ApiService.deleteProduct(id);
    if (mounted) setState(() {});
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
    final dynamic args = ModalRoute.of(context)!.settings.arguments;
    final String userRole;
    final int currentUserId;

    if (args is Map) {
      userRole = args['role']?.toString() ?? 'guest';
      currentUserId = args['userId'] as int? ?? 0;
    } else {
      userRole = args?.toString() ?? 'guest';
      currentUserId = 0;
    }

    return Scaffold(
      backgroundColor: AppStyles.softenerBlue,
      appBar: AppBar(
        title: const Text(
          "Pasaj",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppStyles.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          // Bildirim ikonu
          const _NotificationBadge(),
          // Sepet ikonu
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
          // Mesaj ikonu
          _UnreadBadge(currentUserId: currentUserId),
          // Siparişlerim
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Siparişlerim',
            onPressed: () => Navigator.pushNamed(context, '/orders'),
          ),
          // Kategori filtresi
          PopupMenuButton<int?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Kategoriler',
            onSelected: (value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
            itemBuilder: (context) => [
              _categoryMenuItem(null, Icons.all_inclusive, 'Hepsi'),
              _categoryMenuItem(1, Icons.watch, 'Aksesuar'),
              _categoryMenuItem(2, Icons.diamond, 'Doğal Taş'),
              _categoryMenuItem(3, Icons.palette, 'Tasarım'),
              _categoryMenuItem(4, Icons.checkroom, 'Giyim'),
              _categoryMenuItem(5, Icons.home, 'Ev Dekorasyon'),
              _categoryMenuItem(6, Icons.devices, 'Elektronik'),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Ürün ara...",
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppStyles.primaryGreen,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Hata: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Ürün bulunamadı."));
                }

                final products = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final productMap = products[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              product: productMap,
                              currentUserId: currentUserId,
                            ),
                          ),
                        );
                      },
                      child: _buildProductCard(
                        productMap['id'],
                        productMap['title'],
                        productMap['price'].toString(),
                        productMap['image_data'],
                        productMap['description'] ?? '',
                        userRole,
                        productMap['seller_id'] as int?,
                        productMap['seller_name']?.toString(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: userRole == 'seller'
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.pushNamed(context, '/add_product');
                setState(() {});
              },
              label: const Text("Ürün Ekle"),
              icon: const Icon(Icons.add),
              backgroundColor: AppStyles.accentPeach,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  PopupMenuItem<int?> _categoryMenuItem(
    int? value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: _selectedCategoryId == value
                ? AppStyles.accentPeach
                : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: _selectedCategoryId == value
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: _selectedCategoryId == value
                  ? AppStyles.accentPeach
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    int id,
    String title,
    String price,
    dynamic imageData,
    String description,
    String role,
    int? sellerId,
    String? sellerName,
  ) {
    final imageBytes = _decodeImage(imageData);

    final Map<String, dynamic> productData = {
      'id': id,
      'title': title,
      'price': price,
      'image_data': imageData,
      'description': description,
      'seller_id': sellerId,
      'seller_name': sellerName,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: imageBytes != null
                    ? Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$price TL",
                      style: const TextStyle(
                        color: AppStyles.accentPeach,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (role == 'seller' || role == 'admin')
            Positioned(
              top: 5,
              right: 5,
              child: Row(
                children: [
                  _iconButton(Icons.edit, Colors.blue, () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditProductScreen(product: productData),
                      ),
                    );
                    if (result == true && mounted) setState(() {});
                  }),
                  const SizedBox(width: 4),
                  _iconButton(
                    Icons.delete,
                    Colors.red,
                    () => _showDeleteDialog(id, title),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, Color color, VoidCallback onPressed) {
    return CircleAvatar(
      backgroundColor: Colors.white.withOpacity(0.9),
      radius: 16,
      child: IconButton(
        icon: Icon(icon, color: color, size: 16),
        onPressed: onPressed,
      ),
    );
  }

  void _showDeleteDialog(int id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ürünü Sil"),
        content: Text("'$title' silinecek. Emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await deleteProduct(id);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Silindi!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Bildirim Badge ────────────────────────────────────────────

class _NotificationBadge extends StatefulWidget {
  const _NotificationBadge();

  @override
  State<_NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<_NotificationBadge> {
  int _count = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkCount();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkCount());
  }

  Future<void> _checkCount() async {
    try {
      final data = await ApiService.getUnreadCount();
      if (mounted) setState(() => _count = data['count'] as int? ?? 0);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
            _checkCount();
          },
        ),
        if (_count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: Colors.red,
              child: Text(
                '$_count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Mesaj Badge ──────────────────────────────────────────────

class _UnreadBadge extends StatefulWidget {
  final int currentUserId;
  const _UnreadBadge({required this.currentUserId});

  @override
  State<_UnreadBadge> createState() => _UnreadBadgeState();
}

class _UnreadBadgeState extends State<_UnreadBadge> {
  int _unreadCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkUnread();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkUnread());
  }

  Future<void> _checkUnread() async {
    try {
      final conversations = await ApiService.getInbox();
      int total = 0;
      for (final conv in conversations) {
        total += int.tryParse(conv['unread_count'].toString()) ?? 0;
      }
      if (mounted) setState(() => _unreadCount = total);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    InboxScreen(currentUserId: widget.currentUserId),
              ),
            );
            _checkUnread();
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: AppStyles.accentPeach,
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
