import CoreText
import SwiftUI

// The app has no Info.plist (GENERATE_INFOPLIST_FILE), so UIAppFonts is unavailable and
// Space Mono is registered with CoreText at runtime instead. Registration runs from the
// App init and, because Previews never construct the App, lazily from the Font tokens too.
enum AppFont {
    private static var registered = false

    static func registerIfNeeded() {
        guard !registered else { return }
        registered = true
        for name in ["SpaceMono-Regular", "SpaceMono-Bold"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    static var appLargeTitle: Font { register(); return .custom("SpaceMono-Bold", size: 34, relativeTo: .largeTitle) }
    static var appBody: Font { register(); return .custom("SpaceMono-Regular", size: 17, relativeTo: .body) }
    static var appCallout: Font { register(); return .custom("SpaceMono-Regular", size: 16, relativeTo: .callout) }
    static var appCaption: Font { register(); return .custom("SpaceMono-Regular", size: 12, relativeTo: .caption) }

    // Fixed sizes for FloorPlanView's Canvas text so the exported image stays consistent
    // regardless of Dynamic Type.
    static var appPlanLabel: Font { register(); return .custom("SpaceMono-Regular", fixedSize: 11) }
    static var appPlanReadout: Font { register(); return .custom("SpaceMono-Bold", fixedSize: 13) }

    private static func register() { AppFont.registerIfNeeded() }
}

extension ShapeStyle where Self == Color {
    static var appInk: Color { .black }
    static var appAccent: Color { .blue }
    static var appError: Color { .red }
}
