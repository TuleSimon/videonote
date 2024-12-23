import AVFoundation
import UIKit

class VideoJoinerHelper {

    /// Concatenates multiple video files into one output video
    /// - Parameters:
    ///   - videoFilePaths: Array of video file paths to concatenate.
    ///   - outputFilePath: File path for the concatenated output video.
    ///   - completion: Completion handler returning the output file path or nil in case of failure.
    func concatVideos(videoFilePaths: [String], outputFilePath: String, completion: @escaping (String?) -> Void) {
        print("[VideoConcatHelper] Starting video concatenation...")

        let composition = AVMutableComposition()

        // Track start time to position each video sequentially
        var currentStartTime = CMTime.zero

        // Add each video and audio track
        for videoFilePath in videoFilePaths {
            let inputURL = URL(fileURLWithPath: videoFilePath)
            let asset = AVAsset(url: inputURL)

            // Add video track
            if let videoTrack = asset.tracks(withMediaType: .video).first {
                let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                do {
                    try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: currentStartTime)
                    print("[VideoConcatHelper] Video track added: \(videoFilePath)")
                } catch {
                    logError(message: "Failed to add video track: \(error.localizedDescription)", filePath: videoFilePath)
                    completion(nil)
                    return
                }
            }

            // Add audio track (if available)
            if let audioTrack = asset.tracks(withMediaType: .audio).first {
                let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                do {
                    try compositionAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: currentStartTime)
                    print("[VideoConcatHelper] Audio track added: \(videoFilePath)")
                } catch {
                    logError(message: "Failed to add audio track: \(error.localizedDescription)", filePath: videoFilePath)
                    completion(nil)
                    return
                }
            } else {
                print("[VideoConcatHelper] No audio track found for file: \(videoFilePath)")
            }

            // Update the start time for the next track
            currentStartTime = CMTimeAdd(currentStartTime, asset.duration)
        }

        // Export the concatenated video
        exportComposition(composition: composition, outputFilePath: outputFilePath, completion: completion)
    }

    /// Exports the composition to a file
    private func exportComposition(composition: AVMutableComposition, outputFilePath: String, completion: @escaping (String?) -> Void) {
        let outputURL = URL(fileURLWithPath: outputFilePath)

        // Remove existing file if needed
        if FileManager.default.fileExists(atPath: outputFilePath) {
            do {
                try FileManager.default.removeItem(at: outputURL)
                print("[VideoConcatHelper] Existing output file removed.")
            } catch {
                logError(message: "Failed to remove existing output file: \(error.localizedDescription)", filePath: outputFilePath)
                completion(nil)
                return
            }
        }

        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
            logError(message: "Failed to create AVAssetExportSession.", filePath: outputFilePath)
            completion(nil)
            return
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = .mp4

        print("[VideoConcatHelper] Starting export...")
        exporter.exportAsynchronously {
            switch exporter.status {
            case .completed:
                print("[VideoConcatHelper] Export completed successfully.")
                completion(outputFilePath)
            case .failed:
                self.logError(message: "Export failed: \(String(describing: exporter.error))", filePath: outputFilePath)
                completion(nil)
            case .cancelled:
                print("[VideoConcatHelper] Export cancelled.")
                completion(nil)
            default:
                print("[VideoConcatHelper] Export status: \(exporter.status.rawValue)")
            }
        }
    }

    /// Logs detailed error messages
    private func logError(message: String, filePath: String) {
        print("[VideoConcatHelper - ERROR] \(message)")
        print("[VideoConcatHelper - ERROR] File Path: \(filePath)")
    }
}
