import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

struct CustomError: Error, LocalizedError {
  let errorMessage: String

  var errorDescription: String? {
    return errorMessage
  }

  init(errorMessage: String) {
    self.errorMessage = errorMessage
  }
}

class ResultWrapper<T> {
  let result: T?
  let error: Error?

  private init(result: T? = nil, error: Error? = nil) {
    self.result = result
    self.error = error
  }

  static func createResult(_ result: T) -> ResultWrapper {
    return ResultWrapper(result: result)
  }

  static func createError(_ error: Error) -> ResultWrapper {
    return ResultWrapper(error: error)
  }
}

public class NsFileCoordinatorUtilPlugin: NSObject, FlutterPlugin {
  static let fsResourceKeys: [URLResourceKey] = [
    .nameKey, .fileSizeKey, .isDirectoryKey, .contentModificationDateKey,
  ]

  private let binaryMessenger: FlutterBinaryMessenger
  private var writeStreams: [Int: WriteFileHandler] = [:]

  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
      let binaryMessenger = registrar.messenger()
    #elseif os(macOS)
      let binaryMessenger = registrar.messenger
    #endif
    let channel = FlutterMethodChannel(
      name: "ns_file_coordinator_util", binaryMessenger: binaryMessenger)
    let instance = NsFileCoordinatorUtilPlugin(binaryMessenger: binaryMessenger)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  init(binaryMessenger: FlutterBinaryMessenger) {
    self.binaryMessenger = binaryMessenger
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "InvalidArgsType", message: "Invalid args type", details: nil))
      return
    }
    switch call.method {
    case "readFileSync":
      guard let url = URL(string: args["src"] as! String) else {
        result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
        return
      }
      let start = args["start"] as? Int
      let count = args["count"] as? Int

      DispatchQueue.global().async {
        let res = self.coordinateFSReading(url: url) { url in
          do {
            if let start = start, let count = count, url.isFileURL {
              return ResultWrapper.createResult(
                try self.readFileSyncWithOffset(from: url, startIndex: UInt64(start), count: count))
            }
            let data = try Data(contentsOf: url)
            return ResultWrapper.createResult(data)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        self.reportResult(result: result, data: res)
      }

    case "readFileStream":
      guard let url = URL(string: args["src"] as! String),
        let session = args["session"] as? Int
      else {
        result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
        return
      }
      let bufferSize = args["bufferSize"] as? Int ?? 4 * 1024 * 1024
      let debugDelay = args["debugDelay"] as? Double
      let start = args["start"] as? Int

      let streamQueue = DispatchQueue.init(label: "ns_file_coordinator_util/r/\(session)")
      let readHandler = ReadFileHandler(
        url: url, bufferSize: bufferSize, queue: streamQueue, debugDelay: debugDelay, start: start)
      let eventChannel = FlutterEventChannel(
        name: "ns_file_coordinator_util/event/\(session)", binaryMessenger: self.binaryMessenger)
      eventChannel.setStreamHandler(readHandler)

      DispatchQueue.global().async {
        var coordinatorErr: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: url, error: &coordinatorErr) { (url) in
          DispatchQueue.main.async {
            // Returns immediately and let dart side start listening stream.
            result(nil)
          }

          // Block current queue until read handler is completed.
          readHandler.wait()
        }
        // If err is not nil, the block in coordinator is not executed.
        if let coordinatorErr = coordinatorErr {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "PluginError", message: coordinatorErr.localizedDescription, details: nil))
          }
        }
      }

    case "stat":
      guard let url = URL(string: args["url"] as! String) else {
        result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
        return
      }

      DispatchQueue.global().async {
        let res = self.coordinateFSReading(url: url) { url in
          let statMap = try? self.fsStat(url: url, relativePath: false)
          return ResultWrapper.createResult(statMap)
        }
        self.reportResult(result: result, data: res)
      }

    case "listContents":
      guard let url = URL(string: args["url"] as! String) else {
        result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
        return
      }
      let recursive = args["recursive"] as? Bool ?? false
      let filesOnly = args["filesOnly"] as? Bool ?? false
      let relativePathInfo = args["relativePathInfo"] as? Bool ?? false

      DispatchQueue.global().async {
        let res = self.coordinateFSReading(url: url) { url in
          do {
            var contentURLs: [URL]
            if recursive {
              var urls = [URL]()
              if let enumerator = FileManager.default.enumerator(
                at: url, includingPropertiesForKeys: NsFileCoordinatorUtilPlugin.fsResourceKeys,
                options: relativePathInfo ? [.producesRelativePathURLs] : [])
              {
                for case let fileURL as URL in enumerator {
                  if filesOnly && fileURL.hasDirectoryPath {
                    continue
                  }
                  urls.append(fileURL)
                }
              }
              contentURLs = urls
            } else {
              contentURLs = try FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: NsFileCoordinatorUtilPlugin.fsResourceKeys)

              if filesOnly {
                contentURLs = contentURLs.filter { !$0.hasDirectoryPath }
              }
            }

            var statMaps: [[String: Any?]] = []
            for fileURL in contentURLs {
              do {
                try statMaps.append(self.fsStat(url: fileURL, relativePath: relativePathInfo))
              } catch { print(error, fileURL) }
            }
            return ResultWrapper.createResult(statMaps)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        self.reportResult(result: result, data: res)
      }

    case "listContentFiles":
      guard let url = URL(string: args["url"] as! String) else {
        result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
        return
      }

      DispatchQueue.global().async {
        let res = self.coordinateFSReading(url: url) { url in
          var contentURLs: [URL]
          var urls = [URL]()
          if let enumerator = FileManager.default.enumerator(
            at: url, includingPropertiesForKeys: NsFileCoordinatorUtilPlugin.fsResourceKeys,
            options: [.producesRelativePathURLs])
          {
            for case let fileURL as URL in enumerator {
              if fileURL.hasDirectoryPath {
                continue
              }
              urls.append(fileURL)
            }
          }
          contentURLs = urls

          var statMaps: [[String: Any?]] = []
          for fileURL in contentURLs {
            do {
              try statMaps.append(self.urlAndRelativePath(url: fileURL))
            } catch { print(error, fileURL) }
          }
          return ResultWrapper.createResult(statMaps)
        }
        self.reportResult(result: result, data: res)
      }

    case "delete":
      guard let url = URL(string: args["url"] as! String) else {
        result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
        return
      }

      DispatchQueue.global().async {
        let res = self.coordinateFSDeleting(url: url) { url in
          do {
            try FileManager.default.removeItem(at: url)
            return ResultWrapper.createResult(true)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        self.reportResult(result: result, data: res)
      }

    case "move":
      guard let srcURL = URL(string: args["src"] as! String),
        let destURL = URL(string: args["dest"] as! String)
      else {
        result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
        return
      }

      DispatchQueue.global().async {
        let res = self.coordinateFSMoving(src: srcURL, dest: destURL) { srcURL, destURL in
          do {
            try FileManager.default.moveItem(at: srcURL, to: destURL)
            return ResultWrapper.createResult(true)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        self.reportResult(result: result, data: res)
      }

    case "copyPath":
      guard let srcURL = URL(string: args["src"] as! String),
        let destURL = URL(string: args["dest"] as! String)
      else {
        result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
        return
      }
      let overwrite = args["overwrite"] as? Bool ?? false

      DispatchQueue.global().async {
        let res = self.coordinateFSReadingAndWriting(src: srcURL, dest: destURL) {
          srcURL, destURL in
          do {
            try FileManager.default.createDirectory(
              at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if overwrite && FileManager.default.fileExists(atPath: destURL.path) {
              _ = try FileManager.default.replaceItemAt(destURL, withItemAt: srcURL)
            } else {
              try FileManager.default.copyItem(at: srcURL, to: destURL)
            }
            return ResultWrapper.createResult(true)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        self.reportResult(result: result, data: res)
      }

    case "isDirectory":
      guard let url = URL(string: args["url"] as! String) else {
        result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
        return
      }

      DispatchQueue.global().async {
        let res = self.coordinateFSReading(url: url) { url in
          var isDirectory: ObjCBool = false
          let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
          return ResultWrapper.createResult(exists ? isDirectory.boolValue : nil)
        }
        self.reportResult(result: result, data: res)
      }

    case "mkdirp":
      guard let parentUrl = URL(string: args["url"] as! String) else {
        result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
        return
      }
      let components = args["components"] as! [String]
      let url = components.reduce(parentUrl) { $0.appendingPathComponent($1) }

      DispatchQueue.global().async {
        let res = self.coordinateFSWriting(url: url) { url in
          do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return ResultWrapper.createResult(url.absoluteString)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        self.reportResult(result: result, data: res)
      }

    case "writeFile":
      guard let url = URL(string: args["url"] as! String) else {
        result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
        return
      }
      let dartData = args["data"] as! FlutterStandardTypedData

      DispatchQueue.global().async {
        let res = self.coordinateFSWriting(url: url) { url in
          do {
            try dartData.data.write(to: url)
            return ResultWrapper.createResult(true)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        self.reportResult(result: result, data: res)
      }

    case "startWriteStream":
      guard let url = URL(string: args["url"] as! String) else {
        result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
        return
      }
      let session = args["session"] as! Int

      let streamQueue = DispatchQueue.init(label: "ns_file_coordinator_util/w/\(session)")
      let writeHandler = WriteFileHandler(url: url, queue: streamQueue)
      writeStreams[session] = writeHandler

      DispatchQueue.global().async {
        var coordinatorErr: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: url, error: &coordinatorErr) { (url) in
          DispatchQueue.main.async {
            // Return before waiting (unblock dart caller).
            result(nil)
          }
          writeHandler.wait()
          // Clean up.
          DispatchQueue.main.async {
            self.writeStreams.removeValue(forKey: session)
            // Unblock dart `endWriteStream` call.
            writeHandler.endResult?(nil)
          }
        }
        // If err is not nil, the block in coordinator is not executed.
        if let coordinatorErr = coordinatorErr {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "PluginError", message: coordinatorErr.localizedDescription, details: nil))
          }
        }
      }

    case "writeChunk":
      let session = args["session"] as! Int
      let dartData = args["data"] as! FlutterStandardTypedData
      let data = dartData.data
      guard let writer = self.writeStreams[session] else {
        result(FlutterError(code: "ArgError", message: "Session not found", details: nil))
        return
      }

      DispatchQueue.global().async {
        writer.writeDataAsync(data, writeResult: result)
      }

    case "endWriteStream":
      let session = args["session"] as! Int
      guard let writer = self.writeStreams[session] else {
        result(FlutterError(code: "ArgError", message: "Session not found", details: nil))
        return
      }
      // This will free the semaphore and unblock the write queue in `startWriteStream`.
      // `result` will get called in `startWriteStream` block.
      writer.endWrite(endResult: result)

    case "getPendingWritingSessions":
      let keys = Array(self.writeStreams.keys)
      result(keys)

    case "isEmptyDirectory":
      guard let url = URL(string: args["url"] as! String) else {
        result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
        return
      }

      DispatchQueue.global().async {
        let res = self.coordinateFSReading(
          url: url,
          cb: { url in
            do {
              let contentURLs = try FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: [])
              let isEmpty = contentURLs.count == 0
              return ResultWrapper.createResult(isEmpty)
            } catch {
              return ResultWrapper.createError(error)
            }
          })
        self.reportResult(result: result, data: res)
      }

    default:
      DispatchQueue.main.async {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func reportResult<T>(result: @escaping FlutterResult, data: ResultWrapper<T>) {
    DispatchQueue.main.async {
      if let err = data.error {
        result(FlutterError(code: "PluginError", message: err.localizedDescription, details: nil))
      } else {
        result(data.result!)
      }
    }
  }

  private func handleResultWrapperError<T>(_ res: ResultWrapper<T>?, coordinatorErr: NSError?, context: String)
    -> ResultWrapper<T>
  {
    guard let res = res else {
      return ResultWrapper<T>.createError(
        CustomError(errorMessage: "Unexpected nil result in \(context)"))
    }
    if res.error != nil {
      return res
    }
    if let err = coordinatorErr {
      return ResultWrapper<T>.createError(err)
    }
    return res
  }

  private func coordinateFSDeleting<T>(url: URL, cb: (URL) -> ResultWrapper<T>) -> ResultWrapper<T>
  {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(
      writingItemAt: url, options: .forDeleting, error: &coordinatorErr
    ) { (url) in
      res = cb(url)
    }
    return handleResultWrapperError(res, coordinatorErr: coordinatorErr, context: "FSDelete")
  }

  private func coordinateFSWriting<T>(url: URL, cb: (URL) -> ResultWrapper<T>) -> ResultWrapper<T> {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(writingItemAt: url, error: &coordinatorErr) { (url) in
      res = cb(url)
    }
    return handleResultWrapperError(res, coordinatorErr: coordinatorErr, context: "FSWrite")
  }

  private func coordinateFSReading<T>(url: URL, cb: (URL) -> ResultWrapper<T>) -> ResultWrapper<T> {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(readingItemAt: url, error: &coordinatorErr) { (url) in
      res = cb(url)
    }
    return handleResultWrapperError(res, coordinatorErr: coordinatorErr, context: "FSRead")
  }

  private func coordinateFSReadingAndWriting<T>(
    src: URL, dest: URL, cb: (URL, URL) -> ResultWrapper<T>
  ) -> ResultWrapper<T> {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(readingItemAt: src, writingItemAt: dest, error: &coordinatorErr)
    { (src, dest) in
      res = cb(src, dest)
    }
    return handleResultWrapperError(res, coordinatorErr: coordinatorErr, context: "FSReadAndWrite")
  }

  private func coordinateFSMoving<T>(src: URL, dest: URL, cb: (URL, URL) -> ResultWrapper<T>)
    -> ResultWrapper<T>
  {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(
      writingItemAt: src, options: .forMoving, writingItemAt: dest, options: .forReplacing,
      error: &coordinatorErr
    ) { (src, dest) in
      res = cb(src, dest)
    }
    return handleResultWrapperError(res, coordinatorErr: coordinatorErr, context: "FSMove")
  }

  private func fsStat(url: URL, relativePath: Bool) throws -> [String: Any?] {
    let fileAttributes = try url.resourceValues(
      forKeys: Set(NsFileCoordinatorUtilPlugin.fsResourceKeys))
    let lastModRaw = fileAttributes.contentModificationDate
    var lastMod: Int? = nil
    if let lastModRaw = lastModRaw {
      lastMod = Int(lastModRaw.timeIntervalSince1970)
    }
    let isDir = fileAttributes.isDirectory ?? false
    var urlString = url.absoluteString
    // Make sure directory URLs always end with a trailing /
    if isDir && !urlString.hasSuffix("/") {
      urlString += "/"
    }

    var stat: [String: Any?] = [
      "name": fileAttributes.name,
      "url": urlString,
      // Make sure `size` always has a value to ease parsing code on dart.
      "length": fileAttributes.fileSize ?? 0,
      "isDir": isDir,
      "lastMod": lastMod,
    ]
    if relativePath && !url.relativePath.isEmpty {
      stat["relativePath"] = url.relativePath
    }
    return stat
  }

  private func urlAndRelativePath(url: URL) throws -> [String: Any?] {
    var stat: [String: Any?] = [
      "url": url.absoluteString
    ]
    if !url.relativePath.isEmpty {
      stat["relativePath"] = url.relativePath
    }
    return stat
  }

  private func readFileSyncWithOffset(from fileURL: URL, startIndex: UInt64, count: Int) throws
    -> Data?
  {
    let fileHandle = try FileHandle(forReadingFrom: fileURL)
    try fileHandle.seek(toOffset: startIndex)
    let data = try fileHandle.read(upToCount: count)
    try fileHandle.close()

    return data
  }
}

class ReadFileHandler: NSObject, FlutterStreamHandler {
  let url: URL
  let bufferSize: Int
  let queue: DispatchQueue
  let debugDelay: Double?
  let start: Int?

  private let semaphore = DispatchSemaphore(value: 0)
  private var eventSink: FlutterEventSink?
  private var isCancelled = false

  init(url: URL, bufferSize: Int, queue: DispatchQueue, debugDelay: Double?, start: Int?) {
    self.url = url
    self.bufferSize = bufferSize
    self.queue = queue
    self.debugDelay = debugDelay
    self.start = start
  }

  // This is called from plugin thread.
  func wait() {
    semaphore.wait()  // Block the calling thread
  }

  // Called from main thread.
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    // Use instance variable `eventSink` instead of `events`. Because when `onCancel` is called, `eventSink` is reset.
    self.eventSink = events
    // Don't block the main thread, reading happens on a queue.
    queue.async {
      do {
        if self.url.isFileURL {
          let fileHandle = try FileHandle(forReadingFrom: self.url)
          if let start = self.start {
            try fileHandle.seek(toOffset: UInt64(start))
          }
          while true {
            if let delay = self.debugDelay {
              Thread.sleep(forTimeInterval: delay)
            }
            let data = try fileHandle.read(upToCount: self.bufferSize)
            guard let buffer = data, !buffer.isEmpty else {
              break
            }
            DispatchQueue.main.async {
              self.eventSink?(data)
            }
          }
          try fileHandle.close()
        } else {
          if let stream = InputStream(url: self.url) {
            var buf = [UInt8](repeating: 0, count: self.bufferSize)
            stream.open()

            while case let amount = stream.read(&buf, maxLength: self.bufferSize), amount > 0,
              !self.isCancelled
            {
              if let delay = self.debugDelay {
                Thread.sleep(forTimeInterval: delay)
              }
              let data = Data(buf[..<amount])
              DispatchQueue.main.async {
                self.eventSink?(data)
              }
            }
            stream.close()
          }
        }

        DispatchQueue.main.async {
          self.eventSink?(FlutterEndOfEventStream)
          self.semaphore.signal()
        }
      } catch {
        DispatchQueue.main.async {
          self.eventSink?(
            FlutterError(code: "PluginError", message: error.localizedDescription, details: nil))
          self.semaphore.signal()
        }
      }
    }  // end of queue.async
    return nil
  }

  // Called from main thread.
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    self.isCancelled = true
    // Don't cancel semaphore here. It will be handled in `onListen`.
    return nil
  }
}

class WriteFileHandler: NSObject {
  let url: URL
  let queue: DispatchQueue
  var endResult: FlutterResult?

  private var firstWrite = true

  private let semaphore = DispatchSemaphore(value: 0)

  init(url: URL, queue: DispatchQueue) {
    self.url = url
    self.queue = queue
  }

  // This is called from plugin thread.
  func wait() {
    semaphore.wait()  // Block the calling thread
  }

  // Called from main thread.
  func writeDataAsync(_ data: Data, writeResult: @escaping FlutterResult) {
    // Don't block the main thread, writing happens on a queue.
    queue.async {
      do {
        if self.firstWrite {
          // Clear the dest file on first write.
          self.firstWrite = false
          try Data().write(to: self.url)
        }
        try data.append(fileURL: self.url)
        DispatchQueue.main.async {
          writeResult(nil)
        }
      } catch {
        DispatchQueue.main.async {
          writeResult(
            FlutterError(code: "WriteError", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  func endWrite(endResult: @escaping FlutterResult) {
    self.endResult = endResult
    self.semaphore.signal()
  }
}

class WriteFileStreamResult {
  let isCancelled: Bool?
  let error: String?

  init(isCancelled: Bool?, error: String?) {
    self.isCancelled = isCancelled
    self.error = error
  }
}

extension Data {
  func append(fileURL: URL) throws {
    if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
      defer {
        fileHandle.closeFile()
      }
      fileHandle.seekToEndOfFile()
      fileHandle.write(self)
    } else {
      try write(to: fileURL, options: .atomic)
    }
  }
}
