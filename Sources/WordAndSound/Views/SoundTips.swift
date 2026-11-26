import Foundation
import WordAndSoundCore

enum SoundTips {
    static func tip(for tile: SoundTile) -> String {
        if let specific = tips[tile.label] {
            return specific
        }
        switch tile.kind {
        case "blend":
            return "Say the consonants together without adding a vowel between them."
        case "codaBlend":
            return "Finish with both consonants; keep the last one audible."
        case "onset":
            return "Start the word with this sound, then move straight into the vowel."
        case "coda":
            return "Hold the final sound; do not drop it."
        case "vowel":
            return "Hold the vowel steadily, then finish the word."
        default:
            return "Listen, then repeat at a comfortable speed."
        }
    }

    private static let tips: [String: String] = [
        "θ": "Tongue tip lightly between the teeth; blow air, no voice.",
        "ð": "Tongue tip lightly between the teeth; add voice.",
        "ʃ": "Round the lips a little; tongue near the ridge; say “sh”.",
        "ʒ": "Same mouth position as /ʃ/, but with voice.",
        "tʃ": "Stop the air with /t/, then release into /ʃ/.",
        "dʒ": "Voiced partner of /tʃ/, as in “judge”.",
        "r": "Curl the tongue tip up without touching the ridge.",
        "l": "Tongue tip on the ridge; let air pass around the sides.",
        "f": "Top teeth on the bottom lip; blow, no voice.",
        "v": "Top teeth on the bottom lip; add voice.",
        "w": "Round the lips tightly, then glide into the vowel.",
        "j": "Tongue high and forward, then glide into the vowel.",
        "ŋ": "Back of the tongue up; air through the nose.",
        "h": "Open the throat and breathe out before the vowel.",
        "p": "Close both lips, build pressure, release with a puff.",
        "b": "Close both lips and release with voice.",
        "t": "Tongue tip on the ridge, release with a puff.",
        "d": "Tongue tip on the ridge, release with voice.",
        "k": "Back of the tongue against the soft palate, release with a puff.",
        "g": "Same as /k/, but with voice.",
        "m": "Close the lips and let the sound hum through the nose.",
        "n": "Tongue tip on the ridge; air through the nose.",
        "s": "Tongue near the ridge; narrow air channel, no voice.",
        "z": "Same as /s/, but with voice.",
        "iː": "Long and tense: smile and hold it, as in “sheep”.",
        "ɪ": "Short and relaxed, as in “ship”; keep the jaw loose.",
        "e": "Short /e/, as in “bed”; tongue mid-front.",
        "ɛ": "Short /ɛ/, as in “bed”; keep it relaxed.",
        "æ": "Open the jaw and spread the lips, as in “cat”.",
        "ɑː": "Open the mouth wide; long /ɑː/, as in “car”.",
        "ɒ": "Short, rounded /ɒ/, as in “hot” (British).",
        "ɔː": "Long, rounded /ɔː/, as in “caught”.",
        "ʊ": "Short, rounded /ʊ/, as in “pull”.",
        "uː": "Long, rounded /uː/, as in “pool”; push the lips forward.",
        "ʌ": "Short, central /ʌ/, as in “cup”; keep the jaw relaxed.",
        "ə": "Weak, relaxed schwa, as in the second syllable of “sofa”.",
        "əː": "Long central vowel, as in “bird”; lips neutral.",
        "eɪ": "Glide from /e/ to /ɪ/, as in “day”.",
        "aɪ": "Glide from open /a/ to /ɪ/, as in “time”.",
        "ɔɪ": "Glide from /ɔ/ to /ɪ/, as in “boy”.",
        "əʊ": "Glide from schwa to /ʊ/, as in “go” (British).",
        "aʊ": "Glide from open /a/ to /ʊ/, as in “now”.",
        "ɪə": "Glide from /ɪ/ to schwa, as in “near”.",
        "eə": "Glide from /e/ to schwa, as in “hair”.",
        "ʊə": "Glide from /ʊ/ to schwa, as in “tour”.",
        "aɪə": "Three-part glide: /a/ → /ɪ/ → schwa, as in “fire”.",
        "aʊə": "Three-part glide: /a/ → /ʊ/ → schwa, as in “power”.",
        "oʊ/əʊ": "Glide from /ə/ or /o/ to /ʊ/, as in “go”.",
        "æ/a": "Open the jaw and spread the lips, as in “cat”.",
        "ʌɪ": "Glide from open /a/ to /ɪ/, as in “time”.",
    ]
}
