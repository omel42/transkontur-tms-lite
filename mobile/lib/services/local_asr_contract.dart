class AsrReadiness {
  const AsrReadiness({
    required this.ready,
    required this.title,
    required this.detail,
    this.modelDirectory = '',
  });

  final bool ready;
  final String title;
  final String detail;
  final String modelDirectory;
}

abstract class LocalAsrEngine {
  Future<AsrReadiness> readiness();
  Future<String> transcribe(String wavPath);
}
