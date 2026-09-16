import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../domain/models.dart';
import '../services/local_asr.dart';
import '../theme.dart';
import '../widgets/common.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key, required this.store, required this.onCreate});
  final AppStore store;
  final VoidCallback onCreate;

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  String filter = 'Активные';

  @override
  Widget build(BuildContext context) {
    final visible =
        widget.store.trips.where((trip) {
          if (filter == 'Завершённые') return trip.status == TripStatus.done;
          if (filter == 'Документы') return trip.status == TripStatus.documents;
          return trip.status != TripStatus.done;
        }).toList();
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeader(
                    eyebrow: 'ОПЕРАЦИОННАЯ РАБОТА',
                    title: 'Рейсы',
                    icon: Icons.search_rounded,
                  ),
                  const SizedBox(height: 18),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          ['Активные', 'Документы', 'Завершённые']
                              .map(
                                (name) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(name),
                                    selected: filter == name,
                                    selectedColor: AppColors.acid,
                                    side: BorderSide.none,
                                    onSelected:
                                        (_) => setState(() => filter = name),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 118),
            sliver: SliverList.builder(
              itemCount: visible.length,
              itemBuilder:
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TripCard(trip: visible[i]),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key, required this.store});
  final AppStore store;

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool clients = true;

  @override
  Widget build(BuildContext context) {
    final data = clients ? widget.store.clients : widget.store.carriers;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 118),
        children: [
          const PageHeader(
            eyebrow: 'ВАШИ СВЯЗИ',
            title: 'База',
            icon: Icons.person_add_alt_1_rounded,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE7ECE8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Клиенты',
                    selected: clients,
                    onTap: () => setState(() => clients = true),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'Перевозчики',
                    selected: !clients,
                    onTap: () => setState(() => clients = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: const TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search_rounded, color: AppColors.muted),
                hintText: 'Компания, человек или маршрут',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...data.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _ContactCard(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        boxShadow:
            selected
                ? const [BoxShadow(color: Colors.black12, blurRadius: 8)]
                : null,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: selected ? AppColors.ink : AppColors.muted,
        ),
      ),
    ),
  );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.item});
  final Counterparty item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 45,
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    item.kind == 'client'
                        ? AppColors.cyan.withValues(alpha: .22)
                        : AppColors.acid.withValues(alpha: .33),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                item.name.substring(0, 1),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.contact} · ${item.phone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (item.rating > 0)
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.orange,
                    size: 16,
                  ),
                  Text(
                    item.rating.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...item.tags.map((tag) => TinyTag(label: tag)),
            TinyTag(label: '${item.completedTrips} рейсов'),
          ],
        ),
        if (item.usualRoutes.isNotEmpty) ...[
          const Divider(height: 24, color: AppColors.line),
          Row(
            children: [
              const Icon(
                Icons.route_outlined,
                color: AppColors.muted,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.usualRoutes.first,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ),
              if (item.debt > 0)
                Text(
                  'долг ${money(item.debt)}',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key, required this.store});
  final AppStore store;

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final asr = createLocalAsrEngine();
  late final Future<AsrReadiness> readiness = asr.readiness();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 118),
      children: [
        const PageHeader(
          eyebrow: 'КОНТРОЛЬ БИЗНЕСА',
          title: 'Инструменты',
          icon: Icons.settings_outlined,
        ),
        const SizedBox(height: 20),
        FutureBuilder<AsrReadiness>(
          future: readiness,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.acid,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.graphic_eq_rounded,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Локальная Qwen3-ASR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Alibaba · 0.6B · INT8 · русский язык',
                              style: TextStyle(
                                color: Color(0xFF9DACB5),
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color:
                              data?.ready == true
                                  ? AppColors.acid
                                  : AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    data?.title ?? 'Проверяем модель…',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    data?.detail ?? 'Файлы и среда выполнения проверяются.',
                    style: const TextStyle(
                      color: Color(0xFFAAB5BC),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 13),
                  const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: AppColors.acid,
                        size: 16,
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Аудио и распознанный текст остаются на устройстве',
                          style: TextStyle(
                            color: AppColors.acid,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 22),
        const SectionTitle(title: 'Рабочие центры'),
        const SizedBox(height: 12),
        const _ToolTile(
          icon: Icons.description_outlined,
          color: AppColors.blue,
          title: 'Документы',
          subtitle: 'ПЭ, ЭР, ЭТрН и закрывающие',
          badge: '2 требуют внимания',
        ),
        const _ToolTile(
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.green,
          title: 'Деньги',
          subtitle: 'Маржа, оплаты и задолженность',
          badge: '317 000 ₽ в работе',
        ),
        const _ToolTile(
          icon: Icons.calendar_month_outlined,
          color: AppColors.orange,
          title: 'Календарь погрузок',
          subtitle: 'День, неделя и свободные окна',
          badge: '3 завтра',
        ),
        const _ToolTile(
          icon: Icons.link_rounded,
          color: Color(0xFF00838B),
          title: 'Ссылки водителям',
          subtitle: 'Статусы и геопозиция без установки',
          badge: '2 активны',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Подготовлено к интеграциям',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 11),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  TinyTag(label: 'Контур.Логистика'),
                  TinyTag(label: 'Saby'),
                  TinyTag(label: '1С'),
                  TinyTag(label: 'ATI.SU'),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'В MVP данные не отправляются. Экспедитор сначала проверяет каждую заявку.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                badge,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                ),
              ),
              const SizedBox(height: 5),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 19,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
