import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nymbus_coletor/services/logger_service.dart';

/// Captura o que o [LoggerService] envia para o `debugPrint` durante [action].
List<String> _capturarLogs(void Function() action) {
  final logs = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    logs.add(message ?? '');
  };
  try {
    action();
  } finally {
    debugPrint = original;
  }
  return logs;
}

void main() {
  group('LoggerService.maskLicense', () {
    test('mascara tudo menos os 2 últimos dígitos', () {
      expect(LoggerService.maskLicense('1234'), '**34');
    });

    test('string vazia retorna vazia', () {
      expect(LoggerService.maskLicense(''), '');
    });

    test('string curta (1 char) não é mascarada', () {
      expect(LoggerService.maskLicense('7'), '7');
    });
  });

  group('LoggerService.maskBarcode', () {
    test('mascara tudo menos os 4 últimos dígitos', () {
      expect(LoggerService.maskBarcode('7897186005683'), '*********5683');
    });

    test('string vazia retorna vazia', () {
      expect(LoggerService.maskBarcode(''), '');
    });
  });

  group('LoggerService.redactUrl', () {
    test('mascara o segmento /licenca/<n>', () {
      expect(
        LoggerService.redactUrl('http://10.0.0.1:8080/licenca/1234'),
        contains('/licenca/**34'),
      );
    });

    test('mascara query param ?licenca=', () {
      expect(
        LoggerService.redactUrl('http://host/api?licenca=1234'),
        contains('licenca=**34'),
      );
    });

    test('mascara token em query param', () {
      expect(
        LoggerService.redactUrl('http://host/api?token=abcdef'),
        contains('token=***'),
      );
    });
  });

  group('LoggerService — redação na saída', () {
    test('redige URL presente na mensagem', () {
      final logs = _capturarLogs(
        () => LoggerService.i('GET http://10.0.0.1:9000/licenca/1234'),
      );
      expect(logs.single, contains('/licenca/**34'));
      expect(logs.single, isNot(contains('/licenca/1234')));
    });

    test('redige cabeçalho Authorization: Bearer', () {
      final logs = _capturarLogs(
        () => LoggerService.i('Authorization: Bearer abc123.def-ghi'),
      );
      expect(logs.single, contains('Authorization: Bearer ***'));
      expect(logs.single, isNot(contains('abc123')));
    });

    test('mascara código de barras quando a mensagem o menciona', () {
      final logs = _capturarLogs(
        () => LoggerService.i('Codigo de barras lido: 7897186005683'),
      );
      expect(logs.single, contains('*********5683'));
      expect(logs.single, isNot(contains('7897186005683')));
    });

    test('mascara licença quando a mensagem a menciona', () {
      final logs = _capturarLogs(
        () => LoggerService.i('licenca configurada: 1234'),
      );
      expect(logs.single, contains('**34'));
      expect(logs.single, isNot(contains(': 1234')));
    });
  });
}
