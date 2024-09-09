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
  
  public static func register(with registrar: FlutterPluginRegistrar) {
#if os(iOS)
    let binaryMessenger = registrar.messenger()
#elseif os(macOS)
    let binaryMessenger = registrar.messenger
#endif
    let channel = FlutterMethodChannel(name: "ns_file_coordinator_util", binaryMessenger: binaryMessenger)
    let instance = NsFileCoordinatorUtilPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? Dictionary<String, Any> else {
      result(FlutterError(code: "InvalidArgsType", message: "Invalid args type", details: nil))
      return
    }
    DispatchQueue.global().async {
      switch call.method {
      case "readFile":
        guard let url = URL(string: args["src"] as! String), let destURL = URL(string: args["dest"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = NsFileCoordinatorUtilPlugin.coordinateFSReading(url: url) { url in
          do {
            try FileManager.default.copyItem(at: url, to: destURL)
            return ResultWrapper.createResult(true)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        NsFileCoordinatorUtilPlugin.reportResult(result: result, data: res)
        
      case "stat":
        guard let url = URL(string: args["url"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = NsFileCoordinatorUtilPlugin.coordinateFSReading(url: url) { url in
          let statMap = try? NsFileCoordinatorUtilPlugin.fsStat(url: url, relativePath: false)
          return ResultWrapper.createResult(statMap)
        }
        NsFileCoordinatorUtilPlugin.reportResult(result: result, data: res)
        
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
        
        let res = NsFileCoordinatorUtilPlugin.coordinateFSReading(url: url) { url in
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
                try statMaps.append(NsFileCoordinatorUtilPlugin.fsStat(url: fileURL, relativePath: relativePathInfo))
              } catch { print(error, fileURL) }
            }
            return ResultWrapper.createResult(statMaps)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        NsFileCoordinatorUtilPlugin.reportResult(result: result, data: res)
        
      case "listContentFiles":
        guard let url = URL(string: args["url"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = NsFileCoordinatorUtilPlugin.coordinateFSReading(url: url) { url in
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
              try statMaps.append(NsFileCoordinatorUtilPlugin.urlAndRelativePath(url: fileURL))
            } catch { print(error, fileURL) }
          }
          return ResultWrapper.createResult(statMaps)
        }
        NsFileCoordinatorUtilPlugin.reportResult(result: result, data: res)
        
      case "delete":
        guard let url = URL(string: args["url"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = NsFileCoordinatorUtilPlugin.coordinateFSDeleting(url: url) { url in
          do {
            try FileManager.default.removeItem(at: url)
            return ResultWrapper.createResult(true)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        NsFileCoordinatorUtilPlugin.reportResult(result: result, data: res)
        
      case "move":
        guard let srcURL = URL(string: args["src"] as! String), let destURL = URL(string: args["dest"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = NsFileCoordinatorUtilPlugin.coordinateFSMoving(src: srcURL, dest: destURL) { srcURL, destURL in
          do {
            try FileManager.default.moveItem(at: srcURL, to: destURL)
            return ResultWrapper.createResult(true)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        NsFileCoordinatorUtilPlugin.reportResult(result: result, data: res)
        
      case "copy":
        guard let srcURL = URL(string: args["src"] as! String), let destURL = URL(string: args["dest"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = NsFileCoordinatorUtilPlugin.coordinateFSReadingAndWriting(src: srcURL, dest: destURL) { srcURL, destURL in
          do {
            try FileManager.default.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: srcURL, to: destURL)
            return ResultWrapper.createResult(true)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        NsFileCoordinatorUtilPlugin.reportResult(result: result, data: res)
        
      case "isDirectory":
        guard let url = URL(string: args["url"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = NsFileCoordinatorUtilPlugin.coordinateFSReading(url: url) { url in
          var isDirectory: ObjCBool = false
          let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
          return ResultWrapper.createResult(exists ? isDirectory.boolValue : nil)
        }
        NsFileCoordinatorUtilPlugin.reportResult(result: result, data: res)
        
      case "mkdir":
        guard let url = URL(string: args["url"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = NsFileCoordinatorUtilPlugin.coordinateFSWriting(url: url) { url in
          do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return ResultWrapper.createResult(true)
          } catch {
            return ResultWrapper.createError(error)
          }
        }
        NsFileCoordinatorUtilPlugin.reportResult(result: result, data: res)
        
      case "isEmptyDirectory":
        guard let url = URL(string: args["url"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        let res = NsFileCoordinatorUtilPlugin.coordinateFSReading(url: url, cb: { url in
          do {
            let contentURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [])
            let isEmpty = contentURLs.count == 0
            return ResultWrapper.createResult(isEmpty)
          } catch {
            return ResultWrapper.createError(error)
          }
        })
        NsFileCoordinatorUtilPlugin.reportResult(result: result, data: res)
        
      default:
        DispatchQueue.main.async {
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
  
  private static func reportResult<T>(result: @escaping FlutterResult, data: ResultWrapper<T>) {
    DispatchQueue.main.async {
      if let err = data.error {
        result(FlutterError(code: "PluginError", message: err.localizedDescription, details: nil))
      } else {
        result(data.result!)
      }
    }
  }
  
  private static func coordinateFSDeleting<T>(url: URL, cb: (URL) -> ResultWrapper<T>) -> ResultWrapper<T> {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(writingItemAt: url, options: .forDeleting, error: &coordinatorErr) { (url) in
      res = cb(url)
    }
    
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
  
  private static func coordinateFSWriting<T>(url: URL, cb: (URL) -> ResultWrapper<T>) -> ResultWrapper<T> {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(writingItemAt: url, error: &coordinatorErr) { (url) in
      res = cb(url)
    }
    
    guard let res = res else {
      return ResultWrapper<T>.createError(CustomError(errorMessage: "Unexpected nil res in coordinateFSWriting"))
    }
    if res.error != nil {
      return res
    }
    if let err = coordinatorErr {
      return ResultWrapper<T>.createError(err)
    }
    return res
  }
  
  private static func coordinateFSReading<T>(url: URL, cb: (URL) -> ResultWrapper<T>) -> ResultWrapper<T> {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(readingItemAt: url, error: &coordinatorErr) { (url) in
      res = cb(url)
    }
    
    guard let res = res else {
      return ResultWrapper<T>.createError(CustomError(errorMessage: "Unexpected nil res in coordinateFSReading"))
    }
    if res.error != nil {
      return res
    }
    if let err = coordinatorErr {
      return ResultWrapper<T>.createError(err)
    }
    return res
  }
  
  private static func coordinateReadingAndWriting<T>(src: URL, dest: URL, cb: (URL, URL) -> ResultWrapper<T>) -> ResultWrapper<T> {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(readingItemAt: src, writingItemAt: dest, error: &coordinatorErr) { (src, dest) in
      res = cb(src, dest)
    }
    
    guard let res = res else {
      return ResultWrapper<T>.createError(CustomError(errorMessage: "Unexpected nil res in coordinateReadingAndWriting"))
    }
    if res.error != nil {
      return res
    }
    if let err = coordinatorErr {
      return ResultWrapper<T>.createError(err)
    }
    return res
  }
  
  private static func coordinateFSMoving<T>(src: URL, dest: URL, cb: (URL, URL) -> ResultWrapper<T>) -> ResultWrapper<T> {
    var coordinatorErr: NSError? = nil
    var res: ResultWrapper<T>?
    NSFileCoordinator().coordinate(writingItemAt: src, options: .forMoving, writingItemAt: dest, options: .forReplacing, error: &coordinatorErr) { (src, dest) in
      res = cb(src, dest)
    }
    
    guard let res = res else {
      return ResultWrapper<T>.createError(CustomError(errorMessage: "Unexpected nil res in coordinateFSMoving"))
    }
    if res.error != nil {
      return res
    }
    if let err = coordinatorErr {
      return ResultWrapper<T>.createError(err)
    }
    return res
  }
  
  private static func fsStat(url: URL, relativePath: Bool) throws -> [String: Any?] {
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
  
  private static func urlAndRelativePath(url: URL) throws -> [String: Any?] {
    var urlString = url.absoluteString
    var stat: [String: Any?] = [
      "url": urlString,
    ]
    if !url.relativePath.isEmpty {
      stat["relativePath"] = url.relativePath
    }
    return stat
  }
}
