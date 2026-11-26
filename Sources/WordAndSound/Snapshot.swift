import AppKit
import SwiftUI

@MainActor
enum Snapshot {
    static func write(model: AppModel, to path: String, size: CGSize = CGSize(width: 1180, height: 780)) -> Bool {
        write(RootView(model: model), to: path, size: size)
    }

    static func write<V: View>(_ view: V, to path: String, size: CGSize) -> Bool {
        let root = view.frame(width: size.width, height: size.height)
        let host = NSHostingView(rootView: root)
        host.frame = NSRect(origin: .zero, size: size)
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        host.layoutSubtreeIfNeeded()

        guard let representation = host.bitmapImageRepForCachingDisplay(in: host.bounds) else {
            return false
        }
        host.cacheDisplay(in: host.bounds, to: representation)
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
