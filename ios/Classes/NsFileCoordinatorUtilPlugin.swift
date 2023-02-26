import Flutter
import UIKit

public class NsFileCoordinatorUtilPlugin: NSObject, FlutterPlugin {
  static let fsResourceKeys: [URLResourceKey] = [.nameKey, .fileSizeKey, .isDirectoryKey, .contentModificationDateKey]
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ns_file_coordinator_util", binaryMessenger: registrar.messenger())
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
        guard let srcURL = URL(string: args["src"] as! String), let destURL = URL(string: args["dest"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: srcURL, error: &error) { (url) in
          do {
            try FileManager.default.copyItem(at: srcURL, to: destURL)
            DispatchQueue.main.async {
              result(nil)
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "ReadFileError", message: error.localizedDescription, details: nil))
            }
          }
        }
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
          }
        }
        
      case "stat":
        guard let srcURL = URL(string: args["path"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: srcURL, error: &error) { (url) in
          do {
            let statMap = try NsFileCoordinatorUtilPlugin.fsStat(url: srcURL)
            DispatchQueue.main.async {
              result(statMap)
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "StatError", message: error.localizedDescription, details: nil))
            }
          }
        }
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
          }
        }
        
      case "listContents":
        guard let srcURL = URL(string: args["path"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        let recursive = args["recursive"] as? Bool ?? false
        let filesOnly = args["filesOnly"] as? Bool ?? false
        
        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: srcURL, error: &error) { (url) in
          do {
            var contentURLs: [URL]
            if recursive {
              var urls = [URL]()
              if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: NsFileCoordinatorUtilPlugin.fsResourceKeys) {
                  for case let fileURL as URL in enumerator {
                    urls.append(fileURL)
                  }
              }
              contentURLs = urls
            } else {
              contentURLs = try FileManager.default.contentsOfDirectory(at: srcURL, includingPropertiesForKeys: NsFileCoordinatorUtilPlugin.fsResourceKeys)
            }
            
            if (filesOnly) {
              contentURLs = contentURLs.filter { !$0.hasDirectoryPath }
            }
            
            var statMaps: [[String: Any?]] = []
            for fileURL in contentURLs {
              do {
                try statMaps.append(NsFileCoordinatorUtilPlugin.fsStat(url: fileURL))
              } catch { print(error, fileURL) }
            }
            DispatchQueue.main.async {
              result(statMaps)
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "ListContentError", message: error.localizedDescription, details: nil))
            }
          }
        }
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
          }
        }
        
      case "delete":
        guard let srcURL = URL(string: args["path"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        var error: NSError? = nil
        NSFileCoordinator().coordinate(writingItemAt: srcURL, options: .forDeleting, error: &error) { (url) in
          do {
            try FileManager.default.removeItem(at: srcURL)
            DispatchQueue.main.async {
              result(nil)
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "DeleteError", message: error.localizedDescription, details: nil))
            }
          }
        }
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
          }
        }
        
      case "move":
        guard let srcURL = URL(string: args["src"] as! String), let destURL = URL(string: args["dest"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        var error: NSError? = nil
        NSFileCoordinator().coordinate(writingItemAt: srcURL, options: .forMoving, writingItemAt: destURL, options: .forReplacing, error: &error) { srcURL, destURL in
          do {
            try FileManager.default.moveItem(at: srcURL, to: destURL)
            DispatchQueue.main.async {
              result(nil)
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "MoveError", message: error.localizedDescription, details: nil))
            }
          }
        }
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
          }
        }
        
      case "copy":
        guard let srcURL = URL(string: args["src"] as! String), let destURL = URL(string: args["dest"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: srcURL, writingItemAt: destURL, error: &error) { srcURL, destURL in
          do {
            try FileManager.default.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: srcURL, to: destURL)
            DispatchQueue.main.async {
              result(nil)
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "CopyFileError", message: error.localizedDescription, details: nil))
            }
          }
        }
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
          }
        }
        
        
      case "isDirectory":
        guard let srcURL = URL(string: args["path"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: srcURL, error: &error) { (url) in
          var isDirectory: ObjCBool = false
          let exists = FileManager.default.fileExists(atPath: srcURL.path, isDirectory: &isDirectory)
          DispatchQueue.main.async {
            result(exists ? isDirectory.boolValue : nil)
          }
        }
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
          }
        }
        
      case "mkdir":
        guard let srcURL = URL(string: args["path"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        var error: NSError? = nil
        NSFileCoordinator().coordinate(writingItemAt: srcURL, error: &error) { destURL in
          do {
            try FileManager.default.createDirectory(at: srcURL, withIntermediateDirectories: true)
            DispatchQueue.main.async {
              result(nil)
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "MkdirError", message: error.localizedDescription, details: nil))
            }
          }
        }
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
          }
        }
        
      case "isEmptyDirectory":
        guard let srcURL = URL(string: args["path"] as! String) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "ArgError", message: "Invalid arguments", details: nil))
          }
          return
        }
        
        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: srcURL, error: &error) { (url) in
          do {
            let contentURLs = try FileManager.default.contentsOfDirectory(at: srcURL, includingPropertiesForKeys: [])
            let isEmpty = contentURLs.count == 0
            DispatchQueue.main.async {
              result(isEmpty)
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "ListContentError", message: error.localizedDescription, details: nil))
            }
          }
        }
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
          }
        }
        
      default:
        DispatchQueue.main.async {
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
  
  private static func fsStat(url: URL) throws -> [String: Any?] {
    let fileAttributes = try url.resourceValues(forKeys: Set(NsFileCoordinatorUtilPlugin.fsResourceKeys))
    let lastModRaw = fileAttributes.contentModificationDate
    var lastMod: Int? = nil
    if let lastModRaw = lastModRaw {
      lastMod = Int(lastModRaw.timeIntervalSince1970)
    }
    let stat: [String: Any?] = [
      "name": fileAttributes.name,
      "url": url.absoluteString,
      // Make sure `size` always has a value to ease parsing code on dart.
      "length": fileAttributes.fileSize ?? 0,
      "isDir": fileAttributes.isDirectory,
      "lastMod": lastMod
    ]
    return stat
  }
}
