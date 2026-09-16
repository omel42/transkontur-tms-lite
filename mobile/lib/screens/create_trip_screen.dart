import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/app_store.dart';
import '../domain/models.dart';
import '../services/local_asr.dart';
import '../services/note_parser.dart';
import '../theme.dart';
import 'documents_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key, required this.store});
  final AppStore store;

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  static const demoNote =
      'НордПром, Москва — Казань, завтра к 9 утра, оборудование 20 тонн, нужен тент. Клиент даёт 150 тысяч, перевозчику 118 тысяч.';

  final parser = NoteParser();
  final asr = createLocalAsrEngine();
  final recorder = AudioRecorder();
  final speech = SpeechToText();
  final note = TextEditingController();
  final fields = <String, TextEditingController>{};
  Timer? timer;
  int stage = 0;
  int mode = 0;
  int seconds = 0;
  bool recording = false;
  bool processing = false;
  bool usingSystemSpeech = false;
  bool finishQueued = false;
  Trip? created;

  @override
  void initState() {
    super.initState();
    note.text = widget.store.draft.sourceText;
    _fill(widget.store.draft);
  }

  @override
  void dispose() {
    timer?.cancel();
    speech.cancel();
    recorder.dispose();
    note.dispose();
    for (final item in fields.values) {
      item.dispose();
    }
    super.dispose();
  }

  TextEditingController f(String name) =>
      fields.putIfAbsent(name, TextEditingController.new);

  void _fill(TripDraft draft) {
    final values = <String, String>{
      'from': draft.from,
      'to': draft.to,
      'cargo': draft.cargo,
      'weight': draft.weight == 0 ? '' : weight(draft.weight),
      'vehicle': draft.vehicle,
      'date': draft.pickupDate,
      'time': draft.pickupTime,
      'client': draft.client,
      'clientPhone': draft.clientPhone,
      'clientRate': draft.clientRate == 0 ? '' : draft.clientRate.toString(),
      'carrier': draft.carrier,
      'carrierRate': draft.carrierRate == 0 ? '' : draft.carrierRate.toString(),
      'driver': draft.driver,
      'driverPhone': draft.driverPhone,
      'plate': draft.truckPlate,
      'pickupAddress': draft.pickupAddress,
      'deliveryAddress': draft.deliveryAddress,
      'comment': draft.comment,
    };
    for (final value in values.entries) {
      f(value.key).text = value.value;
    }
  }

  TripDraft _draft() => TripDraft(
    from: f('from').text.trim(),
    to: f('to').text.trim(),
    cargo: f('cargo').text.trim(),
    weight: double.tryParse(f('weight').text.replaceAll(',', '.')) ?? 0,
    vehicle: f('vehicle').text.trim(),
    pickupDate: f('date').text.trim(),
    pickupTime: f('time').text.trim(),
    client: f('client').text.trim(),
    clientPhone: f('clientPhone').text.trim(),
    clientRate:
        int.tryParse(f('clientRate').text.replaceAll(RegExp(r'\D'), '')) ?? 0,
    carrier: f('carrier').text.trim(),
    carrierRate:
        int.tryParse(f('carrierRate').text.replaceAll(RegExp(r'\D'), '')) ?? 0,
    driver: f('driver').text.trim(),
    driverPhone: f('driverPhone').text.trim(),
    truckPlate: f('plate').text.trim(),
    pickupAddress: f('pickupAddress').text.trim(),
    deliveryAddress: f('deliveryAddress').text.trim(),
    comment: f('comment').text.trim(),
    sourceText: note.text.trim(),
  );

  void _analyze() {
    final text = note.text.trim().isEmpty ? demoNote : note.text.trim();
    note.text = text;
    final draft = parser.parse(text, now: DateTime.now());
    widget.store.updateDraft(draft);
    _fill(draft);
    setState(() => stage = 1);
  }

  void _manual() {
    _fill(widget.store.draft);
    setState(() => stage = 1);
  }

  Future<void> _toggleRecording() async {
    if (recording) {
      if (usingSystemSpeech) {
        await speech.stop();
        await _finishSystemSpeech();
        return;
      }
      timer?.cancel();
      final path = await recorder.stop();
      if (!mounted) return;
      setState(() {
        recording = false;
        processing = true;
      });
      String transcript = '';
      try {
        final state = await asr.readiness();
        if (state.ready && path != null) {
          transcript = await asr.transcribe(path);
        }
      } catch (_) {}
      if (transcript.isEmpty) {
        if (!mounted) return;
        setState(() => processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Речь не распознана. Попробуйте ещё раз или вставьте текст.',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      note.text = transcript;
      setState(() => processing = false);
      _analyze();
      return;
    }
    final localState = await asr.readiness();
    if (!localState.ready) {
      await _startSystemSpeech();
      return;
    }
    if (!await recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Разрешите доступ к микрофону.')),
        );
      }
      return;
    }
    var path = '';
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      path = '${dir.path}/transkontur_note.wav';
    }
    await recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    setState(() {
      recording = true;
      seconds = 0;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => seconds++);
    });
  }

  Future<void> _startSystemSpeech() async {
    finishQueued = false;
    final available = await speech.initialize(
      onStatus: (status) {
        if ((status == SpeechToText.doneStatus ||
                status == SpeechToText.notListeningStatus) &&
            recording &&
            usingSystemSpeech) {
          Future<void>.delayed(
            const Duration(milliseconds: 350),
            _finishSystemSpeech,
          );
        }
      },
      onError: _onSpeechError,
    );
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'На телефоне недоступна служба распознавания речи. Проверьте разрешение микрофона.',
          ),
        ),
      );
      return;
    }
    final locales = await speech.locales();
    final russian = locales.where(
      (locale) => locale.localeId.toLowerCase().startsWith('ru'),
    );
    final localeId = russian.isEmpty ? null : russian.first.localeId;
    note.clear();
    if (!mounted) return;
    setState(() {
      usingSystemSpeech = true;
      recording = true;
      processing = false;
      seconds = 0;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && recording) setState(() => seconds++);
    });
    await speech.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 4),
      ),
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() => note.text = result.recognizedWords.trim());
    if (result.finalResult) {
      Future<void>.delayed(
        const Duration(milliseconds: 250),
        _finishSystemSpeech,
      );
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    timer?.cancel();
    if (!mounted) return;
    setState(() {
      recording = false;
      processing = false;
      usingSystemSpeech = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.errorMsg == 'error_no_match'
              ? 'Не расслышал речь. Нажмите микрофон и попробуйте ещё раз.'
              : 'Ошибка распознавания: ${error.errorMsg}',
        ),
      ),
    );
  }

  Future<void> _finishSystemSpeech() async {
    if (finishQueued || !usingSystemSpeech) return;
    finishQueued = true;
    timer?.cancel();
    if (speech.isListening) await speech.stop();
    if (!mounted) return;
    setState(() {
      recording = false;
      processing = note.text.trim().isNotEmpty;
      usingSystemSpeech = false;
    });
    if (note.text.trim().isEmpty) {
      setState(() => processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не расслышал речь. Попробуйте ещё раз.')),
      );
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => processing = false);
    _analyze();
  }

  void _save() {
    final draft = _draft();
    if (draft.missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Проверьте: ${draft.missingFields.join(', ')}')),
      );
      return;
    }
    created = widget.store.createTrip(draft);
    setState(() => stage = 2);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: stage == 0 ? AppColors.ink : AppColors.paper,
    appBar: AppBar(
      backgroundColor: stage == 0 ? AppColors.ink : AppColors.paper,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.close_rounded,
          color: stage == 0 ? Colors.white : AppColors.ink,
        ),
      ),
      title: Text(
        stage == 0
            ? 'Новый рейс'
            : stage == 1
            ? 'Проверка заявки'
            : 'Готово',
        style: TextStyle(
          color: stage == 0 ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
      centerTitle: true,
      actions: [
        if (stage == 1)
          TextButton(
            onPressed: () => setState(() => stage = 0),
            child: const Text(
              'Назад',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child:
            stage == 0
                ? _capture()
                : stage == 1
                ? _review()
                : _success(),
      ),
    ),
  );

  Widget _capture() => ListView(
    key: const ValueKey('capture'),
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
    children: [
      const Text(
        'Как удобно\nсоздать рейс?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 35,
          height: 1.02,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.3,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Не заполняйте всё подряд. Расскажите главное — приложение само подготовит форму.',
        style: TextStyle(color: Color(0xFF9DABB4), fontSize: 14, height: 1.45),
      ),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ModeButton(
                label: 'Голосом',
                icon: Icons.mic_rounded,
                selected: mode == 0,
                onTap: () => setState(() => mode = 0),
              ),
            ),
            Expanded(
              child: _ModeButton(
                label: 'Из текста',
                icon: Icons.notes_rounded,
                selected: mode == 1,
                onTap: () => setState(() => mode = 1),
              ),
            ),
            Expanded(
              child: _ModeButton(
                label: 'Вручную',
                icon: Icons.tune_rounded,
                selected: mode == 2,
                onTap: () => setState(() => mode = 2),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 25),
      if (mode == 0) _voiceMode(),
      if (mode == 1) _textMode(),
      if (mode == 2) _manualMode(),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.tips_and_updates_outlined,
              color: AppColors.acid,
              size: 21,
            ),
            SizedBox(width: 11),
            Expanded(
              child: Text(
                'Можно сказать не всё. Мы подсветим только недостающие данные — ничего не отправится без вашей проверки.',
                style: TextStyle(
                  color: Color(0xFFB4C0C6),
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _voiceMode() => Column(
    children: [
      GestureDetector(
        onTap: processing ? null : _toggleRecording,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: recording ? 174 : 154,
          height: recording ? 174 : 154,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: recording ? const Color(0xFFFF775F) : AppColors.acid,
            boxShadow: [
              BoxShadow(
                color: (recording ? const Color(0xFFFF775F) : AppColors.acid)
                    .withValues(alpha: .28),
                blurRadius: recording ? 50 : 32,
                spreadRadius: recording ? 10 : 2,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: .18),
              width: 7,
            ),
          ),
          child: Icon(
            recording
                ? Icons.stop_rounded
                : processing
                ? Icons.more_horiz_rounded
                : Icons.mic_rounded,
            color: AppColors.ink,
            size: 54,
          ),
        ),
      ),
      const SizedBox(height: 18),
      Text(
        recording
            ? 'Слушаю · 00:${seconds.toString().padLeft(2, '0')}'
            : processing
            ? 'Разбираю речь и заполняю…'
            : 'Нажмите и расскажите',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        recording
            ? 'Нажмите ещё раз, когда закончите'
            : 'Например: Москва — Казань, завтра, 20 тонн…',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF8F9EA7), fontSize: 12),
      ),
      if (recording && note.text.trim().isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            note.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
      const SizedBox(height: 22),
      TextButton.icon(
        onPressed:
            processing
                ? null
                : () {
                  note.text = demoNote;
                  _analyze();
                },
        icon: const Icon(
          Icons.play_circle_outline_rounded,
          color: AppColors.cyan,
        ),
        label: const Text(
          'Показать на примере',
          style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );

  Widget _textMode() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: note,
        maxLines: 7,
        style: const TextStyle(fontSize: 15, height: 1.45),
        decoration: const InputDecoration(
          hintText:
              'Вставьте сообщение клиента, заметку после звонка или текст из мессенджера…',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 11),
      Wrap(
        spacing: 7,
        children: [
          ActionChip(
            label: const Text('Вставить пример'),
            avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
            onPressed: () => setState(() => note.text = demoNote),
          ),
          ActionChip(
            label: const Text('Из буфера'),
            avatar: const Icon(Icons.content_paste_rounded, size: 16),
            onPressed: () async {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null) setState(() => note.text = data!.text!);
            },
          ),
        ],
      ),
      const SizedBox(height: 18),
      ElevatedButton.icon(
        onPressed: _analyze,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.acid,
          foregroundColor: AppColors.ink,
        ),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Разобрать и заполнить'),
      ),
    ],
  );

  Widget _manualMode() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.acid.withValues(alpha: .35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.edit_note_rounded,
            color: AppColors.ink,
            size: 29,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Обычная форма — только без лишнего',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        const Text(
          'Сначала обязательные поля. Водителя, документы и точные адреса можно добавить позже.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 18),
        ElevatedButton(onPressed: _manual, child: const Text('Открыть форму')),
      ],
    ),
  );

  Widget _review() {
    final draft = _draft();
    return ListView(
      key: const ValueKey('review'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      children: [
        if (note.text.isNotEmpty)
          _RecognizedNote(text: note.text, missing: draft.missingFields.length),
        const SizedBox(height: 14),
        _FormSection(
          number: '01',
          title: 'Маршрут и погрузка',
          subtitle: 'Основа рейса',
          children: [
            Row(
              children: [
                Expanded(child: _input('Откуда', 'from', hint: 'Москва')),
                const SizedBox(width: 10),
                Expanded(child: _input('Куда', 'to', hint: 'Казань')),
              ],
            ),
            const SizedBox(height: 9),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Suggestion(
                    label: 'Москва → Казань',
                    onTap:
                        () => setState(() {
                          f('from').text = 'Москва';
                          f('to').text = 'Казань';
                        }),
                  ),
                  _Suggestion(
                    label: 'Москва → Екатеринбург',
                    onTap:
                        () => setState(() {
                          f('from').text = 'Москва';
                          f('to').text = 'Екатеринбург';
                        }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(child: _input('Дата', 'date', hint: '17.09.2026')),
                const SizedBox(width: 10),
                Expanded(child: _input('Время', 'time', hint: '09:00')),
              ],
            ),
            const SizedBox(height: 9),
            _input(
              'Адрес погрузки',
              'pickupAddress',
              hint: 'Можно добавить позже',
            ),
            const SizedBox(height: 9),
            _input(
              'Адрес выгрузки',
              'deliveryAddress',
              hint: 'Можно добавить позже',
            ),
          ],
        ),
        _FormSection(
          number: '02',
          title: 'Груз и машина',
          subtitle: 'Что требуется',
          children: [
            _input('Груз', 'cargo', hint: 'Оборудование'),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _input(
                    'Вес, т',
                    'weight',
                    hint: '20',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _input('Тип машины', 'vehicle', hint: 'Тент')),
              ],
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children:
                  ['Тент', 'Рефрижератор', 'Изотерм', 'Бортовой']
                      .map(
                        (value) => ActionChip(
                          label: Text(value),
                          onPressed:
                              () => setState(() => f('vehicle').text = value),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
        _FormSection(
          number: '03',
          title: 'Клиент и экономика',
          subtitle: 'Сразу видим прибыль',
          children: [
            _input('Клиент', 'client', hint: 'Название компании'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    widget.store.clients
                        .take(3)
                        .map(
                          (client) => _Suggestion(
                            label: client.name,
                            onTap:
                                () => setState(() {
                                  f('client').text = client.name;
                                  f('clientPhone').text = client.phone;
                                }),
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 9),
            _input(
              'Телефон клиента',
              'clientPhone',
              hint: '+7 900 000-00-00',
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _input(
                    'Ставка клиента, ₽',
                    'clientRate',
                    hint: '150 000',
                    keyboard: TextInputType.number,
                    changed: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _input(
                    'Перевозчику, ₽',
                    'carrierRate',
                    hint: '118 000',
                    keyboard: TextInputType.number,
                    changed: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Margin(
              clientRate:
                  int.tryParse(
                    f('clientRate').text.replaceAll(RegExp(r'\D'), ''),
                  ) ??
                  0,
              carrierRate:
                  int.tryParse(
                    f('carrierRate').text.replaceAll(RegExp(r'\D'), ''),
                  ) ??
                  0,
            ),
          ],
        ),
        _FormSection(
          number: '04',
          title: 'Перевозчик',
          subtitle: 'Предложения из своей базы',
          children: [
            ...widget.store.carriers
                .take(3)
                .map(
                  (carrier) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CarrierRow(
                      carrier: carrier,
                      selected: f('carrier').text == carrier.name,
                      onTap:
                          () => setState(() {
                            f('carrier').text = carrier.name;
                            f('driver').text = carrier.contact;
                            f('driverPhone').text = carrier.phone;
                            if (f('carrierRate').text.isEmpty) {
                              f('carrierRate').text =
                                  carrier.name.contains('Ковалёв')
                                      ? '118000'
                                      : '122000';
                            }
                          }),
                    ),
                  ),
                ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Водитель и машина',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              children: [
                _input('Водитель', 'driver', hint: 'ФИО'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _input(
                        'Телефон',
                        'driverPhone',
                        hint: '+7…',
                        keyboard: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _input('Госномер', 'plate', hint: 'А000АА 77'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const _FormSection(
          number: '05',
          title: 'После сохранения',
          subtitle: 'Подготовим автоматически',
          children: [
            _Automation(
              icon: Icons.description_outlined,
              title: 'Заявка и PDF',
              detail: 'Готово для проверки и печати',
            ),
            _Automation(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Поручение экспедитору',
              detail: 'Черновик по данным рейса',
            ),
            _Automation(
              icon: Icons.link_rounded,
              title: 'Ссылка водителю',
              detail: 'Маршрут, статусы и фото',
            ),
            _Automation(
              icon: Icons.notifications_active_outlined,
              title: 'Контроль',
              detail: 'Напоминания без ручных звонков',
            ),
          ],
        ),
        if (draft.missingFields.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.orange,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Нужно уточнить: ${draft.missingFields.join(', ')}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: Color(0xFF8A5525),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Сохранить рейс'),
        ),
        const SizedBox(height: 8),
        const Text(
          'В демо ничего не отправляется клиенту, водителю или оператору ЭДО.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _input(
    String label,
    String key, {
    String hint = '',
    TextInputType? keyboard,
    ValueChanged<String>? changed,
  }) => TextField(
    controller: f(key),
    keyboardType: keyboard,
    onChanged: changed,
    decoration: InputDecoration(labelText: label, hintText: hint),
  );

  Widget _success() => ListView(
    key: const ValueKey('success'),
    padding: const EdgeInsets.fromLTRB(18, 30, 18, 30),
    children: [
      Center(
        child: Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(
            color: AppColors.acid,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.ink,
            size: 46,
          ),
        ),
      ),
      const SizedBox(height: 22),
      Text(
        '${created?.number ?? 'Рейс'} создан',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        created?.route ?? '',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.muted, fontSize: 14),
      ),
      const SizedBox(height: 26),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            const _Result(
              done: true,
              title: 'Карточка рейса',
              detail: 'Ставки и маржа зафиксированы',
            ),
            const _Result(
              done: true,
              title: 'Черновик заявки',
              detail: 'Готов к печати и проверке',
            ),
            _Result(
              done: f('carrier').text.isNotEmpty,
              title: 'Перевозчик',
              detail:
                  f('carrier').text.isEmpty
                      ? 'Нужно назначить'
                      : f('carrier').text,
            ),
            const _Result(
              done: false,
              title: 'Ссылка водителю',
              detail: 'Появится после подтверждения',
            ),
            const _Result(
              done: false,
              title: 'Электронные документы',
              detail: 'Интеграция отключена в MVP',
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed:
            created == null
                ? null
                : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => DocumentsScreen(
                          store: widget.store,
                          initialTrip: created,
                        ),
                  ),
                ),
        icon: const Icon(Icons.description_outlined),
        label: const Text('Открыть подготовленные документы'),
      ),
      const SizedBox(height: 9),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('На главную'),
      ),
      TextButton(
        onPressed:
            () => setState(() {
              stage = 0;
              note.clear();
              created = null;
            }),
        child: const Text(
          'Создать ещё один',
          style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: selected ? AppColors.ink : const Color(0xFF8998A2),
            size: 20,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.ink : const Color(0xFF9CA9B1),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _RecognizedNote extends StatelessWidget {
  const _RecognizedNote({required this.text, required this.missing});
  final String text;
  final int missing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.acid,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.ink,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Заметка разобрана',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              missing == 0 ? 'всё найдено' : '$missing уточнить',
              style: const TextStyle(
                color: AppColors.acid,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFB3C0C7),
            fontSize: 11.5,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String number;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 13),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.acid,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: ActionChip(
      onPressed: onTap,
      avatar: const Icon(
        Icons.history_rounded,
        size: 15,
        color: AppColors.green,
      ),
      label: Text(
        label,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
      backgroundColor: const Color(0xFFEAF5EE),
      side: BorderSide.none,
    ),
  );
}

class _Margin extends StatelessWidget {
  const _Margin({required this.clientRate, required this.carrierRate});
  final int clientRate;
  final int carrierRate;

  @override
  Widget build(BuildContext context) {
    final value = clientRate - carrierRate;
    final percent = clientRate > 0 ? value / clientRate * 100 : 0;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: value >= 0 ? const Color(0xFFE9F7EF) : const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, color: AppColors.green),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Маржа рейса',
                  style: TextStyle(color: AppColors.muted, fontSize: 10.5),
                ),
                Text(
                  'обновляется сразу',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(value),
                style: TextStyle(
                  color: value >= 0 ? AppColors.green : Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(0)}% от ставки',
                style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarrierRow extends StatelessWidget {
  const _CarrierRow({
    required this.carrier,
    required this.selected,
    required this.onTap,
  });
  final Counterparty carrier;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:
            selected ? AppColors.acid.withValues(alpha: .24) : AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.green : AppColors.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              selected ? Icons.check_rounded : Icons.local_shipping_outlined,
              color: selected ? AppColors.green : AppColors.ink,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  carrier.name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${carrier.rating} ★ · ${carrier.completedTrips} рейсов · ${carrier.tags.first}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
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

class _Automation extends StatelessWidget {
  const _Automation({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: AppColors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.green,
          size: 18,
        ),
      ],
    ),
  );
}

class _Result extends StatelessWidget {
  const _Result({
    required this.done,
    required this.title,
    required this.detail,
  });
  final bool done;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (done ? AppColors.green : AppColors.orange).withValues(
              alpha: .11,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            done ? Icons.check_rounded : Icons.schedule_rounded,
            color: done ? AppColors.green : AppColors.orange,
            size: 17,
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
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
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
