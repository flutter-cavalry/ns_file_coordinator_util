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
      body: SingleChildScrollView(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Click the + to select an iCloud folder first'),
                _sep(),
                if (_icloudFolder != null)
                  Text('iCloud folder: $_icloudFolder'),
                _sep(),
                ..._renderButtons(),
                _sep(),
                Text(_output)
              ],
            ),
          ),
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
      OutlinedButton(
          onPressed: _download, child: const Text('Read/download file')),
      _sep(),
      OutlinedButton(onPressed: _stat, child: const Text('Get information')),
      _sep(),
      OutlinedButton(onPressed: _list, child: const Text('List contents')),
      _sep(),
      OutlinedButton(onPressed: _delete, child: const Text('Delete')),
      _sep(),
      OutlinedButton(onPressed: _move, child: const Text('Move')),
      _sep(),
      OutlinedButton(onPressed: _copyPath, child: const Text('Copy path')),
      _sep(),
      OutlinedButton(
          onPressed: _isDirectory,
          child: const Text('Check existence (is directory)')),
      _sep(),
      OutlinedButton(onPressed: _mkdir, child: const Text('Mkdir')),
      _sep(),
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
      var dir = _icloudFolder;
      var fileRelPath = _fileTextController.text;
      if (fileRelPath.isEmpty || dir == null) {
        return;
      }
      var fileAbsPath = p.join(dir, fileRelPath);
      var destPath = tmpPath();

      setState(() {
        _output = 'Reading/downloading $dir';
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

  Future<void> _list() async {
    try {
      var dir = _icloudFolder;
      if (dir == null) {
        return;
      }
      setState(() {
        _output = 'Listing contents of $dir';
      });
      var contents = await _plugin.listContents(dir);
      setState(() {
        _output = '--- Contents ---\n${contents.join('\n')}';
      });
    } catch (err) {
      setState(() {
        _output = '';
      });
      await _showErrorAlert(context, err.toString());
    }
  }

  Future<void> _stat() async {
    try {
      var dir = _icloudFolder;
      var fileRelPath = _fileTextController.text;
      if (fileRelPath.isEmpty || dir == null) {
        return;
      }
      var fileAbsPath = p.join(dir, fileRelPath);

      setState(() {
        _output = 'Getting information of $dir';
      });
      var inf = await _plugin.stat(fileAbsPath);
      setState(() {
        _output = inf.toString();
      });
    } catch (err) {
      setState(() {
        _output = '';
      });
      await _showErrorAlert(context, err.toString());
    }
  }

  Future<void> _delete() async {
    try {
      var dir = _icloudFolder;
      var fileRelPath = _fileTextController.text;
      if (fileRelPath.isEmpty || dir == null) {
        return;
      }
      var fileAbsPath = p.join(dir, fileRelPath);

      setState(() {
        _output = 'Deleting $dir';
      });
      await _plugin.delete(fileAbsPath);
      setState(() {
        _output = 'Deleted';
      });
    } catch (err) {
      setState(() {
        _output = '';
      });
      await _showErrorAlert(context, err.toString());
    }
  }

  Future<void> _move() async {
    try {
      var dir = _icloudFolder;
      var fileRelPath = _fileTextController.text;
      if (fileRelPath.isEmpty || dir == null) {
        return;
      }
      var fileAbsPath = p.join(dir, fileRelPath);
      var newFileAbsPath = p.join(p.dirname(fileAbsPath), 'newName');

      setState(() {
        _output = 'Rename $fileAbsPath to $newFileAbsPath';
      });
      await _plugin.move(fileAbsPath, newFileAbsPath);
      setState(() {
        _output = 'Renamed';
      });
    } catch (err) {
      setState(() {
        _output = '';
      });
      await _showErrorAlert(context, err.toString());
    }
  }

  Future<void> _copyPath() async {
    try {
      var dir = _icloudFolder;
      var fileRelPath = _fileTextController.text;
      if (fileRelPath.isEmpty || dir == null) {
        return;
      }
      var fileAbsPath = p.join(dir, fileRelPath);
      var tmpDir = await _createTempDir();

      setState(() {
        _output = 'Writing to $fileAbsPath';
      });
      await _plugin.copy(tmpDir, fileAbsPath);
      setState(() {
        _output = 'Succeeded';
      });
    } catch (err) {
      setState(() {
        _output = '';
      });
      await _showErrorAlert(context, err.toString());
    }
  }

  Future<void> _isDirectory() async {
    try {
      var dir = _icloudFolder;
      var fileRelPath = _fileTextController.text;
      if (fileRelPath.isEmpty || dir == null) {
        return;
      }
      var fileAbsPath = p.join(dir, fileRelPath);

      setState(() {
        _output = 'Checking if $fileAbsPath exists';
      });
      var isDir = await _plugin.isDirectory(fileAbsPath);
      setState(() {
        _output = 'Result: $isDir';
      });
    } catch (err) {
      setState(() {
        _output = '';
      });
      await _showErrorAlert(context, err.toString());
    }
  }

  Future<void> _mkdir() async {
    try {
      var dir = _icloudFolder;
      var fileRelPath = _fileTextController.text;
      if (fileRelPath.isEmpty || dir == null) {
        return;
      }
      var fileAbsPath = p.join(dir, fileRelPath);

      setState(() {
        _output = 'Creating directory $fileAbsPath';
      });
      await _plugin.mkdir(fileAbsPath);
      setState(() {
        _output = 'Created';
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

  Future<String> _createTempDir() async {
    var tmpDir = tmpPath();
    await Directory(tmpDir).create();
    await File(p.join(tmpDir, '1.txt')).writeAsString('file 1');
    await File(p.join(tmpDir, '2.txt')).writeAsString('file 2');
    return tmpDir;
  }
}
