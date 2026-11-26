import AVFoundation
import Foundation

@MainActor
final class RecordController: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var hasRecording = false
    @Published var error: String?

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var fileURL: URL?

    var displayTime: TimeInterval {
        isRecording ? (recorder?.currentTime ?? elapsed) : elapsed
    }

    func start() {
        guard Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") != nil else {
            error = "Microphone access needs the bundled app. Run `make run` instead of `swift run`."
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            startRecording()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startRecording()
                    } else {
                        self?.error = "Microphone access was denied. Enable it in System Settings → Privacy & Security → Microphone."
                    }
                }
            }
        case .denied, .restricted:
            error = "Microphone access is disabled. Enable it in System Settings → Privacy & Security → Microphone."
        @unknown default:
            error = "Microphone access is unavailable."
        }
    }

    private func startRecording() {
        do {
            let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("WordAndSound/recordings", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent("recording.m4a")
            try? FileManager.default.removeItem(at: url)
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()
            fileURL = url
            hasRecording = true
            isRecording = true
            elapsed = 0
        } catch {
            self.error = error.localizedDescription
        }
    }

    func stop() {
        recorder?.stop()
        elapsed = recorder?.currentTime ?? elapsed
        isRecording = false
    }

    func play() {
        guard let fileURL else { return }
        do {
            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.play()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func delete() {
        stop()
        if let fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        fileURL = nil
        hasRecording = false
        elapsed = 0
    }

    func cleanup() {
        stop()
        delete()
    }
}
