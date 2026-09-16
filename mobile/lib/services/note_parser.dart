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

  static const cityAliases = <String, List<String>>{
    'Москва': ['москва', 'москвы', 'москву', 'москве'],
    'Санкт-Петербург': [
      'санкт-петербург',
      'санкт-петербурга',
      'санкт-петербурге',
      'питер',
      'питера',
    ],
    'Казань': ['казань', 'казани', 'казанью'],
    'Екатеринбург': ['екатеринбург', 'екатеринбурга', 'екатеринбурге'],
    'Нижний Новгород': [
      'нижний новгород',
      'нижнего новгорода',
      'нижнем новгороде',
    ],
    'Самара': ['самара', 'самары', 'самару', 'самаре'],
    'Тверь': ['тверь', 'твери'],
    'Рязань': ['рязань', 'рязани'],
    'Калуга': ['калуга', 'калуги', 'калугу'],
    'Подольск': ['подольск', 'подольска', 'подольске'],
    'Краснодар': ['краснодар', 'краснодара', 'краснодаре'],
    'Ростов-на-Дону': ['ростов-на-дону', 'ростова-на-дону', 'ростов на дону'],
    'Новосибирск': ['новосибирск', 'новосибирска', 'новосибирске'],
    'Уфа': ['уфа', 'уфы', 'уфу'],
    'Пермь': ['пермь', 'перми'],
    'Омск': ['омск', 'омска', 'омске'],
    'Челябинск': ['челябинск', 'челябинска', 'челябинске'],
    'Тула': ['тула', 'тулы', 'тулу'],
    'Ярославль': ['ярославль', 'ярославля', 'ярославле'],
    'Воронеж': ['воронеж', 'воронежа', 'воронеже'],
    'Волгоград': ['волгоград', 'волгограда', 'волгограде'],
    'Саратов': ['саратов', 'саратова', 'саратове'],
    'Ижевск': ['ижевск', 'ижевска', 'ижевске'],
  };

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
    final lower = _normalizeNumbers(text.toLowerCase().replaceAll('ё', 'е'));
    final clock = now ?? DateTime.now();
    final foundCities = <MapEntry<int, String>>[];
    for (final city in cities) {
      final aliases = cityAliases[city] ?? [city.toLowerCase()];
      var earliest = -1;
      for (final alias in aliases) {
        final i = lower.indexOf(alias);
        if (i >= 0 && (earliest < 0 || i < earliest)) earliest = i;
      }
      if (earliest >= 0) foundCities.add(MapEntry(earliest, city));
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
    if (client.isEmpty) {
      final clientMatch = RegExp(
        r'(?:клиент|заказчик)(?:\s+компания)?\s+[«"]?([а-яa-z0-9][а-яa-z0-9\- ]{1,24})',
        caseSensitive: false,
      ).firstMatch(text);
      if (clientMatch != null) {
        client = clientMatch.group(1)!.split(RegExp(r'[,\.;]')).first.trim();
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

  static String _normalizeNumbers(String value) {
    var result = value;
    const replacements = <String, String>{
      'двести пятьдесят': '250',
      'двести сорок': '240',
      'двести тридцать': '230',
      'двести двадцать': '220',
      'двести десять': '210',
      'сто девяносто': '190',
      'сто восемьдесят': '180',
      'сто семьдесят': '170',
      'сто шестьдесят': '160',
      'сто пятьдесят': '150',
      'сто сорок': '140',
      'сто тридцать': '130',
      'сто двадцать': '120',
      'сто восемнадцать': '118',
      'сто десять': '110',
      'девяносто': '90',
      'восемьдесят': '80',
      'семьдесят': '70',
      'шестьдесят': '60',
      'пятьдесят': '50',
      'сорок': '40',
      'тридцать': '30',
      'двадцать пять': '25',
      'двадцать четыре': '24',
      'двадцать три': '23',
      'двадцать две': '22',
      'двадцать два': '22',
      'двадцать одна': '21',
      'двадцать один': '21',
      'двадцать': '20',
      'девятнадцать': '19',
      'восемнадцать': '18',
      'семнадцать': '17',
      'шестнадцать': '16',
      'пятнадцать': '15',
      'четырнадцать': '14',
      'тринадцать': '13',
      'двенадцать': '12',
      'одиннадцать': '11',
      'десять': '10',
      'девять': '9',
      'восемь': '8',
      'семь': '7',
      'шесть': '6',
      'пять': '5',
      'четыре': '4',
      'три': '3',
      'две': '2',
      'два': '2',
      'одна': '1',
      'один': '1',
    };
    for (final entry in replacements.entries) {
      result = result.replaceAllMapped(
        RegExp(
          '(^|[^а-я])${RegExp.escape(entry.key)}'
          r'(?=[^а-я]|$)',
        ),
        (match) => '${match.group(1) ?? ''}${entry.value}',
      );
    }
    return result;
  }

  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
}
