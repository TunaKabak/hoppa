import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_network/core_network.dart';
import 'package:courier_app/src/models/courier_models.dart';
import 'package:courier_app/src/screens/auth/courier_login_screen.dart';
import 'package:courier_app/src/screens/onboarding/courier_status_gate_screen.dart';
import 'package:courier_app/src/utils/distance_formatter.dart';
import 'package:courier_app/src/widgets/courier_order_card.dart';

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => AuthInitial();
}

void main() {
  group('distance_formatter', () {
    test('formats distances below 1 km in meters and >= 1 km with 1 decimal', () {
      expect(formatDistance(0), '0 m');
      expect(formatDistance(0.3496), '350 m');
      expect(formatDistance(1.0), '1.0 km');
      expect(formatDistance(2.46), '2.5 km');
    });

    test('calculates positive Haversine distance between distinct points', () {
      final km = calculateDistanceKm(
        lat1: 35.1856,
        lon1: 33.3823,
        lat2: 35.1956,
        lon2: 33.3923,
      );
      expect(km, greaterThan(1.0));
      expect(km, lessThan(2.0));
    });
  });

  group('courier_models', () {
    test('parses CourierProfile with shops and counts', () {
      final profile = CourierProfile.fromJson({
        'hasProfile': true,
        'id': 'c-1',
        'userId': 'u-1',
        'name': 'Ali Kurye',
        'phoneNumber': '+905331112233',
        'vehicleType': 'MOTORCYCLE',
        'vehiclePlate': 'NG 123',
        'status': 'APPROVED',
        'isActive': true,
        'maxServiceDistanceKm': 12,
        'todayDeliveriesCount': 4,
        'totalDeliveriesCount': 25,
        'shops': [
          {
            'id': 'cs-1',
            'shopId': 's-1',
            'shop': {
              'id': 's-1',
              'name': 'Lefkoşa Burger',
              'type': 'RESTAURANT',
              'address': 'Dereboyu',
              'phone': '+905330001122',
            },
          },
        ],
        'user': {
          'id': 'u-1',
          'name': 'Ali',
          'surname': 'Kurye',
          'phone': '+905331112233',
        },
      });

      expect(profile.hasProfile, isTrue);
      expect(profile.isApproved, isTrue);
      expect(profile.isActive, isTrue);
      expect(profile.shops.length, 1);
      expect(profile.shops.first.displayName, 'Lefkoşa Burger');
      expect(profile.todayDeliveriesCount, 4);
      expect(profile.totalDeliveriesCount, 25);
    });

    test('parses CourierOrder with Decimal strings, lat/lng aliases, and options', () {
      final order = CourierOrder.fromJson({
        'id': 'ord-12345678-abcd',
        'status': 'PREPARING',
        'paymentMethod': 'CASH_ON_DELIVERY',
        'paymentStatus': 'PENDING',
        'totalAmount': '245.50',
        'deliveryFee': '35.00',
        'deliveryAddress': 'Hamitköy, Lefkoşa',
        'customerNote': 'Kapı kodu 12',
        'dontRingBell': true,
        'leaveAtDoor': false,
        'shop': {
          'id': 's-1',
          'name': 'Hoppa Market',
          'phone': '+905331234567',
          'address': 'Merkez',
          'lat': 35.1856,
          'lng': 33.3823,
        },
        'consumer': {
          'id': 'u-2',
          'name': 'Ayşe',
          'surname': 'Demir',
          'phone': '+905339876543',
        },
        'address': {
          'title': 'Ev',
          'fullAddress': 'Hamitköy Sokak No 5',
          'lat': 35.1900,
          'lng': 33.3900,
        },
        'items': [
          {
            'id': 'item-1',
            'quantity': 2,
            'price': '105.25',
            'product': {'id': 'p-1', 'name': 'Tavuk Menü'},
            'options': [
              {
                'groupName': 'Ekstralar',
                'name': 'Ekstra Sos',
                'price': '10.00',
                'quantity': 1,
                'actionType': 'ADD',
              },
              {
                'groupName': 'Çıkarılacaklar',
                'name': 'Soğan',
                'price': '0',
                'quantity': 1,
                'actionType': 'REMOVE',
              },
            ],
          },
        ],
      });

      expect(order.totalAmount, 245.50);
      expect(order.deliveryFee, 35.00);
      expect(order.shop?.latitude, 35.1856);
      expect(order.address?.longitude, 33.3900);
      expect(order.items.single.unitPrice, 105.25);
      expect(order.items.single.options.length, 2);
      expect(order.items.single.options[1].isRemove, isTrue);
    });

    test('parses CourierOrderHistoryResponse summary & pagination', () {
      final history = CourierOrderHistoryResponse.fromJson({
        'orders': [],
        'summary': {
          'todayCount': 3,
          'todayDeliveryFeeTotal': 120.5,
          'weekCount': 14,
          'weekDeliveryFeeTotal': 560,
          'totalCount': 80,
          'totalDeliveryFeeTotal': 3200.75,
        },
        'pagination': {
          'page': 1,
          'limit': 20,
          'totalCount': 80,
          'totalPages': 4,
        },
      });

      expect(history.summary.todayCount, 3);
      expect(history.summary.todayDeliveryFeeTotal, 120.5);
      expect(history.summary.weekCount, 14);
      expect(history.summary.totalCount, 80);
      expect(history.pagination.totalPages, 4);
    });
  });

  group('UI widgets', () {
    testWidgets('CourierLoginScreen starts with empty phone controller and validates input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(
              ApiClient(baseUrl: 'http://127.0.0.1:3000'),
            ),
            authControllerProvider.overrideWith(_FakeAuthController.new),
          ],
          child: const MaterialApp(home: CourierLoginScreen()),
        ),
      );

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(textField.controller?.text, isEmpty);

      await tester.tap(find.text('Doğrulama Kodu Gönder'));
      await tester.pump();
      expect(
        find.text('Geçerli bir telefon numarası girin (ör. +90 5XX XXX XX XX)'),
        findsOneWidget,
      );
    });

    testWidgets('CourierStatusGateScreen shows application form for NOT_APPLIED and status gate for APPLIED', (
      WidgetTester tester,
    ) async {
      const notAppliedProfile = CourierProfile(
        hasProfile: false,
        status: 'NOT_APPLIED',
        isActive: false,
        shops: [],
        todayDeliveriesCount: 0,
        totalDeliveriesCount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(
              ApiClient(baseUrl: 'http://127.0.0.1:3000'),
            ),
          ],
          child: MaterialApp(
            home: CourierStatusGateScreen(
              profile: notAppliedProfile,
              onRefresh: () async {},
              onLogout: () async {},
            ),
          ),
        ),
      );

      expect(find.text('Hoppa Kurye Başvurusu'), findsOneWidget);
      expect(find.text('Başvuruyu Gönder'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);

      const appliedProfile = CourierProfile(
        hasProfile: true,
        name: 'Test Kurye',
        phoneNumber: '+905331112233',
        vehicleType: 'MOTORCYCLE',
        vehiclePlate: 'NG 123',
        status: 'APPLIED',
        isActive: false,
        maxServiceDistanceKm: 15,
        shops: [],
        todayDeliveriesCount: 0,
        totalDeliveriesCount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(
              ApiClient(baseUrl: 'http://127.0.0.1:3000'),
            ),
          ],
          child: MaterialApp(
            home: CourierStatusGateScreen(
              profile: appliedProfile,
              onRefresh: () async {},
              onLogout: () async {},
            ),
          ),
        ),
      );

      expect(find.text('Durumu Yenile'), findsOneWidget);
      expect(find.text('Çıkış Yap'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('CourierOrderCard renders 2-stage swipe labels, payment warning, and options', (
      WidgetTester tester,
    ) async {
      final orderAwaitingPickup = CourierOrder.fromJson({
        'id': 'ord-11112222',
        'status': 'PREPARING',
        'paymentMethod': 'CASH_ON_DELIVERY',
        'paymentStatus': 'PENDING',
        'totalAmount': 180,
        'deliveryFee': 25,
        'deliveryAddress': 'Gönyeli',
        'dontRingBell': true,
        'leaveAtDoor': true,
        'customerNote': 'Lütfen arayın',
        'shop': {'id': 's1', 'name': 'Test Kafe', 'address': 'Merkez'},
        'consumer': {'id': 'c1', 'name': 'Can', 'surname': 'Kaya'},
        'items': [
          {
            'id': 'i1',
            'quantity': 1,
            'unitPrice': 155,
            'product': {'id': 'p1', 'name': 'Tost'},
            'options': [
              {
                'groupName': 'Sos',
                'name': 'Ketçap',
                'price': 0,
                'quantity': 1,
                'actionType': 'ADD',
              },
              {
                'groupName': 'Malzeme',
                'name': 'Turşu',
                'price': 0,
                'quantity': 1,
                'actionType': 'REMOVE',
              },
            ],
          },
        ],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CourierOrderCard(
                order: orderAwaitingPickup,
                isActionLoading: false,
                onPickup: (_) async {},
                onDeliver: (_) async {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mağazadan Teslim Alınacak'), findsOneWidget);
      expect(find.text('Mağazadan Teslim Aldım'), findsOneWidget);
      expect(find.textContaining('Kapıda Nakit Ödeme'), findsOneWidget);
      expect(find.text('🔕 Zili Çalma'), findsOneWidget);
      expect(find.text('🚪 Kapıya Bırak'), findsOneWidget);
      expect(find.text('➕ Sos: Ketçap'), findsOneWidget);
      expect(find.text('❌ Malzeme: Turşu'), findsOneWidget);

      final orderOnWay = CourierOrder.fromJson({
        'id': 'ord-11112222',
        'status': 'ON_THE_WAY',
        'paymentMethod': 'ONLINE_PAYMENT',
        'paymentStatus': 'SUCCESS',
        'totalAmount': 180,
        'deliveryFee': 25,
        'deliveryAddress': 'Gönyeli',
        'dontRingBell': false,
        'leaveAtDoor': false,
        'shop': {'id': 's1', 'name': 'Test Kafe', 'address': 'Merkez'},
        'consumer': {'id': 'c1', 'name': 'Can', 'surname': 'Kaya'},
        'items': [],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CourierOrderCard(
                order: orderOnWay,
                isActionLoading: false,
                onPickup: (_) async {},
                onDeliver: (_) async {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Müşteriye Yolda'), findsOneWidget);
      expect(find.text('Müşteriye Teslim Ettim'), findsOneWidget);
    });
  });
}
