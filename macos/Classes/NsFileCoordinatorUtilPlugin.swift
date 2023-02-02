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
            result(FlutterError(code: "ErrorCopyingFile", message: error.localizedDescription, details: nil))
          }
        }
      }
      if let error = error {
        result(FlutterError(code: "ErrorCoordinatingFile", message: error.localizedDescription, details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
