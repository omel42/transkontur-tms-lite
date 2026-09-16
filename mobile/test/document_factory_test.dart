import 'package:flutter_test/flutter_test.dart';
import 'package:transkontur_mobile/domain/models.dart';
import 'package:transkontur_mobile/services/document_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final trip = Trip(
    id: 'test',
    number: 'ТК-TEST',
    from: 'Москва',
    to: 'Казань',
    cargo: 'Оборудование',
    weight: 20,
    vehicle: 'Тент',
    client: 'НордПром',
    clientRate: 150000,
    carrierRate: 118000,
    pickupAt: DateTime(2026, 9, 18, 9),
    status: TripStatus.documents,
    carrier: 'ИП Ковалёв',
    driver: 'Андрей Ковалёв',
    driverPhone: '+7 916 440-18-02',
    truckPlate: 'Е742КХ 799',
  );

  test('готовит XML для обмена через ИС ЭПД', () {
    final xml = DocumentFactory.buildXml(
      trip,
      TransportDocumentKind.transportBill,
    );

    expect(xml, contains('<Файл>'));
    expect(xml, contains('<ФорматОбмена>ON_TTN</ФорматОбмена>'));
    expect(xml, contains('<Маршрут>Москва — Казань</Маршрут>'));
    expect(xml, contains('<Машиночитаемый>XML_IS_EPD</Машиночитаемый>'));
    expect(xml, contains('<Статус>ГОТОВ_К_ПОДПИСАНИЮ</Статус>'));
  });

  test('в комплекте есть все три экспедиторских документа ФНС', () {
    expect(
      TransportDocumentKind.forwardingOrder.format,
      contains('ЕД-1-26/277@, прил. 1'),
    );
    expect(
      TransportDocumentKind.forwardingReceipt.format,
      contains('ЕД-1-26/277@, прил. 2'),
    );
    expect(
      TransportDocumentKind.warehouseReceipt.format,
      contains('ЕД-1-26/277@, прил. 3'),
    );
  });

  test('создаёт непустой PDF с кириллическим шрифтом', () async {
    final pdf = await DocumentFactory.buildPdf(
      trip,
      TransportDocumentKind.transportOrder,
    );

    expect(pdf.length, greaterThan(10000));
    expect(pdf.take(4).toList(), [37, 80, 68, 70]);
  });
}
