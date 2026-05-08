import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/models/store_payment_method.dart';
import '../../../../core/repositories/bank_repository.dart';
import '../../../../core/repositories/payment_methods_repository.dart';
import '../../../../core/models/bank.dart';

class PaymentMethodFormScreen extends ConsumerStatefulWidget {
  final String storeId;
  final StorePaymentMethod? method;
  const PaymentMethodFormScreen({super.key, required this.storeId, this.method});

  @override
  ConsumerState<PaymentMethodFormScreen> createState() => _PaymentMethodFormScreenState();
}

class _PaymentMethodFormScreenState extends ConsumerState<PaymentMethodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late PaymentMethodType _selectedType;
  late TextEditingController _titleController;
  late TextEditingController _holderController;
  late TextEditingController _idNumberController;
  late TextEditingController _accountNumberController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _walletController;
  late TextEditingController _instructionsController;
  String? _selectedBankId;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.method?.type ?? PaymentMethodType.PAGO_MOVIL;
    _titleController = TextEditingController(text: widget.method?.title);
    _holderController = TextEditingController(text: widget.method?.accountHolder);
    _idNumberController = TextEditingController(text: widget.method?.idNumber);
    _accountNumberController = TextEditingController(text: widget.method?.accountNumber);
    _phoneController = TextEditingController(text: widget.method?.phoneNumber);
    _emailController = TextEditingController(text: widget.method?.email);
    _walletController = TextEditingController(text: widget.method?.walletAddress);
    _instructionsController = TextEditingController(text: widget.method?.instructions);
    _selectedBankId = widget.method?.bank?.id;
    _isActive = widget.method?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _holderController.dispose();
    _idNumberController.dispose();
    _accountNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _walletController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'type': _selectedType.name,
      'title': _titleController.text,
      'accountHolder': _holderController.text.isEmpty ? null : _holderController.text,
      'idNumber': _idNumberController.text.isEmpty ? null : _idNumberController.text,
      'accountNumber': _accountNumberController.text.isEmpty ? null : _accountNumberController.text,
      'phoneNumber': _phoneController.text.isEmpty ? null : _phoneController.text,
      'email': _emailController.text.isEmpty ? null : _emailController.text,
      'walletAddress': _walletController.text.isEmpty ? null : _walletController.text,
      'instructions': _instructionsController.text.isEmpty ? null : _instructionsController.text,
      'bankId': _selectedBankId,
      'isActive': _isActive,
      'storeId': widget.storeId,
    };

    final repository = ref.read(paymentMethodsRepositoryProvider);
    bool success;
    try {
      if (widget.method != null) {
        final updated = await repository.updateMethod(widget.method!.id, data);
        success = updated != null;
      } else {
        final created = await repository.createMethod(data);
        success = created != null;
      }
    } catch (e) {
      success = false;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ref.invalidate(storePaymentMethodsProvider(widget.storeId));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar el método de pago'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar Método'),
        content: const Text('¿Estás seguro de que deseas eliminar este método de pago? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isSaving = true);
              final success = await ref
                  .read(paymentMethodsRepositoryProvider)
                  .deleteMethod(widget.method!.id);
              if (mounted) {
                setState(() => _isSaving = false);
                if (success) {
                  ref.invalidate(storePaymentMethodsProvider(widget.storeId));
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.method == null ? 'Nuevo Método' : 'Editar Método',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (widget.method != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Color(0xFFEF4444),
                size: 24,
              ),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Tipo de Pago'),
              const SizedBox(height: 12),
              _buildTypeSelector(),
              const SizedBox(height: 32),
              _buildSectionTitle('Información General'),
              const SizedBox(height: 12),
              _buildGeneralInfoSection(),
              const SizedBox(height: 32),
              _buildSectionTitle('Detalles de la Cuenta'),
              const SizedBox(height: 12),
              _buildAccountDetailsSection(),
              const SizedBox(height: 40),
              _buildSaveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6B7280),
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<PaymentMethodType>(
          value: _selectedType,
          decoration: const InputDecoration(border: InputBorder.none),
          items: PaymentMethodType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type.displayName,
                style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedType = value);
          },
        ),
      ),
    );
  }

  Widget _buildGeneralInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          _buildTextField(
            label: 'Título descriptivo',
            hint: 'Ej: Mi Banesco, Pago Móvil Personal',
            controller: _titleController,
            icon: Icons.tag,
            validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Método Activo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Switch.adaptive(
                value: _isActive,
                activeTrackColor: const Color(0xFF4F46E5),
                onChanged: (val) => setState(() => _isActive = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetailsSection() {
    final banksAsync = ref.watch(banksProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          if (_selectedType == PaymentMethodType.PAGO_MOVIL || _selectedType == PaymentMethodType.TRANSFER) ...[
            banksAsync.when(
              data: (banks) => _buildBankSelector(banks),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(color: Color(0xFF4F46E5)),
              ),
              error: (_, __) => const Text('Error cargando bancos'),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Titular de la cuenta',
              controller: _holderController,
              icon: Icons.person_outline,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Cédula / RIF del titular',
              controller: _idNumberController,
              icon: Icons.badge_outlined,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
          ],
          if (_selectedType == PaymentMethodType.PAGO_MOVIL) ...[
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Número de Teléfono',
              controller: _phoneController,
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
          ],
          if (_selectedType == PaymentMethodType.TRANSFER) ...[
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Número de Cuenta',
              hint: '20 dígitos',
              controller: _accountNumberController,
              icon: Icons.account_balance_wallet_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Campo requerido';
                if (v!.length != 20) return 'Debe tener 20 dígitos';
                return null;
              },
            ),
          ],
          if (_selectedType == PaymentMethodType.BINANCE) ...[
            _buildTextField(
              label: 'Binance ID / Wallet Address',
              controller: _walletController,
              icon: Icons.currency_bitcoin,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
          ],
          if (_selectedType == PaymentMethodType.ZELLE) ...[
            _buildTextField(
              label: 'Correo de Zelle',
              controller: _emailController,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Nombre del Titular',
              controller: _holderController,
              icon: Icons.person_outline,
              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
          ],
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Instrucciones (Opcional)',
            hint: 'Ej: Reportar por WhatsApp enviando captura',
            controller: _instructionsController,
            icon: Icons.info_outline,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankSelector(List<Bank> banks) {
    final selectedBank = banks.firstWhere(
      (b) => b.id == _selectedBankId,
      orElse: () => Bank(id: '', code: '', name: 'Selecciona un banco'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Banco',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: banks.isEmpty ? null : () => _showBankPicker(banks),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedBankId == null 
                        ? 'Selecciona un banco' 
                        : '${selectedBank.code} - ${selectedBank.name}',
                    style: TextStyle(
                      fontSize: 15,
                      color: _selectedBankId == null ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
        if (banks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'No hay bancos disponibles',
              style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _showBankPicker(List<Bank> banks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String searchQuery = '';
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredBanks = banks.where((bank) {
              final nameMatch = bank.name.toLowerCase().contains(searchQuery.toLowerCase());
              final codeMatch = bank.code.contains(searchQuery);
              return nameMatch || codeMatch;
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Selecciona un Banco',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o código...',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (value) {
                            setModalState(() => searchQuery = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredBanks.isEmpty
                            ? const Center(
                                child: Text(
                                  'No se encontraron bancos',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                itemCount: filteredBanks.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                                itemBuilder: (context, index) {
                                  final bank = filteredBanks[index];
                                  final isSelected = bank.id == _selectedBankId;

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                    title: Text(
                                      bank.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF111827),
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Código: ${bank.code}',
                                      style: const TextStyle(color: Color(0xFF6B7280)),
                                    ),
                                    trailing: isSelected 
                                        ? const Icon(Icons.check_circle, color: Color(0xFF4F46E5))
                                        : null,
                                    onTap: () {
                                      setState(() => _selectedBankId = bank.id);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isSaving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                widget.method == null ? 'Crear Método' : 'Guardar Cambios',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

