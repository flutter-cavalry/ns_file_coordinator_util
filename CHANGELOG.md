## 0.25.0

- Rename `readFileSync` to `readFileBytes`.

## 0.24.2

- `readFileSync` now supports optional `start` and `count` parameters.

## 0.24.0

- Stop swallowing exceptions in `stat`.

## 0.23.0

- Add Swift Package Manager support.

## 0.22.0

- Add `start` param to `readFileStream`.

## 0.21.0

- Add `start` and `count` params to `readFileSync`.

## 0.20.0

- (**Breaking**) `readFile` now returns a `Uint8List`.
- (**Breaking**) Add `readFileStream`.

## 0.15.0

- Add `listContentFiles` to list only files in a directory.

## 0.14.1

- Better handling of `filesOnly`.

## 0.14.0

- Add `relativePathInfo` to `listContents` to return relative path information.

## 0.13.0

- Allow users to opt out of coordinator by using the `scope` parameter.

## 0.12.0

- `stat` now returns null instead of throwing an exception if the file doesn't exist.

## 0.11.2

- Make sure directory URLs always end with a trailing /.

## 0.11.0

- Replaced Dart `Uri` to `String`.

## 0.10.0

- Migrate to Uri based APIs

## 0.9.0

- Renamed `entityType` to `isDirectory`

## 0.8.0

- Added `stat` function.

## 0.7.10

- Added `filesOnly` to `listContents` function.

## 0.7.5

- Added `recursive` argument to `listContents` function.

## 0.7.0

- Renamed `exists` to `entityType` to return entity type whiling checking existence.

## 0.6.5

- Fetch `.contentModificationDateKey` in `listContents`.

## 0.6.0

- Added `isEmptyDirectory`.

## 0.5.0

- Moved work off the main thread.

## 0.4.0

- Added `mkdir` function.

## 0.3.0

- Rename `copyFile` to `copy`.

## 0.2.1

- Create base directories before writing destination file.

## 0.2.0

- Added `exists` function.

## 0.1.0

- Added more util functions.

## 0.0.1

- Initial release.
