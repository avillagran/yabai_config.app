import Cocoa
import FlutterMacOS
import CoreGraphics

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Setup window thumbnail channel
    setupWindowThumbnailChannel(controller: flutterViewController)

    super.awakeFromNib()
  }

  private func setupWindowThumbnailChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "com.yabaiconfig/window_thumbnails",
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "captureWindow":
        if let args = call.arguments as? [String: Any],
           let windowId = args["windowId"] as? Int {
          let thumbnail = self?.captureWindowThumbnail(windowId: CGWindowID(windowId), maxSize: 200)
          result(thumbnail)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "windowId required", details: nil))
        }

      case "captureWindows":
        if let args = call.arguments as? [String: Any],
           let windowIds = args["windowIds"] as? [Int] {
          var thumbnails: [Int: FlutterStandardTypedData] = [:]
          for windowId in windowIds {
            if let data = self?.captureWindowThumbnail(windowId: CGWindowID(windowId), maxSize: 150) {
              thumbnails[windowId] = data
            }
          }
          // Convert to [String: Data] for Flutter compatibility
          var resultMap: [String: FlutterStandardTypedData] = [:]
          for (key, value) in thumbnails {
            resultMap[String(key)] = value
          }
          result(resultMap)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "windowIds required", details: nil))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func captureWindowThumbnail(windowId: CGWindowID, maxSize: Int) -> FlutterStandardTypedData? {
    // Check if we have Screen Recording permission BEFORE attempting capture
    // This prevents the system dialog from appearing
    if #available(macOS 10.15, *) {
      if !CGPreflightScreenCaptureAccess() {
        // No permission - return nil silently without prompting
        return nil
      }
    }

    // Capture the window image
    guard let cgImage = CGWindowListCreateImage(
      .null,
      .optionIncludingWindow,
      windowId,
      [.boundsIgnoreFraming, .nominalResolution]
    ) else {
      return nil
    }

    // Calculate scaled size maintaining aspect ratio
    let originalWidth = cgImage.width
    let originalHeight = cgImage.height

    let scale: CGFloat
    if originalWidth > originalHeight {
      scale = CGFloat(maxSize) / CGFloat(originalWidth)
    } else {
      scale = CGFloat(maxSize) / CGFloat(originalHeight)
    }

    let newWidth = Int(CGFloat(originalWidth) * scale)
    let newHeight = Int(CGFloat(originalHeight) * scale)

    // Create scaled image
    guard let context = CGContext(
      data: nil,
      width: newWidth,
      height: newHeight,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      return nil
    }

    context.interpolationQuality = .high
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

    guard let scaledImage = context.makeImage() else {
      return nil
    }

    // Convert to PNG data
    let bitmapRep = NSBitmapImageRep(cgImage: scaledImage)
    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
      return nil
    }

    return FlutterStandardTypedData(bytes: pngData)
  }
}
