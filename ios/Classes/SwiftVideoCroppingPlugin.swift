public class SwiftVideoCroppingPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "video_cropping_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftVideoCroppingPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "cropVideoToCircle" {
     guard let args = call.arguments as? [String: Any],
                      let inputPath = args["inputPath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing input path", details: nil))
                    return
                }
                let outputPath = getDocumentsDirectory().appendingPathComponent("cropped_video.mp4").path
                cropVideoToCircle(inputPath: inputPath, outputPath: outputPath) { error in
                    if let error = error {
                        result(FlutterError(code: "CROP_ERROR", message: error.localizedDescription, details: nil))
                    } else {
                        result(outputPath)
                    }
                }

    } else {
      result(FlutterMethodNotImplemented)
    }
  }

   private func getDocumentsDirectory() -> URL {
          return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      }

  private func cropVideoToCircle(inputPath: String, outputPath: String, completion: @escaping (Error?) -> Void) {
    let asset = AVAsset(url: URL(fileURLWithPath: inputPath))
    let composition = AVMutableComposition()

    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
      completion(NSError(domain: "VideoCropError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video track not found"]))
      return
    }

    let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)

    do {
      try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
    } catch {
      completion(error)
      return
    }

    let videoSize = videoTrack.naturalSize
    let circlePath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: videoSize))

    let maskLayer = CAShapeLayer()
    maskLayer.path = circlePath.cgPath

    let videoLayer = CALayer()
    videoLayer.frame = CGRect(origin: .zero, size: videoSize)

    let parentLayer = CALayer()
    parentLayer.frame = CGRect(origin: .zero, size: videoSize)
    parentLayer.addSublayer(videoLayer)
    parentLayer.mask = maskLayer

    let videoComposition = AVMutableVideoComposition()
    videoComposition.renderSize = videoSize
    videoComposition.frameDuration = videoTrack.minFrameDuration
    videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)

    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)

    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    instruction.layerInstructions = [layerInstruction]
    videoComposition.instructions = [instruction]

    guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
      completion(NSError(domain: "VideoCropError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"]))
      return
    }

    exportSession.videoComposition = videoComposition
    exportSession.outputFileType = .mp4
    exportSession.outputURL = URL(fileURLWithPath: outputPath)
    exportSession.exportAsynchronously {
      if exportSession.status == .completed {
        completion(nil)
      } else {
        completion(exportSession.error)
      }
    }
  }

}
