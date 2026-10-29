import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/utils/rif_validator_utils.dart';

void main() {
  group('RifValidatorUtils Tests', () {
    test('Calculates correct check digit for J-30369159', () {
      final digit = RifValidatorUtils.calculateCheckDigit('J', '30369159');
      expect(digit, equals(5));
      expect(RifValidatorUtils.formatRif('J', '30369159'), equals('J-30369159-5'));
      expect(RifValidatorUtils.isValidRif('J-30369159-5'), isTrue);
      // Verify that J-30369159-2 is indeed invalid
      expect(RifValidatorUtils.isValidRif('J-30369159-2'), isFalse);
    });

    test('Calculates correct check digit for V-30369159', () {
      final digit = RifValidatorUtils.calculateCheckDigit('V', '30369159');
      expect(digit, equals(2));
      expect(RifValidatorUtils.formatRif('V', '30369159'), equals('V-30369159-2'));
      expect(RifValidatorUtils.isValidRif('V-30369159-2'), isTrue);
    });

    test('Zero pads numbers shorter than 8 digits', () {
      final digit = RifValidatorUtils.calculateCheckDigit('V', '9123456');
      expect(digit, isNotNull);
      final formatted = RifValidatorUtils.formatRif('V', '9123456');
      expect(formatted, startsWith('V-09123456-'));
      expect(RifValidatorUtils.isValidRif(formatted!), isTrue);
    });

    test('Rejects invalid formats', () {
      expect(RifValidatorUtils.isValidRif(''), isFalse);
      expect(RifValidatorUtils.isValidRif('ABC'), isFalse);
      expect(RifValidatorUtils.isValidRif('Z-12345678-9'), isFalse);
      expect(RifValidatorUtils.isValidRif('J-123-4'), isFalse);
    });
  });
}
