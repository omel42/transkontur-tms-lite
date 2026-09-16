import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'local_asr_contract.dart';

LocalAsrEngine createEngine() => Qwen3LocalAsrEngine();

class Qwen3LocalAsrEngine implements LocalAsrEngine {
  static const folderName = 'qwen3_asr';

  Future<List<Directory>> _modelDirectories() async {
    final support = await getApplicationSupportDirectory();
    final external = await getExternalStorageDirectory();
    return [
      if (external != null) Directory('${external.path}/models/$folderName'),
      Directory('${support.path}/models/$folderName'),
    ];
  }

  @override
  Future<AsrReadiness> readiness() async {
    final requiredFiles = [
      'conv_frontend.onnx',
      'encoder.int8.onnx',
      'decoder.int8.onnx',
    ];
    final directories = await _modelDirectories();
    for (final dir in directories) {
      final complete =
          requiredFiles.every(
            (file) => File('${dir.path}/$file').existsSync(),
          ) &&
          Directory('${dir.path}/tokenizer').existsSync();
      if (complete) {
        return AsrReadiness(
          ready: true,
          title: 'Qwen3-ASR работает локально',
          detail: 'Запись обрабатывается на телефоне и никуда не отправляется.',
          modelDirectory: dir.path,
        );
      }
    }

    final dir = directories.first;
    return AsrReadiness(
      ready: false,
      title: 'Модель не установлена',
      detail: 'Нужен комплект Qwen3-ASR 0.6B INT8 в ${dir.path}',
      modelDirectory: dir.path,
    );
  }

  @override
  Future<String> transcribe(String wavPath) async {
    final state = await readiness();
    if (!state.ready) throw StateError(state.detail);
    return Isolate.run(() => _transcribeQwen((state.modelDirectory, wavPath)));
  }
}

String _transcribeQwen((String, String) input) {
  final (dir, wavPath) = input;
  sherpa.initBindings();
  final model = sherpa.OfflineModelConfig(
    qwen3Asr: sherpa.OfflineQwen3AsrModelConfig(
      convFrontend: '$dir/conv_frontend.onnx',
      encoder: '$dir/encoder.int8.onnx',
      decoder: '$dir/decoder.int8.onnx',
      tokenizer: '$dir/tokenizer',
      maxTotalLen: 512,
      maxNewTokens: 128,
      hotwords: '',
    ),
    tokens: '',
    numThreads: 4,
    debug: false,
    modelType: '',
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
      stream.acceptWaveform(samples: wave.samples, sampleRate: wave.sampleRate);
      recognizer.decode(stream);
      return recognizer.getResult(stream).text.trim();
    } finally {
      stream.free();
    }
  } finally {
    recognizer.free();
  }
}
