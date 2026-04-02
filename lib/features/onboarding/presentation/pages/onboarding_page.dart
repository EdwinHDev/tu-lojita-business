import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/usecases/get_onboarding_items.dart';
import '../../../auth/domain/usecases/sign_in_with_google.dart';
import '../../../auth/domain/usecases/authenticate_with_backend.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/entities/auth_response_entity.dart';
import '../widgets/onboarding_carousel.dart';

class OnboardingPage extends StatefulWidget {
  final GetOnboardingItems getOnboardingItems;
  final SignInWithGoogle signInWithGoogle;
  final AuthenticateWithBackend authenticateWithBackend;

  const OnboardingPage({
    super.key,
    required this.getOnboardingItems,
    required this.signInWithGoogle,
    required this.authenticateWithBackend,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final UserEntity? googleUser = await widget.signInWithGoogle();
      
      if (googleUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inicio de sesión cancelado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (googleUser.idToken == null) {
        throw Exception('No se pudo obtener el token de Google');
      }

      final AuthResponseEntity authResponse = 
          await widget.authenticateWithBackend(googleUser.idToken!);
      
      if (mounted) {
        context.go('/home', extra: authResponse.user);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.getOnboardingItems();

    return Scaffold(
      backgroundColor: const Color(0xFFE0E7FF),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: OnboardingCarousel(items: items),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_"G"_logo.svg/120px-Google_"G"_logo.svg.png',
                              height: 24,
                              width: 24,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.login, size: 24);
                              },
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Iniciar con Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
