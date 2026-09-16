import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'local_asr_contract.dart';

LocalAsrEngine createEngine() => Qwen3LocalAsrEngine();

class Qwen3LocalAsrEngine implements LocalAsrEngine {
  static const folderName = 'qwen3_asr';
  bool _bindingsReady = false;

  Future<Directory> _modelDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/models/$folderName');
  }

  @override
  Future<AsrReadiness> readiness() async {
    final dir = await _modelDirectory();
    final requiredFiles = [
      'conv_frontend.onnx',
      'encoder.int8.onnx',
      'decoder.int8.onnx',
      'tokens.txt',
    ];
    final missing = <String>[];
    for (final file in requiredFiles) {
      if (!File('${dir.path}/$file').existsSync()) missing.add(file);
    }
    if (!Directory('${dir.path}/tokenizer').existsSync()) {
      missing.add('tokenizer/');
    }
    if (missing.isNotEmpty) {
      return AsrReadiness(
        ready: false,
        title: 'Модель не установлена',
        detail: 'Нужны файлы Qwen3-ASR 0.6B INT8: ${missing.join(', ')}',
        modelDirectory: dir.path,
      );
    }
    return AsrReadiness(
      ready: true,
      title: 'Qwen3-ASR работает локально',
      detail: 'Запись обрабатывается на телефоне и никуда не отправляется.',
      modelDirectory: dir.path,
    );
  }

  @override
  Future<String> transcribe(String wavPath) async {
    final state = await readiness();
    if (!state.ready) throw StateError(state.detail);
    if (!_bindingsReady) {
      sherpa.initBindings();
      _bindingsReady = true;
    }
    final dir = state.modelDirectory;
    final model = sherpa.OfflineModelConfig(
      qwen3Asr: sherpa.OfflineQwen3AsrModelConfig(
        convFrontend: '$dir/conv_frontend.onnx',
        encoder: '$dir/encoder.int8.onnx',
        decoder: '$dir/decoder.int8.onnx',
        tokenizer: '$dir/tokenizer',
        maxTotalLen: 512,
        maxNewTokens: 128,
        hotwords:
            'Москва,Казань,Екатеринбург,Санкт-Петербург,погрузка,выгрузка,рефрижератор,паллеты,ставка,перевозчик',
      ),
      tokens: '$dir/tokens.txt',
      numThreads: 4,
      debug: false,
      modelType: 'qwen3_asr',
    );
    final recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(model: model),
    );
    try {
      final wave = sherpa.readWave(wavPath);
      if (wave.samples.isEmpty) {
        throw StateError('Запись пуста или имеет неподдерживаемый формат.');
      }
      final stream = recognizer.createStream();
      try {
        stream.acceptWaveform(
          samples: wave.samples,
          sampleRate: wave.sampleRate,
        );
        recognizer.decode(stream);
        return recognizer.getResult(stream).text.trim();
      } finally {
        stream.free();
      }
    } finally {
      recognizer.free();
    }
  }
}
