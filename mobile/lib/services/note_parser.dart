import '../domain/models.dart';

class NoteParser {
  static const cities = [
    'Москва',
    'Санкт-Петербург',
    'Казань',
    'Екатеринбург',
    'Новосибирск',
    'Нижний Новгород',
    'Самара',
    'Ростов-на-Дону',
    'Уфа',
    'Краснодар',
    'Пермь',
    'Омск',
    'Челябинск',
    'Тула',
    'Тверь',
    'Рязань',
    'Калуга',
    'Подольск',
    'Ярославль',
    'Воронеж',
    'Волгоград',
    'Саратов',
    'Ижевск',
  ];

  static const cargoWords = [
    'оборудование',
    'паллеты',
    'кабель',
    'продукты',
    'мебель',
    'металл',
    'стройматериалы',
    'запчасти',
    'напитки',
    'техника',
    'одежда',
    'бумага',
  ];

  static const vehicleWords = {
    'тент': 'Тент',
    'реф': 'Рефрижератор',
    'рефрижератор': 'Рефрижератор',
    'изотерм': 'Изотерм',
    'борт': 'Бортовой',
    'контейнер': 'Контейнеровоз',
    'газель': 'Газель',
    'фура': 'Тент',
  };

  TripDraft parse(String input, {DateTime? now}) {
    final text = input.trim();
    final lower = text.toLowerCase().replaceAll('ё', 'е');
    final clock = now ?? DateTime.now();
    final foundCities = <MapEntry<int, String>>[];
    for (final city in cities) {
      final i = lower.indexOf(city.toLowerCase().replaceAll('ё', 'е'));
      if (i >= 0) foundCities.add(MapEntry(i, city));
    }
    foundCities.sort((a, b) => a.key.compareTo(b.key));

    final weightMatch = RegExp(
      r'(\d+(?:[\.,]\d+)?)\s*(?:тонн|тонны|тонна|т)(?=\s|[,\.]|$)',
    ).firstMatch(lower);
    final weight =
        double.tryParse((weightMatch?.group(1) ?? '').replaceAll(',', '.')) ??
        0;

    String cargo = '';
    for (final word in cargoWords) {
      if (lower.contains(word)) {
        cargo = word[0].toUpperCase() + word.substring(1);
        break;
      }
    }

    String vehicle = '';
    for (final entry in vehicleWords.entries) {
      if (lower.contains(entry.key)) {
        vehicle = entry.value;
        break;
      }
    }

    final clientRate = _moneyAfter(lower, [
      'ставка клиенту',
      'клиент дает',
      'клиент даёт',
      'от клиента',
      'клиент',
    ]);
    final carrierRate = _moneyAfter(lower, [
      'перевозчику',
      'водителю',
      'машина за',
      'на машину',
    ]);

    String date = '';
    if (lower.contains('послезавтра')) {
      date = _formatDate(clock.add(const Duration(days: 2)));
    } else if (lower.contains('завтра')) {
      date = _formatDate(clock.add(const Duration(days: 1)));
    } else if (lower.contains('сегодня')) {
      date = _formatDate(clock);
    } else {
      final dateMatch = RegExp(
        r'\b(\d{1,2})[\./-](\d{1,2})(?:[\./-](\d{2,4}))?\b',
      ).firstMatch(lower);
      if (dateMatch != null) {
        final year = dateMatch.group(3) ?? clock.year.toString();
        date =
            '${dateMatch.group(1)!.padLeft(2, '0')}.${dateMatch.group(2)!.padLeft(2, '0')}.${year.length == 2 ? '20$year' : year}';
      }
    }

    final timeMatch = RegExp(
      r'(?:в|к)\s*(\d{1,2})(?::(\d{2}))?(?=\s|[,\.]|$)',
    ).firstMatch(lower);
    final time =
        timeMatch == null
            ? ''
            : '${timeMatch.group(1)!.padLeft(2, '0')}:${(timeMatch.group(2) ?? '00').padLeft(2, '0')}';

    final phoneMatch = RegExp(
      r'(?:\+7|8)[\s\-\(\)]*\d{3}[\s\-\(\)]*\d{3}[\s\-]*\d{2}[\s\-]*\d{2}',
    ).firstMatch(text);
    final plateMatch = RegExp(
      r'\b[авекмнорстух]\s?\d{3}\s?[авекмнорстух]{2}\s?\d{2,3}\b',
      caseSensitive: false,
    ).firstMatch(text);

    String client = '';
    const knownClients = [
      'НордПром',
      'СтройВектор',
      'Вкус Севера',
      'Альфа Кабель',
      'Линия Дома',
    ];
    for (final candidate in knownClients) {
      if (lower.contains(candidate.toLowerCase())) {
        client = candidate;
        break;
      }
    }

    return TripDraft(
      from: foundCities.isNotEmpty ? foundCities[0].value : '',
      to: foundCities.length > 1 ? foundCities[1].value : '',
      cargo: cargo,
      weight: weight,
      vehicle: vehicle,
      pickupDate: date,
      pickupTime: time,
      client: client,
      clientPhone: phoneMatch?.group(0) ?? '',
      clientRate: clientRate,
      carrierRate: carrierRate,
      truckPlate: plateMatch?.group(0)?.toUpperCase() ?? '',
      sourceText: text,
      comment: text,
      confidence: {
        if (foundCities.isNotEmpty) 'from': .94,
        if (foundCities.length > 1) 'to': .94,
        if (cargo.isNotEmpty) 'cargo': .88,
        if (weight > 0) 'weight': .97,
        if (vehicle.isNotEmpty) 'vehicle': .92,
        if (date.isNotEmpty) 'pickupDate': .93,
        if (clientRate > 0) 'clientRate': .86,
      },
    );
  }

  static int _moneyAfter(String text, List<String> markers) {
    for (final marker in markers) {
      final escaped = RegExp.escape(marker.replaceAll('ё', 'е'));
      final match = RegExp(
        '$escaped[^0-9]{0,18}(\\d[\\d\\s]{2,8})(?:\\s*(?:₽|р|руб|тысяч|тыс))?',
      ).firstMatch(text);
      if (match != null) {
        var value = int.tryParse(match.group(1)!.replaceAll(' ', '')) ?? 0;
        final tail = text.substring(
          match.end > text.length ? text.length : match.end - 8,
          match.end,
        );
        if ((tail.contains('тыс')) && value < 1000) value *= 1000;
        return value;
      }
    }
    return 0;
  }

  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
}
