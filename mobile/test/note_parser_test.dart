import 'package:flutter_test/flutter_test.dart';
import 'package:transkontur_mobile/services/note_parser.dart';

void main() {
  test('разбирает голосовую заметку в заявку', () {
    final draft = NoteParser().parse(
      'НордПром, Москва — Казань, завтра к 9 утра, оборудование 20 тонн, нужен тент. Клиент даёт 150 тысяч, перевозчику 118 тысяч.',
      now: DateTime(2026, 9, 16),
    );

    expect(draft.from, 'Москва');
    expect(draft.to, 'Казань');
    expect(draft.cargo, 'Оборудование');
    expect(draft.weight, 20);
    expect(draft.vehicle, 'Тент');
    expect(draft.pickupDate, '17.09.2026');
    expect(draft.pickupTime, '09:00');
    expect(draft.client, 'НордПром');
    expect(draft.clientRate, 150000);
    expect(draft.carrierRate, 118000);
    expect(draft.margin, 32000);
  });

  test('не выдумывает отсутствующие поля', () {
    final draft = NoteParser().parse('Москва — Тверь, завтра');
    expect(draft.cargo, isEmpty);
    expect(draft.clientRate, 0);
    expect(draft.missingFields, contains('Груз'));
    expect(draft.missingFields, contains('Ставка клиента'));
  });

  test('понимает падежи городов и числа словами', () {
    final draft = NoteParser().parse(
      'Из Москвы в Казань завтра в девять. Оборудование двадцать тонн, '
      'нужен тент. Клиент НордПром даёт сто пятьдесят тысяч, '
      'перевозчику сто восемнадцать тысяч.',
      now: DateTime(2026, 9, 17),
    );

    expect(draft.from, 'Москва');
    expect(draft.to, 'Казань');
    expect(draft.weight, 20);
    expect(draft.pickupTime, '09:00');
    expect(draft.clientRate, 150000);
    expect(draft.carrierRate, 118000);
  });

  test('разбирает новый маршрут и произвольные стороны рейса', () {
    final draft = NoteParser().parse(
      'Рейс Москва-Махачкала, груз микросхемы 10 тонн, нужен тент. '
      'Клиент ООО Ромашка платит 210 тысяч, перевозчик ИП Алиев '
      'просит 165 тысяч. Водитель Рашид Алиев, номер А123ВС05.',
      now: DateTime(2026, 9, 17),
    );

    expect(draft.from, 'Москва');
    expect(draft.to, 'Махачкала');
    expect(draft.cargo, 'Микросхемы');
    expect(draft.weight, 10);
    expect(draft.vehicle, 'Тент');
    expect(draft.client, 'ООО Ромашка');
    expect(draft.clientRate, 210000);
    expect(draft.carrier, 'ИП Алиев');
    expect(draft.carrierRate, 165000);
    expect(draft.driver, 'Рашид Алиев');
    expect(draft.truckPlate, 'А123ВС05');
  });
}
