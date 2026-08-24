import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/shared/text/search_normalization.dart';

void main() {
  test('ricerca ignora maiuscole, accenti e spazi ripetuti', () {
    expect(normalizeForSearch('  CaffÈ   Crème  '), 'caffe creme');
    expect(normalizeForSearch('STRAßE'), 'strasse');
  });

  test('normalizza 1000 elementi senza lavoro patologico', () {
    final values = List.generate(1000, (index) => 'Prodótto speciale $index');
    final stopwatch = Stopwatch()..start();
    final matches = values
        .where((value) => normalizeForSearch(value).contains('prodotto'))
        .length;
    stopwatch.stop();
    expect(matches, 1000);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
  });
}
