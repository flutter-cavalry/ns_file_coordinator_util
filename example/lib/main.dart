import 'dart:io';

import 'package:accessing_security_scoped_resource/accessing_security_scoped_resource.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:macos_file_picker/macos_file_picker.dart';
import 'package:macos_file_picker/macos_file_picker_platform_interface.dart';
import 'dart:async';

import 'package:ns_file_coordinator_util/ns_file_coordinator_util.dart';
import 'package:tmp_path/tmp_path.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHome(),
    );
  }
}

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  String? _icloudFolder;
  final _plugin = NsFileCoordinatorUtil();
  final _macosPicker = MacosFilePicker();
  final _accessPlugin = AccessingSecurityScopedResource();
  late TextEditingController _fileTextController;
  String _output = '';

  @override
  void initState() {
    super.initState();
    _fileTextController = TextEditingController();
  }

  @override
  void dispose() {
    _fileTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Click the + to select an iCloud folder first'),
            _sep(),
            if (_icloudFolder != null) Text('iCloud folder: $_icloudFolder'),
            _sep(),
            ..._renderButtons(),
            _sep(),
            Text(_output)
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectFolder,
        tooltip: 'Select an folder',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _sep() {
    return const SizedBox(
      height: 10,
    );
  }

  List<Widget> _renderButtons() {
    if (_icloudFolder == null) {
      return [];
    }
    return [
      const Text('Relative file path'),
      TextField(
        controller: _fileTextController,
      ),
      _sep(),
      OutlinedButton(onPressed: _download, child: const Text('Download'))
    ];
  }

  Future<void> _selectFolder() async {
    try {
      String? dir;
      if (Platform.isMacOS) {
        var list = await _macosPicker.pick(MacosFilePickerMode.folder);
        if (list == null) {
          dir = null;
        } else {
          dir = list.first;
        }
      } else {
        dir = await FilePicker.platform.getDirectoryPath();
      }
      if (dir == null) {
        return;
      }

      var hasAccess = await _accessPlugin
          .startAccessingSecurityScopedResourceWithFilePath(dir);
      if (!hasAccess) {
        throw 'Failed to gain access to $dir';
      }
      setState(() {
        _icloudFolder = dir;
      });
    } catch (err) {
      await _showErrorAlert(context, err.toString());
    }
  }

  Future<void> _download() async {
    try {
      var fileRelPath = _fileTextController.text;
      if (fileRelPath.isEmpty) {
        return;
      }
      var fileAbsPath = p.join(_icloudFolder!, fileRelPath);
      var destPath = tmpPath();

      setState(() {
        _output = 'Reading $fileAbsPath';
      });
      await _plugin.readFile(fileAbsPath, destPath);

      var length = await File(destPath).length();
      setState(() {
        _output = 'File written to $destPath with $length bytes';
      });
    } catch (err) {
      setState(() {
        _output = '';
      });
      await _showErrorAlert(context, err.toString());
    }
  }

  Future<void> _showErrorAlert(BuildContext context, String msg) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const SelectableText('Error'),
        content: SelectableText(msg),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
