import Cocoa
import FlutterMacOS

public class NsFileCoordinatorUtilPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ns_file_coordinator_util", binaryMessenger: registrar.messenger)
    let instance = NsFileCoordinatorUtilPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? Dictionary<String, Any> else {
      result(FlutterError(code: "InvalidArgsType", message: "Invalid args type", details: nil))
      return
    }
    switch call.method {
    case "readFile":
      // Arguments are enforced on dart side.
      let src = args["src"] as! String
      let dest = args["dest"] as! String
      
      let srcURL = URL(fileURLWithPath: src)
      let destURL = URL(fileURLWithPath: dest)
      
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
        result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
      }
      
    case "listContents":
      // Arguments are enforced on dart side.
      let src = args["src"] as! String
      
      let srcURL = URL(fileURLWithPath: src)
      
      var error: NSError? = nil
      NSFileCoordinator().coordinate(readingItemAt: srcURL, error: &error) { (url) in
        do {
          let contentURLs = try FileManager.default.contentsOfDirectory(at: srcURL, includingPropertiesForKeys: [.nameKey, .fileSizeKey, .isDirectoryKey])
          
          var fileMaps: [[String: Any?]] = []
          for fileURL in contentURLs {
            do {
              let fileAttributes = try fileURL.resourceValues(forKeys:[.nameKey, .fileSizeKey,  .isDirectoryKey])
              let fileDataMap: [String: Any?] = [
                "name": fileAttributes.name,
                "path": fileURL.path,
                // Make sure `size` always has a value to ease parsing code on dart.
                "length": fileAttributes.fileSize ?? 0,
                "isDir": fileAttributes.isDirectory
              ]
              fileMaps.append(fileDataMap)
            } catch { print(error, fileURL) }
          }
          DispatchQueue.main.async {
            result(fileMaps)
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "ListContentError", message: error.localizedDescription, details: nil))
          }
        }
      }
      if let error = error {
        result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
      }
      
    case "delete":
      // Arguments are enforced on dart side.
      let src = args["src"] as! String
      
      let srcURL = URL(fileURLWithPath: src)
      
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
        result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
      }
      
    case "move":
      // Arguments are enforced on dart side.
      let src = args["src"] as! String
      let dest = args["dest"] as! String
      
      let srcURL = URL(fileURLWithPath: src)
      let destURL = URL(fileURLWithPath: dest)
      
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
        result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
      }
      
    case "writeFile":
      // Arguments are enforced on dart side.
      let src = args["src"] as! String
      let dest = args["dest"] as! String
      
      let srcURL = URL(fileURLWithPath: src)
      let destURL = URL(fileURLWithPath: dest)
      
      var error: NSError? = nil
      NSFileCoordinator().coordinate(writingItemAt: destURL, error: &error) { destURL in
        do {
          try FileManager.default.copyItem(at: srcURL, to: destURL)
          DispatchQueue.main.async {
            result(nil)
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "WriteFileError", message: error.localizedDescription, details: nil))
          }
        }
      }
      if let error = error {
        result(FlutterError(code: "NSFileCoordinatorError", message: error.localizedDescription, details: nil))
      }
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
