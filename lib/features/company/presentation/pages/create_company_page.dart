import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/company_provider.dart';
import '../../data/models/company_model.dart';
import '../../../../core/services/token_storage_service.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/di/injection_container.dart';

class CreateCompanyPage extends ConsumerStatefulWidget {
  final String? initialRif;

  const CreateCompanyPage({
    super.key,
    this.initialRif,
  });

  @override
  ConsumerState<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends ConsumerState<CreateCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rifController = TextEditingController();
  final _imageUploadService = ImageUploadService();
  final _imagePicker = ImagePicker();
  
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRif != null) {
      _rifController.text = widget.initialRif!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rifController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createCompany() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar un logo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final tokenStorage = sl<TokenStorageService>();
    final token = await tokenStorage.getAccessToken();

    if (token == null) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró el token de autenticación'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/onboarding');
      }
      return;
    }

    String? uploadedImageUrl;

    try {
      // 1. Subir la imagen primero
      uploadedImageUrl = await _imageUploadService.uploadImage(_selectedImage!);

      // 2. Crear la empresa con la URL relativa (/img/id)
      final dto = CreateCompanyDto(
        name: _nameController.text.trim(),
        rif: _rifController.text.trim(),
        logo: uploadedImageUrl, // /img/id tal como lo devuelve el servidor
      );

      final success = await ref.read(companyProvider.notifier).createCompany(dto, token);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Empresa creada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/home');
      } else if (!success) {
        // Si falla la creación de empresa, eliminar la imagen
        // Extraer el ID de la URL /img/id
        final imageId = uploadedImageUrl.split('/').last;
        await _imageUploadService.deleteImage(imageId);
      }
    } catch (e) {
      // Si hay error, eliminar la imagen si se subió
      if (uploadedImageUrl != null) {
        try {
          // Extraer el ID de la URL /img/id
          final imageId = uploadedImageUrl.split('/').last;
          await _imageUploadService.deleteImage(imageId);
        } catch (deleteError) {
          // Error al eliminar imagen, pero ya se mostró el error principal
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyState = ref.watch(companyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Empresa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crear Empresa',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Completa la información de tu empresa',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),
              if (widget.initialRif != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        size: 24,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Detectamos que ya tienes una tienda. Hemos autocompletado el RIF.',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Logo selector (circular)
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: _selectedImage != null
                        ? Stack(
                            children: [
                              ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  width: 180,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedEdit02,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: _pickImage,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedImage01,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Seleccionar Logo',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Toca para elegir',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la Empresa',
                  hintText: 'Ej: Mi Empresa S.A.',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedBuilding01,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _rifController,
                decoration: InputDecoration(
                  labelText: 'RIF',
                  hintText: 'Ej: J-12345678-9',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedIdVerified,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  helperText: widget.initialRif != null 
                      ? 'RIF autocompletado desde tu tienda (puedes editarlo)'
                      : null,
                  helperMaxLines: 2,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El RIF es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              if (companyState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedAlert01,
                        size: 20,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          companyState.error!,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              FilledButton(
                onPressed: (companyState.isLoading || _isUploading) ? null : _createCompany,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: (companyState.isLoading || _isUploading)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Crear Empresa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
