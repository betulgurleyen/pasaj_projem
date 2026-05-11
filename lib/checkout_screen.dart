import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_styles.dart';
import 'api_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Kargo bilgileri
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  // Kart bilgileri
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expireMonthController = TextEditingController();
  final _expireYearController = TextEditingController();
  final _cvcController = TextEditingController();

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final result = await ApiService.createOrder({
        'shipping_name': _nameController.text,
        'shipping_phone': _phoneController.text,
        'shipping_address': _addressController.text,
        'shipping_city': _cityController.text,
        'card_holder': _cardHolderController.text,
        'card_number': _cardNumberController.text,
        'expire_month': _expireMonthController.text,
        'expire_year': _expireYearController.text,
        'cvc': _cvcController.text,
      });

      if (!mounted) return;

      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Sipariş Alındı!'),
              ],
            ),
            content: const Text(
              'Siparişiniz başarıyla oluşturuldu. Satıcı onayı bekleniyor.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.softenerBlue,
      appBar: AppBar(
        title: const Text('Ödeme'),
        backgroundColor: AppStyles.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kargo Bilgileri
              _sectionTitle('Kargo Bilgileri', Icons.local_shipping),
              const SizedBox(height: 12),
              _buildInput('Ad Soyad', _nameController, Icons.person),
              _buildInput(
                'Telefon',
                _phoneController,
                Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              _buildInput('Şehir', _cityController, Icons.location_city),
              _buildInput('Adres', _addressController, Icons.home, maxLines: 3),

              const SizedBox(height: 24),

              // Kart Bilgileri
              _sectionTitle('Kart Bilgileri', Icons.credit_card),
              const SizedBox(height: 12),

              // Kart önizleme
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppStyles.primaryGreen, AppStyles.textDeepBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.credit_card,
                      color: Colors.white,
                      size: 32,
                    ),
                    Text(
                      _cardNumberController.text.isEmpty
                          ? '**** **** **** ****'
                          : _cardNumberController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _cardHolderController.text.isEmpty
                              ? 'AD SOYAD'
                              : _cardHolderController.text.toUpperCase(),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '${_expireMonthController.text.isEmpty ? 'MM' : _expireMonthController.text}/${_expireYearController.text.isEmpty ? 'YY' : _expireYearController.text}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _buildInput(
                'Kart Üzerindeki İsim',
                _cardHolderController,
                Icons.person,
                onChanged: (_) => setState(() {}),
              ),
              _buildInput(
                'Kart Numarası',
                _cardNumberController,
                Icons.credit_card,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    v!.length != 16 ? '16 haneli kart numarası giriniz' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      'Ay (MM)',
                      _expireMonthController,
                      Icons.calendar_month,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final m = int.tryParse(v ?? '');
                        if (m == null || m < 1 || m > 12) return 'Geçersiz ay';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInput(
                      'Yıl (YY)',
                      _expireYearController,
                      Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (v) => v!.length != 2 ? 'Geçersiz yıl' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInput(
                      'CVC',
                      _cvcController,
                      Icons.lock,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (v) => v!.length < 3 ? 'Geçersiz CVC' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _placeOrder,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock),
                  label: Text(_loading ? 'İşleniyor...' : 'Siparişi Tamamla'),
                ),
              ),

              const SizedBox(height: 12),
              const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Güvenli ödeme',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppStyles.primaryGreen),
        const SizedBox(width: 8),
        Text(title, style: AppStyles.titleStyle.copyWith(fontSize: 18)),
      ],
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppStyles.primaryGreen),
        ),
        validator: validator ?? (v) => v!.isEmpty ? '$label gerekli' : null,
      ),
    );
  }
}
