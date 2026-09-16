import 'local_asr_contract.dart';
import 'local_asr_stub.dart'
    if (dart.library.io) 'local_asr_native.dart'
    as implementation;

export 'local_asr_contract.dart';

LocalAsrEngine createLocalAsrEngine() => implementation.createEngine();
