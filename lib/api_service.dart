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
}
