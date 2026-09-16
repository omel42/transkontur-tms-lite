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

    expect(xml, contains('<ElectronicTransportBill>'));
    expect(xml, contains('<LoadingPoint>Москва</LoadingPoint>'));
    expect(xml, contains('<MachineReadable>XML_IS_EPD</MachineReadable>'));
    expect(xml, contains('<Status>READY_FOR_SIGNING</Status>'));
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
