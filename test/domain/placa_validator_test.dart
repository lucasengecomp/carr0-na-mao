import 'package:carro_na_mao/domain/placa_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalize', () {
    test('remove hífen e espaços', () {
      expect(PlacaValidator.normalize('abc-1234'), 'ABC1234');
      expect(PlacaValidator.normalize('  ABC 1D23 '), 'ABC1D23');
      expect(PlacaValidator.normalize('A.B.C.1.2.3.4'), 'ABC1234');
    });

    test('converte para caixa alta', () {
      expect(PlacaValidator.normalize('abc1d23'), 'ABC1D23');
    });
  });

  group('isValid', () {
    test('aceita placa Mercosul', () {
      expect(PlacaValidator.isValid('ABC1D23'), isTrue);
      expect(PlacaValidator.isValid('XYZ9A99'), isTrue);
    });

    test('aceita placa antiga', () {
      expect(PlacaValidator.isValid('ABC1234'), isTrue);
      expect(PlacaValidator.isValid('ZZZ0000'), isTrue);
    });

    test('rejeita formatos errados', () {
      expect(PlacaValidator.isValid('ABCD123'), isFalse);
      expect(PlacaValidator.isValid('123ABCD'), isFalse);
      expect(PlacaValidator.isValid('AB1D234'), isFalse);
      expect(PlacaValidator.isValid('ABC12D3'), isFalse);
      expect(PlacaValidator.isValid(''), isFalse);
      expect(PlacaValidator.isValid('ABC-1234'), isFalse);
    });
  });

  group('validate', () {
    test('devolve null para válidas', () {
      expect(PlacaValidator.validate('abc1d23'), isNull);
      expect(PlacaValidator.validate('abc-1234'), isNull);
      expect(PlacaValidator.validate('ABC1D23'), isNull);
    });

    test('mensagem específica quando vazia', () {
      expect(PlacaValidator.validate(''), 'Informe a placa');
      expect(PlacaValidator.validate('   '), 'Informe a placa');
    });

    test('mensagem quando tem tamanho diferente de 7', () {
      expect(PlacaValidator.validate('ABC123'), contains('7 caracteres'));
      expect(PlacaValidator.validate('ABC12345'), contains('7 caracteres'));
    });

    test('mensagem quando formato inválido', () {
      expect(PlacaValidator.validate('ABCDEFG'), contains('Formato inválido'));
      expect(PlacaValidator.validate('1234567'), contains('Formato inválido'));
    });
  });
}
