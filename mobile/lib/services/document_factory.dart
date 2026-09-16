import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/models.dart';

enum TransportDocumentKind {
  transportOrder,
  forwardingOrder,
  forwardingReceipt,
  transportBill,
  serviceAct,
  universalTransfer,
}

extension TransportDocumentKindX on TransportDocumentKind {
  String get title => switch (this) {
    TransportDocumentKind.transportOrder => 'Заказ-заявка на перевозку',
    TransportDocumentKind.forwardingOrder => 'Поручение экспедитору',
    TransportDocumentKind.forwardingReceipt => 'Экспедиторская расписка',
    TransportDocumentKind.transportBill => 'Электронная транспортная накладная',
    TransportDocumentKind.serviceAct => 'Акт оказанных услуг',
    TransportDocumentKind.universalTransfer => 'УПД / закрывающий документ',
  };

  String get shortTitle => switch (this) {
    TransportDocumentKind.transportOrder => 'Заказ-заявка',
    TransportDocumentKind.forwardingOrder => 'Поручение экспедитору',
    TransportDocumentKind.forwardingReceipt => 'Экспедиторская расписка',
    TransportDocumentKind.transportBill => 'ЭТрН',
    TransportDocumentKind.serviceAct => 'Акт',
    TransportDocumentKind.universalTransfer => 'УПД',
  };

  String get format => switch (this) {
    TransportDocumentKind.transportOrder ||
    TransportDocumentKind.forwardingOrder ||
    TransportDocumentKind.forwardingReceipt ||
    TransportDocumentKind.transportBill => 'PDF + XML ГИС ЭПД',
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
    TransportDocumentKind.transportBill =>
      'Основной перевозочный документ для отправителя, перевозчика и получателя.',
    TransportDocumentKind.serviceAct =>
      'Подтверждает выполнение экспедиционных услуг для закрытия рейса.',
    TransportDocumentKind.universalTransfer =>
      'Закрывающий документ для бухгалтерии и расчётов с клиентом.',
  };

  String get xmlRoot => switch (this) {
    TransportDocumentKind.transportOrder => 'TransportOrder',
    TransportDocumentKind.forwardingOrder => 'ForwardingOrder',
    TransportDocumentKind.forwardingReceipt => 'ForwardingReceipt',
    TransportDocumentKind.transportBill => 'ElectronicTransportBill',
    TransportDocumentKind.serviceAct => 'ServiceAcceptanceAct',
    TransportDocumentKind.universalTransfer => 'UniversalTransferDocument',
  };

  bool get isEpd => switch (this) {
    TransportDocumentKind.transportOrder ||
    TransportDocumentKind.forwardingOrder ||
    TransportDocumentKind.forwardingReceipt ||
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
  static const companyName = 'ООО «ТрансКонтур»';
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
      kind.xmlRoot: {
        'Version': 'demo-1.0',
        'Status': ready.ready ? 'READY_FOR_SIGNING' : 'DRAFT',
        'DocumentNumber': '${trip.number}-${kind.name}',
        'DocumentDate': date,
        'Expeditor': {'Name': companyName, 'Inn': companyInn},
        'Client': {'Name': trip.client, 'RateRub': trip.clientRate},
        'Route': {
          'LoadingPoint': trip.from,
          'UnloadingPoint': trip.to,
          'LoadingDateTime': trip.pickupAt.toIso8601String(),
        },
        'Cargo': {
          'Name': trip.cargo,
          'WeightTonnes': trip.weight,
          'VehicleType': trip.vehicle,
        },
        'Carrier': {
          'Name': trip.carrier,
          'Driver': trip.driver,
          'DriverPhone': trip.driverPhone,
          'VehiclePlate': trip.truckPlate,
          'RateRub': trip.carrierRate,
        },
        'Economics': {'MarginRub': trip.margin},
        'Exchange': {
          'HumanReadable': 'PDF',
          'MachineReadable': kind.isEpd ? 'XML_IS_EPD' : 'XML',
          'Transmission': kind.isEpd ? 'Через оператора ИС ЭПД' : 'ЭДО',
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
                    'ТРАНСКОНТУР',
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
              _pdfSection(bold, 'Стороны', [
                ['Экспедитор', companyName],
                ['Реквизиты', companyInn],
                ['Клиент / заказчик', trip.client],
                [
                  'Перевозчик',
                  trip.carrier.isEmpty ? 'Не назначен' : trip.carrier,
                ],
                ['Водитель', trip.driver.isEmpty ? 'Не назначен' : trip.driver],
                [
                  'Телефон водителя',
                  trip.driverPhone.isEmpty ? '—' : trip.driverPhone,
                ],
              ]),
              _pdfSection(bold, 'Перевозка', [
                ['Маршрут', '${trip.from} — ${trip.to}'],
                ['Дата погрузки', _dateTime(trip.pickupAt)],
                ['Груз', trip.cargo],
                ['Вес', '${_weight(trip.weight)} т'],
                ['Тип машины', trip.vehicle],
                ['Госномер', trip.truckPlate.isEmpty ? '—' : trip.truckPlate],
              ]),
              _pdfSection(bold, 'Условия и расчёты', [
                ['Ставка клиента', '${_money(trip.clientRate)} ₽'],
                ['Ставка перевозчика', '${_money(trip.carrierRate)} ₽'],
                ['Маржа экспедитора', '${_money(trip.margin)} ₽'],
                ['Текущий статус', trip.status.label],
              ]),
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
