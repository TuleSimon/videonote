import AVFoundation
import UIKit

class VideoProcessingHelper {

    /// Applies a circular mask to video frames and adjusts audio settings
    /// - Parameters:
    ///   - inputFilePath: The file path of the input video.
    ///   - outputFilePath: The desired file path for the output video.
    ///   - completion: A completion handler returning the output file path or nil in case of failure.
    func applyCircularMaskToVideo(inputFilePath: String, outputFilePath: String, completion: @escaping (String?) -> Void) {
        let inputURL = URL(fileURLWithPath: inputFilePath)
        let outputURL = URL(fileURLWithPath: outputFilePath)
        let asset = AVAsset(url: inputURL)
        let composition = AVMutableComposition()

        // Create the video track
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            print("No video track found in the input file.")
            completion(nil)
            return
        }

        // Add video track to the composition
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("Failed to add video track to composition.")
            completion(nil)
            return
        }

        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
        } catch {
            print("Error inserting video track: \(error.localizedDescription)")
            completion(nil)
            return
        }

        // Add audio track (if available)
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                print("Failed to add audio track to composition.")
                completion(nil)
                return
            }

            do {
                try compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)
            } catch {
                print("Error inserting audio track: \(error.localizedDescription)")
                completion(nil)
                return
            }
        }

        // Create a mutable video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: 512, height: 512)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        // Apply the circular mask
        let maskLayer = createCircularMaskLayer(size: CGSize(width: 512, height: 512))
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: 512, height: 512)

        let parentLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: 512, height: 512)
        parentLayer.addSublayer(videoLayer)

        // Masked layer setup
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

        // Set up stereo audio output settings
        let audioMix = AVMutableAudioMix()
        if let audioTrack = composition.tracks(withMediaType: .audio).first {
            let audioInputParams = AVMutableAudioMixInputParameters(track: audioTrack)
            audioInputParams.setVolume(1.0, at: .zero)
            audioMix.inputParameters = [audioInputParams]
        }

        // Export the video with the applied mask
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            print("Failed to create AVAssetExportSession.")
            completion(nil)
            return
        }

        exporter.videoComposition = videoComposition
        exporter.audioMix = audioMix
        exporter.outputFileType = .mp4
        exporter.outputURL = outputURL

        // Remove existing file if needed
        if FileManager.default.fileExists(atPath: outputFilePath) {
            do {
                try FileManager.default.removeItem(at: outputURL)
            } catch {
                print("Failed to remove existing output file: \(error.localizedDescription)")
                completion(nil)
                return
            }
        }

        exporter.exportAsynchronously {
            switch exporter.status {
            case .completed:
                completion(outputFilePath)
            case .failed, .cancelled:
                print("Error exporting video: \(String(describing: exporter.error))")
                completion(nil)
            default:
                break
            }
        }
    }

    // Create a circular mask layer
    private func createCircularMaskLayer(size: CGSize) -> CALayer {
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.black.cgColor
        return maskLayer
    }
}
