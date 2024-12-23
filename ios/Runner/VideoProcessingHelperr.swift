import AVFoundation
import UIKit

class VideoProcessingHelperr {

    /// Applies a circular mask to video frames and adjusts audio settings
    /// - Parameters:
    ///   - inputFilePath: The file path of the input video.
    ///   - outputFilePath: The desired file path for the output video.
    ///   - completion: A completion handler returning the output file path or nil in case of failure.
    func applyCircularMaskToVideo(inputFilePath: String, outputFilePath: String, completion: @escaping (String?) -> Void) {
        print("[VideoProcessingHelper] Starting video processing...")
        print("[VideoProcessingHelper] Input File: \(inputFilePath)")
        print("[VideoProcessingHelper] Output File: \(outputFilePath)")

        let inputURL = URL(fileURLWithPath: inputFilePath)
        let outputURL = URL(fileURLWithPath: outputFilePath)
        let asset = AVAsset(url: inputURL)
        let composition = AVMutableComposition()

        // Create the video track
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            logError(message: "No video track found in the input file.", filePath: inputFilePath)
            completion(nil)
            return
        }
        print("[VideoProcessingHelper] Video track found with dimensions: \(videoTrack.naturalSize)")

        // Add video track to the composition
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            logError(message: "Failed to add video track to composition.", filePath: inputFilePath)
            completion(nil)
            return
        }

        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
            print("[VideoProcessingHelper] Video track added to composition.")
        } catch {
            logError(message: "Error inserting video track: \(error.localizedDescription)", filePath: inputFilePath)
            completion(nil)
            return
        }

        // Add audio track (if available)
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                logError(message: "Failed to add audio track to composition.", filePath: inputFilePath)
                completion(nil)
                return
            }

            do {
                try compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)
                print("[VideoProcessingHelper] Audio track added to composition.")
            } catch {
                logError(message: "Error inserting audio track: \(error.localizedDescription)", filePath: inputFilePath)
                completion(nil)
                return
            }
        } else {
            print("[VideoProcessingHelper] No audio track found in the input file.")
        }

        // Create a mutable video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoTrack.naturalSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        print("[VideoProcessingHelper] Video composition created with render size: \(videoTrack.naturalSize)")

        // Setup layers for the circular mask
        let (parentLayer, videoLayer) = setupLayers(for: videoTrack)
        let maskLayer = createCircularMaskLayer(size: videoTrack.naturalSize)

        // Apply circular mask
        let maskedLayer = CALayer()
        maskedLayer.frame = parentLayer.bounds
        maskedLayer.mask = maskLayer
        maskedLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(maskedLayer)

        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)

        // Create composition instruction
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instruction.layerInstructions = [videoLayerInstruction]
        videoComposition.instructions = [instruction]

        print("[VideoProcessingHelper] Video composition instructions set.")

        // Export the video with the applied mask
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
            logError(message: "Failed to create AVAssetExportSession.", filePath: outputFilePath)
            completion(nil)
            return
        }

        exporter.videoComposition = videoComposition
        exporter.outputFileType = .mp4
        exporter.outputURL = outputURL

        // Remove existing file if needed
        if FileManager.default.fileExists(atPath: outputFilePath) {
            do {
                try FileManager.default.removeItem(at: outputURL)
                print("[VideoProcessingHelper] Existing output file removed.")
            } catch {
                logError(message: "Failed to remove existing output file: \(error.localizedDescription)", filePath: outputFilePath)
                completion(nil)
                return
            }
        }

        // Perform export
        print("[VideoProcessingHelper] Starting export...")
        exporter.exportAsynchronously {
            switch exporter.status {
            case .completed:
                print("[VideoProcessingHelper] Export completed successfully.")
                completion(outputFilePath)
            case .failed:
                self.logError(message: "Export failed: \(String(describing: exporter.error))", filePath: outputFilePath)
                completion(nil)
            case .cancelled:
                print("[VideoProcessingHelper] Export cancelled.")
                completion(nil)
            default:
                print("[VideoProcessingHelper] Export status: \(exporter.status.rawValue)")
            }
        }
    }

    /// Sets up the parent and video layers
    private func setupLayers(for videoTrack: AVAssetTrack) -> (CALayer, CALayer) {
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoTrack.naturalSize)

        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: videoTrack.naturalSize)
        parentLayer.addSublayer(videoLayer)

        return (parentLayer, videoLayer)
    }

    /// Create a circular mask layer
    private func createCircularMaskLayer(size: CGSize) -> CALayer {
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.black.cgColor
        return maskLayer
    }

    /// Logs detailed error messages
    private func logError(message: String, filePath: String) {
        print("[VideoProcessingHelper - ERROR] \(message)")
        print("[VideoProcessingHelper - ERROR] File Path: \(filePath)")
    }
}

