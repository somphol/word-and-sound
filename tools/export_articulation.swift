import Foundation

@main
struct ExportArticulation {
    static func main() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let guides = ArticulationLibrary.guides.sorted { $0.id < $1.id }
        let data = try encoder.encode(guides)
        FileHandle.standardOutput.write(data)
    }
}
