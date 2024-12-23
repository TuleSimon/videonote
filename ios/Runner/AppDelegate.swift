import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.example.app/video", binaryMessenger: controller.binaryMessenger)

        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            // Handle method calls
            if call.method == "clipVideo" {
                guard let args = call.arguments as? [String: String],
                      let inputPath = args["inputPath"],
                      let outputPath = args["outputPath"] else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Input and output paths are required", details: nil))
                    return
                }
                self?.clipVideo(inputPath: inputPath, outputPath: outputPath, result: result)
            } else if call.method == "concatVideos" {
                guard let args = call.arguments as? [String: Any],
                      let videoPaths = args["videoPaths"] as? [String],
                      let outputPath = args["outputPath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Video paths and output path are required", details: nil))
                    return
                }
                self?.mergeVideos(videoPaths: videoPaths, outputPath: outputPath, result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /// Clips video with a circular mask
    private func clipVideo(inputPath: String, outputPath: String, result: @escaping FlutterResult) {
        let helper = VideoProcessingHelperr()
        helper.applyCircularMaskToVideo(inputFilePath: inputPath, outputFilePath: outputPath) { outputPathOrNil in
            if let outputPath = outputPathOrNil {
                result(outputPath)
            } else {
                result(FlutterError(code: "VIDEO_PROCESSING_FAILED", message: "Failed to process video", details: nil))
            }
        }
    }
    
    /// Concatenates multiple videos into one
    /// Merges multiple videos into a single video with audio
      private func mergeVideos(videoPaths: [String], outputPath: String, result: @escaping FlutterResult) {
          let composition = AVMutableComposition()
          let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
          let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

          var currentTime = CMTime.zero

          for path in videoPaths {
              let asset = AVAsset(url: URL(fileURLWithPath: path))

              // Add video track
              if let assetVideoTrack = asset.tracks(withMediaType: .video).first {
                  do {
                      try videoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: assetVideoTrack, at: currentTime)
                  } catch {
                      result(FlutterError(code: "VIDEO_TRACK_ERROR", message: "Failed to insert video track: \(error.localizedDescription)", details: nil))
                      return
                  }
              }

              // Add audio track
              if let assetAudioTrack = asset.tracks(withMediaType: .audio).first {
                  do {
                      try audioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: assetAudioTrack, at: currentTime)
                  } catch {
                      result(FlutterError(code: "AUDIO_TRACK_ERROR", message: "Failed to insert audio track: \(error.localizedDescription)", details: nil))
                      return
                  }
              }

              // Update current time for next video
              currentTime = CMTimeAdd(currentTime, asset.duration)
          }

          // Export the merged video
          let outputURL = URL(fileURLWithPath: outputPath)

          // Remove existing file if necessary
          if FileManager.default.fileExists(atPath: outputPath) {
              do {
                  try FileManager.default.removeItem(at: outputURL)
              } catch {
                  result(FlutterError(code: "FILE_ERROR", message: "Failed to remove existing file: \(error.localizedDescription)", details: nil))
                  return
              }
          }

          guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
              result(FlutterError(code: "EXPORT_ERROR", message: "Failed to create AVAssetExportSession", details: nil))
              return
          }

          exporter.outputURL = outputURL
          exporter.outputFileType = .mp4
          exporter.exportAsynchronously {
              switch exporter.status {
              case .completed:
                  result(outputPath)
              case .failed:
                  result(FlutterError(code: "EXPORT_ERROR", message: "Failed to export video: \(exporter.error?.localizedDescription ?? "Unknown error")", details: nil))
              case .cancelled:
                  result(FlutterError(code: "EXPORT_CANCELLED", message: "Video export was cancelled", details: nil))
              default:
                  result(FlutterError(code: "EXPORT_UNKNOWN", message: "Unknown export status", details: nil))
              }
          }
      }
}
