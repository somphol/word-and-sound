import AVFoundation
import Foundation

final class SpeechEngine: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?

    private let synthesizer = AVSpeechSynthesizer()
    private var voices: [String: AVSpeechSynthesisVoice] = [:]

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, accent: Accent, rate: Double, pitch: Double) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice(for: accent)
        let base = Double(AVSpeechUtteranceDefaultSpeechRate)
        utterance.rate = Float(min(max(base * rate, 0.08), 0.95))
        utterance.pitchMultiplier = Float(min(max(pitch, 0.5), 2.0))
        utterance.postUtteranceDelay = 0.02
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }

    func voice(for accent: Accent) -> AVSpeechSynthesisVoice? {
        if let cached = voices[accent.rawValue] { return cached }
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language == accent.rawValue
        }
        let selected = candidates.first(where: { $0.quality == .premium })
            ?? candidates.first(where: { $0.quality == .enhanced })
            ?? candidates.first
            ?? AVSpeechSynthesisVoice(language: accent.rawValue)
        if let selected { voices[accent.rawValue] = selected }
        return selected
    }

    func hasVoice(for accent: Accent) -> Bool {
        voice(for: accent) != nil
    }

    func voiceName(for accent: Accent) -> String? {
        voice(for: accent)?.name
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.onFinish?()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // A cancelled utterance is a deliberate stop, not a completed word.
    }
}
