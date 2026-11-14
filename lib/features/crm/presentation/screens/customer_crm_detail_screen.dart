import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import '../../domain/entities/crm_entities.dart';
import '../providers/crm_providers.dart';
import '../widgets/create_targeted_offer_sheet.dart';
import '../widgets/crm_action_helpers.dart';
import '../widgets/crm_guides_catalog.dart';
import '../widgets/crm_status_helpers.dart';

class CustomerCrmDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerCrmDetailScreen({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<CustomerCrmDetailScreen> createState() =>
      _CustomerCrmDetailScreenState();
}

class _CustomerCrmDetailScreenState
    extends ConsumerState<CustomerCrmDetailScreen> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _followUpNoteController = TextEditingController();
  String _noteCategory = 'GENERAL';
  bool _savingNote = false;
  bool _savingProfile = false;

  @override
  void dispose() {
    _noteController.dispose();
    _tagController.dispose();
    _followUpNoteController.dispose();
    super.dispose();
  }

  Future<void> _addNote(String companyId) async {
    final text = _noteController.text.trim();
    if (text.isEmpty || _savingNote) return;
    setState(() => _savingNote = true);
    try {
      await ref.read(crmRepositoryProvider).addCustomerNote(
            companyId,
            widget.customerId,
            content: text,
            category: _noteCategory,
          );
      _noteController.clear();
      ref.invalidate(crmCustomerDetailProvider(widget.customerId));
      if (mounted) {
        NotificationService.showSuccess(
          context,
          'Nota guardada en la bitácora interna (solo visible para tu empresa).',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Error al guardar nota: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  Future<void> _updateTags(String companyId, List<String> nextTags) async {
    if (_savingProfile) return;
    setState(() => _savingProfile = true);
    try {
      await ref.read(crmRepositoryProvider).updateCustomerProfile(
            companyId,
            widget.customerId,
            tags: nextTags,
          );
      ref.invalidate(crmCustomerDetailProvider(widget.customerId));
      ref.invalidate(crmCustomersProvider);
      if (mounted) {
        NotificationService.showSuccess(
          context,
          'Etiquetas internas actualizadas (visibles solo para tu equipo y buscables en el CRM).',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Error al actualizar etiquetas: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _scheduleFollowUp(
    String companyId,
    CrmCustomer customer,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          customer.nextFollowUpAt ?? DateTime.now().add(const Duration(days: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;
    _followUpNoteController.text = customer.nextFollowUpNote ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Programar Recordatorio'),
        content: TextField(
          controller: _followUpNoteController,
          decoration: const InputDecoration(
            labelText: 'Motivo / acción de seguimiento',
            hintText: 'Ej: Confirmar abono de 2da cuota',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(crmRepositoryProvider).updateCustomerProfile(
            companyId,
            widget.customerId,
            nextFollowUpAt: pickedDate,
            nextFollowUpNote: _followUpNoteController.text.trim(),
            isFollowUpCompleted: false,
          );
      ref.invalidate(crmCustomerDetailProvider(widget.customerId));
      ref.invalidate(crmCustomersProvider);
      ref.invalidate(crmSummaryProvider);
      if (mounted) {
        final dateStr = DateFormat('dd/MM/yyyy').format(pickedDate);
        NotificationService.showSuccess(
          context,
          'Recordatorio programado para el $dateStr. Si vence sin completarse, verás una alerta ámbar.',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Error al programar recordatorio: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final companyId = user?.company?.id ?? '';
    final canManageCrm = user?.canManageCrm ?? false;
    final detailAsync =
        ref.watch(crmCustomerDetailProvider(widget.customerId));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: TuLojitaBrandColors.canvas,
        appBar: AppBar(
          title: const Text(
            'Expediente 360°',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Resumen & Contacto'),
              Tab(text: 'Favoritos & Ofertas'),
              Tab(text: 'Pedidos, Reservas y Cuotas'),
              Tab(text: 'Reputación & Gobernanza'),
            ],
          ),
        ),
        body: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error al cargar expediente: $err'),
            ),
          ),
          data: (detail) {
            return TabBarView(
              children: [
                _buildSummaryTab(context, detail, companyId, canManageCrm),
                _buildFavoritesAndOffersTab(
                  context,
                  detail,
                  companyId,
                  canManageCrm,
                ),
                _buildOrdersAndBookingsTab(context, detail),
                _buildReputationTab(detail),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryTab(
    BuildContext context,
    CrmCustomerDetail detail,
    String companyId,
    bool canManageCrm,
  ) {
    final c = detail.customer;
    final seg = crmSegmentMeta(c.segment);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TuLojitaBrandColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TuLojitaBrandColors.borderMuted),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              final isCompact = constraints.maxWidth < 330 || textScale >= 1.2;

              final segPill = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: seg.bgColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  seg.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: seg.color,
                  ),
                ),
              );

              final whatsappBtn = FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: TuLojitaBrandColors.positive,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text('WhatsApp'),
                onPressed: () => openWhatsAppTemplateSheet(
                  context,
                  c,
                  onMarkContacted: canManageCrm && companyId.isNotEmpty
                      ? () async {
                          await ref
                              .read(crmRepositoryProvider)
                              .updateCustomerProfile(
                                companyId,
                                c.customerId,
                                markContactedNow: true,
                              );
                          ref.invalidate(
                            crmCustomerDetailProvider(c.customerId),
                          );
                        }
                      : null,
                ),
              );

              final callBtn = OutlinedButton.icon(
                icon: const Icon(Icons.call_outlined, size: 18),
                label: const Text('Llamar'),
                onPressed: () => callCustomerPhone(context, c.phone),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: TuLojitaBrandColors.indigo50,
                        backgroundImage: resolveCrmImageUrl(c.avatarUrl) != null
                            ? NetworkImage(resolveCrmImageUrl(c.avatarUrl)!)
                            : null,
                        onBackgroundImageError:
                            resolveCrmImageUrl(c.avatarUrl) != null
                                ? (_, _) {}
                                : null,
                        child: resolveCrmImageUrl(c.avatarUrl) == null
                            ? Text(
                                c.firstName.isNotEmpty ? c.firstName[0] : 'C',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: TuLojitaBrandColors.indigo700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isCompact) ...[
                              Text(
                                c.fullName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              segPill,
                            ] else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.fullName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  segPill,
                                ],
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '${c.identification} · ${c.phone}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: TuLojitaBrandColors.inkSecondary,
                              ),
                            ),
                            if (c.email.isNotEmpty)
                              Text(
                                c.email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: TuLojitaBrandColors.inkSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    key: const ValueKey('crm_privacy_badge'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: TuLojitaBrandColors.indigo50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: TuLojitaBrandColors.indigo100),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 15,
                          color: TuLojitaBrandColors.indigo700,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Datos protegidos: solo visibles para tu empresa',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: TuLojitaBrandColors.indigo700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isCompact)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [whatsappBtn, callBtn],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: whatsappBtn),
                        const SizedBox(width: 8),
                        callBtn,
                      ],
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        if (!canManageCrm) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: TuLojitaBrandColors.indigo50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TuLojitaBrandColors.indigo100),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 18,
                  color: TuLojitaBrandColors.indigo700,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Modo consulta: para editar notas, etiquetas o recordatorios se requiere permiso crm:manage.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: TuLojitaBrandColors.indigo700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        // Seguimiento y Recordatorio
        _SectionCard(
          title: 'Seguimiento & Recordatorio',
          helpButton: const CrmGuideButton(
            key: ValueKey('detail_reminder_guide_btn'),
            guide: CrmGuidesCatalog.followUpReminders,
          ),
          trailing: canManageCrm
              ? TextButton.icon(
                  icon: const Icon(Icons.event_available_outlined, size: 17),
                  label: const Text('Programar'),
                  onPressed: () => _scheduleFollowUp(companyId, c),
                )
              : null,
          child: c.nextFollowUpAt == null
              ? const Text(
                  'Sin seguimiento programado.',
                  style: TextStyle(
                    fontSize: 13,
                    color: TuLojitaBrandColors.inkSecondary,
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          c.isFollowUpCompleted
                              ? Icons.check_circle_rounded
                              : Icons.notifications_active_rounded,
                          color: c.isFollowUpCompleted
                              ? TuLojitaBrandColors.positive
                              : (c.hasOverdueFollowUp
                                  ? TuLojitaBrandColors.danger
                                  : TuLojitaBrandColors.amber700),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(c.nextFollowUpAt!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (c.nextFollowUpNote != null &&
                                  c.nextFollowUpNote!.isNotEmpty)
                                Text(
                                  c.nextFollowUpNote!,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (canManageCrm && !c.isFollowUpCompleted)
                      TextButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(crmRepositoryProvider)
                                .updateCustomerProfile(
                                  companyId,
                                  c.customerId,
                                  isFollowUpCompleted: true,
                                );
                            ref.invalidate(
                              crmCustomerDetailProvider(c.customerId),
                            );
                            ref.invalidate(crmCustomersProvider);
                            ref.invalidate(crmSummaryProvider);
                            if (context.mounted) {
                              NotificationService.showSuccess(
                                context,
                                'Seguimiento marcado como completado.',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              NotificationService.showError(
                                context,
                                'Error al completar seguimiento: $e',
                              );
                            }
                          }
                        },
                        child: const Text('Completar'),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        // Etiquetas Personalizadas
        _SectionCard(
          title: 'Etiquetas Personalizadas',
          helpButton: const CrmGuideButton(
            key: ValueKey('detail_tags_guide_btn'),
            guide: CrmGuidesCatalog.notesAndTags,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...c.tags.map(
                    (tag) => Chip(
                      label: Text(tag),
                      onDeleted: canManageCrm
                          ? () {
                              final next = c.tags
                                  .where((t) => t != tag)
                                  .toList();
                              _updateTags(companyId, next);
                            }
                          : null,
                    ),
                  ),
                  if (c.tags.isEmpty)
                    const Text(
                      'Sin etiquetas asignadas.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                    ),
                ],
              ),
              if (canManageCrm) ...[
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale =
                        MediaQuery.textScalerOf(context).scale(1.0);
                    final stackTagInput =
                        constraints.maxWidth < 310 || textScale >= 1.2;
                    final tagInput = TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: 'Nueva etiqueta (ej. Mayorista, VIP Norte)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    );
                    final addButton = FilledButton(
                      onPressed: _savingProfile
                          ? null
                          : () {
                              final tag = _tagController.text.trim();
                              if (tag.isEmpty) return;
                              _tagController.clear();
                              _updateTags(
                                companyId,
                                {...c.tags, tag}.toList(),
                              );
                            },
                      child: const Text('Agregar'),
                    );

                    if (stackTagInput) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          tagInput,
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: addButton,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: tagInput),
                        const SizedBox(width: 8),
                        addButton,
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Direcciones Guardadas + Mapa GPS
        _SectionCard(
          title: 'Direcciones Guardadas (${detail.addresses.length})',
          child: detail.addresses.isEmpty
              ? const Text(
                  'El cliente no ha registrado direcciones.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: TuLojitaBrandColors.inkSecondary,
                  ),
                )
              : Column(
                  children: detail.addresses
                      .map(
                        (addr) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: TuLojitaBrandColors.canvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: TuLojitaBrandColors.borderSubtle,
                            ),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final textScale =
                                  MediaQuery.textScalerOf(context).scale(1.0);
                              final stackMapBtn = constraints.maxWidth < 310 ||
                                  textScale >= 1.2;
                              final info = Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: addr.isActive
                                        ? TuLojitaBrandColors.indigo600
                                        : TuLojitaBrandColors.inkSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          addr.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${addr.fullAddress}${addr.reference != null ? ' · Ref: ${addr.reference}' : ''}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                              final mapBtn = OutlinedButton.icon(
                                icon:
                                    const Icon(Icons.map_outlined, size: 16),
                                label: const Text('Mapa'),
                                onPressed: () =>
                                    openCustomerLocationMap(context, addr),
                              );

                              if (stackMapBtn) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    info,
                                    const SizedBox(height: 8),
                                    mapBtn,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(child: info),
                                  const SizedBox(width: 8),
                                  mapBtn,
                                ],
                              );
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 14),
        // Notas Internas del Equipo
        _SectionCard(
          title: 'Bitácora Interna del Equipo (${detail.notes.length})',
          helpButton: const CrmGuideButton(
            key: ValueKey('detail_notes_guide_btn'),
            guide: CrmGuidesCatalog.notesAndTags,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canManageCrm) ...[
                DropdownButtonFormField<String>(
                  initialValue: _noteCategory,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                    DropdownMenuItem(
                      value: 'FOLLOW_UP',
                      child: Text('Seguimiento'),
                    ),
                    DropdownMenuItem(value: 'PAYMENT', child: Text('Cobranza')),
                    DropdownMenuItem(value: 'VIP', child: Text('Atención VIP')),
                    DropdownMenuItem(value: 'ALERT', child: Text('Alerta')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _noteCategory = v);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Escribe una nota interna visible solo para la empresa...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed:
                        _savingNote ? null : () => _addNote(companyId),
                    icon: const Icon(Icons.note_add_outlined, size: 18),
                    label: Text(_savingNote ? 'Guardando...' : 'Guardar Nota'),
                  ),
                ),
                const Divider(height: 24),
              ],
              if (detail.notes.isEmpty)
                const Text(
                  'Sin notas registradas aún.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: TuLojitaBrandColors.inkSecondary,
                  ),
                )
              else
                ...detail.notes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: TuLojitaBrandColors.canvas,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    note.authorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  CrmStatusBadge(
                                    meta: crmNoteCategoryMeta(note.category),
                                    compact: true,
                                  ),
                                ],
                              ),
                              Text(
                                dateFmt.format(note.createdAt.toLocal()),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: TuLojitaBrandColors.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note.content,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesAndOffersTab(
    BuildContext context,
    CrmCustomerDetail detail,
    String companyId,
    bool canManageCrm,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Artículos en Favoritos (${detail.favoriteItems.length})',
          helpButton: const CrmGuideButton(
            key: ValueKey('detail_favorites_guide_btn'),
            guide: CrmGuidesCatalog.targetedOffers,
          ),
          child: detail.favoriteItems.isEmpty
              ? const Text(
                  'Este cliente no tiene productos guardados en favoritos en tus sucursales.',
                  style: TextStyle(
                    fontSize: 13,
                    color: TuLojitaBrandColors.inkSecondary,
                  ),
                )
              : Column(
                  children: detail.favoriteItems
                      .map(
                        (fav) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: TuLojitaBrandColors.canvas,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: TuLojitaBrandColors.borderMuted,
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final textScale =
                                    MediaQuery.textScalerOf(context).scale(1.0);
                                final stackOfferBtn =
                                    constraints.maxWidth < 310 ||
                                        textScale >= 1.2;
                                final itemInfo = Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child:
                                          resolveCrmImageUrl(fav.mainImage) !=
                                                  null
                                              ? Image.network(
                                                  resolveCrmImageUrl(
                                                    fav.mainImage,
                                                  )!,
                                                  width: 54,
                                                  height: 54,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      _imgFallback(),
                                                )
                                              : _imgFallback(),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fav.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                          Text(
                                            fav.storeName,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: TuLojitaBrandColors
                                                  .inkSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          DualPriceText(
                                            amountInUsd: fav.price,
                                            usdStyle: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                            bsStyle: const TextStyle(
                                              fontSize: 10.5,
                                              color: TuLojitaBrandColors
                                                  .inkSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                                final offerBtn = canManageCrm
                                    ? FilledButton.tonalIcon(
                                        icon: const Icon(
                                          Icons.local_offer_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Oferta'),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            showDragHandle: true,
                                            builder: (_) =>
                                                CreateTargetedOfferSheet(
                                              companyId: companyId,
                                              customer: detail.customer,
                                              favoriteItems:
                                                  detail.favoriteItems,
                                              initialItemId: fav.itemId,
                                            ),
                                          );
                                        },
                                      )
                                    : null;

                                if (stackOfferBtn || offerBtn == null) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      itemInfo,
                                      if (offerBtn != null) ...[
                                        const SizedBox(height: 8),
                                        offerBtn,
                                      ],
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(child: itemInfo),
                                    const SizedBox(width: 8),
                                    offerBtn,
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Ofertas Especiales Enviadas (${detail.targetedOffers.length})',
          child: detail.targetedOffers.isEmpty
              ? const Text(
                  'No se han enviado ofertas dirigidas a este cliente.',
                  style: TextStyle(
                    fontSize: 13,
                    color: TuLojitaBrandColors.inkSecondary,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: detail.targetedOffers
                      .map(
                        (offer) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: TuLojitaBrandColors.canvas,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: offer.isActive
                                    ? TuLojitaBrandColors.amber400
                                    : TuLojitaBrandColors.borderMuted,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          offer.offerCode,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        CrmStatusBadge(
                                          meta:
                                              crmOfferStatusMeta(offer.status),
                                          compact: true,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '-${offer.discountPercent.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: TuLojitaBrandColors.positive,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  offer.itemTitle ?? 'Producto',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                DualPriceText(
                                  amountInUsd: offer.offerPrice,
                                  usdStyle: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                if (offer.isActive &&
                                    detail.customer.phone.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final textScale =
                                          MediaQuery.textScalerOf(context)
                                              .scale(1.0);
                                      final stackActions =
                                          constraints.maxWidth < 310 ||
                                              textScale >= 1.2;
                                      final resendBtn = OutlinedButton.icon(
                                        icon: const Icon(
                                          Icons.chat_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('Reenviar WhatsApp'),
                                        onPressed: () => launchDirectWhatsApp(
                                          context,
                                          detail.customer.phone,
                                          message: offer.whatsappShareText,
                                        ),
                                      );
                                      final cancelBtn = canManageCrm
                                          ? TextButton(
                                              onPressed: () async {
                                                try {
                                                  await ref
                                                      .read(
                                                        crmRepositoryProvider,
                                                      )
                                                      .cancelOffer(
                                                        companyId,
                                                        offer.id,
                                                      );
                                                  ref.invalidate(
                                                    crmCustomerDetailProvider(
                                                      widget.customerId,
                                                    ),
                                                  );
                                                  ref.invalidate(
                                                    crmCustomersProvider,
                                                  );
                                                  ref.invalidate(
                                                    crmSummaryProvider,
                                                  );
                                                  if (context.mounted) {
                                                    NotificationService
                                                        .showSuccess(
                                                      context,
                                                      'Oferta especial cancelada.',
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    NotificationService
                                                        .showError(
                                                      context,
                                                      'Error al cancelar oferta: $e',
                                                    );
                                                  }
                                                }
                                              },
                                              child: const Text(
                                                'Cancelar',
                                                style: TextStyle(
                                                  color:
                                                      TuLojitaBrandColors.danger,
                                                ),
                                              ),
                                            )
                                          : null;

                                      if (stackActions || cancelBtn == null) {
                                        return Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            resendBtn,
                                            ?cancelBtn,
                                          ],
                                        );
                                      }
                                      return Row(
                                        children: [
                                          Expanded(child: resendBtn),
                                          const SizedBox(width: 8),
                                          cancelBtn,
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildOrdersAndBookingsTab(
    BuildContext context,
    CrmCustomerDetail detail,
  ) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Pedidos Consolidados (${detail.orders.length})',
          child: detail.orders.isEmpty
              ? const Text('Sin pedidos registrados en las sucursales.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: detail.orders.map((order) {
                    final orderMeta = crmOrderStatusMeta(
                      order.status,
                      preOrderStatus: order.preOrderStatus,
                    );
                    final preOrderCode = order.preOrderStatus?.trim();
                    final installmentsSummary =
                        formatOrderInstallmentsSummary(order.installments);
                    return InkWell(
                      onTap: () =>
                          context.push('/dashboard/orders/${order.id}'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TuLojitaBrandColors.canvas,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: TuLojitaBrandColors.borderMuted,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  order.storeName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    CrmStatusBadge(
                                      meta: orderMeta,
                                      compact: true,
                                    ),
                                    if (preOrderCode != null &&
                                        preOrderCode.isNotEmpty &&
                                        preOrderCode.toUpperCase() != 'NONE')
                                      CrmStatusBadge(
                                        meta:
                                            crmPreOrderStatusMeta(preOrderCode),
                                        compact: true,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            DualPriceText(
                              amountInUsd: order.finalAmount,
                              customRate: order.exchangeRate,
                              usdStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            if (order.remainingBalance > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: DualPriceText(
                                  prefix: 'Saldo pendiente: ',
                                  amountInUsd: order.remainingBalance,
                                  customRate: order.exchangeRate,
                                  usdStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: TuLojitaBrandColors.danger,
                                  ),
                                  bsStyle: const TextStyle(
                                    fontSize: 10.5,
                                    color: TuLojitaBrandColors.danger,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Fecha: ${fmt.format(order.createdAt.toLocal())} · ${order.items.length} ítem(s)${installmentsSummary != null ? ' · $installmentsSummary' : ''}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: TuLojitaBrandColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Citas y Reservas (${detail.slotBookings.length})',
          child: detail.slotBookings.isEmpty
              ? const Text('Sin citas ni reservas registradas.')
              : Column(
                  children: detail.slotBookings.map((bk) {
                    final statusMeta = crmSlotBookingStatusMeta(bk.status);
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: TuLojitaBrandColors.canvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TuLojitaBrandColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: TuLojitaBrandColors.indigo600,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '${bk.bookingDate} (${bk.slotStartTime} - ${bk.slotEndTime})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    CrmStatusBadge(
                                      meta: statusMeta,
                                      compact: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bk.storeName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: TuLojitaBrandColors.inkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildReputationTab(CrmCustomerDetail detail) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Reputación como Comprador',
          helpButton: const CrmGuideButton(
            key: ValueKey('detail_governance_guide_btn'),
            guide: CrmGuidesCatalog.reputationAndGovernance,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 32,
                color: TuLojitaBrandColors.amber500,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${detail.customer.averageBuyerRating.toStringAsFixed(1)} / 5.0',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${detail.customer.totalBuyerReviews} calificación(es) recibida(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TuLojitaBrandColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Disputas y Reclamos (${detail.disputes.length})',
          child: detail.disputes.isEmpty
              ? const Text('Sin disputas en las órdenes con la empresa.')
              : Column(
                  children: detail.disputes.map((d) {
                    final typeLabel =
                        crmDisputeTypeLabel(d['type']?.toString() ?? '');
                    final statusMeta =
                        crmDisputeStatusMeta(d['status']?.toString() ?? '');
                    final desc = d['description']?.toString() ?? '';
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: TuLojitaBrandColors.canvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TuLojitaBrandColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.gavel_outlined,
                            size: 18,
                            color: TuLojitaBrandColors.danger,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      typeLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    CrmStatusBadge(
                                      meta: statusMeta,
                                      compact: true,
                                    ),
                                  ],
                                ),
                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    desc,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: TuLojitaBrandColors.inkSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Bloqueos por Sucursal (${detail.blocks.length})',
          child: detail.blocks.isEmpty
              ? const Text('Cliente habilitado en todas las sucursales.')
              : Column(
                  children: detail.blocks
                      .map(
                        (b) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.block_rounded,
                            color: TuLojitaBrandColors.danger,
                          ),
                          title: Text(b['storeName']?.toString() ?? 'Sucursal'),
                          subtitle: Text(
                            b['reason']?.toString() ?? 'Bloqueo preventivo',
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _imgFallback() => Container(
        width: 54,
        height: 54,
        color: TuLojitaBrandColors.borderSubtle,
        child: const Icon(Icons.image_not_supported_outlined, size: 20),
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? helpButton;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    this.helpButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TuLojitaBrandColors.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              final hasExtras = helpButton != null || trailing != null;
              final titleWidget = Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              );
              final extrasWidget = Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ?helpButton,
                  ?trailing,
                ],
              );

              if (!hasExtras) return titleWidget;
              if (constraints.maxWidth < 310 || textScale >= 1.2) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 6),
                    extrasWidget,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: titleWidget),
                  const SizedBox(width: 8),
                  extrasWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
