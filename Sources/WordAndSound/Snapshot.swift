import AppKit
import SwiftUI

@MainActor
enum Snapshot {
    static func write(model: AppModel, to path: String, size: CGSize = CGSize(width: 1180, height: 780)) -> Bool {
        let root = RootView(model: model)
            .frame(width: size.width, height: size.height)
        let view = NSHostingView(rootView: root)
        view.frame = NSRect(origin: .zero, size: size)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        view.layoutSubtreeIfNeeded()

        guard let representation = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            return false
        }
        view.cacheDisplay(in: view.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            return false
        }
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            return false
        }
    }
}
