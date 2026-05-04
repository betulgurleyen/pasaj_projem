import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
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
  List<dynamic> _salesData = [];
  List<dynamic> _usersData = [];
  bool _loadingSales = true;
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
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

  // ── PDF ──────────────────────────────────────────────────

  Future<void> _exportSalesPDF() async {
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
            data: _salesData
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
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<void> _exportUsersPDF() async {
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
            data: _usersData
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
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // ── EXCEL ─────────────────────────────────────────────────

  Future<void> _exportSalesExcel() async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Satış Raporu');
    final sheet = excel['Satış Raporu'];

    // Başlıklar
    final headers = ['ID', 'Ürün Adı', 'Fiyat', 'Kategori', 'Satıcı', 'Tarih'];
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }

    // Veriler
    for (var rowIndex = 0; rowIndex < _salesData.length; rowIndex++) {
      final row = _salesData[rowIndex];
      final values = [
        row['id'].toString(),
        row['title']?.toString() ?? '',
        '${row['price']} TL',
        row['category_name']?.toString() ?? '',
        row['seller_name']?.toString() ?? '',
        _formatDate(row['created_at']?.toString() ?? ''),
      ];
      for (var colIndex = 0; colIndex < values.length; colIndex++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex + 1,
              ),
            )
            .value = TextCellValue(
          values[colIndex],
        );
      }
    }

    await _saveAndOpenExcel(excel, 'satis_raporu');
  }

  Future<void> _exportUsersExcel() async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Kullanıcı Raporu');
    final sheet = excel['Kullanıcı Raporu'];

    // Başlıklar
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

    // Veriler
    for (var rowIndex = 0; rowIndex < _usersData.length; rowIndex++) {
      final row = _usersData[rowIndex];
      final values = [
        row['id'].toString(),
        row['full_name']?.toString() ?? '',
        row['email']?.toString() ?? '',
        row['role_name']?.toString() ?? '',
        row['product_count'].toString(),
        _formatDate(row['created_at']?.toString() ?? ''),
      ];
      for (var colIndex = 0; colIndex < values.length; colIndex++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex + 1,
              ),
            )
            .value = TextCellValue(
          values[colIndex],
        );
      }
    }

    await _saveAndOpenExcel(excel, 'kullanici_raporu');
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
        title: const Text('Raporlar'),
        backgroundColor: AppStyles.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppStyles.accentPeach,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag), text: 'Satış Raporu'),
            Tab(icon: Icon(Icons.people), text: 'Kullanıcı Raporu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSalesTab(), _buildUsersTab()],
      ),
    );
  }

  // ── SATIŞ TABLOSU ─────────────────────────────────────────

  Widget _buildSalesTab() {
    if (_loadingSales) return const Center(child: CircularProgressIndicator());
    if (_salesData.isEmpty)
      return const Center(child: Text('Veri bulunamadı.'));

    return Column(
      children: [
        // Export butonları
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportSalesPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF İndir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportSalesExcel,
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
        ),

        // Tablo
        Expanded(
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
                rows: _salesData.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(Text(row['id'].toString())),
                      DataCell(Text(row['title']?.toString() ?? '')),
                      DataCell(Text('${row['price']} TL')),
                      DataCell(Text(row['category_name']?.toString() ?? '')),
                      DataCell(Text(row['seller_name']?.toString() ?? '')),
                      DataCell(
                        Text(_formatDate(row['created_at']?.toString() ?? '')),
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

  // ── KULLANICI TABLOSU ─────────────────────────────────────

  Widget _buildUsersTab() {
    if (_loadingUsers) return const Center(child: CircularProgressIndicator());
    if (_usersData.isEmpty)
      return const Center(child: Text('Veri bulunamadı.'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportUsersPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF İndir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportUsersExcel,
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
        ),

        Expanded(
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
                rows: _usersData.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(Text(row['id'].toString())),
                      DataCell(Text(row['full_name']?.toString() ?? '')),
                      DataCell(Text(row['email']?.toString() ?? '')),
                      DataCell(Text(row['role_name']?.toString() ?? '')),
                      DataCell(Text(row['product_count'].toString())),
                      DataCell(
                        Text(_formatDate(row['created_at']?.toString() ?? '')),
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
}
