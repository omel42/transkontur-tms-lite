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
  });
  final AppStore store;
  final VoidCallback onCreate;
  final VoidCallback onTrips;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: _Header(store: store)),
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
                child: _AttentionCard(item: item),
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
                    child: TripCard(trip: trip),
                  ),
                ),
            const SizedBox(height: 12),
            const _AutomationCard(),
          ],
        ),
      ),
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.store});
  final AppStore store;

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
                    'ТрансКонтур',
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
            Container(
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
          ],
        ),
        const SizedBox(height: 25),
        const Text(
          'Доброе утро, Алексей',
          style: TextStyle(
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

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .065),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.acid,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF95A4AD),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
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
          colors: [Color(0xFFBEFA32), Color(0xFFDFFF75)],
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
                    Icon(Icons.circle, color: AppColors.green, size: 8),
                    SizedBox(width: 7),
                    Text(
                      'НОВЫЙ РЕЙС ЗА МИНУТУ',
                      style: TextStyle(
                        color: AppColors.green,
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
                    color: AppColors.ink,
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
                    color: Color(0xFF405123),
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
  const _AttentionCard({required this.item});
  final AttentionItem item;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.kind) {
      'money' => (Icons.payments_outlined, AppColors.green),
      'warning' => (Icons.schedule_rounded, AppColors.orange),
      _ => (Icons.description_outlined, AppColors.blue),
    };
    return Container(
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
    );
  }
}

class _AutomationCard extends StatelessWidget {
  const _AutomationCard();
  @override
  Widget build(BuildContext context) => Container(
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
  );
}
