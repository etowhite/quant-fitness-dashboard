import Flutter
import UIKit
import UserNotifications
import HealthKit
import Security

@main
@objc class AppDelegate: FlutterAppDelegate, UIDocumentPickerDelegate {
  private var documentResult: FlutterResult?
  private var exporting = false
  private var temporaryExport: URL?
  private var documentChannel: FlutterMethodChannel?
  private var healthChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self
    let controller = window?.rootViewController as! FlutterViewController
    healthChannel = FlutterMethodChannel(name: "quant/health_capabilities", binaryMessenger: controller.binaryMessenger)
    healthChannel?.setMethodCallHandler { call, result in
      guard call.method == "healthKitAvailable" else { result(FlutterMethodNotImplemented); return }
      // Inspect the actual signed entitlement, never just an Info.plist claim.
      typealias CreateTask = @convention(c) (CFAllocator?) -> Unmanaged<CFTypeRef>?
      typealias CopyValue = @convention(c) (CFTypeRef, CFString, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> Unmanaged<CFTypeRef>?
      guard let createSymbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "SecTaskCreateFromSelf"),
        let copySymbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "SecTaskCopyValueForEntitlement") else { result(false); return }
      let create = unsafeBitCast(createSymbol, to: CreateTask.self)
      let copy = unsafeBitCast(copySymbol, to: CopyValue.self)
      guard let task = create(nil)?.takeRetainedValue(),
        let entitlement = copy(task, "com.apple.developer.healthkit" as CFString, nil)?.takeRetainedValue() as? Bool,
        entitlement else { result(false); return }
      result(HKHealthStore.isHealthDataAvailable())
    }
    documentChannel = FlutterMethodChannel(name: "smart_fitness/local_documents", binaryMessenger: controller.binaryMessenger)
    documentChannel?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      guard self.documentResult == nil else { result(FlutterError(code: "busy", message: "Document picker already open", details: nil)); return }
      self.documentResult = result
      let picker: UIDocumentPickerViewController
      if call.method == "export", let bytes = call.arguments as? FlutterStandardTypedData {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("quant-backup.json")
        do { try bytes.data.write(to: url, options: .atomic) } catch {
          self.documentResult = nil
          result(FlutterError(code: "write", message: "Cannot create backup", details: nil)); return
        }
        self.exporting = true
        self.temporaryExport = url
        picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
      } else if call.method == "import" {
        self.exporting = false
        picker = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
      } else { self.documentResult = nil; result(FlutterMethodNotImplemented); return }
      picker.delegate = self
      controller.present(picker, animated: true)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    documentResult?(exporting ? false : nil)
    finishDocument()
  }
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    defer { finishDocument() }
    if exporting { documentResult?(true); return }
    guard let url = urls.first else { documentResult?(nil); return }
    let access = url.startAccessingSecurityScopedResource()
    defer { if access { url.stopAccessingSecurityScopedResource() } }
    do {
      let values = try url.resourceValues(forKeys: [.fileSizeKey])
      guard (values.fileSize ?? Int.max) <= 10 * 1024 * 1024 else {
        documentResult?(FlutterError(code: "size", message: "Backup exceeds 10 MB", details: nil)); return
      }
      documentResult?(FlutterStandardTypedData(bytes: try Data(contentsOf: url)))
    } catch { documentResult?(FlutterError(code: "read", message: "Cannot read backup", details: nil)) }
  }
  private func finishDocument() {
    documentResult = nil
    if let url = temporaryExport { try? FileManager.default.removeItem(at: url) }
    temporaryExport = nil
  }
}
