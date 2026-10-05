import 'package:arunika_app/constants/api_paths.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Angka copy matches the design', () {
    expect(
      AppStrings.angkaQuestionHeader(2, 3, 10),
      'Level 2 · Soal 3 dari 10',
    );
    expect(
      AppStrings.angkaSuccessBody(7, 'apel'),
      'Ada 7 apel. Kamu pintar berhitung!',
    );
    expect(
      AppStrings.angkaRetryBody(6, 'apel'),
      'Jawabanmu 6. Yuk, hitung apelnya sekali lagi.',
    );
    expect(AppStrings.angkaFinishFirst(2), 'Selesaikan Level 2 untuk membuka');
    expect(AppStrings.angkaAnswered(3, 10), '3/10 soal');
    expect(AppStrings.angkaLevelLabel(1), 'Level 1');
    expect(AppStrings.angkaQuestionFallback('bola'), 'Ada berapa bola?');
    expect(
      AppStrings.angkaLevelDoneBody(9, 10),
      '9 dari 10 benar di percobaan pertama.',
    );
    expect(AppStrings.angkaStarsLabel(2), '2 dari 3 bintang');
  });

  test('Angka API paths', () {
    expect(ApiPaths.angkaNumber(7), '/learn/angka/numbers/7');
    expect(ApiPaths.angkaLevel('l1'), '/learn/angka/levels/l1');
    expect(ApiPaths.angkaProgress('c'), '/children/c/angka/progress');
    expect(ApiPaths.angkaSessions('c'), '/children/c/angka/sessions');
    expect(ApiPaths.angkaSession('c', 's'), '/children/c/angka/sessions/s');
    expect(
      ApiPaths.angkaSessionComplete('c', 's'),
      '/children/c/angka/sessions/s/complete',
    );
  });
}
