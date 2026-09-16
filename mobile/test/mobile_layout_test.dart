import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transkontur_mobile/data/app_store.dart';
import 'package:transkontur_mobile/screens/documents_screen.dart';
import 'package:transkontur_mobile/screens/feature_screens.dart';
import 'package:transkontur_mobile/screens/other_screens.dart';
import 'package:transkontur_mobile/theme.dart';

void main() {
  Future<void> renderAt(WidgetTester tester, Size size, Widget screen) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: screen));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'экран $size');
  }

  for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
    testWidgets('документы помещаются на телефоне $size', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      await renderAt(tester, size, DocumentsScreen(store: AppStore()));
      expect(find.text('Документы рейса'), findsOneWidget);
    });

    testWidgets('календарь помещается на телефоне $size', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      await renderAt(tester, size, CalendarScreen(store: AppStore()));
      expect(find.text('Календарь рейсов'), findsOneWidget);
    });

    testWidgets('база контактов помещается на телефоне $size', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      await renderAt(
        tester,
        size,
        Scaffold(body: ContactsScreen(store: AppStore())),
      );
      expect(find.text('База'), findsOneWidget);
    });
  }
}
