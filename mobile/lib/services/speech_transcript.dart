/// Keeps a long dictation intact when Android closes and reopens recognition
/// after a short pause. Some recognizers repeat the last words at the start of
/// the next segment, so overlapping words are removed before joining.
class SpeechTranscript {
  String _committed = '';
  String _partial = '';

  String get committed => _committed;
  String get text => _join(_committed, _partial);
  bool get isEmpty => text.trim().isEmpty;

  void reset([String seed = '']) {
    _committed = _clean(seed);
    _partial = '';
  }

  void updatePartial(String value) {
    _partial = _clean(value);
  }

  void commit(String value) {
    final clean = _clean(value);
    if (clean.isNotEmpty) _committed = _join(_committed, clean);
    _partial = '';
  }

  void commitPartial() {
    commit(_partial);
  }

  static String _join(String left, String right) {
    final a = _clean(left);
    final b = _clean(right);
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    if (a.toLowerCase().endsWith(b.toLowerCase())) return a;

    final aWords = a.split(' ');
    final bWords = b.split(' ');
    final limit = aWords.length < bWords.length ? aWords.length : bWords.length;
    var overlap = 0;
    for (var size = 1; size <= limit && size <= 8; size++) {
      final tail = aWords.sublist(aWords.length - size).join(' ').toLowerCase();
      final head = bWords.sublist(0, size).join(' ').toLowerCase();
      if (tail == head) overlap = size;
    }
    final addition = bWords.skip(overlap).join(' ');
    if (addition.isEmpty) return a;
    return '$a $addition';
  }

  static String _clean(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');
}
