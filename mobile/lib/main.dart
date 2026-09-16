import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/app_store.dart';
import 'domain/models.dart';
import 'screens/create_trip_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/feature_screens.dart';
import 'screens/home_screen.dart';
import 'screens/other_screens.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.ink,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ReysApp());
}

class ReysApp extends StatefulWidget {
  const ReysApp({super.key});

  @override
  State<ReysApp> createState() => _ReysAppState();
}

class _ReysAppState extends State<ReysApp> {
  final store = AppStore();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'РЕЙС — мобильный экспедитор',
    theme: buildAppTheme(),
    home: Shell(store: store),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.store});
  final AppStore store;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void openCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CreateTripScreen(store: widget.store),
      ),
    );
  }

  void openDocuments([Trip? trip]) =>
      _open(DocumentsScreen(store: widget.store, initialTrip: trip));

  void openDriver([Trip? trip]) =>
      _open(DriverLinksScreen(store: widget.store, initialTrip: trip));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final screens = [
        HomeScreen(
          store: widget.store,
          onCreate: openCreate,
          onTrips: () => setState(() => index = 1),
          onNotifications:
              () => _open(
                NotificationsScreen(
                  store: widget.store,
                  onOpenDocuments: openDocuments,
                ),
              ),
          onDocuments: openDocuments,
          onDriver: openDriver,
        ),
        TripsScreen(
          store: widget.store,
          onCreate: openCreate,
          onDocuments: openDocuments,
          onDriver: openDriver,
        ),
        ContactsScreen(store: widget.store),
        ToolsScreen(
          store: widget.store,
          onDocuments: openDocuments,
          onMoney: () => _open(MoneyScreen(store: widget.store)),
          onCalendar: () => _open(CalendarScreen(store: widget.store)),
          onDriverLinks: openDriver,
          onVoice: () => _open(const VoiceSettingsScreen()),
          onIntegrations: () => _open(const IntegrationsScreen()),
        ),
      ];
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: IndexedStack(index: index, children: screens),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          height: 72,
          backgroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black12,
          indicatorColor: AppColors.acid.withValues(alpha: .4),
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Главная',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping_rounded),
              label: 'Рейсы',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_alt_outlined),
              selectedIcon: Icon(Icons.people_alt_rounded),
              label: 'База',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_mosaic_outlined),
              selectedIcon: Icon(Icons.auto_awesome_mosaic_rounded),
              label: 'Ещё',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openCreate,
          backgroundColor: AppColors.acid,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Новый рейс',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );
    },
  );
}
