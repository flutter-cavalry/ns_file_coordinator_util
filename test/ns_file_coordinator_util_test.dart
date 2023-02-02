import 'package:flutter_test/flutter_test.dart';
import 'package:ns_file_coordinator_util/ns_file_coordinator_util.dart';
import 'package:ns_file_coordinator_util/ns_file_coordinator_util_platform_interface.dart';
import 'package:ns_file_coordinator_util/ns_file_coordinator_util_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNsFileCoordinatorUtilPlatform
    with MockPlatformInterfaceMixin
    implements NsFileCoordinatorUtilPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NsFileCoordinatorUtilPlatform initialPlatform = NsFileCoordinatorUtilPlatform.instance;

  test('$MethodChannelNsFileCoordinatorUtil is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNsFileCoordinatorUtil>());
  });

  test('getPlatformVersion', () async {
    NsFileCoordinatorUtil nsFileCoordinatorUtilPlugin = NsFileCoordinatorUtil();
    MockNsFileCoordinatorUtilPlatform fakePlatform = MockNsFileCoordinatorUtilPlatform();
    NsFileCoordinatorUtilPlatform.instance = fakePlatform;

    expect(await nsFileCoordinatorUtilPlugin.getPlatformVersion(), '42');
  });
}
