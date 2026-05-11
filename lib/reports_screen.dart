import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'app_styles.dart';
import 'api_service.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Satış raporu
  List<dynamic> _salesData = [];
  bool _loadingSales = true;

  // Kullanıcı raporu
  List<dynamic> _usersData = [];
  bool _loadingUsers = true;

  // Sipariş raporu
  List<dynamic> _ordersData = [];
  bool _loadingOrders = true;

  // Sipariş filtreler
  final _orderBuyerController = TextEditingController();
  final _orderSellerController = TextEditingController();
  final _orderProductController = TextEditingController();
  String? _orderStatusFilter;
  DateTime? _orderStartDate;
  DateTime? _orderEndDate;

  // Satış filtreler
  final _salesSellerController = TextEditingController();
  final _salesProductController = TextEditingController();

  // Kullanıcı filtreler
  final _userNameController = TextEditingController();
  String? _userRoleFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    _loadSales();
    _loadUsers();
    _loadOrders();
  }

  Future<void> _loadSales() async {
    try {
      final sales = await ApiService.getSalesReport();
      if (mounted)
        setState(() {
          _salesData = sales;
          _loadingSales = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingSales = false);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ApiService.getUsersReport();
      if (mounted)
        setState(() {
          _usersData = users;
          _loadingUsers = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _loadingOrders = true);
    try {
      final orders = await ApiService.getOrdersReport(
        startDate: _orderStartDate?.toIso8601String(),
        endDate: _orderEndDate?.toIso8601String(),
        buyerName: _orderBuyerController.text.isNotEmpty
            ? _orderBuyerController.text
            : null,
        sellerName: _orderSellerController.text.isNotEmpty
            ? _orderSellerController.text
            : null,
        status: _orderStatusFilter,
        productTitle: _orderProductController.text.isNotEmpty
            ? _orderProductController.text
            : null,
      );
      if (mounted)
        setState(() {
          _ordersData = orders;
          _loadingOrders = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  // Satış verisini filtrele
  List<dynamic> get _filteredSales {
    return _salesData.where((row) {
      final seller = row['seller_name']?.toString().toLowerCase() ?? '';
      final title = row['title']?.toString().toLowerCase() ?? '';
      final sellerQ = _salesSellerController.text.toLowerCase();
      final productQ = _salesProductController.text.toLowerCase();
      return seller.contains(sellerQ) && title.contains(productQ);
    }).toList();
  }

  // Kullanıcı verisini filtrele
  List<dynamic> get _filteredUsers {
    return _usersData.where((row) {
      final name = row['full_name']?.toString().toLowerCase() ?? '';
      final role = row['role_name']?.toString() ?? '';
      final nameQ = _userNameController.text.toLowerCase();
      final roleMatch = _userRoleFilter == null || role == _userRoleFilter;
      return name.contains(nameQ) && roleMatch;
    }).toList();
  }

  String _statusText(String? status) {
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
        return status ?? '';
    }
  }

  Color _statusColor(String? status) {
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

  // ── PDF ──────────────────────────────────────────────────

  Future<void> _exportSalesPDF() async {
    final data = _filteredSales;
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Satış Raporu',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Oluşturulma: ${DateTime.now().toString().substring(0, 16)}'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['ID', 'Ürün Adı', 'Fiyat', 'Kategori', 'Satıcı', 'Tarih'],
            data: data
                .map(
                  (row) => [
                    row['id'].toString(),
                    row['title']?.toString() ?? '',
                    '${row['price']} TL',
                    row['category_name']?.toString() ?? '',
                    row['seller_name']?.toString() ?? '',
                    _formatDate(row['created_at']?.toString() ?? ''),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<void> _exportUsersPDF() async {
    final data = _filteredUsers;
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Kullanıcı Raporu',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Oluşturulma: ${DateTime.now().toString().substring(0, 16)}'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'ID',
              'Ad Soyad',
              'E-posta',
              'Rol',
              'Ürün Sayısı',
              'Kayıt Tarihi',
            ],
            data: data
                .map(
                  (row) => [
                    row['id'].toString(),
                    row['full_name']?.toString() ?? '',
                    row['email']?.toString() ?? '',
                    row['role_name']?.toString() ?? '',
                    row['product_count'].toString(),
                    _formatDate(row['created_at']?.toString() ?? ''),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<void> _exportOrdersPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Sipariş Raporu',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Oluşturulma: ${DateTime.now().toString().substring(0, 16)}'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'Sipariş #',
              'Alıcı',
              'Satıcı',
              'Ürünler',
              'Toplam',
              'Durum',
              'Tarih',
            ],
            data: _ordersData.map((row) {
              final items = (row['items'] as List? ?? [])
                  .map((i) => '${i['quantity']}x ${i['product_title']}')
                  .join(', ');
              return [
                row['order_id'].toString(),
                row['buyer_name']?.toString() ?? '',
                row['seller_name']?.toString() ?? '',
                items,
                '${row['total_price']} TL',
                _statusText(row['status']?.toString()),
                _formatDate(row['created_at']?.toString() ?? ''),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // ── EXCEL ─────────────────────────────────────────────────

  Future<void> _exportSalesExcel() async {
    final data = _filteredSales;
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Satış Raporu');
    final sheet = excel['Satış Raporu'];
    final headers = ['ID', 'Ürün Adı', 'Fiyat', 'Kategori', 'Satıcı', 'Tarih'];
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }
    for (var r = 0; r < data.length; r++) {
      final row = data[r];
      final values = [
        row['id'].toString(),
        row['title']?.toString() ?? '',
        '${row['price']} TL',
        row['category_name']?.toString() ?? '',
        row['seller_name']?.toString() ?? '',
        _formatDate(row['created_at']?.toString() ?? ''),
      ];
      for (var c = 0; c < values.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(
          values[c],
        );
      }
    }
    await _saveAndOpenExcel(excel, 'satis_raporu');
  }

  Future<void> _exportUsersExcel() async {
    final data = _filteredUsers;
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Kullanıcı Raporu');
    final sheet = excel['Kullanıcı Raporu'];
    final headers = [
      'ID',
      'Ad Soyad',
      'E-posta',
      'Rol',
      'Ürün Sayısı',
      'Kayıt Tarihi',
    ];
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }
    for (var r = 0; r < data.length; r++) {
      final row = data[r];
      final values = [
        row['id'].toString(),
        row['full_name']?.toString() ?? '',
        row['email']?.toString() ?? '',
        row['role_name']?.toString() ?? '',
        row['product_count'].toString(),
        _formatDate(row['created_at']?.toString() ?? ''),
      ];
      for (var c = 0; c < values.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(
          values[c],
        );
      }
    }
    await _saveAndOpenExcel(excel, 'kullanici_raporu');
  }

  Future<void> _exportOrdersExcel() async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Sipariş Raporu');
    final sheet = excel['Sipariş Raporu'];
    final headers = [
      'Sipariş #',
      'Alıcı',
      'Satıcı',
      'Ürünler',
      'Toplam',
      'Durum',
      'Tarih',
    ];
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }
    for (var r = 0; r < _ordersData.length; r++) {
      final row = _ordersData[r];
      final items = (row['items'] as List? ?? [])
          .map((i) => '${i['quantity']}x ${i['product_title']}')
          .join(', ');
      final values = [
        row['order_id'].toString(),
        row['buyer_name']?.toString() ?? '',
        row['seller_name']?.toString() ?? '',
        items,
        '${row['total_price']} TL',
        _statusText(row['status']?.toString()),
        _formatDate(row['created_at']?.toString() ?? ''),
      ];
      for (var c = 0; c < values.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(
          values[c],
        );
      }
    }
    await _saveAndOpenExcel(excel, 'siparis_raporu');
  }

  Future<void> _saveAndOpenExcel(Excel excel, String fileName) async {
    try {
      final bytes = excel.encode();
      if (bytes == null) return;
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', '$fileName.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _orderStartDate = picked;
        else
          _orderEndDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderBuyerController.dispose();
    _orderSellerController.dispose();
    _orderProductController.dispose();
    _salesSellerController.dispose();
    _salesProductController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.softenerBlue,
      appBar: AppBar(
        title: const Text('Raporlar'),
        backgroundColor: AppStyles.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppStyles.accentPeach,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Siparişler'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Ürün Satışları'),
            Tab(icon: Icon(Icons.people), text: 'Kullanıcılar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOrdersTab(), _buildSalesTab(), _buildUsersTab()],
      ),
    );
  }

  // ── SİPARİŞ TABLOSU ──────────────────────────────────────

  Widget _buildOrdersTab() {
    return Column(
      children: [
        // Filtreler
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _orderBuyerController,
                      decoration: const InputDecoration(
                        labelText: 'Alıcı Adı',
                        prefixIcon: Icon(Icons.person),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _orderSellerController,
                      decoration: const InputDecoration(
                        labelText: 'Satıcı Adı',
                        prefixIcon: Icon(Icons.store),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _orderProductController,
                      decoration: const InputDecoration(
                        labelText: 'Ürün Adı',
                        prefixIcon: Icon(Icons.shopping_bag),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _orderStatusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Durum',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tümü')),
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Onay Bekleniyor'),
                        ),
                        DropdownMenuItem(
                          value: 'processing',
                          child: Text('Hazırlanıyor'),
                        ),
                        DropdownMenuItem(
                          value: 'shipped',
                          child: Text('Kargoda'),
                        ),
                        DropdownMenuItem(
                          value: 'delivered',
                          child: Text('Teslim Edildi'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('İptal Edildi'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _orderStatusFilter = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _orderStartDate == null
                            ? 'Başlangıç Tarihi'
                            : '${_orderStartDate!.day}/${_orderStartDate!.month}/${_orderStartDate!.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _orderEndDate == null
                            ? 'Bitiş Tarihi'
                            : '${_orderEndDate!.day}/${_orderEndDate!.month}/${_orderEndDate!.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _pickDate(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _loadOrders,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Filtrele'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    tooltip: 'Filtreyi Temizle',
                    onPressed: () {
                      setState(() {
                        _orderBuyerController.clear();
                        _orderSellerController.clear();
                        _orderProductController.clear();
                        _orderStatusFilter = null;
                        _orderStartDate = null;
                        _orderEndDate = null;
                      });
                      _loadOrders();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportOrdersPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF İndir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportOrdersExcel,
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Excel İndir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Tablo
        Expanded(
          child: _loadingOrders
              ? const Center(child: CircularProgressIndicator())
              : _ordersData.isEmpty
              ? const Center(child: Text('Sipariş bulunamadı.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppStyles.primaryGreen,
                      ),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      columns: const [
                        DataColumn(label: Text('Sipariş #')),
                        DataColumn(label: Text('Alıcı')),
                        DataColumn(label: Text('Satıcı')),
                        DataColumn(label: Text('Ürünler')),
                        DataColumn(label: Text('Toplam')),
                        DataColumn(label: Text('Durum')),
                        DataColumn(label: Text('Tarih')),
                      ],
                      rows: _ordersData.map((row) {
                        final items = (row['items'] as List? ?? [])
                            .map(
                              (i) => '${i['quantity']}x ${i['product_title']}',
                            )
                            .join(', ');
                        final status = row['status']?.toString();
                        return DataRow(
                          cells: [
                            DataCell(Text('#${row['order_id']}')),
                            DataCell(Text(row['buyer_name']?.toString() ?? '')),
                            DataCell(
                              Text(row['seller_name']?.toString() ?? ''),
                            ),
                            DataCell(
                              SizedBox(
                                width: 200,
                                child: Text(
                                  items,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${row['total_price']} TL',
                                style: const TextStyle(
                                  color: AppStyles.accentPeach,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _statusText(status),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatDate(
                                  row['created_at']?.toString() ?? '',
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ── SATIŞ TABLOSU ─────────────────────────────────────────

  Widget _buildSalesTab() {
    if (_loadingSales) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _salesSellerController,
                      decoration: const InputDecoration(
                        labelText: 'Satıcı Adı',
                        prefixIcon: Icon(Icons.store),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _salesProductController,
                      decoration: const InputDecoration(
                        labelText: 'Ürün Adı',
                        prefixIcon: Icon(Icons.shopping_bag),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      _salesSellerController.clear();
                      _salesProductController.clear();
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportSalesPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text('PDF İndir (${_filteredSales.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportSalesExcel,
                      icon: const Icon(Icons.table_chart),
                      label: Text('Excel İndir (${_filteredSales.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _filteredSales.isEmpty
            ? const Expanded(child: Center(child: Text('Veri bulunamadı.')))
            : Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppStyles.primaryGreen,
                      ),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Ürün Adı')),
                        DataColumn(label: Text('Fiyat')),
                        DataColumn(label: Text('Kategori')),
                        DataColumn(label: Text('Satıcı')),
                        DataColumn(label: Text('Tarih')),
                      ],
                      rows: _filteredSales
                          .map(
                            (row) => DataRow(
                              cells: [
                                DataCell(Text(row['id'].toString())),
                                DataCell(Text(row['title']?.toString() ?? '')),
                                DataCell(Text('${row['price']} TL')),
                                DataCell(
                                  Text(row['category_name']?.toString() ?? ''),
                                ),
                                DataCell(
                                  Text(row['seller_name']?.toString() ?? ''),
                                ),
                                DataCell(
                                  Text(
                                    _formatDate(
                                      row['created_at']?.toString() ?? '',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  // ── KULLANICI TABLOSU ─────────────────────────────────────

  Widget _buildUsersTab() {
    if (_loadingUsers) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userNameController,
                      decoration: const InputDecoration(
                        labelText: 'Kullanıcı Adı',
                        prefixIcon: Icon(Icons.person),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _userRoleFilter,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tümü')),
                        DropdownMenuItem(
                          value: 'seller',
                          child: Text('Satıcı'),
                        ),
                        DropdownMenuItem(
                          value: 'guest',
                          child: Text('Misafir'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (v) => setState(() => _userRoleFilter = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      _userNameController.clear();
                      setState(() => _userRoleFilter = null);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportUsersPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text('PDF İndir (${_filteredUsers.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportUsersExcel,
                      icon: const Icon(Icons.table_chart),
                      label: Text('Excel İndir (${_filteredUsers.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _filteredUsers.isEmpty
            ? const Expanded(child: Center(child: Text('Veri bulunamadı.')))
            : Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppStyles.primaryGreen,
                      ),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Ad Soyad')),
                        DataColumn(label: Text('E-posta')),
                        DataColumn(label: Text('Rol')),
                        DataColumn(label: Text('Ürün Sayısı')),
                        DataColumn(label: Text('Kayıt Tarihi')),
                      ],
                      rows: _filteredUsers
                          .map(
                            (row) => DataRow(
                              cells: [
                                DataCell(Text(row['id'].toString())),
                                DataCell(
                                  Text(row['full_name']?.toString() ?? ''),
                                ),
                                DataCell(Text(row['email']?.toString() ?? '')),
                                DataCell(
                                  Text(row['role_name']?.toString() ?? ''),
                                ),
                                DataCell(Text(row['product_count'].toString())),
                                DataCell(
                                  Text(
                                    _formatDate(
                                      row['created_at']?.toString() ?? '',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
