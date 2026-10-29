import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/network/socket_service.dart';
import 'package:tu_lojita_business/features/auth/data/datasources/local_auth_data_source.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/chat/presentation/screens/order_support_chat_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order_dispute.dart';
import 'package:tu_lojita_business/features/orders/domain/enums/dispute_enums.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_dispute_bottom_sheet.dart';
import 'package:tu_lojita_business/features/orders/presentation/providers/dispute_providers.dart';

class FakeLocalAuthDataSource implements LocalAuthDataSource {
  @override
  Future<String?> getAccessToken() async => 'mock-token';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBusinessSocketService extends SocketService {
  FakeBusinessSocketService() : super(FakeLocalAuthDataSource());

  final List<Map<String, dynamic>> sentMessages = [];
  final List<String> joinedRooms = [];
  final _historyController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get supportChatHistoryStream => _historyController.stream;

  @override
  void joinSupportChat(String orderId, String channelType) {
    joinedRooms.add('$orderId:$channelType');
    Future.microtask(() {
      _historyController.add({
        'orderId': orderId,
        'channelType': channelType,
        'messages': [],
      });
    });
  }

  @override
  void leaveSupportChat(String orderId, String channelType) {}

  @override
  void markSupportMessagesRead(String orderId, String channelType) {}

  @override
  Future<Map<String, dynamic>> sendSupportMessageWithAck(
    String orderId,
    String channelType,
    String content, {
    String? imageUrl,
    Duration timeout = const Duration(seconds: 8),
    bool isRetry = false,
  }) async {
    sentMessages.add({
      'orderId': orderId,
      'channelType': channelType,
      'content': content,
      'imageUrl': imageUrl,
    });
    return {
      'success': true,
      'messageId': 'msg-business-ack-1',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

class MockAuthNotifier extends AuthNotifier {
  final User _mockUser;
  MockAuthNotifier(this._mockUser);

  @override
  AuthState build() => Authenticated(_mockUser);
}

void main() {
  const testMerchantUser = User(
    id: 'user-merchant-1',
    email: 'tienda@test.com',
    firstName: 'Dueño',
    lastName: 'Tienda',
    role: 'MERCHANT',
    hasCompany: true,
  );

  testWidgets('OrderSupportChatScreen renders privacy banner and sends messages for merchant', (tester) async {
    final fakeSocket = FakeBusinessSocketService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socketServiceProvider.overrideWithValue(fakeSocket),
          authProvider.overrideWith(() => MockAuthNotifier(testMerchantUser)),
        ],
        child: const MaterialApp(
          home: OrderSupportChatScreen(orderId: 'order-biz-123'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify support header and privacy banner
    expect(find.text('Soporte Tu Lojita'), findsWidgets);
    expect(find.text('Canal Privado con Soporte'), findsOneWidget);
    expect(find.textContaining('El comprador no tiene acceso a esta conversación'), findsOneWidget);

    // Verify room joined with merchant channel
    expect(fakeSocket.joinedRooms, contains('order-biz-123:DISPUTE_MERCHANT_SUPPORT'));

    // Write a message to support
    final inputFinder = find.byType(TextField);
    expect(inputFinder, findsOneWidget);

    await tester.enterText(inputFinder, 'Adjunto comprobante de entrega del paquete');
    await tester.pump();

    // Tap send button
    final sendButton = find.byKey(const ValueKey('support_send_button'));
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pump();

    // Verify message sent via socket on DISPUTE_MERCHANT_SUPPORT
    expect(fakeSocket.sentMessages.length, 1);
    expect(fakeSocket.sentMessages.first['channelType'], 'DISPUTE_MERCHANT_SUPPORT');
    expect(fakeSocket.sentMessages.first['content'], 'Adjunto comprobante de entrega del paquete');
  });

  testWidgets('OrderDisputeBottomSheet shows Hablar con Soporte button in adminReview', (tester) async {
    final dispute = OrderDispute(
      id: 'disp-biz-1',
      orderId: 'order-biz-123',
      userId: 'client-1',
      type: DisputeType.refundRequest,
      status: DisputeStatus.adminReview,
      reason: 'El cliente no reconoce la entrega',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeDisputesByOrderProvider('order-biz-123').overrideWith((ref) => Future.value([dispute])),
          activeStoreDisputeProvider('order-biz-123').overrideWithValue(dispute),
          authProvider.overrideWith(() => MockAuthNotifier(testMerchantUser)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: OrderDisputeBottomSheet(
              orderId: 'order-biz-123',
              initialDispute: dispute,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pedido en mediación con Soporte'), findsOneWidget);
    expect(find.text('Hablar con Soporte'), findsOneWidget);
  });
}
