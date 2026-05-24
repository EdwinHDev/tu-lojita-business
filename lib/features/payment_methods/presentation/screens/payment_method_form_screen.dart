import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/models/store_payment_method.dart';
import '../../../../core/repositories/bank_repository.dart';
import '../../../../core/repositories/payment_methods_repository.dart';
import '../../../../core/models/bank.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';

class PaymentMethodFormScreen extends ConsumerStatefulWidget {
  final String storeId;
  final StorePaymentMethod? method;
  const PaymentMethodFormScreen({
    super.key,
    required this.storeId,
    this.method,
  });

  @override
  ConsumerState<PaymentMethodFormScreen> createState() =>
      _PaymentMethodFormScreenState();
}

class _PaymentMethodFormScreenState
    extends ConsumerState<PaymentMethodFormScreen> {
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

  // --- Reactive save button ---
  bool get _isEditing => widget.method != null;

  bool _hasChanges() {
    if (!_isEditing) return true; // Always enabled when creating
    final m = widget.method!;
    if (_selectedType != m.type) return true;
    if (_titleController.text.trim() != (m.title).trim()) return true;
    if (_holderController.text.trim() != (m.accountHolder ?? '').trim()) {
      return true;
    }
    if (_idNumberController.text.trim() != (m.idNumber ?? '').trim()) {
      return true;
    }
    if (_accountNumberController.text.trim() !=
        (m.accountNumber ?? '').trim()) {
      return true;
    }
    if (_phoneController.text.trim() != (m.phoneNumber ?? '').trim()) {
      return true;
    }
    if (_emailController.text.trim() != (m.email ?? '').trim()) return true;
    if (_walletController.text.trim() != (m.walletAddress ?? '').trim()) {
      return true;
    }
    if (_instructionsController.text.trim() !=
        (m.instructions ?? '').trim()) {
      return true;
    }
    if (_selectedBankId != m.bank?.id) return true;
    if (_isActive != m.isActive) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _selectedType = widget.method?.type ?? PaymentMethodType.pagoMovil;
    _titleController = TextEditingController(text: widget.method?.title);
    _holderController = TextEditingController(
      text: widget.method?.accountHolder,
    );
    _idNumberController =
        TextEditingController(text: widget.method?.idNumber);
    _accountNumberController = TextEditingController(
      text: widget.method?.accountNumber,
    );
    _phoneController =
        TextEditingController(text: widget.method?.phoneNumber);
    _emailController = TextEditingController(text: widget.method?.email);
    _walletController = TextEditingController(
      text: widget.method?.walletAddress,
    );
    _instructionsController = TextEditingController(
      text: widget.method?.instructions,
    );
    _selectedBankId = widget.method?.bank?.id;
    _isActive = widget.method?.isActive ?? true;

    // Listen to all controllers to rebuild the save button reactively
    for (final ctrl in _allControllers) {
      ctrl.addListener(_onFieldChanged);
    }
  }

  List<TextEditingController> get _allControllers => [
        _titleController,
        _holderController,
        _idNumberController,
        _accountNumberController,
        _phoneController,
        _emailController,
        _walletController,
        _instructionsController,
      ];

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final ctrl in _allControllers) {
      ctrl.removeListener(_onFieldChanged);
      ctrl.dispose();
    }
    super.dispose();
  }

  // --- Icon & color helpers ---

  List<List<dynamic>> _hugeIconForType(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.pagoMovil:
        return HugeIcons.strokeRoundedSmartPhone01;
      case PaymentMethodType.transfer:
        return HugeIcons.strokeRoundedBank;
      case PaymentMethodType.binance:
        return HugeIcons.strokeRoundedBitcoin01;
    }
  }

  // --- Save / Delete ---

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final type = _selectedType;
    final data = {
      'type': type.toJsonValue(),
      'title': _titleController.text.trim(),
      'instructions': _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
      'isActive': _isActive,
      'storeId': widget.storeId,
      'accountHolder': (type == PaymentMethodType.pagoMovil || type == PaymentMethodType.transfer)
          ? (_holderController.text.trim().isEmpty ? null : _holderController.text.trim())
          : null,
      'idNumber': (type == PaymentMethodType.pagoMovil || type == PaymentMethodType.transfer)
          ? (_idNumberController.text.trim().isEmpty ? null : _idNumberController.text.trim())
          : null,
      'bankId': (type == PaymentMethodType.pagoMovil || type == PaymentMethodType.transfer)
          ? _selectedBankId
          : null,
      'phoneNumber': (type == PaymentMethodType.pagoMovil)
          ? (_phoneController.text.trim().isEmpty ? null : _phoneController.text.trim())
          : null,
      'accountNumber': (type == PaymentMethodType.transfer)
          ? (_accountNumberController.text.trim().isEmpty ? null : _accountNumberController.text.trim())
          : null,
      'walletAddress': (type == PaymentMethodType.binance)
          ? (_walletController.text.trim().isEmpty ? null : _walletController.text.trim())
          : null,
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

    final methodTitle = _titleController.text.trim();
    if (success) {
      ref.invalidate(storePaymentMethodsProvider(widget.storeId));
      NotificationService.showSuccess(
        context,
        _isEditing
            ? '"$methodTitle" actualizado correctamente'
            : '"$methodTitle" creado correctamente',
      );
      Navigator.pop(context);
    } else {
      NotificationService.showError(
        context,
        'Error al guardar el método de pago. Intenta de nuevo.',
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar Método',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este método de pago? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isSaving = true);
              final success = await ref
                  .read(paymentMethodsRepositoryProvider)
                  .deleteMethod(widget.method!.id);
              if (context.mounted) {
                setState(() => _isSaving = false);
                if (success) {
                  ref.invalidate(
                      storePaymentMethodsProvider(widget.storeId));
                  Navigator.pop(context);
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Color(0xFF111827),
            size: 22,
          ),
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
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                color: Color(0xFFEF4444),
                size: 22,
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
              // Dynamic type header
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildTypeHeader(_selectedType),
              ),
              const SizedBox(height: 20),

              // Type selector chips
              _buildSectionLabel('Tipo de Pago'),
              const SizedBox(height: 10),
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // General info
              _buildSectionLabel('Información General'),
              const SizedBox(height: 10),
              _buildGeneralInfoSection(),
              const SizedBox(height: 24),

              // Account details with animated switcher
              _buildSectionLabel('Detalles de la Cuenta'),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      )),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_selectedType),
                  child: _buildAccountDetailsSection(),
                ),
              ),

              const SizedBox(height: 36),
              _buildSaveButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header ---

  Widget _buildTypeHeader(PaymentMethodType type) {
    return Container(
      key: ValueKey(type),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: HugeIcon(
              icon: _hugeIconForType(type),
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.method == null
                      ? 'Nuevo método de pago'
                      : 'Editar configuración',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Type selector chips ---

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PaymentMethodType.values.map((type) {
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: _hugeIconForType(type),
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6B7280),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type.displayName,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF374151),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Section label ---

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF9CA3AF),
        letterSpacing: 1.2,
      ),
    );
  }

  // --- General info section ---

  Widget _buildGeneralInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            label: 'Título descriptivo',
            hint: 'Ej: Mi Banesco, Pago Móvil Personal',
            controller: _titleController,
            icon: HugeIcons.strokeRoundedTag01,
            validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: Color(0xFF6B7280),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Método Activo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Visible para tus clientes al pagar',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                  ],
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

  // --- Account details section ---

  Widget _buildAccountDetailsSection() {
    final banksAsync = ref.watch(banksProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedType == PaymentMethodType.pagoMovil ||
              _selectedType == PaymentMethodType.transfer) ...[
            banksAsync.when(
              data: (banks) => _buildBankSelector(banks),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(color: Color(0xFF4F46E5)),
              ),
              error: (_, _) =>
                  const Text('Error cargando bancos'),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Titular de la cuenta',
              controller: _holderController,
              icon: HugeIcons.strokeRoundedUser02,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Cédula / RIF del titular',
              controller: _idNumberController,
              icon: HugeIcons.strokeRoundedIdentityCard,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
          ],
          if (_selectedType == PaymentMethodType.pagoMovil) ...[
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Número de Teléfono',
              controller: _phoneController,
              icon: HugeIcons.strokeRoundedSmartPhone01,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
          ],
          if (_selectedType == PaymentMethodType.transfer) ...[
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Número de Cuenta',
              hint: '20 dígitos',
              controller: _accountNumberController,
              icon: HugeIcons.strokeRoundedBank,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Campo requerido';
                if (v!.length != 20) return 'Debe tener 20 dígitos';
                return null;
              },
            ),
          ],
          if (_selectedType == PaymentMethodType.binance) ...[
            _buildTextField(
              label: 'Binance ID / Wallet Address',
              controller: _walletController,
              icon: HugeIcons.strokeRoundedBitcoin01,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
          ],

          const SizedBox(height: 16),
          _buildTextField(
            label: 'Instrucciones (Opcional)',
            hint: 'Ej: Reportar por WhatsApp enviando captura',
            controller: _instructionsController,
            icon: HugeIcons.strokeRoundedInformationCircle,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // --- Text field ---

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required List<List<dynamic>> icon,
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
            hintStyle:
                const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: HugeIcon(icon: icon, color: const Color(0xFF9CA3AF), size: 20),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // --- Bank selector ---

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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedBank,
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
                      color: _selectedBankId == null
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  color: Color(0xFF9CA3AF),
                  size: 18,
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
              final nameMatch = bank.name.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
              final codeMatch = bank.code.contains(searchQuery);
              return nameMatch || codeMatch;
            }).toList();

            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(bottom: bottomPadding),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o código...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF9CA3AF),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
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
                              style:
                                  TextStyle(color: Color(0xFF6B7280)),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            itemCount: filteredBanks.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              color: Color(0xFFF3F4F6),
                            ),
                            itemBuilder: (context, index) {
                              final bank = filteredBanks[index];
                              final isSelected =
                                  bank.id == _selectedBankId;

                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                title: Text(
                                  bank.name,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFF111827),
                                  ),
                                ),
                                subtitle: Text(
                                  'Código: ${bank.code}',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF4F46E5),
                                      )
                                    : null,
                                onTap: () {
                                  setState(
                                      () => _selectedBankId = bank.id);
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
  }

  // --- Save button ---

  Widget _buildSaveButton() {
    final canSave = !_isSaving && _hasChanges();
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: FilledButton(
          onPressed: canSave ? _save : null,
          style: FilledButton.styleFrom(
            backgroundColor:
                canSave ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB),
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.method == null ? 'Crear Método' : 'Guardar Cambios',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: canSave ? Colors.white : const Color(0xFF9CA3AF),
                  ),
                ),
        ),
      ),
    );
  }
}
