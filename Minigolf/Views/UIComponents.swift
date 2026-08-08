//
//  UIComponents.swift
//  Minigolf
//
//  Shared building blocks for menus and overlays.
//

import SwiftUI

// MARK: - App info

/// Read from the bundle rather than typed out in the views, so the menu and the
/// settings sheet cannot drift away from `MARKETING_VERSION` at the next bump.
enum AppInfo {
    static let version = Bundle.main
        .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
}

// MARK: - Dynamic Type

/// A point size that still answers to Dynamic Type.
///
/// SwiftUI only offers `relativeTo:` for custom fonts — `Font.system(size:)` is
/// frozen at whatever it is handed, which is why a layout tuned in points stays
/// put while the rest of iOS grows with the reader's text size. `@ScaledMetric`
/// runs the same `UIFontMetrics` curve by hand, so these views keep the
/// proportions they were drawn with at the default size and scale from there.
private struct ScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, design: Font.Design,
         relativeTo textStyle: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    /// `.font(.system(size:))` that grows with the reader's text size.
    ///
    /// `relativeTo` picks the curve, not the size: small print scales faster
    /// than display type does, so a caption tracks `.caption` and a headline
    /// number tracks `.title`.
    func scaledFont(_ size: CGFloat,
                    weight: Font.Weight = .regular,
                    design: Font.Design = .default,
                    relativeTo textStyle: Font.TextStyle = .body) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design,
                            relativeTo: textStyle))
    }
}

// MARK: - VoiceOver announcements

/// Speaks a message through VoiceOver, if it is listening.
///
/// For the banners that come and go on a timer. A toast is off screen again
/// within two and a half seconds, which is not long enough to swipe over and
/// find it, so it has to come to the listener rather than wait to be read.
func announce(_ message: String?) {
    guard let message, !message.isEmpty else { return }
    AccessibilityNotification.Announcement(message).post()
}

// MARK: - Button styles

struct PrimaryButtonStyle: ButtonStyle {
    var colors: [Color] = [Color(red: 0.20, green: 0.62, blue: 0.28),
                           Color(red: 0.12, green: 0.47, blue: 0.22)]

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title3, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 34)
            .frame(maxWidth: 320)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: colors,
                                         startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
            )
            .overlay(
                Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 11)
            .padding(.horizontal, 26)
            .frame(maxWidth: 320)
            .background(Capsule().fill(.white.opacity(0.16)))
            .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}

// MARK: - Overlay card

struct OverlayCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 18) {
            content
        }
        .padding(28)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.35), radius: 22, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
        )
        .padding(24)
    }
}

/// Dimmed backdrop behind overlay cards.
struct OverlayBackdrop: View {
    var body: some View {
        Color.black.opacity(0.45)
            .ignoresSafeArea()
            .transition(.opacity)
    }
}

// MARK: - Stars

struct StarsView: View {
    var count: Int
    var max = 3
    var size: CGFloat = 34
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<max, id: \.self) { i in
                Image(systemName: i < count ? "star.fill" : "star")
                    .scaledFont(size, relativeTo: .title)
                    .foregroundStyle(i < count
                                     ? AnyShapeStyle(.yellow.gradient)
                                     : AnyShapeStyle(.white.opacity(0.35)))
                    .popIn(appeared, from: 0.2,
                           animation: .spring(response: 0.4, dampingFraction: 0.55)
                               .delay(Double(i) * 0.18))
            }
        }
        .onAppear { appeared = true }
        // One rating, not three icons: read on its own, an empty star says
        // nothing, and VoiceOver would spell out the row a symbol at a time.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(count) out of \(max) stars"))
    }
}

// MARK: - Hearts (lives)

struct LivesView: View {
    var lives: Int
    var max = GameController.livesPerCourse

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<max, id: \.self) { i in
                Image(systemName: i < lives ? "heart.fill" : "heart")
                    .scaledFont(15, weight: .bold, relativeTo: .subheadline)
                    .foregroundStyle(i < lives ? .red : .white.opacity(0.4))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(lives) of \(max) lives left"))
    }
}

// MARK: - HUD chip

struct HUDChip: View {
    var text: String
    var systemImage: String?
    /// What VoiceOver reads instead of the bare text. A chip like "252/324"
    /// only means something next to the star it sits beside, and that star is
    /// decoration — so chips whose text does not stand alone spell it out here.
    var voiceOverLabel: Text?

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .scaledFont(12, weight: .bold, relativeTo: .caption)
            }
            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .monospacedDigit()
                // A chip is a short reading — "252/324", "Par 35" — and wrapping
                // one splits the number across two lines, which reads as two
                // numbers. It shrinks to fit its row instead.
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 7)
        .padding(.horizontal, 12)
        .background(Capsule().fill(.black.opacity(0.35)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(voiceOverLabel ?? Text(text))
    }
}

// MARK: - Menu background

struct MenuBackground: View {
    var colors: [Color]

    var body: some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(
                GeometryReader { proxy in
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.07))
                            .frame(width: proxy.size.width * 1.1)
                            .offset(x: -proxy.size.width * 0.4, y: -proxy.size.height * 0.25)
                        Circle()
                            .fill(.white.opacity(0.05))
                            .frame(width: proxy.size.width * 0.9)
                            .offset(x: proxy.size.width * 0.55, y: proxy.size.height * 0.55)
                    }
                }
            )
            .ignoresSafeArea()
    }
}
