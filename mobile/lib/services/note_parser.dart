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
    'Махачкала',
    'Грозный',
    'Ставрополь',
    'Астрахань',
    'Оренбург',
    'Набережные Челны',
    'Ульяновск',
    'Барнаул',
    'Тюмень',
    'Сургут',
    'Красноярск',
    'Иркутск',
    'Хабаровск',
    'Владивосток',
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
    'Махачкала': ['махачкала', 'махачкалы', 'махачкалу', 'махачкале'],
    'Грозный': ['грозный', 'грозного', 'грозном'],
    'Ставрополь': ['ставрополь', 'ставрополя', 'ставрополе'],
    'Астрахань': ['астрахань', 'астрахани'],
    'Оренбург': ['оренбург', 'оренбурга', 'оренбурге'],
    'Набережные Челны': ['набережные челны', 'набережных челнов', 'челны'],
    'Ульяновск': ['ульяновск', 'ульяновска', 'ульяновске'],
    'Барнаул': ['барнаул', 'барнаула', 'барнауле'],
    'Тюмень': ['тюмень', 'тюмени'],
    'Сургут': ['сургут', 'сургута', 'сургуте'],
    'Красноярск': ['красноярск', 'красноярска', 'красноярске'],
    'Иркутск': ['иркутск', 'иркутска', 'иркутске'],
    'Хабаровск': ['хабаровск', 'хабаровска', 'хабаровске'],
    'Владивосток': ['владивосток', 'владивостока', 'владивостоке'],
  };

  static const cargoWords = <String, String>{
    'оборудование': 'Оборудование',
    'паллет': 'Паллеты',
    'поддон': 'Паллеты',
    'кабель': 'Кабель',
    'продукт': 'Продукты',
    'замороз': 'Замороженные продукты',
    'мебель': 'Мебель',
    'металл': 'Металл',
    'стройматериал': 'Стройматериалы',
    'запчаст': 'Запчасти',
    'напит': 'Напитки',
    'техник': 'Техника',
    'одежд': 'Одежда',
    'бумаг': 'Бумага',
    'хими': 'Химическая продукция',
    'пиломатериал': 'Пиломатериалы',
    'мешк': 'Груз в мешках',
  };

  static const vehicleWords = {
    'тент': 'Тент',
    'реф': 'Рефрижератор',
    'рефрижератор': 'Рефрижератор',
    'изотерм': 'Изотерм',
    'борт': 'Бортовой',
    'контейнер': 'Контейнеровоз',
    'газель': 'Газель',
    'фура': 'Тент',
    'термос': 'Изотерм',
    'открытая машина': 'Бортовой',
    'низкорам': 'Трал',
    'трал': 'Трал',
  };

  static const knownClients = {
    'нордпром': 'НордПром',
    'норд пром': 'НордПром',
    'стройвектор': 'СтройВектор',
    'строй вектор': 'СтройВектор',
    'вкус севера': 'Вкус Севера',
    'альфа кабель': 'Альфа Кабель',
    'линия дома': 'Линия Дома',
  };

  static const knownCarriers = {
    'ип ковалев': ('ИП Ковалёв', 'Андрей Ковалёв', '+7 916 440-18-02'),
    'ип ковалёв': ('ИП Ковалёв', 'Андрей Ковалёв', '+7 916 440-18-02'),
    'севертранс': ('ООО СеверТранс', 'Михаил Серов', '+7 921 084-05-51'),
    'север транс': ('ООО СеверТранс', 'Михаил Серов', '+7 921 084-05-51'),
    'ип руденко': ('ИП Руденко', 'Олег Руденко', '+7 915 118-30-70'),
    'волга карго': ('ООО Волга Карго', 'Роман Юдин', '+7 927 440-12-09'),
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
    var routeFrom = foundCities.isNotEmpty ? foundCities[0].value : '';
    var routeTo = foundCities.length > 1 ? foundCities[1].value : '';
    if (routeFrom.isEmpty || routeTo.isEmpty) {
      final route = _routeFromText(text);
      routeFrom = routeFrom.isEmpty ? route.$1 : routeFrom;
      routeTo = routeTo.isEmpty ? route.$2 : routeTo;
    }

    final weightMatch = RegExp(
      r'(\d+(?:[\.,]\d+)?)\s*(?:тонн|тонны|тонна|т)(?=\s|[,\.]|$)',
    ).firstMatch(lower);
    final weight =
        double.tryParse((weightMatch?.group(1) ?? '').replaceAll(',', '.')) ??
        0;

    String cargo = '';
    for (final entry in cargoWords.entries) {
      if (lower.contains(entry.key)) {
        cargo = entry.value;
        break;
      }
    }
    if (cargo.isEmpty) cargo = _genericCargo(text);

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
      'клиент платит',
      'заказчик платит',
      'заказчик дает',
      'от заказчика',
      'продажа',
      'от клиента',
      'клиент',
    ]);
    final carrierRate = _moneyAfter(lower, [
      'перевозчику',
      'водителю',
      'машина за',
      'на машину',
      'закупка',
      'перевозчик берет',
      'перевозчик просит',
      'берет',
      'просит',
    ]);

    String date = '';
    if (lower.contains('послезавтра')) {
      date = _formatDate(clock.add(const Duration(days: 2)));
    } else if (lower.contains('завтра')) {
      date = _formatDate(clock.add(const Duration(days: 1)));
    } else if (lower.contains('сегодня')) {
      date = _formatDate(clock);
    } else {
      date = _dateFromWords(lower, clock);
      final dateMatch = RegExp(
        r'\b(\d{1,2})[\./-](\d{1,2})(?:[\./-](\d{2,4}))?\b',
      ).firstMatch(lower);
      final looksLikeWeight =
          dateMatch != null &&
          lower
              .substring(
                dateMatch.end,
                (dateMatch.end + 10).clamp(0, lower.length),
              )
              .contains('тон');
      if (date.isEmpty && dateMatch != null && !looksLikeWeight) {
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

    final phoneMatches =
        RegExp(
          r'(?:\+7|8)[\s\-\(\)]*\d{3}[\s\-\(\)]*\d{3}[\s\-]*\d{2}[\s\-]*\d{2}',
        ).allMatches(text).toList();
    final plateMatch = RegExp(
      r'[авекмнорстух]\s?\d{3}\s?[авекмнорстух]{2}\s?\d{2,3}',
      caseSensitive: false,
    ).firstMatch(text);

    String client = '';
    for (final candidate in knownClients.entries) {
      if (lower.contains(candidate.key)) {
        client = candidate.value;
        break;
      }
    }
    if (client.isEmpty) {
      client = _partyAfter(text, const ['клиент', 'заказчик']);
    }
    if (client.isEmpty) {
      final leadingCompany = RegExp(
        r'^\s*((?:ООО|ИП|АО|ПАО)\s+[«"]?[^,\.;]{2,40})[,\.;]',
        caseSensitive: false,
      ).firstMatch(text);
      client = _cleanPartyName(leadingCompany?.group(1) ?? '');
    }

    String carrier = '';
    String driver = '';
    String driverPhone = '';
    for (final candidate in knownCarriers.entries) {
      if (lower.contains(candidate.key)) {
        carrier = candidate.value.$1;
        driver = candidate.value.$2;
        driverPhone = candidate.value.$3;
        break;
      }
    }
    if (carrier.isEmpty) {
      carrier = _partyAfter(text, const ['перевозчик', 'машина от']);
    }
    final driverMatch = RegExp(
      r'(?:водитель|за рулем|за рулём)\s+([А-ЯЁ][а-яё]+(?:\s+[А-ЯЁ][а-яё]+){0,2})',
      caseSensitive: false,
    ).firstMatch(text);
    if (driverMatch != null) driver = driverMatch.group(1)!.trim();
    if (phoneMatches.isNotEmpty) {
      final driverWord = lower.indexOf('водител');
      final lastPhone = phoneMatches.last;
      if (driverWord >= 0 && lastPhone.start > driverWord) {
        driverPhone = lastPhone.group(0)!;
      }
    }

    final pickupAddress = _valueAfter(text, [
      'адрес погрузки',
      'забрать по адресу',
      'погрузка по адресу',
    ]);
    final deliveryAddress = _valueAfter(text, [
      'адрес выгрузки',
      'доставить по адресу',
      'выгрузка по адресу',
    ]);

    return TripDraft(
      from: routeFrom,
      to: routeTo,
      cargo: cargo,
      weight: weight,
      vehicle: vehicle,
      pickupDate: date,
      pickupTime: time,
      client: client,
      clientPhone: phoneMatches.isEmpty ? '' : phoneMatches.first.group(0)!,
      clientRate: clientRate,
      carrier: carrier,
      carrierRate: carrierRate,
      driver: driver,
      driverPhone: driverPhone,
      truckPlate: plateMatch?.group(0)?.toUpperCase() ?? '',
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      sourceText: text,
      comment: text,
      confidence: {
        if (routeFrom.isNotEmpty) 'from': .94,
        if (routeTo.isNotEmpty) 'to': .94,
        if (cargo.isNotEmpty) 'cargo': .88,
        if (weight > 0) 'weight': .97,
        if (vehicle.isNotEmpty) 'vehicle': .92,
        if (date.isNotEmpty) 'pickupDate': .93,
        if (clientRate > 0) 'clientRate': .86,
        if (carrierRate > 0) 'carrierRate': .86,
        if (carrier.isNotEmpty) 'carrier': .9,
      },
    );
  }

  static (String, String) _routeFromText(String text) {
    final patterns = [
      RegExp(
        r'(?:рейс|маршрут)\s+([А-ЯЁA-Z][А-ЯЁа-яёA-Za-z-]*(?:\s+[А-ЯЁA-Z][А-ЯЁа-яёA-Za-z-]*)?)\s*[—–-]\s*([А-ЯЁA-Z][А-ЯЁа-яёA-Za-z-]*(?:\s+[А-ЯЁA-Z][А-ЯЁа-яёA-Za-z-]*)?)',
        caseSensitive: false,
      ),
      RegExp(
        r'([А-ЯЁA-Z][А-ЯЁа-яёA-Za-z-]*(?:\s+[А-ЯЁA-Z][А-ЯЁа-яёA-Za-z-]*)?)\s*[—–-]\s*([А-ЯЁA-Z][А-ЯЁа-яёA-Za-z-]*(?:\s+[А-ЯЁA-Z][А-ЯЁа-яёA-Za-z-]*)?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:из|от)\s+([А-ЯЁA-Z][А-ЯЁа-яёA-Za-z-]*(?:\s+[А-ЯЁA-Z][А-ЯЁа-яёA-Za-z-]*)?)\s+(?:в|до)\s+([А-ЯЁA-Z][А-ЯЁа-яёA-Za-z-]*(?:\s+[А-ЯЁA-Z][А-ЯЁа-яёA-Za-z-]*)?)',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final from = _canonicalCity(match.group(1) ?? '');
      final to = _canonicalCity(match.group(2) ?? '');
      if (from.isNotEmpty && to.isNotEmpty) return (from, to);
    }
    return ('', '');
  }

  static String _canonicalCity(String value) {
    final cleaned = value
        .trim()
        .replaceFirst(RegExp(r'^(?:рейс|маршрут)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'[,\.;]+$'), '');
    final normalized = cleaned.toLowerCase().replaceAll('ё', 'е');
    for (final entry in cityAliases.entries) {
      if (entry.value.any(
        (alias) => alias.replaceAll('ё', 'е') == normalized,
      )) {
        return entry.key;
      }
    }
    if (cleaned.isEmpty) return '';
    return cleaned
        .split(RegExp(r'\s+'))
        .map(
          (part) =>
              part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String _genericCargo(String text) {
    final match = RegExp(
      r'(?:груз(?:ом)?|вез(?:е|ё)?м|перевозим)\s*[:—-]?\s*([а-яёa-z][а-яёa-z0-9\- ]{1,40}?)(?=\s+\d+(?:[\.,]\d+)?\s*(?:т|тонн)|\s+(?:вес|нужен|нужна|нужно|машина|тент|реф|клиент|заказчик|перевозчик)|[,\.;]|$)',
      caseSensitive: false,
    ).firstMatch(text);
    final value = match?.group(1)?.trim() ?? '';
    if (value.isEmpty) return '';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  static String _partyAfter(String text, List<String> markers) {
    for (final marker in markers) {
      final match = RegExp(
        '${RegExp.escape(marker)}(?:\\s+компания)?\\s+[«"]?([^,\\.;]{2,55})',
        caseSensitive: false,
      ).firstMatch(text);
      if (match == null) continue;
      final value =
          match
              .group(1)!
              .split(
                RegExp(
                  r'\s+(?:платит|дает|даёт|берет|берёт|просит|ставка|за)(?=\s|\d|$)',
                  caseSensitive: false,
                ),
              )
              .first;
      final cleaned = _cleanPartyName(value);
      if (cleaned.isNotEmpty) return cleaned;
    }
    return '';
  }

  static String _cleanPartyName(String value) => value
      .trim()
      .replaceAll(RegExp(r'^[«"]+|[»"]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  static int _moneyAfter(String text, List<String> markers) {
    for (final marker in markers) {
      final escaped = RegExp.escape(marker.replaceAll('ё', 'е'));
      final match = RegExp(
        '$escaped[^0-9]{0,24}(\\d+(?:[\\.,]\\d+)?(?:\\s+\\d{3})?)\\s*(млн|миллион(?:а|ов)?|тысяч(?:а|и)?|тыс\\.?|к|₽|руб(?:лей|ля)?|р\\.?)?',
      ).firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(' ', '').replaceAll(',', '.');
        final number = double.tryParse(raw) ?? 0;
        final unit = match.group(2) ?? '';
        final multiplier =
            unit.startsWith('млн') || unit.startsWith('миллион')
                ? 1000000
                : unit.startsWith('тыс') || unit == 'к'
                ? 1000
                : 1;
        return (number * multiplier).round();
      }
    }
    return 0;
  }

  static String _normalizeNumbers(String value) {
    var result = value;
    const replacements = <String, String>{
      'полторы': '1.5',
      'полтора': '1.5',
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

  static String _valueAfter(String text, List<String> markers) {
    for (final marker in markers) {
      final match = RegExp(
        '${RegExp.escape(marker)}\\s*[:—-]?\\s*([^;\\n]{4,70})',
        caseSensitive: false,
      ).firstMatch(text);
      if (match != null) {
        return match
            .group(1)!
            .split(
              RegExp(r'\s+(?:адрес|ставка|клиент|вес)\b', caseSensitive: false),
            )
            .first
            .trim()
            .replaceAll(RegExp(r'[,\.]$'), '');
      }
    }
    return '';
  }

  static String _dateFromWords(String text, DateTime clock) {
    const months = {
      'января': 1,
      'февраля': 2,
      'марта': 3,
      'апреля': 4,
      'мая': 5,
      'июня': 6,
      'июля': 7,
      'августа': 8,
      'сентября': 9,
      'октября': 10,
      'ноября': 11,
      'декабря': 12,
    };
    for (final month in months.entries) {
      final match = RegExp('(\\d{1,2})\\s+${month.key}').firstMatch(text);
      if (match == null) continue;
      final day = int.parse(match.group(1)!);
      var year = clock.year;
      if (DateTime(
        year,
        month.value,
        day,
      ).isBefore(DateTime(clock.year, clock.month, clock.day))) {
        year++;
      }
      return _formatDate(DateTime(year, month.value, day));
    }
    return '';
  }

  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
}
