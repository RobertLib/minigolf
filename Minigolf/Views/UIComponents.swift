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
                    .font(.system(size: size))
                    .foregroundStyle(i < count
                                     ? AnyShapeStyle(.yellow.gradient)
                                     : AnyShapeStyle(.white.opacity(0.35)))
                    .scaleEffect(appeared ? 1 : 0.2)
                    .animation(.spring(response: 0.4, dampingFraction: 0.55)
                        .delay(Double(i) * 0.18), value: appeared)
            }
        }
        .onAppear { appeared = true }
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
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(i < lives ? .red : .white.opacity(0.4))
            }
        }
    }
}

// MARK: - HUD chip

struct HUDChip: View {
    var text: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .bold))
            }
            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.vertical, 7)
        .padding(.horizontal, 12)
        .background(Capsule().fill(.black.opacity(0.35)))
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
