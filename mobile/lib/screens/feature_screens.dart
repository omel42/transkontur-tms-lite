import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_store.dart';
import '../domain/models.dart';
import '../services/local_asr.dart';
import '../theme.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.store,
    required this.onOpenDocuments,
  });

  final AppStore store;
  final VoidCallback onOpenDocuments;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String filter = 'Все';
  final read = <int>{3, 4};

  static const items = [
    _Notice(
      title: 'Не хватает транспортной накладной',
      detail: 'ТК-1005 · водитель получил напоминание',
      time: '8 минут назад',
      kind: 'Документы',
      icon: Icons.description_outlined,
      color: AppColors.blue,
    ),
    _Notice(
      title: 'Машина ещё не назначена',
      detail: 'ТК-1008 · погрузка завтра в 08:30',
      time: '24 минуты назад',
      kind: 'Рейсы',
      icon: Icons.local_shipping_outlined,
      color: AppColors.orange,
    ),
    _Notice(
      title: 'Оплата просрочена на 2 дня',
      detail: 'СтройВектор · 112 000 ₽',
      time: 'Сегодня, 09:10',
      kind: 'Оплаты',
      icon: Icons.payments_outlined,
      color: AppColors.green,
    ),
    _Notice(
      title: 'Водитель отметил прибытие',
      detail: 'ТК-1007 · точка погрузки',
      time: 'Вчера, 18:42',
      kind: 'Рейсы',
      icon: Icons.location_on_outlined,
      color: Color(0xFF00838B),
    ),
    _Notice(
      title: 'Комплект документов проверен',
      detail: 'ТК-1004 · 5 из 5 документов',
      time: 'Вчера, 14:05',
      kind: 'Документы',
      icon: Icons.task_alt_rounded,
      color: AppColors.green,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible =
        filter == 'Все'
            ? items
            : items.where((item) => item.kind == filter).toList();
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Уведомления',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed:
                () => setState(
                  () => read.addAll(List.generate(items.length, (i) => i)),
                ),
            child: const Text(
              'Прочитать все',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['Все', 'Рейсы', 'Документы', 'Оплаты']
                      .map(
                        (name) => Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                            label: Text(name),
                            selected: filter == name,
                            selectedColor: AppColors.acid,
                            side: BorderSide.none,
                            onSelected: (_) => setState(() => filter = name),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 14),
          ...visible.map((item) {
            final index = items.indexOf(item);
            final isRead = read.contains(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  setState(() => read.add(index));
                  _openNotice(context, item);
                },
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : const Color(0xFFF7FFE7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isRead ? AppColors.line : AppColors.acid,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: item.color, size: 21),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.detail,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.time,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openNotice(BuildContext context, _Notice item) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: item.color, size: 34),
                const SizedBox(height: 13),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.detail,
                  style: const TextStyle(color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (item.kind == 'Документы') {
                        widget.onOpenDocuments();
                      } else {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('Открыто действие: ${item.title}'),
                          ),
                        );
                      }
                    },
                    child: Text(
                      item.kind == 'Документы'
                          ? 'Открыть документы'
                          : 'Открыть карточку',
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _Notice {
  const _Notice({
    required this.title,
    required this.detail,
    required this.time,
    required this.kind,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final String time;
  final String kind;
  final IconData icon;
  final Color color;
}

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.paper,
    appBar: AppBar(title: const Text('Деньги и оплаты')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: _MoneyMetric(
                label: 'Маржа в работе',
                value: money(store.monthMargin),
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: _MoneyMetric(
                label: 'К получению',
                value: '317 000 ₽',
                color: AppColors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionTitle(title: 'Расчёты по рейсам'),
        const SizedBox(height: 10),
        ...store.trips.map(
          (trip) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.number} · ${trip.client}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trip.route,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        money(trip.clientRate),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '+${money(trip.margin)} маржа',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _showPaymentDialog(context),
          icon: const Icon(Icons.add_card_rounded),
          label: const Text('Зафиксировать оплату'),
        ),
      ],
    ),
  );

  void _showPaymentDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Оплата зафиксирована'),
            content: const Text(
              'В демонстрации запись не меняет бухгалтерские данные. В рабочей версии она свяжется с рейсом и закроет напоминание.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Готово'),
              ),
            ],
          ),
    );
  }
}

class _MoneyMetric extends StatelessWidget {
  const _MoneyMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.store});
  final AppStore store;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime selectedDate = _day(DateTime.now());
  final reminders = <_CalendarEntry>[];

  DateTime get weekStart => selectedDate.subtract(
    Duration(days: selectedDate.weekday - DateTime.monday),
  );

  List<_CalendarEntry> _entries(DateTime date) {
    final entries = <_CalendarEntry>[];
    for (final trip in widget.store.trips) {
      if (_sameDay(trip.pickupAt, date)) {
        entries.add(
          _CalendarEntry(
            at: trip.pickupAt,
            type: 'Погрузка',
            color: AppColors.orange,
            title: '${trip.number} · ${trip.from}',
            detail:
                '${trip.client} · ${trip.carrier.isEmpty ? 'машина не назначена' : trip.driver}',
          ),
        );
      }
      final unloading = trip.pickupAt.add(const Duration(days: 1, hours: 5));
      if (_sameDay(unloading, date) && trip.status != TripStatus.done) {
        entries.add(
          _CalendarEntry(
            at: unloading,
            type: 'Выгрузка',
            color: AppColors.green,
            title: '${trip.number} · ${trip.to}',
            detail: '${trip.client} · плановое окно выгрузки',
          ),
        );
      }
    }
    entries.addAll(reminders.where((entry) => _sameDay(entry.at, date)));
    if (_sameDay(date, DateTime.now())) {
      for (final trip in widget.store.trips.where(
        (item) => item.status == TripStatus.documents,
      )) {
        entries.add(
          _CalendarEntry(
            at: DateTime(date.year, date.month, date.day, 16, 20),
            type: 'Документы',
            color: AppColors.blue,
            title: 'Документы ${trip.number}',
            detail: 'Проверить комплект и запросить недостающие файлы',
          ),
        );
      }
    }
    entries.sort((a, b) => a.at.compareTo(b.at));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    final entries = _entries(selectedDate);
    final loads = entries.where((entry) => entry.type == 'Погрузка').length;
    final unloads = entries.where((entry) => entry.type == 'Выгрузка').length;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text(
          'Календарь рейсов',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed:
                () => setState(() => selectedDate = _day(DateTime.now())),
            child: const Text('Сегодня'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            children: [
              IconButton(
                onPressed:
                    () => setState(
                      () =>
                          selectedDate = selectedDate.subtract(
                            const Duration(days: 7),
                          ),
                    ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  '${_month(selectedDate.month)} ${selectedDate.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    () => setState(
                      () =>
                          selectedDate = selectedDate.add(
                            const Duration(days: 7),
                          ),
                    ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 7),
              itemBuilder: (context, i) {
                final day = days[i];
                final active = _sameDay(selectedDate, day);
                final count = _entries(day).length;
                return SizedBox(
                  width: 58,
                  child: InkWell(
                    onTap: () => setState(() => selectedDate = day),
                    borderRadius: BorderRadius.circular(17),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: active ? AppColors.ink : Colors.white,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: active ? AppColors.ink : AppColors.line,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _weekday(day.weekday),
                            style: TextStyle(
                              color: active ? AppColors.cyan : AppColors.muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day.day.toString(),
                            style: TextStyle(
                              color: active ? Colors.white : AppColors.ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  count == 0
                                      ? Colors.transparent
                                      : active
                                      ? Colors.white.withValues(alpha: .18)
                                      : AppColors.blue.withValues(alpha: .1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count == 0 ? '·' : count.toString(),
                              style: TextStyle(
                                color: active ? Colors.white : AppColors.blue,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _DayMetric(
                label: 'Погрузки',
                value: loads,
                color: AppColors.orange,
              ),
              const SizedBox(width: 8),
              _DayMetric(
                label: 'Выгрузки',
                value: unloads,
                color: AppColors.green,
              ),
              const SizedBox(width: 8),
              _DayMetric(
                label: 'Всего',
                value: entries.length,
                color: AppColors.blue,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionTitle(
            title:
                '${selectedDate.day} ${_month(selectedDate.month).toLowerCase()}',
            count: entries.length.toString(),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: const Column(
                children: [
                  Icon(Icons.event_available_rounded, color: AppColors.muted),
                  SizedBox(height: 8),
                  Text('На этот день ничего не запланировано'),
                ],
              ),
            )
          else
            ...entries.map(
              (entry) => _ScheduleItem(
                time: _time(entry.at),
                type: entry.type,
                color: entry.color,
                title: entry.title,
                detail: entry.detail,
              ),
            ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _addReminder,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Добавить напоминание'),
          ),
        ],
      ),
    );
  }

  Future<void> _addReminder() async {
    final title = TextEditingController();
    var time = const TimeOfDay(hour: 14, minute: 0);
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Новое напоминание'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: title,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Что сделать',
                          hintText: 'Позвонить перевозчику',
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule_rounded),
                        title: Text('Время · ${time.format(context)}'),
                        onTap: () async {
                          final value = await showTimePicker(
                            context: context,
                            initialTime: time,
                          );
                          if (value != null) setDialogState(() => time = value);
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Отмена'),
                    ),
                    ElevatedButton(
                      onPressed:
                          () => Navigator.pop(
                            context,
                            title.text.trim().isNotEmpty,
                          ),
                      child: const Text('Добавить'),
                    ),
                  ],
                ),
          ),
    );
    if (saved == true) {
      reminders.add(
        _CalendarEntry(
          at: DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            time.hour,
            time.minute,
          ),
          type: 'Напоминание',
          color: AppColors.blue,
          title: title.text.trim(),
          detail: 'Личная задача экспедитора',
        ),
      );
      setState(() {});
    }
    title.dispose();
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  static String _weekday(int value) =>
      const ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'][value - 1];
  static String _month(int value) =>
      const [
        'Январь',
        'Февраль',
        'Март',
        'Апрель',
        'Май',
        'Июнь',
        'Июль',
        'Август',
        'Сентябрь',
        'Октябрь',
        'Ноябрь',
        'Декабрь',
      ][value - 1];
}

class _CalendarEntry {
  const _CalendarEntry({
    required this.at,
    required this.type,
    required this.color,
    required this.title,
    required this.detail,
  });
  final DateTime at;
  final String type;
  final Color color;
  final String title;
  final String detail;
}

class _DayMetric extends StatelessWidget {
  const _DayMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
          ),
        ],
      ),
    ),
  );
}

class _ScheduleItem extends StatelessWidget {
  const _ScheduleItem({
    required this.time,
    required this.type,
    required this.color,
    required this.title,
    required this.detail,
  });
  final String time;
  final String type;
  final Color color;
  final String title;
  final String detail;

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
          width: 54,
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            time,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
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
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                type.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class DriverLinksScreen extends StatelessWidget {
  const DriverLinksScreen({super.key, required this.store, this.initialTrip});
  final AppStore store;
  final Trip? initialTrip;

  @override
  Widget build(BuildContext context) {
    final trips = store.trips.where((trip) => trip.driver.isNotEmpty).toList();
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Связь с водителями')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Icon(Icons.link_rounded, color: AppColors.acid, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Водителю приходит простая ссылка: маршрут, статусы, геопозиция и загрузка фото — без установки приложения.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...trips.map(
            (trip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DriverLinkCard(
                trip: trip,
                highlighted: initialTrip?.id == trip.id,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverLinkCard extends StatelessWidget {
  const _DriverLinkCard({required this.trip, required this.highlighted});
  final Trip trip;
  final bool highlighted;

  String get link =>
      'https://go.reys.dev/${trip.id.substring(0, trip.id.length.clamp(1, 8))}';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: highlighted ? AppColors.acid : AppColors.line,
        width: highlighted ? 2 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${trip.number} · ${trip.driver}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const TinyTag(label: 'ССЫЛКА АКТИВНА'),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${trip.route} · ${trip.truckPlate}',
          style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ссылка водителю скопирована'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Копировать'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DriverTrackingScreen(trip: trip),
                      ),
                    ),
                icon: const Icon(Icons.near_me_rounded),
                label: const Text('Открыть'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class DriverTrackingScreen extends StatelessWidget {
  const DriverTrackingScreen({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.paper,
    appBar: AppBar(title: Text('${trip.number} · водитель')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: const Color(0xFFDCE7E2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoutePainter(progress: trip.progress),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '${(trip.progress * 100).round()}% маршрута',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const Center(
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.green,
                  size: 38,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              _InfoLine(label: 'Водитель', value: trip.driver),
              _InfoLine(label: 'Телефон', value: trip.driverPhone),
              _InfoLine(label: 'Машина', value: trip.truckPlate),
              _InfoLine(label: 'Последнее событие', value: trip.lastEvent),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed:
              () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Водителю отправлен запрос геопозиции'),
                ),
              ),
          icon: const Icon(Icons.location_searching_rounded),
          label: const Text('Запросить актуальную точку'),
        ),
        const SizedBox(height: 9),
        OutlinedButton.icon(
          onPressed:
              () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Водителю отправлено напоминание о документах'),
                ),
              ),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Попросить фото документов'),
        ),
      ],
    ),
  );
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final grid =
        Paint()
          ..color = const Color(0xFFCBD8D2)
          ..strokeWidth = 1;
    for (var x = 20.0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 20.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final route =
        Path()
          ..moveTo(28, size.height - 45)
          ..cubicTo(
            size.width * .3,
            size.height * .2,
            size.width * .62,
            size.height * .85,
            size.width - 28,
            42,
          );
    canvas.drawPath(
      route,
      Paint()
        ..color = AppColors.green
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(28, size.height - 45),
      8,
      Paint()..color = AppColors.acid,
    );
    canvas.drawCircle(
      Offset(size.width - 28, 42),
      8,
      Paint()..color = AppColors.ink,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class VoiceSettingsScreen extends StatelessWidget {
  const VoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = createLocalAsrEngine();
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Голосовой ввод')),
      body: FutureBuilder<AsrReadiness>(
        future: engine.readiness(),
        builder: (context, snapshot) {
          final local = snapshot.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _VoiceModeCard(
                icon: Icons.android_rounded,
                title: 'Распознавание Android',
                subtitle:
                    'Работает сейчас · русский язык · результат сразу попадает в форму',
                color: AppColors.green,
                active: true,
              ),
              const SizedBox(height: 10),
              _VoiceModeCard(
                icon: Icons.memory_rounded,
                title: 'Локальная Qwen3-ASR 0.6B',
                subtitle: local?.detail ?? 'Проверяем файлы модели…',
                color:
                    local?.ready == true ? AppColors.green : AppColors.orange,
                active: local?.ready == true,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Как это работает',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 10),
                    _Step(
                      text:
                          'Нажмите микрофон и расскажите условия рейса обычной речью.',
                    ),
                    _Step(
                      text:
                          'Речь превращается в текст, маршрут, груз, дата и ставки выделяются автоматически.',
                    ),
                    _Step(
                      text:
                          'Экспедитор проверяет поля — без проверки ничего не отправляется.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VoiceModeCard extends StatelessWidget {
  const _VoiceModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.active,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(
        color: active ? color : AppColors.line,
        width: active ? 1.5 : 1,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (active) const TinyTag(label: 'АКТИВЕН'),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10.5,
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

class _Step extends StatelessWidget {
  const _Step({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.green,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11.5, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});
  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  final enabled = <String>{'1С'};

  @override
  Widget build(BuildContext context) {
    const integrations = [
      ('Госключ', 'КЭП / НЭП на телефоне и статус подписания'),
      ('Оператор ИС ЭПД', 'Передача XML в ГИС ЭПД'),
      ('1С', 'Клиенты, счета и закрывающие'),
      ('ATI.SU', 'Поиск машин и ставки'),
      ('ЭДО', 'Документы, подписи и статусы обмена'),
    ];
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Интеграции')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text(
            'В демо переключатели показывают будущую настройку. Реальные ключи и отправка не используются.',
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 14),
          ...integrations.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.hub_outlined,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: enabled.contains(item.$1),
                    activeColor: AppColors.green,
                    onChanged:
                        (value) => setState(() {
                          if (value) {
                            enabled.add(item.$1);
                          } else {
                            enabled.remove(item.$1);
                          }
                        }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
          ),
        ),
      ],
    ),
  );
}
