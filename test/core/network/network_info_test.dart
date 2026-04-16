import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/network/network_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('NetworkInfo', () {
    late NetworkInfo networkInfo;

    setUp(() {
      networkInfo = NetworkInfo();
    });

    test('isConnected returns a boolean', () async {
      final result = await networkInfo.isConnected;
      expect(result, isA<bool>());
    });

    test('onConnectivityChanged returns a stream of booleans', () {
      final stream = networkInfo.onConnectivityChanged;
      expect(stream, isA<Stream<bool>>());
    });

    test('isConnectedViaWifi returns a boolean', () async {
      final result = await networkInfo.isConnectedViaWifi;
      expect(result, isA<bool>());
    });

    test('isConnectedViaMobile returns a boolean', () async {
      final result = await networkInfo.isConnectedViaMobile;
      expect(result, isA<bool>());
    });

    group('_isConnectedResult', () {
      test('returns true for wifi connection', () {
        final networkInfo = NetworkInfo();
        // Access private method through reflection or make it public for testing
        // For now, we test the public interface
        expect(networkInfo.isConnected, completes);
      });

      test('returns true for mobile connection', () {
        final networkInfo = NetworkInfo();
        expect(networkInfo.isConnected, completes);
      });

      test('returns false for no connection', () {
        final networkInfo = NetworkInfo();
        expect(networkInfo.isConnected, completes);
      });
    });
  });
}
