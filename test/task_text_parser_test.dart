import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/features/tasks/application/task_text_parser.dart';

void main() {
  group('parseTaskText', () {
    test('leerer Text bzw. nur Whitespace ergibt null', () {
      expect(parseTaskText(''), isNull);
      expect(parseTaskText('   \r\n  \n '), isNull);
    });

    test('kurze einzelne Zeile: Titel, keine Beschreibung', () {
      final result = parseTaskText('  Bienen füttern  ');
      expect(result?.title, 'Bienen füttern');
      expect(result?.description, isNull);
    });

    test('genau 85 Zeichen: Titel vollständig, keine Beschreibung', () {
      final text = 'a' * 85;
      final result = parseTaskText(text);
      expect(result?.title, text);
      expect(result?.description, isNull);
    });

    test('86 Zeichen: Titel gekürzt, Beschreibung = Originaltext', () {
      final text = 'a' * 86;
      final result = parseTaskText(text);
      expect(result?.title, 'a' * 85);
      expect(result?.description, text);
    });

    test(
      'mehrzeilig (mit \\r\\n): erste Zeile Titel, Beschreibung komplett',
      () {
        final result = parseTaskText('  Waben prüfen\r\nStock 3 und 4\r\n');
        expect(result?.title, 'Waben prüfen');
        expect(result?.description, 'Waben prüfen\nStock 3 und 4');
      },
    );

    test('lange erste Zeile + weitere Zeilen: Titel gekürzt', () {
      final firstLine = 'b' * 120;
      final text = '$firstLine\nDetails';
      final result = parseTaskText(text);
      expect(result?.title, 'b' * 85);
      expect(result?.description, text);
    });
  });

  group('taskDescriptionBody', () {
    test('entfernt den wiederholten Titel', () {
      expect(
        taskDescriptionBody('Waben prüfen', 'Waben prüfen\nStock 3 und 4'),
        'Stock 3 und 4',
      );
    });

    test('ältere Beschreibung ohne Titel bleibt unverändert', () {
      expect(taskDescriptionBody('Einkauf', 'Milch holen'), 'Milch holen');
    });

    test('leere Beschreibung ergibt leeren Text', () {
      expect(taskDescriptionBody('Einkauf', ''), isEmpty);
    });
  });
}
