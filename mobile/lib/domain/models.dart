import 'dart:convert';

enum TripStatus { draft, matching, loading, moving, unloading, documents, done }

extension TripStatusX on TripStatus {
  String get label => switch (this) {
    TripStatus.draft => 'Черновик',
    TripStatus.matching => 'Ищем машину',
    TripStatus.loading => 'На погрузке',
    TripStatus.moving => 'В пути',
    TripStatus.unloading => 'На выгрузке',
    TripStatus.documents => 'Ждём документы',
    TripStatus.done => 'Завершён',
  };
}

class Trip {
  const Trip({
    required this.id,
    required this.number,
    required this.from,
    required this.to,
    required this.cargo,
    required this.weight,
    required this.vehicle,
    required this.client,
    required this.clientRate,
    required this.carrierRate,
    required this.pickupAt,
    required this.status,
    this.carrier = '',
    this.driver = '',
    this.driverPhone = '',
    this.truckPlate = '',
    this.lastEvent = '',
    this.progress = 0,
    this.documentsReady = 0,
    this.documentsTotal = 5,
  });

  final String id;
  final String number;
  final String from;
  final String to;
  final String cargo;
  final double weight;
  final String vehicle;
  final String client;
  final int clientRate;
  final int carrierRate;
  final DateTime pickupAt;
  final TripStatus status;
  final String carrier;
  final String driver;
  final String driverPhone;
  final String truckPlate;
  final String lastEvent;
  final double progress;
  final int documentsReady;
  final int documentsTotal;

  int get margin => clientRate - carrierRate;
  String get route => '$from → $to';
}

class Counterparty {
  const Counterparty({
    required this.id,
    required this.name,
    required this.contact,
    required this.phone,
    required this.kind,
    this.rating = 0,
    this.completedTrips = 0,
    this.usualRoutes = const [],
    this.tags = const [],
    this.debt = 0,
  });

  final String id;
  final String name;
  final String contact;
  final String phone;
  final String kind;
  final double rating;
  final int completedTrips;
  final List<String> usualRoutes;
  final List<String> tags;
  final int debt;
}

class TripDraft {
  const TripDraft({
    this.from = '',
    this.to = '',
    this.cargo = '',
    this.weight = 0,
    this.vehicle = '',
    this.pickupDate = '',
    this.pickupTime = '',
    this.client = '',
    this.clientContact = '',
    this.clientPhone = '',
    this.clientRate = 0,
    this.carrier = '',
    this.carrierRate = 0,
    this.driver = '',
    this.driverPhone = '',
    this.truckPlate = '',
    this.pickupAddress = '',
    this.deliveryAddress = '',
    this.comment = '',
    this.sourceText = '',
    this.confidence = const {},
  });

  final String from;
  final String to;
  final String cargo;
  final double weight;
  final String vehicle;
  final String pickupDate;
  final String pickupTime;
  final String client;
  final String clientContact;
  final String clientPhone;
  final int clientRate;
  final String carrier;
  final int carrierRate;
  final String driver;
  final String driverPhone;
  final String truckPlate;
  final String pickupAddress;
  final String deliveryAddress;
  final String comment;
  final String sourceText;
  final Map<String, double> confidence;

  int get margin => clientRate - carrierRate;
  bool get hasRoute => from.isNotEmpty && to.isNotEmpty;
  List<String> get missingFields => [
    if (from.isEmpty) 'Откуда',
    if (to.isEmpty) 'Куда',
    if (cargo.isEmpty) 'Груз',
    if (weight <= 0) 'Вес',
    if (vehicle.isEmpty) 'Тип машины',
    if (pickupDate.isEmpty) 'Дата погрузки',
    if (client.isEmpty) 'Клиент',
    if (clientRate <= 0) 'Ставка клиента',
  ];

  TripDraft copyWith({
    String? from,
    String? to,
    String? cargo,
    double? weight,
    String? vehicle,
    String? pickupDate,
    String? pickupTime,
    String? client,
    String? clientContact,
    String? clientPhone,
    int? clientRate,
    String? carrier,
    int? carrierRate,
    String? driver,
    String? driverPhone,
    String? truckPlate,
    String? pickupAddress,
    String? deliveryAddress,
    String? comment,
    String? sourceText,
    Map<String, double>? confidence,
  }) => TripDraft(
    from: from ?? this.from,
    to: to ?? this.to,
    cargo: cargo ?? this.cargo,
    weight: weight ?? this.weight,
    vehicle: vehicle ?? this.vehicle,
    pickupDate: pickupDate ?? this.pickupDate,
    pickupTime: pickupTime ?? this.pickupTime,
    client: client ?? this.client,
    clientContact: clientContact ?? this.clientContact,
    clientPhone: clientPhone ?? this.clientPhone,
    clientRate: clientRate ?? this.clientRate,
    carrier: carrier ?? this.carrier,
    carrierRate: carrierRate ?? this.carrierRate,
    driver: driver ?? this.driver,
    driverPhone: driverPhone ?? this.driverPhone,
    truckPlate: truckPlate ?? this.truckPlate,
    pickupAddress: pickupAddress ?? this.pickupAddress,
    deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    comment: comment ?? this.comment,
    sourceText: sourceText ?? this.sourceText,
    confidence: confidence ?? this.confidence,
  );

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'cargo': cargo,
    'weight': weight,
    'vehicle': vehicle,
    'pickupDate': pickupDate,
    'pickupTime': pickupTime,
    'client': client,
    'clientContact': clientContact,
    'clientPhone': clientPhone,
    'clientRate': clientRate,
    'carrier': carrier,
    'carrierRate': carrierRate,
    'driver': driver,
    'driverPhone': driverPhone,
    'truckPlate': truckPlate,
    'pickupAddress': pickupAddress,
    'deliveryAddress': deliveryAddress,
    'comment': comment,
    'sourceText': sourceText,
  };

  factory TripDraft.fromJson(Map<String, dynamic> json) => TripDraft(
    from: json['from'] as String? ?? '',
    to: json['to'] as String? ?? '',
    cargo: json['cargo'] as String? ?? '',
    weight: (json['weight'] as num?)?.toDouble() ?? 0,
    vehicle: json['vehicle'] as String? ?? '',
    pickupDate: json['pickupDate'] as String? ?? '',
    pickupTime: json['pickupTime'] as String? ?? '',
    client: json['client'] as String? ?? '',
    clientContact: json['clientContact'] as String? ?? '',
    clientPhone: json['clientPhone'] as String? ?? '',
    clientRate: json['clientRate'] as int? ?? 0,
    carrier: json['carrier'] as String? ?? '',
    carrierRate: json['carrierRate'] as int? ?? 0,
    driver: json['driver'] as String? ?? '',
    driverPhone: json['driverPhone'] as String? ?? '',
    truckPlate: json['truckPlate'] as String? ?? '',
    pickupAddress: json['pickupAddress'] as String? ?? '',
    deliveryAddress: json['deliveryAddress'] as String? ?? '',
    comment: json['comment'] as String? ?? '',
    sourceText: json['sourceText'] as String? ?? '',
  );

  String encode() => jsonEncode(toJson());
  factory TripDraft.decode(String value) =>
      TripDraft.fromJson(jsonDecode(value) as Map<String, dynamic>);
}

class AttentionItem {
  const AttentionItem({
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.tripNumber,
  });

  final String title;
  final String subtitle;
  final String kind;
  final String tripNumber;
}
