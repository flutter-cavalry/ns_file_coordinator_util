import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ns_file_coordinator_util/ns_file_coordinator_util_method_channel.dart';

void main() {
  MethodChannelNsFileCoordinatorUtil platform = MethodChannelNsFileCoordinatorUtil();
  const MethodChannel channel = MethodChannel('ns_file_coordinator_util');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
