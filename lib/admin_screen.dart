import 'dart:async';
import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic> _stats = {};
  List<dynamic> _users = [];
  List<dynamic> _products = [];
  List<dynamic> _messages = [];

  bool _loadingStats = true;
  bool _loadingUsers = true;
  bool _loadingProducts = true;
  bool _loadingMessages = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    _loadStats();
    _loadUsers();
    _loadProducts();
    _loadMessages();
  }

  Future<void> _loadStats() async {
    try {
      final data = await ApiService.getAdminStats();
      if (mounted)
        setState(() {
          _stats = data;
          _loadingStats = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final data = await ApiService.getAdminUsers();
      if (mounted)
        setState(() {
          _users = data;
          _loadingUsers = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final data = await ApiService.getAdminProducts();
      if (mounted)
        setState(() {
          _products = data;
          _loadingProducts = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _loadMessages() async {
    try {
      final data = await ApiService.getAdminMessages();
      if (mounted)
        setState(() {
          _messages = data;
          _loadingMessages = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  Future<void> _deleteUser(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: Text('$name silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteAdminUser(id);
      _loadUsers();
      _loadStats();
    }
  }

  Future<void> _deleteProduct(int id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text('$title silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteAdminProduct(id);
      _loadProducts();
      _loadStats();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.softenerBlue,
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        backgroundColor: AppStyles.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadingStats = true;
                _loadingUsers = true;
                _loadingProducts = true;
                _loadingMessages = true;
              });
              _loadAll();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppStyles.accentPeach,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Özet'),
            Tab(icon: Icon(Icons.people), text: 'Kullanıcılar'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Ürünler'),
            Tab(icon: Icon(Icons.message), text: 'Mesajlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildUsersTab(),
          _buildProductsTab(),
          _buildMessagesTab(),
        ],
      ),
    );
  }

  // ── ÖZET ──────────────────────────────────────────────────

  Widget _buildStatsTab() {
    if (_loadingStats) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Genel Bakış', style: AppStyles.titleStyle),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Toplam Kullanıcı',
                  _stats['totalUsers']?.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Toplam Ürün',
                  _stats['totalProducts']?.toString() ?? '0',
                  Icons.shopping_bag,
                  AppStyles.accentPeach,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Toplam Mesaj',
                  _stats['totalMessages']?.toString() ?? '0',
                  Icons.message,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Satıcı Sayısı',
                  _stats['totalSellers']?.toString() ?? '0',
                  Icons.store,
                  AppStyles.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── KULLANICILAR ──────────────────────────────────────────

  Widget _buildUsersTab() {
    if (_loadingUsers) return const Center(child: CircularProgressIndicator());
    if (_users.isEmpty)
      return const Center(child: Text('Kullanıcı bulunamadı.'));

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _users[index];
          final role = user['role_name']?.toString() ?? '';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: role == 'seller'
                  ? AppStyles.accentPeach
                  : role == 'admin'
                  ? Colors.red
                  : AppStyles.primaryGreen,
              child: Text(
                (user['full_name']?.toString() ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              user['full_name']?.toString() ?? 'İsimsiz',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(user['email']?.toString() ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: role == 'seller'
                        ? AppStyles.accentPeach.withOpacity(0.2)
                        : role == 'admin'
                        ? Colors.red.withOpacity(0.2)
                        : AppStyles.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 11,
                      color: role == 'seller'
                          ? AppStyles.accentPeach
                          : role == 'admin'
                          ? Colors.red
                          : AppStyles.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (role != 'admin')
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _deleteUser(
                      user['id'],
                      user['full_name']?.toString() ?? '',
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── ÜRÜNLER ──────────────────────────────────────────────

  Widget _buildProductsTab() {
    if (_loadingProducts)
      return const Center(child: CircularProgressIndicator());
    if (_products.isEmpty) return const Center(child: Text('Ürün bulunamadı.'));

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = _products[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppStyles.softenerBlue,
              child: const Icon(
                Icons.shopping_bag,
                color: AppStyles.primaryGreen,
              ),
            ),
            title: Text(
              product['title']?.toString() ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${product['seller_name']} • ${product['category_name'] ?? 'Kategori yok'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${product['price']} TL',
                  style: const TextStyle(
                    color: AppStyles.accentPeach,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteProduct(
                    product['id'],
                    product['title']?.toString() ?? '',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── MESAJLAR ──────────────────────────────────────────────

  Widget _buildMessagesTab() {
    if (_loadingMessages)
      return const Center(child: CircularProgressIndicator());
    if (_messages.isEmpty)
      return const Center(child: Text('Mesaj bulunamadı.'));

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final msg = _messages[index];
          final isRead = msg['is_read'] == true;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isRead
                  ? Colors.grey[200]
                  : AppStyles.accentPeach.withOpacity(0.2),
              child: Icon(
                Icons.message,
                color: isRead ? Colors.grey : AppStyles.accentPeach,
                size: 20,
              ),
            ),
            title: Text(
              '${msg['sender_name']} → ${msg['receiver_name']}',
              style: TextStyle(
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Text(
              msg['content']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              _formatDate(msg['created_at']?.toString() ?? ''),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
