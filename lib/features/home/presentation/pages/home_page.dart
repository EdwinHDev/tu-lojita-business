import 'package:flutter/material.dart';
import '../../../auth/domain/entities/backend_user_entity.dart';

class HomePage extends StatelessWidget {
  final BackendUserEntity? user;

  const HomePage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Lojita Business'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(
              child: Text('No hay usuario autenticado'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        if (user!.avatarUrl != null)
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(user!.avatarUrl!),
                          )
                        else
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              user!.firstName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          '¡Bienvenido!',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user!.fullName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user!.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Información de Usuario',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    'ID de Usuario',
                    user!.id,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    'Email',
                    user!.email,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    'Nombre',
                    user!.firstName,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    'Apellido',
                    user!.lastName ?? 'No disponible',
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 64,
                          color: Colors.green.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '¡Autenticación exitosa!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estos datos provienen de tu backend',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
