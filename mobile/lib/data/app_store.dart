import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

class AppStore extends ChangeNotifier {
  AppStore() {
    _restoreDraft();
  }

  TripDraft draft = const TripDraft();

  final List<Trip> trips = [
    Trip(
      id: '1007',
      number: 'ТК-1007',
      from: 'Москва',
      to: 'Екатеринбург',
      cargo: 'Оборудование',
      weight: 18,
      vehicle: 'Тент',
      client: 'НордПром',
      clientRate: 238000,
      carrierRate: 184000,
      pickupAt: DateTime(2026, 9, 16, 9),
      status: TripStatus.moving,
      carrier: 'ИП Ковалёв',
      driver: 'Андрей Ковалёв',
      driverPhone: '+7 916 440-18-02',
      truckPlate: 'Е742КХ 799',
      lastEvent: 'Проехал Нижний Новгород · 18 мин назад',
      progress: .46,
      documentsReady: 3,
    ),
    Trip(
      id: '1008',
      number: 'ТК-1008',
      from: 'Подольск',
      to: 'Нижний Новгород',
      cargo: 'Кабель',
      weight: 20,
      vehicle: 'Тент',
      client: 'СтройВектор',
      clientRate: 112000,
      carrierRate: 84000,
      pickupAt: DateTime(2026, 9, 17, 8, 30),
      status: TripStatus.matching,
      lastEvent: 'Подходят 3 перевозчика из вашей базы',
      progress: .08,
      documentsReady: 1,
    ),
    Trip(
      id: '1005',
      number: 'ТК-1005',
      from: 'Тверь',
      to: 'Санкт-Петербург',
      cargo: 'Продукты',
      weight: 15,
      vehicle: 'Рефрижератор',
      client: 'Вкус Севера',
      clientRate: 129000,
      carrierRate: 91000,
      pickupAt: DateTime(2026, 9, 15, 7),
      status: TripStatus.documents,
      carrier: 'ООО СеверТранс',
      driver: 'Михаил Серов',
      driverPhone: '+7 921 084-05-51',
      truckPlate: 'М118РО 78',
      lastEvent: 'Ожидается фото транспортной накладной',
      progress: .92,
      documentsReady: 4,
    ),
    Trip(
      id: '1004',
      number: 'ТК-1004',
      from: 'Калуга',
      to: 'Рязань',
      cargo: 'Мебель',
      weight: 8,
      vehicle: 'Тент',
      client: 'Линия Дома',
      clientRate: 78000,
      carrierRate: 57000,
      pickupAt: DateTime(2026, 9, 13, 11),
      status: TripStatus.done,
      carrier: 'ИП Руденко',
      driver: 'Олег Руденко',
      driverPhone: '+7 915 118-30-70',
      truckPlate: 'А504ТМ 40',
      lastEvent: 'Закрывающие документы получены',
      progress: 1,
      documentsReady: 5,
    ),
  ];

  final clients = const [
    Counterparty(
      id: 'c1',
      name: 'НордПром',
      contact: 'Екатерина Морозова',
      phone: '+7 903 721-18-06',
      kind: 'client',
      completedTrips: 14,
      usualRoutes: ['Москва → Екатеринбург'],
      tags: ['Платит вовремя'],
    ),
    Counterparty(
      id: 'c2',
      name: 'СтройВектор',
      contact: 'Сергей Павлов',
      phone: '+7 926 744-09-31',
      kind: 'client',
      completedTrips: 8,
      usualRoutes: ['Подольск → Нижний Новгород'],
      debt: 112000,
    ),
    Counterparty(
      id: 'c3',
      name: 'Вкус Севера',
      contact: 'Марина Волкова',
      phone: '+7 901 944-10-56',
      kind: 'client',
      completedTrips: 21,
      usualRoutes: ['Тверь → Санкт-Петербург'],
      tags: ['Рефрижератор'],
    ),
    Counterparty(
      id: 'c4',
      name: 'Альфа Кабель',
      contact: 'Дмитрий Орлов',
      phone: '+7 916 330-04-17',
      kind: 'client',
      completedTrips: 5,
      usualRoutes: ['Москва → Самара'],
    ),
  ];

  final carriers = const [
    Counterparty(
      id: 'p1',
      name: 'ИП Ковалёв',
      contact: 'Андрей Ковалёв',
      phone: '+7 916 440-18-02',
      kind: 'carrier',
      rating: 4.9,
      completedTrips: 32,
      usualRoutes: ['Москва → Екатеринбург', 'Москва → Казань'],
      tags: ['Тент 20 т', 'Надёжный'],
    ),
    Counterparty(
      id: 'p2',
      name: 'ООО СеверТранс',
      contact: 'Михаил Серов',
      phone: '+7 921 084-05-51',
      kind: 'carrier',
      rating: 4.8,
      completedTrips: 18,
      usualRoutes: ['Москва → Санкт-Петербург'],
      tags: ['Рефрижератор', 'ЭДО'],
    ),
    Counterparty(
      id: 'p3',
      name: 'ИП Руденко',
      contact: 'Олег Руденко',
      phone: '+7 915 118-30-70',
      kind: 'carrier',
      rating: 4.7,
      completedTrips: 11,
      usualRoutes: ['Калуга → Рязань'],
      tags: ['Тент 10 т'],
    ),
    Counterparty(
      id: 'p4',
      name: 'ООО Волга Карго',
      contact: 'Роман Юдин',
      phone: '+7 927 440-12-09',
      kind: 'carrier',
      rating: 4.6,
      completedTrips: 9,
      usualRoutes: ['Москва → Казань', 'Москва → Самара'],
      tags: ['Тент 20 т', 'GPS'],
    ),
  ];

  List<AttentionItem> get attention => const [
    AttentionItem(
      title: 'Не хватает транспортной накладной',
      subtitle: 'Водителю отправлено напоминание',
      kind: 'document',
      tripNumber: 'ТК-1005',
    ),
    AttentionItem(
      title: 'Погрузка завтра в 08:30',
      subtitle: 'Машина ещё не назначена',
      kind: 'warning',
      tripNumber: 'ТК-1008',
    ),
    AttentionItem(
      title: 'Оплата просрочена на 2 дня',
      subtitle: '112 000 ₽ · СтройВектор',
      kind: 'money',
      tripNumber: 'ТК-0998',
    ),
  ];

  int get activeTrips => trips.where((e) => e.status != TripStatus.done).length;
  int get monthMargin => trips.fold(0, (sum, trip) => sum + trip.margin);

  void updateDraft(TripDraft value) {
    draft = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('trip_draft', value.encode()),
    );
  }

  void clearDraft() {
    draft = const TripDraft();
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) => prefs.remove('trip_draft'));
  }

  Trip createTrip(TripDraft value) {
    final number = 'ТК-${1004 + trips.length + 1}';
    final trip = Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      number: number,
      from: value.from,
      to: value.to,
      cargo: value.cargo,
      weight: value.weight,
      vehicle: value.vehicle,
      client: value.client,
      clientRate: value.clientRate,
      carrierRate: value.carrierRate,
      pickupAt: DateTime.now().add(const Duration(days: 1)),
      status: value.carrier.isEmpty ? TripStatus.matching : TripStatus.draft,
      carrier: value.carrier,
      driver: value.driver,
      driverPhone: value.driverPhone,
      truckPlate: value.truckPlate,
      lastEvent:
          value.carrier.isEmpty
              ? 'Подберём перевозчиков из вашей базы'
              : 'Готово к подтверждению',
      progress: .04,
      documentsReady: 1,
    );
    trips.insert(0, trip);
    clearDraft();
    notifyListeners();
    return trip;
  }

  void repeatTrip(Trip trip) {
    updateDraft(
      TripDraft(
        from: trip.from,
        to: trip.to,
        cargo: trip.cargo,
        weight: trip.weight,
        vehicle: trip.vehicle,
        client: trip.client,
        clientRate: trip.clientRate,
        carrier: trip.carrier,
        carrierRate: trip.carrierRate,
        driver: trip.driver,
        driverPhone: trip.driverPhone,
        truckPlate: trip.truckPlate,
        pickupDate: 'Завтра',
      ),
    );
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('trip_draft');
    if (value != null) {
      try {
        draft = TripDraft.decode(value);
        notifyListeners();
      } catch (_) {
        await prefs.remove('trip_draft');
      }
    }
  }
}
