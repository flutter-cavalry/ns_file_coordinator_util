// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:accessing_security_scoped_resource/accessing_security_scoped_resource.dart';
import 'package:darwin_url/darwin_url.dart';
import 'package:flutter/material.dart';
import 'package:ios_document_picker/ios_document_picker.dart';
import 'package:ios_document_picker/ios_document_picker_platform_interface.dart';
import 'package:macos_file_picker/macos_file_picker.dart';
import 'package:macos_file_picker/macos_file_picker_platform_interface.dart';
import 'dart:async';

import 'package:ns_file_coordinator_util/ns_file_coordinator_util.dart';
import 'package:ns_file_coordinator_util_example/async_read_route.dart';
import 'package:ns_file_coordinator_util_example/async_write_route.dart';
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
  final _plugin = NsFileCoordinatorUtil();
  final _macosPicker = MacosFilePicker();
  final _iosPicker = IosDocumentPicker();
  final _accessPlugin = AccessingSecurityScopedResource();
  final _darwinUrlPlugin = DarwinUrl();

  late TextEditingController _fileTextController;
  String _output = '';
  String? _icloudFolder;
  bool _overwriteFlag = false;

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
              spacing: 8,
              children: [
                const Text('Click the + to select an iCloud folder first'),
                if (_icloudFolder != null)
                  OutlinedButton(
                      onPressed: () async {
                        if (_icloudFolder == null) {
                          return;
                        }
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AsyncReadRoute(dirUrl: _icloudFolder!)));
                      },
                      child: const Text('Read file async tests')),
                if (_icloudFolder != null)
                  OutlinedButton(
                      onPressed: () async {
                        if (_icloudFolder == null) {
                          return;
                        }
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AsyncWriteRoute(dirUrl: _icloudFolder!)));
                      },
                      child: const Text('Write file async tests')),
                if (_icloudFolder != null)
                  Text('iCloud folder: $_icloudFolder'),
                if (_icloudFolder != null) ..._renderButtons(),
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

  List<Widget> _renderButtons() {
    if (_icloudFolder == null) {
      return [];
    }
    return [
      const Text('Relative file path'),
      TextField(
        controller: _fileTextController,
      ),
      OutlinedButton(
          onPressed: _readSync, child: const Text('Read/download file')),
      OutlinedButton(
          onPressed: () => _readSync(partial: true),
          child: const Text('Read file with offset')),
      OutlinedButton(onPressed: _stat, child: const Text('Get information')),
      OutlinedButton(
          onPressed: () => _list(recursive: false),
          child: const Text('List contents')),
      OutlinedButton(
          onPressed: () => _list(recursive: true),
          child: const Text('List contents recursively')),
      OutlinedButton(
          onPressed: () => _listFiles(), child: const Text('List files')),
      OutlinedButton(onPressed: _delete, child: const Text('Delete')),
      OutlinedButton(onPressed: _move, child: const Text('Move')),
      OutlinedButton(onPressed: _copyPath, child: const Text('Copy path')),
      OutlinedButton(onPressed: _exists, child: const Text('Check existence')),
      OutlinedButton(onPressed: _mkdir, child: const Text('Mkdir')),
      CheckboxListTile(
        title: const Text('Overwrite flag'),
        value: _overwriteFlag,
        onChanged: (value) {
          setState(() {
            _overwriteFlag = value!;
          });
        },
      ),
    ];
  }

  Future<void> _selectFolder() async {
    try {
      String? dirUrl;
      if (Platform.isMacOS) {
        var list = await _macosPicker.pick(MacosFilePickerMode.folder);
        if (list == null) {
          dirUrl = null;
        } else {
          dirUrl = list.first.url;
        }
      } else {
        final res = await _iosPicker.pick(DocumentPickerType.directory);
        if (res == null) {
          dirUrl = null;
        } else {
          dirUrl = res.first.url;
        }
      }
      if (dirUrl == null) {
        return;
      }

      var hasAccess = await _accessPlugin
          .startAccessingSecurityScopedResourceWithURL(dirUrl);
      if (!hasAccess) {
        throw 'Failed to gain access to $dirUrl';
      }
      setState(() {
        _icloudFolder = dirUrl;
      });
    } catch (err) {
      await _showErrorAlert(context, err.toString());
    }
  }

  Future<void> _readSync({bool? partial}) async {
    try {
      var dir = _icloudFolder;
      var fileRelPath = _fileTextController.text;
      if (fileRelPath.isEmpty || dir == null) {
        return;
      }
      var fileAbsUrl =
          await _darwinUrlPlugin.append(dir, [fileRelPath], isDir: false);

      setState(() {
        _output = 'Reading/downloading $dir';
      });
      final data = await _plugin.readFileSync(fileAbsUrl,
          start: partial == true ? 3 : null, count: partial == true ? 2 : null);
      setState(() {
        _output = 'File content: ${data.length} bytes';
      });
    } catch (err) {
      setState(() {
        _output = '';
      });
      await _showErrorAlert(context, err.toString());
    }
  }

  Future<void> _list({required bool recursive}) async {
    try {
      var dir = _icloudFolder;
      if (dir == null) {
        return;
      }
      setState(() {
        _output = 'Listing contents of $dir';
      });
      var contents = await _plugin.listContents(dir,
          recursive: recursive, relativePathInfo: true);
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

  Future<void> _listFiles() async {
    try {
      var dir = _icloudFolder;
      if (dir == null) {
        return;
      }
      setState(() {
        _output = 'Listing content files of $dir';
      });
      var contents = await _plugin.listContentFiles(dir);
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
      var fileAbsUrl =
          await _darwinUrlPlugin.append(dir, [fileRelPath], isDir: false);

      setState(() {
        _output = 'Getting information of $dir';
      });
      var info = await _plugin.stat(fileAbsUrl);
      setState(() {
        _output = info == null ? '<NULL>' : info.fullDescription();
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
      var fileAbsUrl =
          await _darwinUrlPlugin.append(dir, [fileRelPath], isDir: false);

      setState(() {
        _output = 'Deleting $dir';
      });
      await _plugin.delete(fileAbsUrl);
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
      var fileAbsUrl =
          await _darwinUrlPlugin.append(dir, [fileRelPath], isDir: false);
      var newFileAbsUrl =
          await _darwinUrlPlugin.append(dir, ['newName'], isDir: false);

      setState(() {
        _output = 'Rename $fileAbsUrl to $newFileAbsUrl';
      });
      await _plugin.move(fileAbsUrl, newFileAbsUrl);
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
      var fileAbsUrl =
          await _darwinUrlPlugin.append(dir, [fileRelPath], isDir: false);
      var tmpDir = await _createTempDir();
      var tmpDirUrl = await _darwinUrlPlugin.filePathToUrl(tmpDir);

      setState(() {
        _output = 'Writing to $fileAbsUrl: overwrite=$_overwriteFlag';
      });
      await _plugin.copyPath(tmpDirUrl, fileAbsUrl, overwrite: _overwriteFlag);
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

  Future<void> _exists() async {
    try {
      var dir = _icloudFolder;
      var fileRelPath = _fileTextController.text;
      if (fileRelPath.isEmpty || dir == null) {
        return;
      }
      var fileAbsUrl =
          await _darwinUrlPlugin.append(dir, [fileRelPath], isDir: false);

      setState(() {
        _output = 'Checking if $fileAbsUrl exists';
      });
      var isDir = await _plugin.isDirectory(fileAbsUrl);
      setState(() {
        if (isDir == null) {
          _output = 'Not found';
          return;
        }
        _output = 'Result: ${isDir ? 'is a directory' : 'is a file'}';
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
      var dirName = _fileTextController.text;
      if (dirName.isEmpty || dir == null) {
        return;
      }

      setState(() {
        _output = 'Creating directory $dirName';
      });
      await _plugin.mkdirp(dir, [dirName]);
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
