import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_providers.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_state.dart';
import 'package:tu_lojita_business/core/config/envs.dart';

class CompanyOnboardingScreen extends ConsumerStatefulWidget {
  const CompanyOnboardingScreen({super.key});

  @override
  ConsumerState<CompanyOnboardingScreen> createState() => _CompanyOnboardingScreenState();
}

class _CompanyOnboardingScreenState extends ConsumerState<CompanyOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rifController = TextEditingController();
  File? _logoFile;
  final _picker = ImagePicker();
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(companyOnboardingProvider.notifier).checkStatus());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rifController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    _isPickingImage = true;
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _logoFile = File(pickedFile.path);
        });
      }
    } finally {
      _isPickingImage = false;
    }
  }

  void _showStoreDetectionDialog(String storeName, String? storeRif) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Tienda detectada'),
        content: const Text(
          'Hemos detectado que ya tienes una tienda. Por normativa legal, tu empresa debe compartir el mismo RIF.\n\n'
          'El nombre de la empresa que elijas será la marca oficial para todas tus sucursales.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (storeRif != null) {
                _rifController.text = storeRif;
              }
              _nameController.text = storeName;
              Navigator.pop(context);
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final state = ref.read(companyOnboardingProvider);
    if (_logoFile == null && state.detectedStoreLogo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un logo')),
      );
      return;
    }

    final finished = await ref.read(companyOnboardingProvider.notifier).createCompany(
          name: _nameController.text,
          rif: _rifController.text,
          logoFile: _logoFile,
        );

    if (finished) {
      await ref.read(authProvider.notifier).checkStatus();
    }
  }

  Future<void> _submitBranchName(String branchName) async {
    if (branchName.isEmpty) return;
    
    final success = await ref.read(companyOnboardingProvider.notifier).setBranchName(branchName);
    if (success) {
      await ref.read(authProvider.notifier).checkStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyOnboardingProvider);

    ref.listen<CompanyOnboardingState>(companyOnboardingProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
      if (next.hasStore && (previous == null || !previous.hasStore)) {
        _showStoreDetectionDialog(next.detectedStoreName!, next.detectedStoreRif);
      }
    });

    if (state.isNamingBranch) {
      return _BranchNamingView(
        onSubmitted: _submitBranchName,
        isLoading: state.isLoading,
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                actions: [
                  IconButton(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedLogout01,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Crea tu Empresa',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo, Colors.indigoAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedStore01,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 100,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      'Bienvenido a Tu Lojita Business',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Para comenzar a gestionar tus ventas, necesitamos que registres tu empresa.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    if (state.hasStore) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Row(
                          children: [
                            const HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, color: Colors.amber, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'El nombre y logo que elijas serán la marca oficial para todas tus tiendas.',
                                style: TextStyle(fontSize: 13, color: Colors.brown),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                  image: _logoFile != null
                                      ? DecorationImage(
                                          image: FileImage(_logoFile!),
                                          fit: BoxFit.cover,
                                        )
                                      : state.detectedStoreLogo != null
                                          ? DecorationImage(
                                              image: NetworkImage('${Envs.apiBaseUrlImages}${state.detectedStoreLogo!}'),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                ),
                                child: _logoFile == null && state.detectedStoreLogo == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: Colors.indigo, size: 30),
                                          const SizedBox(height: 4),
                                          const Text('Logo', style: TextStyle(color: Colors.indigo, fontSize: 12)),
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nombre de la Empresa',
                              hintText: 'Ej: Inversiones Mi Tienda, C.A.',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: HugeIcon(icon: HugeIcons.strokeRoundedStore01, color: Colors.indigo, size: 20),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _rifController,
                            readOnly: state.hasStore,
                            decoration: InputDecoration(
                              labelText: 'RIF',
                              filled: state.hasStore,
                              fillColor: state.hasStore ? Colors.grey[100] : null,
                              prefixIcon: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: HugeIcon(icon: HugeIcons.strokeRoundedDocumentCode, color: Colors.indigo, size: 20),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: state.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: state.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Crear Empresa', style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          if (state.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _BranchNamingView extends StatefulWidget {
  final Function(String) onSubmitted;
  final bool isLoading;

  const _BranchNamingView({
    required this.onSubmitted,
    required this.isLoading,
  });

  @override
  State<_BranchNamingView> createState() => _BranchNamingViewState();
}

class _BranchNamingViewState extends State<_BranchNamingView> {
  final _controller = TextEditingController(text: 'Sede Principal');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paso Final'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¡Empresa creada con éxito!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ahora identifica tu primera tienda. Esto te ayudará a distinguirla de futuras sucursales.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Nombre de la Sucursal',
                hintText: 'Ej: Sede Principal, Tienda Norte',
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedLocation01, color: Colors.indigo, size: 20),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: widget.isLoading ? null : () => widget.onSubmitted(_controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: widget.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Finalizar', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
