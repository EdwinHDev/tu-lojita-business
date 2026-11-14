import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/contextual_help_sheet.dart';

/// Immutable contextual guide content entry for the Mini CRM 360° module.
class CrmGuideEntry {
  final String title;
  final String explanation;
  final List<String> bulletPoints;
  final String? example;
  final IconData icon;
  final Color color;

  const CrmGuideEntry({
    required this.title,
    required this.explanation,
    this.bulletPoints = const [],
    this.example,
    this.icon = Icons.help_outline_rounded,
    this.color = TuLojitaBrandColors.indigo600,
  });
}

/// Centralized catalog of contextual guides for CRM features, governance and RBAC.
abstract final class CrmGuidesCatalog {
  static const CrmGuideEntry rfmSegments = CrmGuideEntry(
    title: '¿Qué significan los Segmentos RFM?',
    explanation:
        'RFM evalúa a cada comprador según tres dimensiones reales: Recencia (qué tan reciente fue su última compra), Frecuencia (cuántos pedidos completó) y Monto (cuánto suma en compras válidas).',
    bulletPoints: [
      'VIP: clientes con LTV >= \$250 USD o >= 4 compras en los últimos 60 días.',
      'Frecuente: clientes con >= 2 compras válidas en los últimos 45 días.',
      'Nuevo: compradores recientes que están iniciando relación con tu negocio.',
      'En Riesgo: compradores que superan 45–60 días sin volver a comprar.',
      'Con Deuda: compradores con saldo o cuotas pendientes por cobrar.',
      'Con Favoritos / Bloqueado: prospectos con productos guardados o clientes restringidos en alguna sede.',
    ],
    example:
        'Tip: Selecciona "Con Favoritos" o "En Riesgo" y toca Oferta o WhatsApp para reactivar compras en segundos.',
    icon: Icons.auto_awesome_outlined,
    color: TuLojitaBrandColors.indigo600,
  );

  static const CrmGuideEntry ltvMetric = CrmGuideEntry(
    title: '¿Qué es LTV (Valor de Vida del Cliente)?',
    explanation:
        'LTV significa Lifetime Value (Valor de Vida del Cliente): es el monto total acumulado en compras válidas que un comprador ha realizado en tus sucursales autorizadas.',
    bulletPoints: [
      'Suma el historial de pedidos pagados o completados en USD y su equivalente referencial en Bs.',
      'Excluye pedidos cancelados o con pago rechazado para reflejar ingresos reales.',
      'Te ayuda a detectar clientes clave (por ejemplo >= \$250 USD para nivel VIP) y priorizar seguimiento.',
    ],
    example:
        'Ejemplo: Si un cliente compró 3 veces por \$90, \$80 y \$110 USD, su LTV Total es \$280 USD.',
    icon: Icons.monetization_on_outlined,
    color: TuLojitaBrandColors.positive,
  );

  static const CrmGuideEntry followUpReminders = CrmGuideEntry(
    title: 'Seguimiento & Recordatorios',
    explanation:
        'Programa fechas clave para contactar a un cliente (confirmar un abono, avisar reposición de stock o cerrar una cotización) sin depender de memoria ni libretas.',
    bulletPoints: [
      'La fecha programada cuenta en tu indicador "Seguimientos" del panel CRM.',
      'Si la fecha vence sin marcarse como completada, la app resalta una alerta ámbar en la tarjeta y en la pestaña Clientes.',
      'Al cumplir la tarea, toca "Completar" para limpiar la alerta del equipo.',
    ],
    example:
        'Ejemplo: Programa seguimiento a 3 días con nota "Confirmar pago de 2da cuota y ofrecer envío prioritario".',
    icon: Icons.event_available_outlined,
    color: TuLojitaBrandColors.amber700,
  );

  static const CrmGuideEntry notesAndTags = CrmGuideEntry(
    title: 'Etiquetas y Bitácora Interna',
    explanation:
        'Organiza a tus compradores con etiquetas rápidas y documenta cada interacción en una bitácora 100% privada para tu empresa y colaboradores autorizados.',
    bulletPoints: [
      'Visibilidad interna exclusiva: el comprador nunca ve estas etiquetas ni notas.',
      'Las etiquetas (ej. Mayorista, VIP Norte) también sirven para encontrar clientes desde el buscador del CRM.',
      'Clasifica tus notas en General, Seguimiento, Cobranza, Atención VIP o Alerta para dar contexto a todo el equipo.',
    ],
    example:
        'Ejemplo: Agrega la etiqueta "Mayorista" y una nota "Prefiere entregas los martes antes de las 2:00 PM".',
    icon: Icons.sticky_note_2_outlined,
    color: TuLojitaBrandColors.indigo600,
  );

  static const CrmGuideEntry targetedOffers = CrmGuideEntry(
    title: 'Ofertas Relámpago en Favoritos',
    explanation:
        'Convierte el interés real en pedidos enviando un descuento privado por tiempo limitado únicamente sobre artículos que este cliente guardó en sus favoritos.',
    bulletPoints: [
      'Solo aplican sobre artículos activos en la lista de favoritos del comprador.',
      'Al activar la campaña, el cliente recibe una notificación Push con su código privado y enlace directo al producto.',
      'Puedes reforzar al instante compartiendo el mensaje y enlace profundo por WhatsApp.',
      'La vigencia (6h a 72h) y la tarifa administrativa de campaña se rigen por la configuración vigente de plataforma.',
    ],
    example:
        'Ejemplo: Ofrece un -15% válido por 24h en los audífonos que guardó ayer para acelerar el cierre de venta.',
    icon: Icons.local_offer_outlined,
    color: TuLojitaBrandColors.amber800,
  );

  static const CrmGuideEntry reputationAndGovernance = CrmGuideEntry(
    title: 'Reputación, Disputas y Bloqueos',
    explanation:
        'Consulta el historial de confiabilidad del comprador antes de despachar o aprobar planes en cuotas dentro de tus sucursales autorizadas.',
    bulletPoints: [
      'Reputación: promedio de calificaciones recibidas como comprador.',
      'Disputas: historial de reclamos registrados en órdenes con tu empresa.',
      'Bloqueos por sucursal: restricciones preventivas activas y su motivo.',
    ],
    example:
        'Si un usuario acumula reclamos o bloqueos en una sede, tu equipo lo verá de inmediato en su expediente 360°.',
    icon: Icons.verified_user_outlined,
    color: TuLojitaBrandColors.indigo700,
  );

  static const CrmGuideEntry rolePermissions = CrmGuideEntry(
    title: 'Permisos CRM en Roles de Colaboradores',
    explanation:
        'El módulo CRM expone datos personales del cliente protegidos por sucursal. Asigna el nivel exacto según la responsabilidad de cada miembro de tu equipo.',
    bulletPoints: [
      'Ver CRM (crm:access): permite consultar el directorio, métricas, teléfono, cédula, correo y direcciones GPS de clientes de sus sucursales autorizadas.',
      'Gestionar CRM (crm:manage): habilita agregar o quitar etiquetas, escribir notas internas, programar recordatorios y enviar o cancelar ofertas relámpago.',
      'Un colaborador sin crm:manage operará en Modo Consulta (solo lectura) dentro de la pestaña Clientes.',
    ],
    example:
        'Recomendación: Otorga solo crm:access a personal de atención básica y reserva crm:manage para líderes de ventas o gerencia.',
    icon: Icons.admin_panel_settings_outlined,
    color: TuLojitaBrandColors.indigo600,
  );
}

/// Standardized compact/full contextual 'Guía' chip backed by [CrmGuideEntry].
class CrmGuideButton extends StatelessWidget {
  final CrmGuideEntry guide;
  final bool compact;
  final String label;

  const CrmGuideButton({
    super.key,
    required this.guide,
    this.compact = true,
    this.label = 'Guía',
  });

  @override
  Widget build(BuildContext context) {
    return ContextualHelpButton(
      title: guide.title,
      explanation: guide.explanation,
      bulletPoints: guide.bulletPoints,
      example: guide.example,
      icon: guide.icon,
      color: guide.color,
      label: label,
      compact: compact,
    );
  }
}
