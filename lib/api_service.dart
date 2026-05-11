import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://pasaj-backend-production.up.railway.app';

  static String? _token;
  static int? currentUserId;
  static String? currentRole;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── ADMIN ──────────────────────────────────────────

  static Future<Map<String, dynamic>> getAdminStats() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateUserRole(
    int userId,
    String role,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId/role'),
      headers: _headers,
      body: jsonEncode({'role_name': role}),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getAdminUsers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getAdminProducts() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/products'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getAdminMessages() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/messages'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getSalesReport() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/reports/sales'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getUsersReport() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/reports/users'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deleteAdminUser(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/admin/users/$id'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deleteAdminProduct(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/admin/products/$id'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }
  // ── AUTH ──────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      _token = data['token'];
      currentUserId = data['userId'];
      currentRole = data['role'];
    }
    return data;
  }

  static Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String password,
    String role,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    return jsonDecode(res.body);
  }

  // ── PRODUCTS ──────────────────────────────────────

  static Future<List<dynamic>> getProducts({
    String? search,
    int? categoryId,
  }) async {
    String url = '$baseUrl/products';
    final params = <String>[];
    if (search != null && search.isNotEmpty) params.add('search=$search');
    if (categoryId != null) params.add('category_id=$categoryId');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final res = await http.get(Uri.parse(url), headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getProduct(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> addProduct(
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateProduct(
    int id,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deleteProduct(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  // ── MESSAGES ──────────────────────────────────────

  static Future<List<dynamic>> getInbox() async {
    final res = await http.get(
      Uri.parse('$baseUrl/messages'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getMessages(int otherUserId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/messages/$otherUserId'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> sendMessage(
    int receiverId,
    String content,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: _headers,
      body: jsonEncode({'receiver_id': receiverId, 'content': content}),
    );
    return jsonDecode(res.body);
  }

  // ── CART ──────────────────────────────────────────

  static Future<List<dynamic>> getCart() async {
    final res = await http.get(Uri.parse('$baseUrl/cart'), headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> addToCart(
    int productId, {
    int quantity = 1,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: _headers,
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateCartItem(
    int id,
    int quantity,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/cart/$id'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> removeFromCart(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/cart/$id'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> clearCart() async {
    final res = await http.delete(
      Uri.parse('$baseUrl/cart'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  // ── ORDERS ──────────────────────────────────────────

  static Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getOrders() async {
    final res = await http.get(Uri.parse('$baseUrl/orders'), headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(res.body);
  }

  // ── NOTIFICATIONS ──────────────────────────────────────────

  static Future<List<dynamic>> getNotifications() async {
    final res = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getUnreadCount() async {
    final res = await http.get(
      Uri.parse('$baseUrl/notifications/unread-count'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<void> markNotificationRead(int id) async {
    await http.put(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: _headers,
    );
  }

  static Future<void> markAllNotificationsRead() async {
    await http.put(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: _headers,
    );
  }

  static Future<List<dynamic>> getOrdersReport({
    String? startDate,
    String? endDate,
    String? buyerName,
    String? sellerName,
    String? status,
    String? productTitle,
  }) async {
    final params = <String>[];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    if (buyerName != null && buyerName.isNotEmpty)
      params.add('buyer_name=$buyerName');
    if (sellerName != null && sellerName.isNotEmpty)
      params.add('seller_name=$sellerName');
    if (status != null && status.isNotEmpty) params.add('status=$status');
    if (productTitle != null && productTitle.isNotEmpty)
      params.add('product_title=$productTitle');

    String url = '$baseUrl/admin/reports/orders';
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final res = await http.get(Uri.parse(url), headers: _headers);
    return jsonDecode(res.body);
  }
}
