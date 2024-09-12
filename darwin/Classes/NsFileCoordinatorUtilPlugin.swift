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
  static let fsResourceKeys: [URLResourceKey] = [.nameKey, .fileSizeKey, .isDirectoryKey, .contentModificationDateKey]
  
  let binaryMessenger: FlutterBinaryMessenger
  
  public static func register(with registrar: FlutterPluginRegistrar) {
#if os(iOS)
    let binaryMessenger = registrar.messenger()
#elseif os(macOS)
    let binaryMessenger = registrar.messenger
#endif
    let channel = FlutterMethodChannel(name: "ns_file_coordinator_util", binaryMessenger: binaryMessenger)
    let instance = NsFileCoordinatorUtilPlugin(binaryMessenger: binaryMessenger)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  init(binaryMessenger: FlutterBinaryMessenger) {
    self.binaryMessenger = binaryMessenger
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? Dictionary<String, Any> else {
      result(FlutterError(code: "InvalidArgsType", message: "Invalid args type", details: nil))
      return
    }
    DispatchQueue.global().async {
      switch call.method {
      case "readFile":
        guard let url = URL(string: args["src"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = self.coordinateFSReading(url: url) { url in
          do {
            let data = try Data(contentsOf: url)
            return ResultWrapper.createResult(data)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        self.reportResult(result: result, data: res)
        
      case "readFileStream":
        guard let url = URL(string: args["src"] as! String),
              let session = args["session"] as? Int
        else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        let bufferSize = args["bufferSize"] as? Int ?? 4 * 1024 * 1024
        let debugDelay = args["debugDelay"] as? Double
        var coordinatorErr: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: url, error: &coordinatorErr) { (url) in
          // Returns immediately and let dart side start listening stream.
          result(nil)
          let streamQueue = DispatchQueue.init(label: "ns_file_coordinator_util/stream_queue/\(session)")
          let eventHandler = ReadFileHandler(url: url, bufferSize: bufferSize, queue: streamQueue, debugDelay: debugDelay)
          let eventChannel = FlutterEventChannel(name: "ns_file_coordinator_util/event/\(session)", binaryMessenger: self.binaryMessenger)
          eventChannel.setStreamHandler(eventHandler)
          eventHandler.wait()
          eventChannel.setStreamHandler(nil)
        }
        // If err is not nil, the block in coordinator is not executed.
        if let coordinatorErr = coordinatorErr {
          result(FlutterError(code: "PluginError", message: coordinatorErr.localizedDescription, details: nil))
        }
        
      case "stat":
        guard let url = URL(string: args["url"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = self.coordinateFSReading(url: url) { url in
          let statMap = try? self.fsStat(url: url, relativePath: false)
          return ResultWrapper.createResult(statMap)
        }
        self.reportResult(result: result, data: res)
        
      case "listContents":
        guard let url = URL(string: args["url"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        let recursive = args["recursive"] as? Bool ?? false
        let filesOnly = args["filesOnly"] as? Bool ?? false
        let relativePathInfo = args["relativePathInfo"] as? Bool ?? false
        
        let res = self.coordinateFSReading(url: url) { url in
          do {
            var contentURLs: [URL]
            if recursive {
              var urls = [URL]()
              if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: NsFileCoordinatorUtilPlugin.fsResourceKeys, options: relativePathInfo ? [.producesRelativePathURLs] : []) {
                for case let fileURL as URL in enumerator {
                  if (filesOnly && fileURL.hasDirectoryPath) {
                    continue
                  }
                  urls.append(fileURL)
                }
              }
              contentURLs = urls
            } else {
              contentURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: NsFileCoordinatorUtilPlugin.fsResourceKeys)
              
              if (filesOnly) {
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
        
      case "listContentFiles":
        guard let url = URL(string: args["url"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = self.coordinateFSReading(url: url) { url in
          var contentURLs: [URL]
          var urls = [URL]()
          if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: NsFileCoordinatorUtilPlugin.fsResourceKeys, options: [.producesRelativePathURLs]) {
            for case let fileURL as URL in enumerator {
              if (fileURL.hasDirectoryPath) {
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
        
      case "delete":
        guard let url = URL(string: args["url"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = self.coordinateFSDeleting(url: url) { url in
          do {
            try FileManager.default.removeItem(at: url)
            return ResultWrapper.createResult(true)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        self.reportResult(result: result, data: res)
        
      case "move":
        guard let srcURL = URL(string: args["src"] as! String), let destURL = URL(string: args["dest"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = self.coordinateFSMoving(src: srcURL, dest: destURL) { srcURL, destURL in
          do {
            try FileManager.default.moveItem(at: srcURL, to: destURL)
            return ResultWrapper.createResult(true)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        self.reportResult(result: result, data: res)
        
      case "copyPath":
        guard let srcURL = URL(string: args["src"] as! String), let destURL = URL(string: args["dest"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = self.coordinateFSReadingAndWriting(src: srcURL, dest: destURL) { srcURL, destURL in
          do {
            try FileManager.default.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: srcURL, to: destURL)
            return ResultWrapper.createResult(true)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        self.reportResult(result: result, data: res)
        
      case "isDirectory":
        guard let url = URL(string: args["url"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = self.coordinateFSReading(url: url) { url in
          var isDirectory: ObjCBool = false
          let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
          return ResultWrapper.createResult(exists ? isDirectory.boolValue : nil)
        }
        self.reportResult(result: result, data: res)
        
      case "mkdir":
        guard let url = URL(string: args["url"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = self.coordinateFSWriting(url: url) { url in
          do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return ResultWrapper.createResult(true)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        self.reportResult(result: result, data: res)
        
      case "isEmptyDirectory":
        guard let url = URL(string: args["url"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = self.coordinateFSReading(url: url, cb: { url in
          do {
            let contentURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [])
            let isEmpty = contentURLs.count == 0
            return ResultWrapper.createResult(isEmpty)
          } catch {
            return ResultWrapper.createError(error)
          }
        })
        self.reportResult(result: result, data: res)
        
      default:
        DispatchQueue.main.async {
          result(FlutterMethodNotImplemented)
        }
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
  
  private func handleResultWrapperError<T>(_ res: ResultWrapper<T>?, coordinatorErr: NSError?) -> ResultWrapper<T> {
    guard let res = res else {
      return ResultWrapper<T>.createError(CustomError(errorMessage: "Unexpected nil res in coordinateFSDeleting"))
    }
    if res.error != nil {
      return res
    }
    if let err = coordinatorErr {
      return ResultWrapper<T>.createError(err)
    }
    return res
  }
  
  private func coordinateFSDeleting<T>(url: URL, cb: (URL) -> ResultWrapper<T>) -> ResultWrapper<T> {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(writingItemAt: url, options: .forDeleting, error: &coordinatorErr) { (url) in
      res = cb(url)
    }
    return handleResultWrapperError(res, coordinatorErr: coordinatorErr)
  }
  
  private func coordinateFSWriting<T>(url: URL, cb: (URL) -> ResultWrapper<T>) -> ResultWrapper<T> {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(writingItemAt: url, error: &coordinatorErr) { (url) in
      res = cb(url)
    }
    return handleResultWrapperError(res, coordinatorErr: coordinatorErr)
  }
  
  private func coordinateFSReading<T>(url: URL, cb: (URL) -> ResultWrapper<T>) -> ResultWrapper<T> {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(readingItemAt: url, error: &coordinatorErr) { (url) in
      res = cb(url)
    }
    return handleResultWrapperError(res, coordinatorErr: coordinatorErr)
  }
  
  private func coordinateFSReadingAndWriting<T>(src: URL, dest: URL, cb: (URL, URL) -> ResultWrapper<T>) -> ResultWrapper<T> {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(readingItemAt: src, writingItemAt: dest, error: &coordinatorErr) { (src, dest) in
      res = cb(src, dest)
    }
    return handleResultWrapperError(res, coordinatorErr: coordinatorErr)
  }
  
  private func coordinateFSMoving<T>(src: URL, dest: URL, cb: (URL, URL) -> ResultWrapper<T>) -> ResultWrapper<T> {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(writingItemAt: src, options: .forMoving, writingItemAt: dest, options: .forReplacing, error: &coordinatorErr) { (src, dest) in
      res = cb(src, dest)
    }
    return handleResultWrapperError(res, coordinatorErr: coordinatorErr)
  }
  
  private func fsStat(url: URL, relativePath: Bool) throws -> [String: Any?] {
    let fileAttributes = try url.resourceValues(forKeys: Set(NsFileCoordinatorUtilPlugin.fsResourceKeys))
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
      "lastMod": lastMod
    ]
    if relativePath && !url.relativePath.isEmpty {
      stat["relativePath"] = url.relativePath
    }
    return stat
  }
  
  private func urlAndRelativePath(url: URL) throws -> [String: Any?] {
    var stat: [String: Any?] = [
      "url": url.absoluteString,
    ]
    if !url.relativePath.isEmpty {
      stat["relativePath"] = url.relativePath
    }
    return stat
  }
}

class ReadFileHandler: NSObject, FlutterStreamHandler {
  let url: URL
  let bufferSize: Int
  let queue: DispatchQueue
  let debugDelay: Double?
  private let semaphore = DispatchSemaphore(value: 0)
  private var eventSink: FlutterEventSink?
  private var isCancelled = false
  
  init(url: URL, bufferSize: Int, queue: DispatchQueue, debugDelay: Double?) {
    self.url = url
    self.bufferSize = bufferSize
    self.queue = queue
    self.debugDelay = debugDelay
  }
  
  // This is called from plugin thread.
  func wait() {
    semaphore.wait()  // Block the calling thread
  }
  
  // Called from main thread.
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    // Use instance variable `eventSink` instead of `events`. Because when `onCancel` is called, `eventSink` is reset.
    self.eventSink = events
    // Don't block the main thread, reading happens on a queue.
    queue.async {
      if let stream = InputStream(url: self.url) {
        var buf = [UInt8](repeating: 0, count: self.bufferSize)
        stream.open()
        
        while case let amount = stream.read(&buf, maxLength: self.bufferSize), amount > 0, !self.isCancelled {
          if let delay = self.debugDelay {
            Thread.sleep(forTimeInterval: delay)
          }
          let data = Data(buf[..<amount])
          self.eventSink?(data)
        }
        stream.close()
      }
      
      self.eventSink?(FlutterEndOfEventStream)
      self.semaphore.signal()
    }
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
