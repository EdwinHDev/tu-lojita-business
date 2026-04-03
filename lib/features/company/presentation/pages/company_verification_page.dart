import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/company_provider.dart';
import '../../../../core/services/token_storage_service.dart';
import '../../../../core/di/injection_container.dart';

class CompanyVerificationPage extends ConsumerStatefulWidget {
  const CompanyVerificationPage({super.key});

  @override
  ConsumerState<CompanyVerificationPage> createState() => _CompanyVerificationPageState();
}

class _CompanyVerificationPageState extends ConsumerState<CompanyVerificationPage> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkCompanyStatus();
  }

  Future<void> _checkCompanyStatus() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final tokenStorage = sl<TokenStorageService>();
      final token = await tokenStorage.getAccessToken();

      if (token == null) {
        if (mounted) {
          context.go('/onboarding');
        }
        return;
      }

      await ref.read(companyProvider.notifier).checkUserCompanyStatus(token);

      final companyState = ref.read(companyProvider);

      if (companyState.hasCompany) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _isChecking = false;
        });
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyState = ref.watch(companyProvider);

    if (_isChecking || companyState.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Verificando empresa...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedBuilding01,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              Text(
                '¡Bienvenido!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Para continuar, necesitas crear tu empresa',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (companyState.hasStore && companyState.storeRif != null) ...[
                const SizedBox(height: 24),
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
                          'Detectamos que ya tienes una tienda registrada. Autocompletaremos el RIF por ti.',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (companyState.hasStore && companyState.storeRif != null) {
                    context.go('/create-company?rif=${companyState.storeRif}');
                  } else {
                    context.go('/create-company');
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Crear Empresa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (companyState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
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
            ],
          ),
        ),
      ),
    );
  }
}
