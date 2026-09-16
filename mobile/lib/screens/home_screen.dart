import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../domain/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.onCreate,
    required this.onTrips,
    required this.onNotifications,
    required this.onDocuments,
    required this.onDriver,
  });
  final AppStore store;
  final VoidCallback onCreate;
  final VoidCallback onTrips;
  final VoidCallback onNotifications;
  final ValueChanged<Trip?> onDocuments;
  final ValueChanged<Trip?> onDriver;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: _Header(store: store, onNotifications: onNotifications),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 118),
        sliver: SliverList.list(
          children: [
            _VoiceHero(onTap: onCreate),
            const SizedBox(height: 24),
            SectionTitle(
              title: 'Сейчас важно',
              count: '${store.attention.length}',
            ),
            const SizedBox(height: 12),
            ...store.attention.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _AttentionCard(
                  item: item,
                  onTap:
                      item.kind == 'document'
                          ? () => onDocuments(
                            _tripByNumber(store.trips, item.tripNumber),
                          )
                          : onTrips,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SectionTitle(
              title: 'Активные рейсы',
              action: 'Все рейсы',
              onTap: onTrips,
            ),
            const SizedBox(height: 12),
            ...store.trips
                .where((e) => e.status != TripStatus.done)
                .take(3)
                .map(
                  (trip) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TripCard(
                      trip: trip,
                      onTap:
                          () => showTripDetails(
                            context,
                            trip,
                            onDocuments: () => onDocuments(trip),
                            onDriver: () => onDriver(trip),
                          ),
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            _AutomationCard(onTap: () => onDocuments(null)),
          ],
        ),
      ),
    ],
  );
}

Trip? _tripByNumber(List<Trip> trips, String number) {
  for (final trip in trips) {
    if (trip.number == number) return trip;
  }
  return null;
}

class _Header extends StatelessWidget {
  const _Header({required this.store, required this.onNotifications});
  final AppStore store;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppColors.ink,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    padding: EdgeInsets.fromLTRB(
      20,
      MediaQuery.paddingOf(context).top + 16,
      20,
      24,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BrandMark(),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'РЕЙС',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'РАБОЧИЙ ПУЛЬТ ЭКСПЕДИТОРА',
                    style: TextStyle(
                      color: Color(0xFF8998A3),
                      fontSize: 8,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onNotifications,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      top: 9,
                      right: 10,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.acid,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Text(
          '${_greeting(DateTime.now())}, Виталий',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Сегодня главное — назначить машину на ТК-1008',
          style: TextStyle(color: Color(0xFFAAB5BC), fontSize: 13),
        ),
        const SizedBox(height: 19),
        Row(
          children: [
            Expanded(
              child: _Metric(
                value: '${store.activeTrips}',
                label: 'активных рейса',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric(
                value: money(store.monthMargin),
                label: 'маржа в работе',
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: _Metric(value: '2', label: 'нужны действия')),
          ],
        ),
      ],
    ),
  );
}

String _greeting(DateTime now) => switch (now.hour) {
  >= 5 && < 12 => 'Доброе утро',
  >= 12 && < 18 => 'Добрый день',
  >= 18 && < 23 => 'Добрый вечер',
  _ => 'Доброй ночи',
};

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .065),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 23,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.acid,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 23,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.fade,
            style: const TextStyle(
              color: Color(0xFF95A4AD),
              fontSize: 8.5,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _VoiceHero extends StatelessWidget {
  const _VoiceHero({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(26),
    child: Ink(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3F70DF), Color(0xFF65A6E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.acid.withValues(alpha: .22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, color: AppColors.cyan, size: 8),
                    SizedBox(width: 7),
                    Text(
                      'НОВЫЙ РЕЙС ЗА МИНУТУ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Наговорите,\nчто договорились',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Маршрут, груз, дата и ставка сами попадут в заявку.',
                  style: TextStyle(
                    color: Color(0xFFE4EDF8),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: .3),
                width: 4,
              ),
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    ),
  );
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.item, required this.onTap});
  final AttentionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.kind) {
      'money' => (Icons.payments_outlined, AppColors.green),
      'warning' => (Icons.schedule_rounded, AppColors.orange),
      _ => (Icons.description_outlined, AppColors.blue),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.tripNumber} · ${item.subtitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFABB4B2)),
          ],
        ),
      ),
    );
  }
}

class _AutomationCard extends StatelessWidget {
  const _AutomationCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(23),
    child: Ink(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(23),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.acid, size: 28),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Рутина под контролем',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Напоминания водителю, документы и оплаты проверяются автоматически.',
                  style: TextStyle(
                    color: Color(0xFFAAB5BC),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
