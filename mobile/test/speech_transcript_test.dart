import 'package:flutter_test/flutter_test.dart';
import 'package:transkontur_mobile/services/speech_transcript.dart';

void main() {
  test('120 раз склеивает фразы после пауз без потери и повторов', () {
    const phrase =
        'НордПром Москва Казань завтра девять утра оборудование двадцать тонн тент клиент платит сто пятьдесят тысяч перевозчику сто восемнадцать тысяч';
    final words = phrase.split(' ');
    var checked = 0;

    for (var iteration = 0; iteration < 120; iteration++) {
      final transcript = SpeechTranscript();
      final chunkSize = 2 + iteration % 7;
      final overlap = iteration % 3;
      var start = 0;
      while (start < words.length) {
        final end = (start + chunkSize).clamp(0, words.length);
        transcript.updatePartial(words.sublist(start, end).join(' '));
        transcript.commitPartial();
        if (end == words.length) break;
        start = (end - overlap).clamp(start + 1, words.length);
      }
      final normalized = transcript.text
          .replaceAll('.', '')
          .replaceAll('  ', ' ');
      expect(normalized, phrase, reason: 'итерация $iteration');
      checked++;
    }

    expect(checked, 120);
  });

  test('не дублирует финальный результат распознавания', () {
    final transcript = SpeechTranscript();
    transcript.updatePartial('Москва Казань завтра');
    transcript.commit('Москва Казань завтра');
    transcript.commit('завтра двадцать тонн');

    expect(transcript.text, 'Москва Казань завтра двадцать тонн');
  });
}
