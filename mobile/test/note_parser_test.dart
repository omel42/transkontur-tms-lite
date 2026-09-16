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
}
