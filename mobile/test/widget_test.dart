import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transkontur_mobile/main.dart';

void main() {
  testWidgets('главный экран показывает рабочий день экспедитора', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TransKonturApp());
    await tester.pumpAndSettle();

    expect(find.text('ТрансКонтур'), findsOneWidget);
    expect(find.text('Доброе утро, Алексей'), findsOneWidget);
    expect(find.text('Новый рейс'), findsOneWidget);
    expect(find.text('Сейчас важно'), findsOneWidget);
  });

  testWidgets('основной сценарий помещается на экране телефона', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const TransKonturApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Новый рейс'));
    await tester.pumpAndSettle();
    expect(find.text('Как удобно\nсоздать рейс?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Показать на примере'));
    await tester.pumpAndSettle();
    expect(find.text('Проверка заявки'), findsOneWidget);
    expect(find.text('Москва'), findsWidgets);
    expect(find.text('Казань'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
