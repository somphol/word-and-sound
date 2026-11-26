import Foundation

public enum ArticulationContact: String, Hashable, Codable {
    case none
    case lips
    case teeth
    case betweenTeeth
    case alveolar
    case postAlveolar
    case palatal
    case velar
    case glottal
}

public enum ArticulationAirflow: String, Hashable, Codable {
    case none
    case center
    case side
    case nasal
    case stop
}

public struct MouthShape: Hashable, Codable {
    public var tip: Double
    public var body: Double
    public var back: Double
    public var lipRound: Double
    public var jaw: Double
    public var contact: ArticulationContact
    public var airflow: ArticulationAirflow
    public var voiced: Bool

    public init(
        tip: Double,
        body: Double,
        back: Double,
        lipRound: Double,
        jaw: Double,
        contact: ArticulationContact,
        airflow: ArticulationAirflow,
        voiced: Bool
    ) {
        self.tip = tip
        self.body = body
        self.back = back
        self.lipRound = lipRound
        self.jaw = jaw
        self.contact = contact
        self.airflow = airflow
        self.voiced = voiced
    }

    public func blended(to other: MouthShape, phase: Double) -> MouthShape {
        let t = min(max(phase, 0), 1)
        return MouthShape(
            tip: tip + (other.tip - tip) * t,
            body: body + (other.body - body) * t,
            back: back + (other.back - back) * t,
            lipRound: lipRound + (other.lipRound - lipRound) * t,
            jaw: jaw + (other.jaw - jaw) * t,
            contact: t < 0.5 ? contact : other.contact,
            airflow: t < 0.5 ? airflow : other.airflow,
            voiced: t < 0.5 ? voiced : other.voiced
        )
    }
}

public struct ArticulationError: Hashable, Codable {
    public let heardAs: String
    public let fix: String

    public init(heardAs: String, fix: String) {
        self.heardAs = heardAs
        self.fix = fix
    }
}

public struct Articulation: Identifiable, Hashable, Codable {
    public let id: String
    public let symbol: String
    public let name: String
    public let place: String
    public let manner: String
    public let voiced: Bool
    public let steps: [String]
    public let errors: [ArticulationError]
    public let anchors: [String]
    public let shape: MouthShape
    public let glide: MouthShape?
    public let isVowel: Bool
    public let anchorWord: String?
    public let contrasts: [String]
    public let lengthLabel: String?

    public init(
        id: String,
        symbol: String,
        name: String,
        place: String,
        manner: String,
        voiced: Bool,
        steps: [String],
        errors: [ArticulationError],
        anchors: [String],
        shape: MouthShape,
        glide: MouthShape? = nil,
        isVowel: Bool = false,
        anchorWord: String? = nil,
        contrasts: [String] = [],
        lengthLabel: String? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.place = place
        self.manner = manner
        self.voiced = voiced
        self.steps = steps
        self.errors = errors
        self.anchors = anchors
        self.shape = shape
        self.glide = glide
        self.isVowel = isVowel
        self.anchorWord = anchorWord
        self.contrasts = contrasts
        self.lengthLabel = lengthLabel
    }
}

public enum ArticulationLibrary {
    public static func components(for label: String) -> [Articulation] {
        componentKeys(for: label).compactMap { all[$0] }
    }

    public static func componentKeys(for label: String) -> [String] {
        if let blend = blends[label] { return blend }
        return [labelMap[label] ?? label]
    }

    public static func articulation(for label: String) -> Articulation? {
        all[labelMap[label] ?? label]
    }

    public static var guides: [Articulation] {
        Array(all.values)
    }

    private static let labelMap: [String: String] = [
        "æ/a": "æ",
        "oʊ/əʊ": "əʊ",
        "əː": "ɜː",
        "ʌɪ": "aɪ",
        "ɛ": "ɛ",
        "ɛː": "ɛː",
    ]

    private static let blends: [String: [String]] = [
        "fj": ["f", "j"], "nj": ["n", "j"], "θr": ["θ", "r"],
        "tr": ["t", "r"], "bl": ["b", "l"], "str": ["s", "t", "r"],
        "br": ["b", "r"], "dr": ["d", "r"], "dw": ["d", "w"],
        "fr": ["f", "r"], "gl": ["g", "l"], "gr": ["g", "r"],
        "gw": ["g", "w"], "hj": ["h", "j"], "kl": ["k", "l"],
        "kr": ["k", "r"], "kw": ["k", "w"], "lj": ["l", "j"],
        "mj": ["m", "j"], "pl": ["p", "l"], "pr": ["p", "r"],
        "sk": ["s", "k"], "skr": ["s", "k", "r"], "skw": ["s", "k", "w"],
        "sl": ["s", "l"], "sm": ["s", "m"], "sn": ["s", "n"],
        "sp": ["s", "p"], "spl": ["s", "p", "l"], "spr": ["s", "p", "r"],
        "st": ["s", "t"], "sw": ["s", "w"], "tw": ["t", "w"],
        "vj": ["v", "j"], "ʃr": ["ʃ", "r"],
        "kt": ["k", "t"], "lm": ["l", "m"], "dz": ["d", "z"],
        "ks": ["k", "s"], "kst": ["k", "s", "t"], "ld": ["l", "d"],
        "lf": ["l", "f"], "lk": ["l", "k"], "lp": ["l", "p"],
        "ls": ["l", "s"], "lt": ["l", "t"], "lz": ["l", "z"],
        "mf": ["m", "f"], "mp": ["m", "p"], "mpt": ["m", "p", "t"],
        "mz": ["m", "z"], "nd": ["n", "d"], "ns": ["n", "s"],
        "nt": ["n", "t"], "nts": ["n", "t", "s"], "nz": ["n", "z"],
        "ps": ["p", "s"], "pt": ["p", "t"], "ts": ["t", "s"],
        "ðd": ["ð", "d"], "ŋk": ["ŋ", "k"], "ŋz": ["ŋ", "z"],
        "ŋθ": ["ŋ", "θ"], "ʃt": ["ʃ", "t"], "ʒd": ["ʒ", "d"],
    ]

    private static let all: [String: Articulation] = {
        var entries: [String: Articulation] = [:]
        for entry in consonants { entries[entry.id] = entry }
        for entry in vowels { entries[entry.id] = entry }
        return entries
    }()

    private static func cue(place: String) -> String {
        switch place {
        case "bilabial": return "Close both lips."
        case "labiodental": return "Put the top teeth lightly on the bottom lip."
        case "dental": return "Put the tongue tip between the teeth."
        case "alveolar": return "Put the tongue tip at the ridge behind the top teeth."
        case "post-alveolar": return "Put the tongue just behind the ridge."
        case "palatal": return "Raise the tongue body toward the hard palate."
        case "velar": return "Raise the back of the tongue to the soft palate."
        case "glottal": return "Open the throat; do not block the mouth."
        default: return "Set the mouth for this sound."
        }
    }

    private static func mannerCue(_ manner: String) -> String {
        switch manner {
        case "stop": return "Stop the air completely, then release."
        case "fricative": return "Narrow the gap and let the air hiss."
        case "affricate": return "Stop the air, then release into a hiss."
        case "nasal": return "Let the air flow through the nose."
        case "lateral": return "Let the air flow around the sides of the tongue."
        case "approximant": return "Narrow the gap but do not touch."
        default: return "Shape the mouth and let the air flow."
        }
    }

    private static func c(
        _ symbol: String,
        _ name: String,
        place: String,
        manner: String,
        voiced: Bool,
        tip: Double,
        body: Double,
        back: Double,
        lip: Double,
        jaw: Double,
        contact: ArticulationContact,
        airflow: ArticulationAirflow,
        extraSteps: [String] = [],
        stepsOverride: [String]? = nil
    ) -> Articulation {
        let steps = stepsOverride ?? ([cue(place: place), mannerCue(manner), voiced ? "Turn voice on." : "Keep voice off."] + extraSteps)
        let errors = errorsBySound[symbol] ?? defaultErrors(manner: manner)
        let anchors = anchorsBySound[symbol] ?? ["Listen, copy the position, then add the word."]
        return Articulation(
            id: symbol,
            symbol: symbol,
            name: name,
            place: place,
            manner: manner,
            voiced: voiced,
            steps: steps,
            errors: errors,
            anchors: anchors,
            shape: MouthShape(
                tip: tip, body: body, back: back, lipRound: lip, jaw: jaw,
                contact: contact, airflow: airflow, voiced: voiced
            )
        )
    }

    private static func v(
        _ symbol: String,
        _ name: String,
        height: Double,
        back: Double,
        round: Double,
        jaw: Double,
        glide: (height: Double, back: Double, round: Double, jaw: Double)? = nil,
        steps: [String] = []
    ) -> Articulation {
        let start = MouthShape(
            tip: 0.16, body: height, back: back, lipRound: round, jaw: jaw,
            contact: .none, airflow: .none, voiced: true
        )
        let end = glide.map {
            MouthShape(
                tip: 0.16, body: $0.height, back: $0.back, lipRound: $0.round, jaw: $0.jaw,
                contact: .none, airflow: .none, voiced: true
            )
        }
        let defaultSteps = [
            "Tongue: \(heightWord(height)), \(backWord(back)).",
            "Lips: \(roundWord(round)); jaw: \(jawWord(jaw)).",
            "Voice on; keep the vowel steady.",
        ]
        var finalSteps = steps.isEmpty ? defaultSteps : steps
        if finalSteps.count < 3 {
            finalSteps.append(
                glide == nil
                    ? "Keep the vowel steady and voiced."
                    : "Move smoothly from the first position to the second."
            )
        }
        if finalSteps.count < 3 {
            finalSteps.append("Keep the glide short and voiced.")
        }
        return Articulation(
            id: symbol,
            symbol: symbol,
            name: name,
            place: "vowel",
            manner: "vowel",
            voiced: true,
            steps: finalSteps,
            errors: errorsBySound[symbol] ?? [ArticulationError(heardAs: "a nearby vowel", fix: "Match the tongue height, backness and lip rounding, then hold the vowel.")],
            anchors: anchorsBySound[symbol] ?? ["Hold the vowel, then copy the example word."],
            shape: start,
            glide: end,
            isVowel: true,
            anchorWord: anchorWords[symbol],
            contrasts: vowelContrasts[symbol] ?? [],
            lengthLabel: symbol.contains("ː") ? "long" : (glide == nil ? "short" : "glide")
        )
    }

    private static func defaultErrors(manner: String) -> [ArticulationError] {
        switch manner {
        case "stop":
            return [ArticulationError(heardAs: "a weak stop", fix: "Build pressure and release once, cleanly.")]
        case "fricative":
            return [ArticulationError(heardAs: "too little friction", fix: "Narrow the gap and keep the air moving.")]
        case "affricate":
            return [ArticulationError(heardAs: "a plain fricative", fix: "Start with a complete stop, then release into the hiss.")]
        case "nasal":
            return [ArticulationError(heardAs: "air through the mouth", fix: "Seal the mouth and let the air flow through the nose.")]
        case "lateral":
            return [ArticulationError(heardAs: "a plain /l/", fix: "Keep the tip on the ridge and let the air pass around the sides.")]
        default:
            return [ArticulationError(heardAs: "too much friction", fix: "Open the gap slightly; do not touch the roof of the mouth.")]
        }
    }

    private static func heightWord(_ value: Double) -> String {
        if value > 0.8 { return "high" }
        if value > 0.55 { return "mid-high" }
        if value > 0.35 { return "mid" }
        return "low"
    }

    private static func backWord(_ value: Double) -> String {
        if value > 0.7 { return "back" }
        if value > 0.4 { return "central" }
        return "front"
    }

    private static func roundWord(_ value: Double) -> String {
        if value > 0.65 { return "rounded" }
        if value > 0.25 { return "slightly rounded" }
        return "spread"
    }

    private static func jawWord(_ value: Double) -> String {
        if value > 0.4 { return "open" }
        if value > 0.2 { return "slightly open" }
        return "nearly closed"
    }

    private static let consonants: [Articulation] = [
        c("p", "voiceless bilabial stop", place: "bilabial", manner: "stop", voiced: false, tip: 0.2, body: 0.15, back: 0.3, lip: 0, jaw: 0.05, contact: .lips, airflow: .stop, extraSteps: ["Build pressure, then release both lips."]),
        c("b", "voiced bilabial stop", place: "bilabial", manner: "stop", voiced: true, tip: 0.2, body: 0.15, back: 0.3, lip: 0, jaw: 0.05, contact: .lips, airflow: .stop, extraSteps: ["Release both lips with voice."]),
        c("t", "voiceless alveolar stop", place: "alveolar", manner: "stop", voiced: false, tip: 0.95, body: 0.55, back: 0.45, lip: 0, jaw: 0.12, contact: .alveolar, airflow: .stop, extraSteps: ["Release with a puff of air."]),
        c("d", "voiced alveolar stop", place: "alveolar", manner: "stop", voiced: true, tip: 0.95, body: 0.55, back: 0.45, lip: 0, jaw: 0.12, contact: .alveolar, airflow: .stop, extraSteps: ["Release with voice."]),
        c("k", "voiceless velar stop", place: "velar", manner: "stop", voiced: false, tip: 0.2, body: 0.25, back: 0.95, lip: 0, jaw: 0.22, contact: .velar, airflow: .stop, extraSteps: ["Release with a puff."]),
        c("g", "voiced velar stop", place: "velar", manner: "stop", voiced: true, tip: 0.2, body: 0.25, back: 0.95, lip: 0, jaw: 0.22, contact: .velar, airflow: .stop, extraSteps: ["Release with voice."]),
        c("f", "voiceless labiodental fricative", place: "labiodental", manner: "fricative", voiced: false, tip: 0.2, body: 0.15, back: 0.3, lip: 0.1, jaw: 0.05, contact: .teeth, airflow: .center, extraSteps: ["Blow through the gap; do not close the lips."]),
        c("v", "voiced labiodental fricative", place: "labiodental", manner: "fricative", voiced: true, tip: 0.2, body: 0.15, back: 0.3, lip: 0.1, jaw: 0.05, contact: .teeth, airflow: .center, extraSteps: ["Keep the teeth on the lip and add voice."]),
        c("θ", "voiceless dental fricative", place: "dental", manner: "fricative", voiced: false, tip: 0.95, body: 0.2, back: 0.3, lip: 0, jaw: 0.12, contact: .betweenTeeth, airflow: .center, extraSteps: ["Let the air hiss over the tongue tip."]),
        c("ð", "voiced dental fricative", place: "dental", manner: "fricative", voiced: true, tip: 0.95, body: 0.2, back: 0.3, lip: 0, jaw: 0.12, contact: .betweenTeeth, airflow: .center, extraSteps: ["Keep the tip between the teeth and add voice."]),
        c("s", "voiceless alveolar fricative", place: "alveolar", manner: "fricative", voiced: false, tip: 0.9, body: 0.55, back: 0.4, lip: -0.25, jaw: 0.12, contact: .alveolar, airflow: .center, stepsOverride: ["Put the tongue tip close behind the ridge, not touching.", "Make a narrow groove down the middle; spread the lips.", "Keep voice off and let the air hiss.", "Seal the sides of the tongue against the upper molars."]),
        c("z", "voiced alveolar fricative", place: "alveolar", manner: "fricative", voiced: true, tip: 0.9, body: 0.55, back: 0.4, lip: -0.2, jaw: 0.12, contact: .alveolar, airflow: .center, extraSteps: ["Same tongue shape as /s/, but add voice."]),
        c("ʃ", "voiceless post-alveolar fricative", place: "post-alveolar", manner: "fricative", voiced: false, tip: 0.8, body: 0.65, back: 0.55, lip: 0.35, jaw: 0.12, contact: .postAlveolar, airflow: .center, extraSteps: ["Round the lips slightly; tongue just behind the ridge."]),
        c("ʒ", "voiced post-alveolar fricative", place: "post-alveolar", manner: "fricative", voiced: true, tip: 0.8, body: 0.65, back: 0.55, lip: 0.35, jaw: 0.12, contact: .postAlveolar, airflow: .center),
        c("h", "voiceless glottal fricative", place: "glottal", manner: "fricative", voiced: false, tip: 0.2, body: 0.3, back: 0.5, lip: 0, jaw: 0.25, contact: .glottal, airflow: .center, extraSteps: ["Breathe out as if fogging a mirror."]),
        c("tʃ", "voiceless post-alveolar affricate", place: "post-alveolar", manner: "affricate", voiced: false, tip: 0.9, body: 0.6, back: 0.5, lip: 0.2, jaw: 0.12, contact: .alveolar, airflow: .stop, stepsOverride: ["Start with the tongue at the ridge, as for /t/.", "Release into a hiss just behind the ridge.", "Keep voice off."]),
        c("dʒ", "voiced post-alveolar affricate", place: "post-alveolar", manner: "affricate", voiced: true, tip: 0.9, body: 0.6, back: 0.5, lip: 0.2, jaw: 0.12, contact: .alveolar, airflow: .stop, stepsOverride: ["Start with the tongue at the ridge, as for /d/.", "Release into a voiced hiss just behind the ridge.", "Turn voice on."]),
        c("m", "voiced bilabial nasal", place: "bilabial", manner: "nasal", voiced: true, tip: 0.2, body: 0.15, back: 0.3, lip: 0, jaw: 0.05, contact: .lips, airflow: .nasal),
        c("n", "voiced alveolar nasal", place: "alveolar", manner: "nasal", voiced: true, tip: 0.95, body: 0.55, back: 0.45, lip: 0, jaw: 0.12, contact: .alveolar, airflow: .nasal),
        c("ŋ", "voiced velar nasal", place: "velar", manner: "nasal", voiced: true, tip: 0.2, body: 0.25, back: 0.95, lip: 0, jaw: 0.22, contact: .velar, airflow: .nasal, stepsOverride: ["Raise the back of the tongue to the soft palate.", "Let the air flow through the nose.", "Turn voice on."]),
        c("l", "voiced alveolar lateral", place: "alveolar", manner: "lateral", voiced: true, tip: 0.95, body: 0.55, back: 0.45, lip: 0, jaw: 0.12, contact: .alveolar, airflow: .side, stepsOverride: ["Touch the ridge with the tongue tip.", "Let the air flow around the sides of the tongue.", "Turn voice on."]),
        c("r", "voiced alveolar approximant", place: "alveolar", manner: "approximant", voiced: true, tip: 0.82, body: 0.78, back: 0.55, lip: 0, jaw: 0.08, contact: .alveolar, airflow: .center, stepsOverride: ["Raise the tongue tip toward the ridge, but do not touch it.", "Bunch the tongue body and keep the lips neutral.", "Turn voice on and hold the tongue still.", "Do not tap or trill the tongue."]),
        c("j", "voiced palatal approximant", place: "palatal", manner: "approximant", voiced: true, tip: 0.45, body: 0.9, back: 0.25, lip: 0, jaw: 0.08, contact: .palatal, airflow: .center, extraSteps: ["Start with the tongue high, then glide into the vowel."]),
        c("w", "voiced labial-velar approximant", place: "velar", manner: "approximant", voiced: true, tip: 0.2, body: 0.55, back: 0.8, lip: 0.95, jaw: 0.08, contact: .none, airflow: .center, extraSteps: ["Round the lips tightly, then relax into the vowel."]),
    ]

    private static let vowels: [Articulation] = [
        v("iː", "close front unrounded vowel", height: 1, back: 0.05, round: 0, jaw: 0.05, steps: ["Tongue high and front; lips spread.", "Hold it long and tense; smile slightly."]),
        v("ɪ", "near-close front unrounded vowel", height: 0.82, back: 0.1, round: 0, jaw: 0.12, steps: ["Tongue high and front, but relaxed.", "Keep it short; do not smile as much as /iː/."]),
        v("e", "open-mid front unrounded vowel", height: 0.62, back: 0.15, round: 0, jaw: 0.22),
        v("ɛ", "open-mid front unrounded vowel", height: 0.6, back: 0.15, round: 0, jaw: 0.25),
        v("æ", "near-open front unrounded vowel", height: 0.28, back: 0.1, round: 0, jaw: 0.48, steps: ["Open the jaw; tongue low and front.", "Spread the lips and keep the sound short."]),
        v("ɛː", "long open-mid front unrounded vowel", height: 0.6, back: 0.15, round: 0, jaw: 0.28, steps: ["Tongue mid-front; lips spread.", "Hold it long; do not glide into schwa."]),
        v("ɑː", "open back unrounded vowel", height: 0.12, back: 1, round: 0, jaw: 0.55),
        v("ɒ", "open back rounded vowel", height: 0.2, back: 0.9, round: 0.6, jaw: 0.45),
        v("ɔː", "open-mid back rounded vowel", height: 0.35, back: 0.85, round: 0.8, jaw: 0.4),
        v("ʊ", "near-close back rounded vowel", height: 0.8, back: 0.75, round: 0.55, jaw: 0.15),
        v("uː", "close back rounded vowel", height: 1, back: 0.9, round: 1, jaw: 0.1, steps: ["Push the lips forward; tongue high and back.", "Hold it long and tense."]),
        v("ʌ", "open-mid central unrounded vowel", height: 0.45, back: 0.5, round: 0, jaw: 0.32),
        v("ɜː", "open-mid central unrounded vowel", height: 0.5, back: 0.5, round: 0, jaw: 0.28),
        v("ə", "mid central schwa", height: 0.5, back: 0.5, round: 0, jaw: 0.22, steps: ["Relax the tongue and jaw.", "Keep it short and weak; no lip rounding."]),
        v("eɪ", "front closing diphthong", height: 0.62, back: 0.15, round: 0, jaw: 0.22, glide: (1, 0.05, 0, 0.05), steps: ["Start at /e/; glide up to /ɪ/.", "Keep the first part longer."]),
        v("aɪ", "front closing diphthong", height: 0.2, back: 0.1, round: 0, jaw: 0.4, glide: (1, 0.1, 0, 0.08), steps: ["Start with an open /a/; glide up to /ɪ/.", "Do not hold the first part too long."]),
        v("ɔɪ", "back-to-front closing diphthong", height: 0.35, back: 0.85, round: 0.8, jaw: 0.4, glide: (1, 0.1, 0, 0.08), steps: ["Start rounded at /ɔ/; glide to /ɪ/.", "Finish with spread lips."]),
        v("əʊ", "central-back closing diphthong", height: 0.5, back: 0.5, round: 0, jaw: 0.22, glide: (0.8, 0.75, 0.6, 0.15), steps: ["Start at schwa; round the lips as you glide to /ʊ/."]),
        v("aʊ", "front-to-back closing diphthong", height: 0.2, back: 0.1, round: 0, jaw: 0.4, glide: (0.8, 0.75, 0.7, 0.15), steps: ["Start open at /a/; round the lips as you glide to /ʊ/."]),
        v("ɪə", "centring diphthong", height: 0.82, back: 0.1, round: 0, jaw: 0.12, glide: (0.5, 0.5, 0, 0.22), steps: ["Start at /ɪ/; relax into schwa."]),
        v("eə", "centring diphthong", height: 0.6, back: 0.15, round: 0, jaw: 0.25, glide: (0.5, 0.5, 0, 0.25), steps: ["Start at /e/; relax into schwa."]),
        v("ʊə", "centring diphthong", height: 0.8, back: 0.75, round: 0.55, jaw: 0.15, glide: (0.5, 0.5, 0, 0.22), steps: ["Start at /ʊ/; relax into schwa."]),
        v("aɪə", "triphthong", height: 0.2, back: 0.1, round: 0, jaw: 0.4, glide: (1, 0.1, 0, 0.08), steps: ["Glide /a/ → /ɪ/ → schwa.", "Keep the middle part brief."]),
        v("aʊə", "triphthong", height: 0.2, back: 0.1, round: 0, jaw: 0.4, glide: (0.8, 0.75, 0.7, 0.15), steps: ["Glide /a/ → /ʊ/ → schwa.", "Keep the middle part brief."]),
    ]

    private static let anchorWords: [String: String] = [
        "iː": "see", "ɪ": "ship", "e": "bed", "ɛ": "bed", "æ": "cat",
        "ɑː": "car", "ɒ": "hot", "ɔː": "saw", "ʊ": "book", "uː": "food",
        "ʌ": "cup", "ɜː": "bird", "ə": "sofa", "eɪ": "day", "aɪ": "time",
        "ɔɪ": "boy", "əʊ": "go", "aʊ": "now", "ɪə": "near", "eə": "hair",
        "ʊə": "tour", "ɛː": "there", "aɪə": "fire", "aʊə": "power",
    ]

    private static let vowelContrasts: [String: [String]] = [
        "iː": ["ɪ", "eɪ"], "ɪ": ["iː", "e"], "e": ["ɪ", "æ"], "ɛ": ["æ", "ɪ"],
        "æ": ["ɛ", "ɑː"], "ɑː": ["æ", "ʌ", "ɒ"], "ɒ": ["ɔː", "ʌ"],
        "ɔː": ["ɒ", "əʊ"], "ʊ": ["uː", "ɔː"], "uː": ["ʊ", "əʊ"],
        "ʌ": ["ɑː", "ɒ", "ə"], "ɜː": ["ə", "ɔː"], "ə": ["ʌ", "ɜː"],
        "eɪ": ["e", "aɪ"], "aɪ": ["eɪ", "ɔɪ"], "ɔɪ": ["aɪ", "əʊ"],
        "əʊ": ["ɔː", "aʊ"], "aʊ": ["əʊ", "ɔɪ"], "ɪə": ["eə", "ɪ"],
        "eə": ["ɪə", "ɛː"], "ʊə": ["ɔː", "uː"], "ɛː": ["eə", "e"],
        "aɪə": ["aɪ", "ə"], "aʊə": ["aʊ", "ə"],
    ]

    private static let errorsBySound: [String: [ArticulationError]] = [
        "r": [
            ArticulationError(heardAs: "/w/", fix: "Relax the lips; do not round them."),
            ArticulationError(heardAs: "/l/", fix: "Lift the tip slightly; do not touch the ridge."),
            ArticulationError(heardAs: "tapped or trilled /r/", fix: "Keep the tip still and bunched; do not tap."),
        ],
        "s": [
            ArticulationError(heardAs: "/θ/", fix: "Pull the tongue behind the teeth; do not show the tip."),
            ArticulationError(heardAs: "/ʃ/", fix: "Spread the lips and move the tongue slightly forward."),
            ArticulationError(heardAs: "/t/", fix: "Leave a narrow gap; do not touch the ridge."),
        ],
        "l": [
            ArticulationError(heardAs: "/r/", fix: "Touch the ridge with the tongue tip."),
            ArticulationError(heardAs: "/w/", fix: "Do not round the lips; keep the tongue tip on the ridge."),
        ],
        "θ": [
            ArticulationError(heardAs: "/s/", fix: "Put the tongue tip between the teeth."),
            ArticulationError(heardAs: "/t/", fix: "Keep the air flowing; do not stop it."),
        ],
        "ð": [
            ArticulationError(heardAs: "/d/", fix: "Keep the tip between the teeth and add voice."),
            ArticulationError(heardAs: "/z/", fix: "Move the tongue forward, between the teeth."),
        ],
        "v": [
            ArticulationError(heardAs: "/w/", fix: "Put the top teeth on the bottom lip."),
            ArticulationError(heardAs: "/b/", fix: "Do not close both lips."),
        ],
        "w": [
            ArticulationError(heardAs: "/v/", fix: "Do not touch the bottom lip with the teeth."),
        ],
        "ʃ": [
            ArticulationError(heardAs: "/s/", fix: "Move the tongue back and round the lips slightly."),
        ],
        "tʃ": [
            ArticulationError(heardAs: "/ʃ/", fix: "Start with a /t/ stop before the hiss."),
            ArticulationError(heardAs: "/t/", fix: "Release into a hiss; do not stop after the release."),
        ],
        "dʒ": [
            ArticulationError(heardAs: "/ʒ/", fix: "Start with a /d/ stop before the voiced hiss."),
        ],
        "ŋ": [
            ArticulationError(heardAs: "/n/", fix: "Raise the back of the tongue, not the tip."),
        ],
        "f": [
            ArticulationError(heardAs: "/p/", fix: "Do not close both lips; keep the top teeth on the lip."),
        ],
        "iː": [ArticulationError(heardAs: "/ɪ/", fix: "Stretch and lengthen the vowel.")],
        "ɪ": [ArticulationError(heardAs: "/iː/", fix: "Relax and shorten the vowel.")],
        "æ": [ArticulationError(heardAs: "/ɛ/", fix: "Open the jaw more.")],
        "ɛ": [ArticulationError(heardAs: "/æ/", fix: "Close the jaw slightly.")],
        "ʊ": [ArticulationError(heardAs: "/uː/", fix: "Relax and shorten the vowel.")],
        "uː": [ArticulationError(heardAs: "/ʊ/", fix: "Push the lips forward and lengthen.")],
        "ɒ": [ArticulationError(heardAs: "/ɔː/", fix: "Shorten the vowel and open the jaw.")],
        "ɔː": [ArticulationError(heardAs: "/ɒ/", fix: "Lengthen and round the lips more.")],
    ]

    private static let anchorsBySound: [String: [String]] = [
        "r": ["Say “la” and pull the tip back without touching.", "Growl like a dog; keep the lips neutral."],
        "s": ["Long snake hiss; feel the air on your palm.", "Smile and keep the tongue behind the teeth."],
        "l": ["Sing “la-la-la”.", "Hold the tip on the ridge and let the air escape at the sides."],
        "θ": ["Peek the tongue between the teeth and blow."],
        "ð": ["Same as /θ/, but add voice; feel the buzz."],
        "v": ["Bite the bottom lip gently and hum."],
        "w": ["Round the lips like a kiss, then open into the vowel."],
        "ʃ": ["Ask for quiet: “shhh”."],
        "tʃ": ["Say “church” slowly."],
        "dʒ": ["Say “judge” slowly."],
        "ŋ": ["Say “sing” and hold the end."],
        "j": ["Say “yes” and hold the first sound."],
        "f": ["Blow out a candle with the top teeth on the lip."],
        "iː": ["Smile and hold “see”."],
        "uː": ["Push the lips forward and hold “too”."],
        "æ": ["Open wide and say “cat”."],
    ]
}
