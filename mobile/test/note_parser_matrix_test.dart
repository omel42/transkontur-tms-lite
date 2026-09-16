import 'package:flutter_test/flutter_test.dart';
import 'package:transkontur_mobile/services/note_parser.dart';

void main() {
  test('180 вариантов диктовки заполняют ключевые поля без перестановок', () {
    const routes = [
      ('Москва', 'Казань'),
      ('Санкт-Петербург', 'Тверь'),
      ('Екатеринбург', 'Пермь'),
      ('Новосибирск', 'Омск'),
      ('Нижний Новгород', 'Самара'),
      ('Уфа', 'Челябинск'),
      ('Краснодар', 'Ростов-на-Дону'),
      ('Калуга', 'Рязань'),
      ('Подольск', 'Воронеж'),
      ('Ярославль', 'Москва'),
      ('Волгоград', 'Саратов'),
      ('Ижевск', 'Пермь'),
    ];
    const routeTemplates = [
      'из {from} в {to}',
      '{from} — {to}',
      'забрать в {from} и доставить в {to}',
    ];
    const weights = [2.0, 5.0, 10.0, 15.0, 20.0];
    const cargoes = ['оборудование', 'мебель', 'кабель'];
    const vehicles = ['тент', 'рефрижератор', 'изотерм'];
    var checked = 0;

    for (var routeIndex = 0; routeIndex < routes.length; routeIndex++) {
      final route = routes[routeIndex];
      for (
        var templateIndex = 0;
        templateIndex < routeTemplates.length;
        templateIndex++
      ) {
        for (final tonnes in weights) {
          final routeText = routeTemplates[templateIndex]
              .replaceAll('{from}', route.$1)
              .replaceAll('{to}', route.$2);
          final cargo = cargoes[(routeIndex + templateIndex) % cargoes.length];
          final vehicle =
              vehicles[(routeIndex + templateIndex) % vehicles.length];
          final draft = NoteParser().parse(
            'НордПром, $routeText, завтра в 9 утра, $cargo '
            '${tonnes.toInt()} тонн, нужен $vehicle. '
            'Заказчик платит 150 тысяч, перевозчику 118 тысяч.',
            now: DateTime(2026, 9, 17),
          );

          expect(draft.from, route.$1, reason: routeText);
          expect(draft.to, route.$2, reason: routeText);
          expect(draft.weight, tonnes, reason: routeText);
          expect(draft.vehicle, isNotEmpty, reason: routeText);
          expect(draft.cargo, isNotEmpty, reason: routeText);
          expect(draft.pickupDate, '18.09.2026', reason: routeText);
          expect(draft.pickupTime, '09:00', reason: routeText);
          expect(draft.client, 'НордПром', reason: routeText);
          expect(draft.clientRate, 150000, reason: routeText);
          expect(draft.carrierRate, 118000, reason: routeText);
          checked++;
        }
      }
    }

    expect(checked, 180);
  });

  test('понимает разговорные деньги, дату, адреса и назначенную машину', () {
    final draft = NoteParser().parse(
      'Клиент Норд Пром. Из Москвы в Казань 21 сентября к 08:30. '
      'Оборудование полторы тонны, нужна фура. Клиент платит 0,15 млн, '
      'перевозчик ИП Ковалёв берет 118к. Водитель Андрей Ковалёв, '
      'номер Е742КХ 799. Адрес погрузки: Москва, Рябиновая 45; '
      'адрес выгрузки: Казань, Техническая 12.',
      now: DateTime(2026, 9, 17),
    );

    expect(draft.weight, 1.5);
    expect(draft.pickupDate, '21.09.2026');
    expect(draft.pickupTime, '08:30');
    expect(draft.clientRate, 150000);
    expect(draft.carrierRate, 118000);
    expect(draft.carrier, 'ИП Ковалёв');
    expect(draft.driver, 'Андрей Ковалёв');
    expect(draft.truckPlate, 'Е742КХ 799');
    expect(draft.pickupAddress, contains('Рябиновая 45'));
    expect(draft.deliveryAddress, contains('Техническая 12'));
  });
}
