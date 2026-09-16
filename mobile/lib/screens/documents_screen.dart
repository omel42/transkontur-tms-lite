import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../data/app_store.dart';
import '../domain/models.dart';
import '../services/document_factory.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, required this.store, this.initialTrip});

  final AppStore store;
  final Trip? initialTrip;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Trip selected = widget.initialTrip ?? widget.store.trips.first;

  @override
  Widget build(BuildContext context) {
    final documents = TransportDocumentKind.values;
    final readyCount =
        documents
            .where((kind) => DocumentFactory.readiness(selected, kind).ready)
            .length;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Документы рейса',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
        children: [
          _LawCard(),
          const SizedBox(height: 15),
          _TripSelector(
            trips: widget.store.trips,
            selected: selected,
            onChanged: (trip) => setState(() => selected = trip),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(23),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$readyCount из ${documents.length} готовы',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const TinyStatus(text: 'АВТОЗАПОЛНЕНИЕ'),
                  ],
                ),
                const SizedBox(height: 7),
                const Text(
                  'Одна карточка рейса заполняет весь комплект. Вы проверяете только подсвеченные поля.',
                  style: TextStyle(
                    color: Color(0xFFAAB5BC),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: readyCount / documents.length,
                    minHeight: 7,
                    color: AppColors.acid,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle(title: 'Комплект по рейсу'),
          const SizedBox(height: 10),
          ...documents.map(
            (kind) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DocumentCard(
                trip: selected,
                kind: kind,
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => DocumentDetailScreen(
                              trip: selected,
                              kind: kind,
                            ),
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showPackage(context, readyCount),
            icon: const Icon(Icons.task_alt_rounded),
            label: const Text('Проверить весь комплект'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _showExchange(context),
            icon: const Icon(Icons.hub_outlined),
            label: const Text('Как уйдёт в ГИС ЭПД'),
          ),
        ],
      ),
    );
  }

  void _showPackage(BuildContext context, int readyCount) {
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
                const Text(
                  'Проверка комплекта завершена',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  '$readyCount документов готовы к подписанию. Остальные сохранены как черновики — приложение показывает, каких данных не хватает.',
                  style: const TextStyle(color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 18),
                _FlowLine(
                  number: '1',
                  title: 'Проверить реквизиты',
                  done: true,
                ),
                _FlowLine(
                  number: '2',
                  title: 'Подписать электронной подписью',
                  done: readyCount == TransportDocumentKind.values.length,
                ),
                const _FlowLine(
                  number: '3',
                  title: 'Передать через оператора ИС ЭПД',
                  done: false,
                ),
              ],
            ),
          ),
    );
  }

  void _showExchange(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Обмен без ручной перепечатки'),
            content: const Text(
              'Приложение формирует XML установленного формата. После проверки и электронной подписи файл передаётся оператору ИС ЭПД, а оператор — в ГИС ЭПД. PDF остаётся удобной копией для просмотра и печати.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Понятно'),
              ),
            ],
          ),
    );
  }
}

class _LawCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFE9F7EF),
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: AppColors.green.withValues(alpha: .18)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.verified_user_outlined, color: AppColors.green),
        SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ЭПД обязателен с 1 сентября 2026',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
              ),
              SizedBox(height: 4),
              Text(
                'Для автоперевозок электронными становятся транспортная накладная, заказ / заявка и экспедиторские документы. Обмен идёт через аккредитованного оператора ИС ЭПД.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10.8,
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

class _TripSelector extends StatelessWidget {
  const _TripSelector({
    required this.trips,
    required this.selected,
    required this.onChanged,
  });

  final List<Trip> trips;
  final Trip selected;
  final ValueChanged<Trip> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<Trip>(
        value: selected,
        isExpanded: true,
        borderRadius: BorderRadius.circular(18),
        icon: const Icon(Icons.expand_more_rounded),
        items:
            trips
                .map(
                  (trip) => DropdownMenuItem(
                    value: trip,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.number} · ${trip.route}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          trip.client,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
        onChanged: (trip) {
          if (trip != null) onChanged(trip);
        },
      ),
    ),
  );
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.trip,
    required this.kind,
    required this.onTap,
  });

  final Trip trip;
  final TransportDocumentKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = DocumentFactory.readiness(trip, kind);
    final color = state.ready ? AppColors.green : AppColors.orange;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                state.ready ? Icons.description_rounded : Icons.edit_document,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind.shortTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    kind.format,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.ready
                        ? 'Заполнено автоматически'
                        : 'Уточнить: ${state.missing.take(2).join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({
    super.key,
    required this.trip,
    required this.kind,
  });

  final Trip trip;
  final TransportDocumentKind kind;

  @override
  Widget build(BuildContext context) {
    final state = DocumentFactory.readiness(trip, kind);
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        title: Text(
          kind.shortTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (state.ready
                                ? AppColors.green
                                : AppColors.orange)
                            .withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        state.ready ? 'ГОТОВО К ПРОВЕРКЕ' : 'ЧЕРНОВИК',
                        style: TextStyle(
                          color:
                              state.ready ? AppColors.green : AppColors.orange,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      trip.number,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  kind.title,
                  style: const TextStyle(
                    fontSize: 23,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  kind.purpose,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const Divider(height: 30, color: AppColors.line),
                _PreviewLine(label: 'Маршрут', value: trip.route),
                _PreviewLine(
                  label: 'Груз',
                  value: '${trip.cargo} · ${weight(trip.weight)} т',
                ),
                _PreviewLine(label: 'Клиент', value: trip.client),
                _PreviewLine(
                  label: 'Перевозчик',
                  value: trip.carrier.isEmpty ? 'Не назначен' : trip.carrier,
                ),
                _PreviewLine(label: 'Ставка', value: money(trip.clientRate)),
                _PreviewLine(label: 'Формат', value: kind.format),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    const TinyTag(label: 'Автозаполнение'),
                    TinyTag(label: kind.format),
                    if (kind.isEpd) const TinyTag(label: 'ЭПД'),
                  ],
                ),
              ],
            ),
          ),
          if (!state.ready) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Перед подписанием нужно добавить: ${state.missing.join(', ')}. Предпросмотр и экспорт черновика уже доступны.',
                style: const TextStyle(
                  color: Color(0xFF8A5525),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DocumentPdfScreen(trip: trip, kind: kind),
                  ),
                ),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Открыть заполненный PDF'),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      () => Printing.layoutPdf(
                        name: DocumentFactory.fileName(trip, kind),
                        onLayout: (_) => DocumentFactory.buildPdf(trip, kind),
                      ),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Печать'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final data = await DocumentFactory.buildPdf(trip, kind);
                    await Printing.sharePdf(
                      bytes: data,
                      filename: DocumentFactory.fileName(trip, kind),
                    );
                  },
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Поделиться'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: () => _showXml(context),
            icon: const Icon(Icons.code_rounded),
            label: Text(
              kind.isEpd ? 'Показать XML для ИС ЭПД' : 'Показать XML',
            ),
          ),
          const SizedBox(height: 9),
          FilledButton.tonalIcon(
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => SigningFlowScreen(
                          trip: trip,
                          kind: kind,
                          readiness: state,
                        ),
                  ),
                ),
            icon: const Icon(Icons.draw_outlined),
            label: const Text('Проверить и подписать'),
          ),
        ],
      ),
    );
  }

  void _showXml(BuildContext context) {
    final xml = DocumentFactory.buildXml(trip, kind);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder:
          (context) => SizedBox(
            height: MediaQuery.sizeOf(context).height * .78,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Машиночитаемый XML',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Демонстрационная структура. В боевой интеграции версия и XSD берутся у оператора ИС ЭПД.',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          xml,
                          style: const TextStyle(
                            color: Color(0xFFCDE8D8),
                            fontFamily: 'monospace',
                            fontSize: 10,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: xml));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('XML скопирован')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Скопировать XML'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class SigningFlowScreen extends StatefulWidget {
  const SigningFlowScreen({
    super.key,
    required this.trip,
    required this.kind,
    required this.readiness,
  });

  final Trip trip;
  final TransportDocumentKind kind;
  final DocumentReadiness readiness;

  @override
  State<SigningFlowScreen> createState() => _SigningFlowScreenState();
}

class _SigningFlowScreenState extends State<SigningFlowScreen> {
  bool employee = false;
  bool certificateConnected = false;
  bool powerOfAttorney = false;
  String operatorName = 'Оператор ИС ЭПД (демо)';
  bool prepared = false;
  bool signed = false;

  bool get canPrepare =>
      widget.readiness.ready &&
      certificateConnected &&
      (!employee || powerOfAttorney);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.paper,
    appBar: AppBar(
      backgroundColor: AppColors.paper,
      title: const Text(
        'Подпись и отправка',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(23),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.security_rounded, color: AppColors.cyan),
              const SizedBox(height: 12),
              Text(
                '${widget.kind.shortTitle} · ${widget.trip.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.kind.isEpd
                    ? 'Телефон готовит XML и отправляет его через API оператора в «Госключ». Ключ остаётся в государственном приложении. После подтверждения подпись возвращается оператору ИС ЭПД.'
                    : 'Телефон готовит файл, отправляет его в «Госключ» и получает статус подписания через оператора ЭДО.',
                style: const TextStyle(
                  color: Color(0xFFB6C3CB),
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle(title: 'Кто подписывает'),
        const SizedBox(height: 9),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.business_center_outlined),
              label: Text('Руководитель'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.badge_outlined),
              label: Text('Сотрудник'),
            ),
          ],
          selected: {employee},
          onSelectionChanged:
              (value) => setState(() {
                employee = value.first;
                if (!employee) powerOfAttorney = false;
                prepared = false;
                signed = false;
              }),
        ),
        const SizedBox(height: 13),
        _SigningCheck(
          icon: Icons.key_rounded,
          title:
              employee
                  ? '«Госключ»: КЭП сотрудника'
                  : '«Госключ»: КЭП организации / ИП',
          detail:
              certificateConnected
                  ? 'Учётная запись связана · сертификат доступен'
                  : 'Связать ЕСИА и выбрать сертификат через оператора',
          checked: certificateConnected,
          onTap:
              () => setState(() {
                certificateConnected = !certificateConnected;
                prepared = false;
                signed = false;
              }),
        ),
        if (employee) ...[
          const SizedBox(height: 9),
          _SigningCheck(
            icon: Icons.assignment_ind_outlined,
            title: 'Машиночитаемая доверенность',
            detail:
                powerOfAttorney
                    ? 'МЧД найдена · полномочия приложены'
                    : 'Для представителя ООО полномочия подтверждаются МЧД',
            checked: powerOfAttorney,
            onTap:
                () => setState(() {
                  powerOfAttorney = !powerOfAttorney;
                  prepared = false;
                  signed = false;
                }),
          ),
        ],
        const SizedBox(height: 18),
        const SectionTitle(title: 'Канал обмена'),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          value: operatorName,
          decoration: const InputDecoration(labelText: 'Оператор ИС ЭПД'),
          items: const [
            DropdownMenuItem(
              value: 'Оператор ИС ЭПД (демо)',
              child: Text('Оператор ИС ЭПД (демо)'),
            ),
            DropdownMenuItem(
              value: 'СБИС / Saby EDO',
              child: Text('СБИС / Saby EDO'),
            ),
            DropdownMenuItem(
              value: 'Другой аккредитованный оператор',
              child: Text('Другой оператор'),
            ),
          ],
          onChanged:
              (value) => setState(() {
                operatorName = value ?? operatorName;
                prepared = false;
                signed = false;
              }),
        ),
        const SizedBox(height: 16),
        _ExchangeStep(
          number: '1',
          title: 'Проверка обязательных полей',
          done: widget.readiness.ready,
        ),
        _ExchangeStep(
          number: '2',
          title: 'Задание отправлено в «Госключ»',
          done: prepared,
        ),
        _ExchangeStep(
          number: '3',
          title: 'Пользователь подтвердил подпись',
          done: signed,
        ),
        _ExchangeStep(
          number: '4',
          title: 'Подпись и сертификат получены оператором',
          done: signed,
        ),
        _ExchangeStep(number: '5', title: 'Квитанция ГИС ЭПД', done: false),
        if (!widget.readiness.ready) ...[
          const SizedBox(height: 8),
          Text(
            'Не хватает: ${widget.readiness.missing.join(', ')}.',
            style: const TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (!prepared)
          ElevatedButton.icon(
            onPressed:
                canPrepare
                    ? () => setState(() {
                      prepared = true;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Демо: задание отправлено. В бою документ появится в «Госключе».',
                          ),
                        ),
                      );
                    })
                    : null,
            icon: const Icon(Icons.send_to_mobile_rounded),
            label: const Text('Отправить в «Госключ»'),
          )
        else if (!signed)
          ElevatedButton.icon(
            onPressed:
                () => setState(() {
                  signed = true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Демо: оператор получил подпись и сертификат подписанта',
                      ),
                    ),
                  );
                }),
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Проверить статус подписи'),
          )
        else
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, color: AppColors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Подпись получена. Документ готов к проверке оператором ИС ЭПД.',
                    style: TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 9),
        const Text(
          'В MVP показан сценарий без реальной отправки. В продакшене приложение передаёт файл через API оператора или интеграцию «Госключа», проверяет статус и получает отделённую подпись. Закрытый ключ в «РЕЙС» не попадает. Для подписи сотрудника ООО может потребоваться МЧД.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 10.5, height: 1.4),
        ),
      ],
    ),
  );
}

class _SigningCheck extends StatelessWidget {
  const _SigningCheck({
    required this.icon,
    required this.title,
    required this.detail,
    required this.checked,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String detail;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Ink(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: checked ? AppColors.green : AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: checked ? AppColors.green : AppColors.muted),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            checked
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: checked ? AppColors.green : AppColors.muted,
          ),
        ],
      ),
    ),
  );
}

class _ExchangeStep extends StatelessWidget {
  const _ExchangeStep({
    required this.number,
    required this.title,
    required this.done,
  });
  final String number;
  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: done ? AppColors.green : AppColors.line,
          child: Text(
            done ? '✓' : number,
            style: TextStyle(
              color: done ? Colors.white : AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ],
    ),
  );
}

class DocumentPdfScreen extends StatelessWidget {
  const DocumentPdfScreen({super.key, required this.trip, required this.kind});

  final Trip trip;
  final TransportDocumentKind kind;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        '${kind.shortTitle} · ${trip.number}',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
      ),
    ),
    body: PdfPreview(
      build: (_) => DocumentFactory.buildPdf(trip, kind),
      pdfFileName: DocumentFactory.fileName(trip, kind),
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      allowPrinting: true,
      allowSharing: true,
      loadingWidget: const Center(child: CircularProgressIndicator()),
    ),
  );
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 98,
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

class TinyStatus extends StatelessWidget {
  const TinyStatus({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.acid,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _FlowLine extends StatelessWidget {
  const _FlowLine({
    required this.number,
    required this.title,
    required this.done,
  });

  final String number;
  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: done ? AppColors.acid : AppColors.paper,
          child: Text(
            done ? '✓' : number,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}
