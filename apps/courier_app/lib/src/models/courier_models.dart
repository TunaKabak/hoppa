import 'dart:math' as math;

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

double _asDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString()) ?? fallback;
}

bool _asBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final str = value.toString().trim().toLowerCase();
  if (str == 'true' || str == '1') return true;
  if (str == 'false' || str == '0') return false;
  return fallback;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}

class CourierUserSummary {
  final String id;
  final String? name;
  final String? surname;
  final String? phone;

  const CourierUserSummary({
    required this.id,
    this.name,
    this.surname,
    this.phone,
  });

  factory CourierUserSummary.fromJson(Map<String, dynamic> json) {
    return CourierUserSummary(
      id: json['id']?.toString() ?? '',
      name: _asNullableString(json['name']),
      surname: _asNullableString(json['surname']),
      phone: _asNullableString(json['phone']),
    );
  }

  String get fullName {
    final parts = [
      if (name != null && name!.isNotEmpty) name!,
      if (surname != null && surname!.isNotEmpty) surname!,
    ];
    return parts.join(' ');
  }
}

class CourierShopInfo {
  final String id;
  final String name;
  final String? type;
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;

  const CourierShopInfo({
    required this.id,
    required this.name,
    this.type,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
  });

  factory CourierShopInfo.fromJson(Map<String, dynamic> json) {
    return CourierShopInfo(
      id: json['id']?.toString() ?? '',
      name: _asNullableString(json['name']) ?? 'Mağaza',
      type: _asNullableString(json['type']),
      address: _asNullableString(json['address']),
      phone: _asNullableString(json['phone']),
      latitude: _asNullableDouble(json['latitude'] ?? json['lat']),
      longitude: _asNullableDouble(json['longitude'] ?? json['lng']),
    );
  }
}

class CourierAssignedShop {
  final String id;
  final String shopId;
  final CourierShopInfo? shop;

  const CourierAssignedShop({
    required this.id,
    required this.shopId,
    this.shop,
  });

  factory CourierAssignedShop.fromJson(Map<String, dynamic> json) {
    final shopMap = _asMap(json['shop']);
    return CourierAssignedShop(
      id: json['id']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? shopMap?['id']?.toString() ?? '',
      shop: shopMap != null ? CourierShopInfo.fromJson(shopMap) : null,
    );
  }

  String get displayName => shop?.name ?? 'Atanmış Mağaza';
}

class CourierProfile {
  final bool hasProfile;
  final String? id;
  final String? userId;
  final String? name;
  final String? phoneNumber;
  final String? vehicleType;
  final String? vehiclePlate;
  final String status;
  final bool isActive;
  final double? maxServiceDistanceKm;
  final List<CourierAssignedShop> shops;
  final int todayDeliveriesCount;
  final int totalDeliveriesCount;
  final CourierUserSummary? user;

  const CourierProfile({
    required this.hasProfile,
    this.id,
    this.userId,
    this.name,
    this.phoneNumber,
    this.vehicleType,
    this.vehiclePlate,
    required this.status,
    required this.isActive,
    this.maxServiceDistanceKm,
    required this.shops,
    required this.todayDeliveriesCount,
    required this.totalDeliveriesCount,
    this.user,
  });

  factory CourierProfile.fromJson(Map<String, dynamic> json) {
    final rawShops = json['shops'];
    final shops = rawShops is List
        ? rawShops
              .map(_asMap)
              .whereType<Map<String, dynamic>>()
              .map(CourierAssignedShop.fromJson)
              .toList()
        : <CourierAssignedShop>[];
    final userMap = _asMap(json['user']);

    return CourierProfile(
      hasProfile: _asBool(json['hasProfile'], false),
      id: _asNullableString(json['id']),
      userId: _asNullableString(json['userId']),
      name: _asNullableString(json['name']),
      phoneNumber: _asNullableString(json['phoneNumber']),
      vehicleType: _asNullableString(json['vehicleType']),
      vehiclePlate: _asNullableString(json['vehiclePlate']),
      status: _asNullableString(json['status']) ?? 'NOT_APPLIED',
      isActive: _asBool(json['isActive'], false),
      maxServiceDistanceKm: _asNullableDouble(json['maxServiceDistanceKm']),
      shops: shops,
      todayDeliveriesCount: _asInt(json['todayDeliveriesCount'], 0),
      totalDeliveriesCount: _asInt(json['totalDeliveriesCount'], 0),
      user: userMap != null ? CourierUserSummary.fromJson(userMap) : null,
    );
  }

  bool get isApproved => status == 'APPROVED';

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    final userFull = user?.fullName ?? '';
    if (userFull.isNotEmpty) return userFull;
    return phoneNumber ?? user?.phone ?? 'Kurye';
  }
}

class CourierOrderItemOption {
  final String groupName;
  final String name;
  final double price;
  final int quantity;
  final String actionType;

  const CourierOrderItemOption({
    required this.groupName,
    required this.name,
    required this.price,
    required this.quantity,
    required this.actionType,
  });

  factory CourierOrderItemOption.fromJson(Map<String, dynamic> json) {
    return CourierOrderItemOption(
      groupName: _asNullableString(json['groupName']) ?? '',
      name: _asNullableString(json['name']) ?? '',
      price: _asDouble(json['price']),
      quantity: _asInt(json['quantity'], 1),
      actionType: _asNullableString(json['actionType']) ?? 'ADD',
    );
  }

  bool get isRemove => actionType.toUpperCase() == 'REMOVE';
}

class CourierOrderItem {
  final String id;
  final double quantity;
  final double unitPrice;
  final String? productId;
  final String productName;
  final List<CourierOrderItemOption> options;

  const CourierOrderItem({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    this.productId,
    required this.productName,
    required this.options,
  });

  factory CourierOrderItem.fromJson(Map<String, dynamic> json) {
    final productMap = _asMap(json['product']);
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions
              .map(_asMap)
              .whereType<Map<String, dynamic>>()
              .map(CourierOrderItemOption.fromJson)
              .toList()
        : <CourierOrderItemOption>[];

    return CourierOrderItem(
      id: json['id']?.toString() ?? '',
      quantity: _asDouble(json['quantity'], 1.0),
      unitPrice: _asDouble(json['unitPrice'] ?? json['price'], 0.0),
      productId: _asNullableString(productMap?['id'] ?? json['productId']),
      productName:
          _asNullableString(productMap?['name'] ?? json['productName']) ??
          'Ürün',
      options: options,
    );
  }

  String get formattedQuantity {
    if ((quantity - quantity.roundToDouble()).abs() < 0.001) {
      return quantity.round().toString();
    }
    return quantity.toStringAsFixed(1);
  }
}

class CourierOrderConsumer {
  final String id;
  final String? name;
  final String? surname;
  final String? phone;

  const CourierOrderConsumer({
    required this.id,
    this.name,
    this.surname,
    this.phone,
  });

  factory CourierOrderConsumer.fromJson(Map<String, dynamic> json) {
    return CourierOrderConsumer(
      id: json['id']?.toString() ?? '',
      name: _asNullableString(json['name']),
      surname: _asNullableString(json['surname']),
      phone: _asNullableString(json['phone']),
    );
  }

  String get fullName {
    final parts = [
      if (name != null && name!.isNotEmpty) name!,
      if (surname != null && surname!.isNotEmpty) surname!,
    ];
    return parts.isNotEmpty ? parts.join(' ') : 'Müşteri';
  }
}

class CourierOrderAddress {
  final String? title;
  final String? fullAddress;
  final String? street;
  final String? buildingNo;
  final String? apartmentNo;
  final String? city;
  final String? district;
  final double? latitude;
  final double? longitude;

  const CourierOrderAddress({
    this.title,
    this.fullAddress,
    this.street,
    this.buildingNo,
    this.apartmentNo,
    this.city,
    this.district,
    this.latitude,
    this.longitude,
  });

  factory CourierOrderAddress.fromJson(Map<String, dynamic> json) {
    return CourierOrderAddress(
      title: _asNullableString(json['title']),
      fullAddress: _asNullableString(json['fullAddress']),
      street: _asNullableString(json['street']),
      buildingNo: _asNullableString(json['buildingNo']),
      apartmentNo: _asNullableString(json['apartmentNo']),
      city: _asNullableString(json['city']),
      district: _asNullableString(json['district']),
      latitude: _asNullableDouble(json['latitude'] ?? json['lat']),
      longitude: _asNullableDouble(json['longitude'] ?? json['lng']),
    );
  }

  String get composedDetails {
    if (fullAddress != null && fullAddress!.isNotEmpty) {
      final extra = <String>[
        if (buildingNo != null) 'Bina: $buildingNo',
        if (apartmentNo != null) 'Daire: $apartmentNo',
      ];
      if (extra.isEmpty) return fullAddress!;
      return '$fullAddress (${extra.join(', ')})';
    }
    final parts = <String>[
      if (street != null) street!,
      if (buildingNo != null) 'No: $buildingNo',
      if (apartmentNo != null) 'Daire: $apartmentNo',
      if (district != null) district!,
      if (city != null) city!,
    ];
    return parts.join(', ');
  }
}

class CourierOrder {
  final String id;
  final String? orderNumber;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double totalAmount;
  final double deliveryFee;
  final String deliveryAddress;
  final String? customerNote;
  final bool dontRingBell;
  final bool leaveAtDoor;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CourierShopInfo? shop;
  final CourierOrderConsumer? consumer;
  final CourierOrderAddress? address;
  final List<CourierOrderItem> items;

  const CourierOrder({
    required this.id,
    this.orderNumber,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalAmount,
    required this.deliveryFee,
    required this.deliveryAddress,
    this.customerNote,
    required this.dontRingBell,
    required this.leaveAtDoor,
    this.createdAt,
    this.updatedAt,
    this.shop,
    this.consumer,
    this.address,
    required this.items,
  });

  factory CourierOrder.fromJson(Map<String, dynamic> json) {
    final shopMap = _asMap(json['shop']);
    final consumerMap = _asMap(json['consumer']);
    final addressMap = _asMap(json['address']);
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .map(_asMap)
              .whereType<Map<String, dynamic>>()
              .map(CourierOrderItem.fromJson)
              .toList()
        : <CourierOrderItem>[];

    return CourierOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: _asNullableString(json['orderNumber']),
      status: _asNullableString(json['status']) ?? 'PREPARING',
      paymentMethod:
          _asNullableString(json['paymentMethod']) ?? 'CASH_ON_DELIVERY',
      paymentStatus: _asNullableString(json['paymentStatus']) ?? 'PENDING',
      totalAmount: _asDouble(json['totalAmount']),
      deliveryFee: _asDouble(json['deliveryFee']),
      deliveryAddress: _asNullableString(json['deliveryAddress']) ?? '',
      customerNote: _asNullableString(json['customerNote']),
      dontRingBell: _asBool(json['dontRingBell'], false),
      leaveAtDoor: _asBool(json['leaveAtDoor'], false),
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
      shop: shopMap != null ? CourierShopInfo.fromJson(shopMap) : null,
      consumer: consumerMap != null
          ? CourierOrderConsumer.fromJson(consumerMap)
          : null,
      address: addressMap != null
          ? CourierOrderAddress.fromJson(addressMap)
          : null,
      items: items,
    );
  }

  String get displayOrderNumber {
    if (orderNumber != null && orderNumber!.isNotEmpty) {
      return orderNumber!.startsWith('#') ? orderNumber! : '#$orderNumber';
    }
    final shortLen = math.min(8, id.length);
    return '#${id.substring(0, shortLen).toUpperCase()}';
  }

  String get resolvedDeliveryAddress {
    final fromAddress = address?.composedDetails ?? '';
    if (deliveryAddress.isNotEmpty) return deliveryAddress;
    if (fromAddress.isNotEmpty) return fromAddress;
    return 'Teslimat adresi belirtilmemiş';
  }

  bool get isOnTheWay => status == 'ON_THE_WAY';

  bool get isAwaitingPickup =>
      status == 'PREPARING' || status == 'READY_FOR_PICKUP';

  bool get requiresDoorCollection =>
      paymentMethod != 'ONLINE_PAYMENT' && paymentMethod != 'WALLET';
}

class CourierHistorySummary {
  final int todayCount;
  final double todayDeliveryFeeTotal;
  final int weekCount;
  final double weekDeliveryFeeTotal;
  final int totalCount;
  final double totalDeliveryFeeTotal;

  const CourierHistorySummary({
    required this.todayCount,
    required this.todayDeliveryFeeTotal,
    required this.weekCount,
    required this.weekDeliveryFeeTotal,
    required this.totalCount,
    required this.totalDeliveryFeeTotal,
  });

  factory CourierHistorySummary.fromJson(Map<String, dynamic> json) {
    return CourierHistorySummary(
      todayCount: _asInt(json['todayCount']),
      todayDeliveryFeeTotal: _asDouble(json['todayDeliveryFeeTotal']),
      weekCount: _asInt(json['weekCount']),
      weekDeliveryFeeTotal: _asDouble(json['weekDeliveryFeeTotal']),
      totalCount: _asInt(json['totalCount']),
      totalDeliveryFeeTotal: _asDouble(json['totalDeliveryFeeTotal']),
    );
  }

  static const CourierHistorySummary empty = CourierHistorySummary(
    todayCount: 0,
    todayDeliveryFeeTotal: 0,
    weekCount: 0,
    weekDeliveryFeeTotal: 0,
    totalCount: 0,
    totalDeliveryFeeTotal: 0,
  );
}

class CourierHistoryPagination {
  final int page;
  final int limit;
  final int totalCount;
  final int totalPages;

  const CourierHistoryPagination({
    required this.page,
    required this.limit,
    required this.totalCount,
    required this.totalPages,
  });

  factory CourierHistoryPagination.fromJson(Map<String, dynamic> json) {
    return CourierHistoryPagination(
      page: _asInt(json['page'], 1),
      limit: _asInt(json['limit'], 20),
      totalCount: _asInt(json['totalCount'], 0),
      totalPages: _asInt(json['totalPages'], 1),
    );
  }

  static const CourierHistoryPagination empty = CourierHistoryPagination(
    page: 1,
    limit: 20,
    totalCount: 0,
    totalPages: 1,
  );
}

class CourierOrderHistoryResponse {
  final List<CourierOrder> orders;
  final CourierHistorySummary summary;
  final CourierHistoryPagination pagination;

  const CourierOrderHistoryResponse({
    required this.orders,
    required this.summary,
    required this.pagination,
  });

  factory CourierOrderHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'];
    final orders = rawOrders is List
        ? rawOrders
              .map(_asMap)
              .whereType<Map<String, dynamic>>()
              .map(CourierOrder.fromJson)
              .toList()
        : <CourierOrder>[];
    final summaryMap = _asMap(json['summary']);
    final paginationMap = _asMap(json['pagination']);

    return CourierOrderHistoryResponse(
      orders: orders,
      summary: summaryMap != null
          ? CourierHistorySummary.fromJson(summaryMap)
          : CourierHistorySummary.empty,
      pagination: paginationMap != null
          ? CourierHistoryPagination.fromJson(paginationMap)
          : CourierHistoryPagination.empty,
    );
  }
}
