import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/models.dart';

enum TransportDocumentKind {
  transportOrder,
  forwardingOrder,
  forwardingReceipt,
  warehouseReceipt,
  transportBill,
  serviceAct,
  universalTransfer,
}

extension TransportDocumentKindX on TransportDocumentKind {
  String get title => switch (this) {
    TransportDocumentKind.transportOrder => 'Заказ-заявка на перевозку',
    TransportDocumentKind.forwardingOrder => 'Поручение экспедитору',
    TransportDocumentKind.forwardingReceipt => 'Экспедиторская расписка',
    TransportDocumentKind.warehouseReceipt => 'Складская расписка',
    TransportDocumentKind.transportBill => 'Электронная транспортная накладная',
    TransportDocumentKind.serviceAct => 'Акт оказанных услуг',
    TransportDocumentKind.universalTransfer => 'УПД / закрывающий документ',
  };

  String get shortTitle => switch (this) {
    TransportDocumentKind.transportOrder => 'Заказ-заявка',
    TransportDocumentKind.forwardingOrder => 'Поручение экспедитору',
    TransportDocumentKind.forwardingReceipt => 'Экспедиторская расписка',
    TransportDocumentKind.warehouseReceipt => 'Складская расписка',
    TransportDocumentKind.transportBill => 'ЭТрН',
    TransportDocumentKind.serviceAct => 'Акт',
    TransportDocumentKind.universalTransfer => 'УПД',
  };

  String get format => switch (this) {
    TransportDocumentKind.transportOrder => 'XML · приказ ФНС № 108@',
    TransportDocumentKind.forwardingOrder => 'XML 5.01 · ЕД-1-26/277@, прил. 1',
    TransportDocumentKind.forwardingReceipt =>
      'XML 5.01 · ЕД-1-26/277@, прил. 2',
    TransportDocumentKind.warehouseReceipt =>
      'XML 5.01 · ЕД-1-26/277@, прил. 3',
    TransportDocumentKind.transportBill => 'XML ГИС ЭПД · ЕД-7-26/1065@',
    TransportDocumentKind.serviceAct => 'PDF для печати',
    TransportDocumentKind.universalTransfer => 'PDF + XML ФНС',
  };

  String get purpose => switch (this) {
    TransportDocumentKind.transportOrder =>
      'Фиксирует маршрут, груз, сроки, ставки и требования к машине.',
    TransportDocumentKind.forwardingOrder =>
      'Задание клиента экспедитору: что организовать и на каких условиях.',
    TransportDocumentKind.forwardingReceipt =>
      'Подтверждает, что экспедитор принял груз или документы в работу.',
    TransportDocumentKind.warehouseReceipt =>
      'Подтверждает принятие груза экспедитором на складское хранение.',
    TransportDocumentKind.transportBill =>
      'Основной перевозочный документ для отправителя, перевозчика и получателя.',
    TransportDocumentKind.serviceAct =>
      'Подтверждает выполнение экспедиционных услуг для закрытия рейса.',
    TransportDocumentKind.universalTransfer =>
      'Закрывающий документ для бухгалтерии и расчётов с клиентом.',
  };

  String get xmlRoot => switch (this) {
    TransportDocumentKind.transportOrder => 'ON_ZAKAZ',
    TransportDocumentKind.forwardingOrder => 'ON_POREXPEXP',
    TransportDocumentKind.forwardingReceipt => 'ON_EXPRASP',
    TransportDocumentKind.warehouseReceipt => 'ON_SKLADRASP',
    TransportDocumentKind.transportBill => 'ON_TTN',
    TransportDocumentKind.serviceAct => 'ServiceAcceptanceAct',
    TransportDocumentKind.universalTransfer => 'UniversalTransferDocument',
  };

  bool get isEpd => switch (this) {
    TransportDocumentKind.transportOrder ||
    TransportDocumentKind.forwardingOrder ||
    TransportDocumentKind.forwardingReceipt ||
    TransportDocumentKind.warehouseReceipt ||
    TransportDocumentKind.transportBill => true,
    _ => false,
  };
}

class DocumentReadiness {
  const DocumentReadiness({required this.ready, required this.missing});

  final bool ready;
  final List<String> missing;
}

class DocumentFactory {
  static const companyName = 'ООО «Рейс»';
  static const companyInn = 'ИНН 7700000000';

  static DocumentReadiness readiness(Trip trip, TransportDocumentKind kind) {
    final missing = <String>[
      if (trip.from.isEmpty) 'пункт отправления',
      if (trip.to.isEmpty) 'пункт назначения',
      if (trip.cargo.isEmpty) 'груз',
      if (trip.weight <= 0) 'вес',
      if (trip.client.isEmpty) 'клиент',
      if (trip.clientRate <= 0) 'ставка клиента',
    ];
    if (kind == TransportDocumentKind.forwardingReceipt ||
        kind == TransportDocumentKind.transportBill) {
      if (trip.carrier.isEmpty) missing.add('перевозчик');
      if (trip.driver.isEmpty) missing.add('водитель');
      if (trip.truckPlate.isEmpty) missing.add('госномер');
    }
    if (kind == TransportDocumentKind.serviceAct ||
        kind == TransportDocumentKind.universalTransfer) {
      if (trip.status != TripStatus.done &&
          trip.status != TripStatus.documents) {
        missing.add('подтверждение выполнения рейса');
      }
    }
    return DocumentReadiness(ready: missing.isEmpty, missing: missing);
  }

  static String buildXml(Trip trip, TransportDocumentKind kind) {
    final ready = readiness(trip, kind);
    final date = _date(trip.pickupAt);
    return const XmlEncoder.withIndent('  ').convert({
      'Файл': {
        'ИдФайл': '${kind.xmlRoot}_${trip.number}_${trip.id}',
        'ВерсФорм': kind.isEpd ? '5.01' : '1.0',
        'ФорматОбмена': kind.xmlRoot,
        'Статус': ready.ready ? 'ГОТОВ_К_ПОДПИСАНИЮ' : 'ЧЕРНОВИК',
        'Документ': {
          'НомерДок': '${trip.number}-${kind.name}',
          'ДатаДок': date,
          'СодОпер': kind.title,
          'СвЭксп': {'НаимОрг': companyName, 'ИНН': companyInn},
          'СвКлнт': {'НаимОрг': trip.client, 'СумУслуг': trip.clientRate},
          'СвГруз': {
            'НаимГруз': trip.cargo,
            'ВесГруз': trip.weight,
            'Маршрут': '${trip.from} — ${trip.to}',
            'ДатаПогруз': trip.pickupAt.toIso8601String(),
          },
          'СвТрсГруз': {
            'Перевозчик': trip.carrier,
            'Водитель': trip.driver,
            'Телефон': trip.driverPhone,
            'ГосНомер': trip.truckPlate,
            'ТипТС': trip.vehicle,
          },
          'Обмен': {
            'Машиночитаемый': kind.isEpd ? 'XML_IS_EPD' : 'XML_EDO',
            'Канал': kind.isEpd ? 'Оператор ИС ЭПД → ГИС ЭПД' : 'Оператор ЭДО',
          },
        },
      },
    });
  }

  static Future<Uint8List> buildPdf(
    Trip trip,
    TransportDocumentKind kind,
  ) async {
    final regularData = await rootBundle.load(
      'assets/fonts/Roboto-Regular.ttf',
    );
    final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final regular = pw.Font.ttf(regularData);
    final bold = pw.Font.ttf(boldData);
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);
    final ready = readiness(trip, kind);
    final document = pw.Document(
      title: '${kind.shortTitle} ${trip.number}',
      author: companyName,
      subject: 'Демонстрационный автоматически заполненный документ',
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        theme: theme,
        header:
            (context) => pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'РЕЙС',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 11,
                      color: PdfColor.fromHex('#226343'),
                    ),
                  ),
                  pw.Text(
                    '${trip.number} · ${_date(trip.pickupAt)}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
        footer:
            (context) => pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Страница ${context.pageNumber} из ${context.pagesCount} · демо-черновик',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ),
        build:
            (context) => [
              pw.SizedBox(height: 18),
              pw.Text(
                kind.title,
                style: pw.TextStyle(font: bold, fontSize: 24),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                ready.ready
                    ? 'Автоматически заполнено · готово к проверке и подписанию'
                    : 'Черновик · требуется дополнить: ${ready.missing.join(', ')}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color:
                      ready.ready
                          ? PdfColor.fromHex('#226343')
                          : PdfColors.deepOrange,
                ),
              ),
              pw.SizedBox(height: 22),
              ..._pdfContent(bold, trip, kind),
              pw.SizedBox(height: 18),
              pw.Container(
                padding: const pw.EdgeInsets.all(13),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F1F5F2'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  '${kind.purpose} Этот файл создан для предпросмотра и печати. Для юридически значимого обмена формируется XML установленного формата, подписывается электронной подписью и передаётся через оператора ИС ЭПД.',
                  style: const pw.TextStyle(fontSize: 9, lineSpacing: 3),
                ),
              ),
              pw.SizedBox(height: 36),
              pw.Row(
                children: [
                  pw.Expanded(child: _signature(bold, 'Экспедитор')),
                  pw.SizedBox(width: 24),
                  pw.Expanded(child: _signature(bold, 'Клиент / перевозчик')),
                ],
              ),
            ],
      ),
    );
    return document.save();
  }

  static pw.Widget _pdfSection(
    pw.Font bold,
    String title,
    List<List<String>> rows,
  ) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 14),
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(9),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 12)),
        pw.SizedBox(height: 8),
        ...rows.map(
          (row) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 145,
                  child: pw.Text(
                    row[0],
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    row[1],
                    style: pw.TextStyle(font: bold, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  static List<pw.Widget> _pdfContent(
    pw.Font bold,
    Trip trip,
    TransportDocumentKind kind,
  ) => switch (kind) {
    TransportDocumentKind.transportOrder => [
      _pdfSection(bold, '1. Заявка и стороны', [
        ['Заказчик', trip.client],
        ['Экспедитор', companyName],
        ['Номер заявки', '${trip.number}-ЗЗ'],
        ['Дата', _date(trip.pickupAt)],
      ]),
      _pdfSection(bold, '2. Условия перевозки', [
        ['Маршрут', '${trip.from} — ${trip.to}'],
        ['Подача машины', _dateTime(trip.pickupAt)],
        ['Груз / вес', '${trip.cargo}, ${_weight(trip.weight)} т'],
        ['Требуемое ТС', trip.vehicle],
        ['Ставка', '${_money(trip.clientRate)} ₽'],
      ]),
      _pdfSection(bold, '3. Назначенное исполнение', [
        ['Перевозчик', _orDash(trip.carrier)],
        ['Водитель', _orDash(trip.driver)],
        ['Телефон', _orDash(trip.driverPhone)],
        ['Госномер', _orDash(trip.truckPlate)],
      ]),
    ],
    TransportDocumentKind.forwardingOrder => [
      _pdfSection(bold, '1. Поручение клиента', [
        ['Клиент', trip.client],
        ['Экспедитор', companyName],
        ['Поручение №', '${trip.number}-ПЭ'],
        ['Услуга', 'Организовать автомобильную перевозку груза'],
      ]),
      _pdfSection(bold, '2. Сведения о грузе', [
        ['Наименование', trip.cargo],
        ['Масса брутто', '${_weight(trip.weight)} т'],
        ['Пункт отправления', trip.from],
        ['Пункт назначения', trip.to],
        ['Дата готовности', _dateTime(trip.pickupAt)],
      ]),
      _pdfSection(bold, '3. Экспедиционные услуги', [
        ['Организация перевозки', 'Да'],
        ['Подбор перевозчика', 'Да'],
        ['Контроль документов', 'Да'],
        ['Вознаграждение / стоимость', '${_money(trip.clientRate)} ₽'],
      ]),
    ],
    TransportDocumentKind.forwardingReceipt => [
      _pdfSection(bold, '1. Приём груза экспедитором', [
        ['Расписка №', '${trip.number}-ЭР'],
        ['Дата приёма', _dateTime(trip.pickupAt)],
        ['Клиент', trip.client],
        ['Экспедитор', companyName],
      ]),
      _pdfSection(bold, '2. Принятый груз', [
        ['Наименование', trip.cargo],
        ['Масса', '${_weight(trip.weight)} т'],
        ['Место приёма', trip.from],
        ['Назначение', trip.to],
        [
          'Состояние / оговорки',
          'Без видимых повреждений · уточнить при приёмке',
        ],
      ]),
      _pdfSection(bold, '3. Доставка', [
        ['Перевозчик', _orDash(trip.carrier)],
        ['Водитель', _orDash(trip.driver)],
        ['ТС / госномер', '${trip.vehicle} · ${_orDash(trip.truckPlate)}'],
      ]),
    ],
    TransportDocumentKind.warehouseReceipt => [
      _pdfSection(bold, '1. Приём на хранение', [
        ['Складская расписка №', '${trip.number}-СР'],
        ['Клиент', trip.client],
        ['Экспедитор', companyName],
        ['Дата и время приёма', _dateTime(trip.pickupAt)],
        ['Склад', '${trip.from} · адрес требуется уточнить'],
      ]),
      _pdfSection(bold, '2. Груз на складе', [
        ['Наименование', trip.cargo],
        ['Масса партии', '${_weight(trip.weight)} т'],
        ['Упаковка', 'Требуется подтвердить при приёмке'],
        ['Состояние', 'Требуется подтвердить при приёмке'],
        ['Условия хранения', 'По договору транспортной экспедиции'],
      ]),
    ],
    TransportDocumentKind.transportBill => [
      _pdfSection(bold, 'Разделы 1–2. Участники', [
        ['Грузоотправитель', trip.client],
        ['Грузополучатель', 'Получатель в г. ${trip.to} · уточнить реквизиты'],
        ['Перевозчик', _orDash(trip.carrier)],
        ['Экспедитор', companyName],
      ]),
      _pdfSection(bold, 'Разделы 3–6. Груз и маршрут', [
        ['Груз', trip.cargo],
        ['Масса брутто', '${_weight(trip.weight)} т'],
        ['Погрузка', '${trip.from} · ${_dateTime(trip.pickupAt)}'],
        ['Выгрузка', trip.to],
        ['Сопроводительные документы', 'Заказ-заявка, поручение экспедитору'],
      ]),
      _pdfSection(bold, 'Разделы 7–11. Перевозка', [
        ['Водитель', _orDash(trip.driver)],
        ['Телефон', _orDash(trip.driverPhone)],
        ['Транспортное средство', trip.vehicle],
        ['Госномер', _orDash(trip.truckPlate)],
        ['Стоимость перевозки', '${_money(trip.carrierRate)} ₽'],
      ]),
    ],
    TransportDocumentKind.serviceAct => [
      _pdfSection(bold, 'Акт об оказании услуг', [
        ['Исполнитель', companyName],
        ['Заказчик', trip.client],
        ['Основание', 'Договор транспортной экспедиции / ${trip.number}'],
        ['Период', _date(trip.pickupAt)],
      ]),
      _pdfSection(bold, 'Оказанные услуги', [
        ['Наименование', 'Организация перевозки ${trip.from} — ${trip.to}'],
        ['Количество', '1 услуга'],
        ['Стоимость без НДС', '${_money(trip.clientRate)} ₽'],
        ['Итого', '${_money(trip.clientRate)} ₽'],
        ['Претензии', 'Сторонами не заявлены'],
      ]),
    ],
    TransportDocumentKind.universalTransfer => [
      _pdfSection(bold, 'Универсальный передаточный документ', [
        ['Статус', '2 — передаточный документ (акт)'],
        ['Продавец / исполнитель', companyName],
        ['ИНН / КПП', companyInn],
        ['Покупатель / заказчик', trip.client],
        ['Основание передачи', 'Транспортно-экспедиционные услуги'],
      ]),
      _pdfSection(bold, 'Табличная часть УПД', [
        ['Наименование услуги', 'Организация перевозки ${trip.route}'],
        ['Единица', 'услуга'],
        ['Количество', '1'],
        ['Цена / стоимость', '${_money(trip.clientRate)} ₽'],
        ['НДС', 'Без НДС · настройка организации'],
        ['Всего к оплате', '${_money(trip.clientRate)} ₽'],
      ]),
    ],
  };

  static String _orDash(String value) => value.trim().isEmpty ? '—' : value;

  static pw.Widget _signature(pw.Font bold, String title) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(height: 1, color: PdfColors.grey500),
      pw.SizedBox(height: 5),
      pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 8)),
      pw.Text(
        'Подпись / дата',
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
      ),
    ],
  );

  static String fileName(Trip trip, TransportDocumentKind kind) =>
      '${trip.number}_${kind.name}.pdf';

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

  static String _dateTime(DateTime value) =>
      '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  static String _weight(double value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);

  static String _money(int value) {
    final chars = value.abs().toString().split('').reversed.toList();
    final chunks = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      chunks.add(chars.skip(i).take(3).toList().reversed.join());
    }
    final formatted = chunks.reversed.join(' ');
    return value < 0 ? '-$formatted' : formatted;
  }
}

class XmlEncoder extends Converter<Map<String, dynamic>, String> {
  const XmlEncoder.withIndent(this.indent);

  final String indent;

  @override
  String convert(Map<String, dynamic> input) {
    final buffer = StringBuffer('<?xml version="1.0" encoding="UTF-8"?>\n');
    for (final entry in input.entries) {
      _writeNode(buffer, entry.key, entry.value, 0);
    }
    return buffer.toString();
  }

  void _writeNode(StringBuffer out, String name, dynamic value, int depth) {
    final pad = indent * depth;
    if (value is Map) {
      out.writeln('$pad<$name>');
      for (final entry in value.entries) {
        _writeNode(out, entry.key.toString(), entry.value, depth + 1);
      }
      out.writeln('$pad</$name>');
      return;
    }
    out.writeln('$pad<$name>${_escape(value?.toString() ?? '')}</$name>');
  }

  String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
