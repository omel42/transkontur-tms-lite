import 'local_asr_contract.dart';

LocalAsrEngine createEngine() => _BrowserAsrEngine();

class _BrowserAsrEngine implements LocalAsrEngine {
  @override
  Future<AsrReadiness> readiness() async => const AsrReadiness(
    ready: false,
    title: 'Демо-режим в браузере',
    detail:
        'Qwen3-ASR запускается локально в сборке Android/iOS. В веб-демо используется готовая тестовая расшифровка.',
  );

  @override
  Future<String> transcribe(String wavPath) =>
      throw UnsupportedError(
        'Локальная ASR-модель доступна в мобильной сборке.',
      );
}
