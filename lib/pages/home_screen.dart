import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'db_service.dart';
import 'edit_product_screen.dart';
import 'product_detail_screen.dart';
import 'inbox_screen.dart'; // ✅ YENİ

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
    final conn = await DatabaseService.connect();

    String query = '''
      SELECT p.id, p.title, p.price, p.image_data, p.description,
             p.seller_id, up.full_name AS seller_name
      FROM products p
      LEFT JOIN user_profiles up ON up.user_id = p.seller_id
      WHERE 1=1
    ''';
    List<dynamic> params = [];

    if (_currentSearch.isNotEmpty) {
      params.add('%$_currentSearch%');
      query += ' AND p.title ILIKE \$${params.length}';
    }

    if (_selectedCategoryId != null) {
      params.add(_selectedCategoryId);
      query += ' AND p.category_id = \$${params.length}';
    }

    query += ' ORDER BY p.id DESC';

    final result = await conn.execute(query, parameters: params);

    return result
        .map(
          (row) => {
            'id': row[0],
            'title': row[1],
            'price': row[2],
            'image_data': row[3],
            'description': row[4],
            'seller_id': row[5],
            'seller_name': row[6],
          },
        )
        .toList();
  }

  Future<void> deleteProduct(int id) async {
    final conn = await DatabaseService.connect();
    await conn.execute(r'DELETE FROM products WHERE id = $1', parameters: [id]);
    if (mounted) setState(() {});
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
          // ✅ YENİ: Mesaj kutusu ikonu
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InboxScreen(currentUserId: currentUserId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ARAMA ÇUBUĞU
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

          // KATEGORİ FİLTRELEME CHIPS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryChip("Hepsi", null),
                const SizedBox(width: 8),
                _buildCategoryChip("Aksesuar", 1),
                const SizedBox(width: 8),
                _buildCategoryChip("Doğal Taş", 2),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ÜRÜN LİSTESİ
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
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
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

  Widget _buildCategoryChip(String label, int? id) {
    final bool isSelected = _selectedCategoryId == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategoryId = id;
        });
      },
      selectedColor: AppStyles.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppStyles.textDeepBlue,
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
                child: imageData != null
                    ? Image.memory(
                        imageData as Uint8List,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey,
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
          if (role == 'seller')
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
