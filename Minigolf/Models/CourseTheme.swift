//
//  CourseTheme.swift
//  Minigolf
//
//  Visual recipe (palette + lighting) for every world. `CourseType` itself
//  lives in CourseType.swift so the level data stays UIKit-free.
//

import Foundation
import SwiftUI
import UIKit

extension CourseType {
    var theme: CourseTheme { CourseTheme.theme(for: self) }
}

/// Visual palette and lighting recipe for a course type.
struct CourseTheme {
    // RealityKit material colors
    var feltTop: UIColor          // main playing surface
    var feltStripe: UIColor       // second mowing-stripe tone
    var wallColor: UIColor
    var wallTopColor: UIColor
    var groundColor: UIColor      // terrain under the elevated course
    var groundDetail: UIColor
    var sandColor: UIColor
    var sandDetail: UIColor
    var mudColor: UIColor         // sticky rough: mud, ash, slush
    var iceColor: UIColor         // slick patches
    var waterColor: UIColor
    var lavaColor: UIColor        // molten hazard
    var skyTop: UIColor
    var skyHorizon: UIColor
    var skyBottom: UIColor
    var sunColor: UIColor
    var sunIntensity: Float
    var fillIntensity: Float      // secondary soft light
    var accent: UIColor           // bumpers, flags, highlights
    var emissiveWalls: Bool       // neon style glowing wall tops
    var accentLights: Bool        // coloured point lights for atmosphere
    var starrySky: Bool

    // SwiftUI colors for menus / HUD
    var uiPrimary: Color
    var uiSecondary: Color

    static func theme(for course: CourseType) -> CourseTheme {
        switch course {
        case .garden:
            return CourseTheme(
                feltTop: UIColor(red: 0.28, green: 0.62, blue: 0.24, alpha: 1),
                feltStripe: UIColor(red: 0.33, green: 0.70, blue: 0.28, alpha: 1),
                wallColor: UIColor(red: 0.48, green: 0.33, blue: 0.20, alpha: 1),
                wallTopColor: UIColor(red: 0.58, green: 0.42, blue: 0.27, alpha: 1),
                groundColor: UIColor(red: 0.42, green: 0.58, blue: 0.30, alpha: 1),
                groundDetail: UIColor(red: 0.36, green: 0.52, blue: 0.26, alpha: 1),
                sandColor: UIColor(red: 0.88, green: 0.78, blue: 0.55, alpha: 1),
                sandDetail: UIColor(red: 0.80, green: 0.69, blue: 0.46, alpha: 1),
                mudColor: UIColor(red: 0.35, green: 0.30, blue: 0.18, alpha: 1),
                iceColor: UIColor(red: 0.74, green: 0.88, blue: 0.94, alpha: 1),
                waterColor: UIColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 1),
                lavaColor: UIColor(red: 0.95, green: 0.40, blue: 0.10, alpha: 1),
                skyTop: UIColor(red: 0.35, green: 0.62, blue: 0.94, alpha: 1),
                skyHorizon: UIColor(red: 0.78, green: 0.90, blue: 0.98, alpha: 1),
                skyBottom: UIColor(red: 0.60, green: 0.78, blue: 0.62, alpha: 1),
                sunColor: UIColor(red: 1.0, green: 0.96, blue: 0.88, alpha: 1),
                sunIntensity: 6200,
                fillIntensity: 1400,
                accent: UIColor(red: 0.92, green: 0.26, blue: 0.21, alpha: 1),
                emissiveWalls: false,
                accentLights: false,
                starrySky: false,
                uiPrimary: Color(red: 0.20, green: 0.55, blue: 0.25),
                uiSecondary: Color(red: 0.55, green: 0.78, blue: 0.35)
            )
        case .desert:
            return CourseTheme(
                feltTop: UIColor(red: 0.13, green: 0.52, blue: 0.42, alpha: 1),
                feltStripe: UIColor(red: 0.16, green: 0.58, blue: 0.47, alpha: 1),
                wallColor: UIColor(red: 0.75, green: 0.44, blue: 0.26, alpha: 1),
                wallTopColor: UIColor(red: 0.84, green: 0.53, blue: 0.33, alpha: 1),
                groundColor: UIColor(red: 0.87, green: 0.72, blue: 0.48, alpha: 1),
                groundDetail: UIColor(red: 0.80, green: 0.63, blue: 0.40, alpha: 1),
                sandColor: UIColor(red: 0.93, green: 0.83, blue: 0.58, alpha: 1),
                sandDetail: UIColor(red: 0.85, green: 0.73, blue: 0.47, alpha: 1),
                mudColor: UIColor(red: 0.52, green: 0.40, blue: 0.24, alpha: 1),
                iceColor: UIColor(red: 0.78, green: 0.90, blue: 0.92, alpha: 1),
                waterColor: UIColor(red: 0.20, green: 0.65, blue: 0.75, alpha: 1),
                lavaColor: UIColor(red: 0.95, green: 0.45, blue: 0.10, alpha: 1),
                skyTop: UIColor(red: 0.45, green: 0.42, blue: 0.75, alpha: 1),
                skyHorizon: UIColor(red: 0.99, green: 0.72, blue: 0.45, alpha: 1),
                skyBottom: UIColor(red: 0.86, green: 0.62, blue: 0.42, alpha: 1),
                sunColor: UIColor(red: 1.0, green: 0.85, blue: 0.65, alpha: 1),
                sunIntensity: 5200,
                fillIntensity: 1600,
                accent: UIColor(red: 0.98, green: 0.55, blue: 0.15, alpha: 1),
                emissiveWalls: false,
                accentLights: false,
                starrySky: false,
                uiPrimary: Color(red: 0.85, green: 0.48, blue: 0.16),
                uiSecondary: Color(red: 0.96, green: 0.72, blue: 0.35)
            )
        case .jungle:
            return CourseTheme(
                feltTop: UIColor(red: 0.19, green: 0.49, blue: 0.26, alpha: 1),
                feltStripe: UIColor(red: 0.23, green: 0.56, blue: 0.31, alpha: 1),
                wallColor: UIColor(red: 0.44, green: 0.46, blue: 0.36, alpha: 1),
                wallTopColor: UIColor(red: 0.56, green: 0.58, blue: 0.46, alpha: 1),
                groundColor: UIColor(red: 0.21, green: 0.33, blue: 0.19, alpha: 1),
                groundDetail: UIColor(red: 0.14, green: 0.25, blue: 0.13, alpha: 1),
                sandColor: UIColor(red: 0.79, green: 0.72, blue: 0.53, alpha: 1),
                sandDetail: UIColor(red: 0.68, green: 0.61, blue: 0.42, alpha: 1),
                mudColor: UIColor(red: 0.30, green: 0.22, blue: 0.14, alpha: 1),
                iceColor: UIColor(red: 0.70, green: 0.88, blue: 0.88, alpha: 1),
                waterColor: UIColor(red: 0.12, green: 0.42, blue: 0.40, alpha: 1),
                lavaColor: UIColor(red: 0.90, green: 0.40, blue: 0.10, alpha: 1),
                skyTop: UIColor(red: 0.26, green: 0.50, blue: 0.56, alpha: 1),
                skyHorizon: UIColor(red: 0.76, green: 0.86, blue: 0.68, alpha: 1),
                skyBottom: UIColor(red: 0.32, green: 0.44, blue: 0.28, alpha: 1),
                sunColor: UIColor(red: 1.0, green: 0.97, blue: 0.84, alpha: 1),
                sunIntensity: 5000,
                fillIntensity: 1900,
                accent: UIColor(red: 0.95, green: 0.72, blue: 0.18, alpha: 1),
                emissiveWalls: false,
                accentLights: false,
                starrySky: false,
                uiPrimary: Color(red: 0.13, green: 0.44, blue: 0.28),
                uiSecondary: Color(red: 0.85, green: 0.68, blue: 0.22)
            )
        case .ice:
            return CourseTheme(
                feltTop: UIColor(red: 0.42, green: 0.66, blue: 0.64, alpha: 1),
                feltStripe: UIColor(red: 0.49, green: 0.73, blue: 0.71, alpha: 1),
                wallColor: UIColor(red: 0.58, green: 0.69, blue: 0.78, alpha: 1),
                wallTopColor: UIColor(red: 0.78, green: 0.88, blue: 0.95, alpha: 1),
                groundColor: UIColor(red: 0.85, green: 0.90, blue: 0.95, alpha: 1),
                groundDetail: UIColor(red: 0.70, green: 0.79, blue: 0.88, alpha: 1),
                sandColor: UIColor(red: 0.92, green: 0.95, blue: 0.98, alpha: 1),
                sandDetail: UIColor(red: 0.79, green: 0.85, blue: 0.92, alpha: 1),
                mudColor: UIColor(red: 0.58, green: 0.63, blue: 0.68, alpha: 1),
                iceColor: UIColor(red: 0.73, green: 0.90, blue: 0.96, alpha: 1),
                waterColor: UIColor(red: 0.08, green: 0.32, blue: 0.55, alpha: 1),
                lavaColor: UIColor(red: 0.90, green: 0.40, blue: 0.10, alpha: 1),
                skyTop: UIColor(red: 0.38, green: 0.57, blue: 0.85, alpha: 1),
                skyHorizon: UIColor(red: 0.86, green: 0.93, blue: 0.99, alpha: 1),
                skyBottom: UIColor(red: 0.76, green: 0.86, blue: 0.93, alpha: 1),
                sunColor: UIColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 1),
                sunIntensity: 5600,
                fillIntensity: 2300,
                accent: UIColor(red: 0.16, green: 0.62, blue: 0.94, alpha: 1),
                emissiveWalls: false,
                accentLights: false,
                starrySky: false,
                uiPrimary: Color(red: 0.18, green: 0.48, blue: 0.72),
                uiSecondary: Color(red: 0.55, green: 0.82, blue: 0.95)
            )
        case .neon:
            return CourseTheme(
                feltTop: UIColor(red: 0.10, green: 0.12, blue: 0.24, alpha: 1),
                feltStripe: UIColor(red: 0.13, green: 0.16, blue: 0.30, alpha: 1),
                wallColor: UIColor(red: 0.14, green: 0.10, blue: 0.28, alpha: 1),
                wallTopColor: UIColor(red: 0.0, green: 0.95, blue: 0.95, alpha: 1),
                groundColor: UIColor(red: 0.045, green: 0.04, blue: 0.10, alpha: 1),
                groundDetail: UIColor(red: 0.30, green: 0.22, blue: 0.62, alpha: 1),
                sandColor: UIColor(red: 0.35, green: 0.22, blue: 0.55, alpha: 1),
                sandDetail: UIColor(red: 0.28, green: 0.16, blue: 0.45, alpha: 1),
                mudColor: UIColor(red: 0.16, green: 0.10, blue: 0.30, alpha: 1),
                iceColor: UIColor(red: 0.35, green: 0.85, blue: 0.95, alpha: 1),
                waterColor: UIColor(red: 0.55, green: 0.10, blue: 0.85, alpha: 1),
                lavaColor: UIColor(red: 1.0, green: 0.20, blue: 0.55, alpha: 1),
                skyTop: UIColor(red: 0.03, green: 0.02, blue: 0.10, alpha: 1),
                skyHorizon: UIColor(red: 0.20, green: 0.05, blue: 0.38, alpha: 1),
                skyBottom: UIColor(red: 0.05, green: 0.03, blue: 0.12, alpha: 1),
                sunColor: UIColor(red: 0.75, green: 0.80, blue: 1.0, alpha: 1),
                sunIntensity: 2800,
                fillIntensity: 900,
                accent: UIColor(red: 1.0, green: 0.20, blue: 0.65, alpha: 1),
                emissiveWalls: true,
                accentLights: true,
                starrySky: true,
                uiPrimary: Color(red: 0.55, green: 0.25, blue: 0.95),
                uiSecondary: Color(red: 0.10, green: 0.85, blue: 0.90)
            )
        case .volcano:
            return CourseTheme(
                feltTop: UIColor(red: 0.17, green: 0.25, blue: 0.21, alpha: 1),
                feltStripe: UIColor(red: 0.21, green: 0.30, blue: 0.25, alpha: 1),
                wallColor: UIColor(red: 0.20, green: 0.17, blue: 0.16, alpha: 1),
                wallTopColor: UIColor(red: 0.34, green: 0.28, blue: 0.25, alpha: 1),
                groundColor: UIColor(red: 0.13, green: 0.10, blue: 0.10, alpha: 1),
                groundDetail: UIColor(red: 0.36, green: 0.14, blue: 0.06, alpha: 1),
                sandColor: UIColor(red: 0.36, green: 0.32, blue: 0.30, alpha: 1),
                sandDetail: UIColor(red: 0.25, green: 0.22, blue: 0.21, alpha: 1),
                mudColor: UIColor(red: 0.22, green: 0.19, blue: 0.18, alpha: 1),
                iceColor: UIColor(red: 0.60, green: 0.80, blue: 0.88, alpha: 1),
                waterColor: UIColor(red: 0.30, green: 0.45, blue: 0.55, alpha: 1),
                lavaColor: UIColor(red: 1.0, green: 0.42, blue: 0.05, alpha: 1),
                skyTop: UIColor(red: 0.10, green: 0.05, blue: 0.09, alpha: 1),
                skyHorizon: UIColor(red: 0.62, green: 0.19, blue: 0.07, alpha: 1),
                skyBottom: UIColor(red: 0.24, green: 0.08, blue: 0.05, alpha: 1),
                sunColor: UIColor(red: 1.0, green: 0.70, blue: 0.52, alpha: 1),
                sunIntensity: 3300,
                fillIntensity: 1100,
                accent: UIColor(red: 1.0, green: 0.55, blue: 0.10, alpha: 1),
                emissiveWalls: false,
                accentLights: true,
                starrySky: false,
                uiPrimary: Color(red: 0.62, green: 0.20, blue: 0.10),
                uiSecondary: Color(red: 0.95, green: 0.52, blue: 0.15)
            )
        case .clockwork:
            return CourseTheme(
                feltTop: UIColor(red: 0.24, green: 0.35, blue: 0.30, alpha: 1),
                feltStripe: UIColor(red: 0.28, green: 0.40, blue: 0.34, alpha: 1),
                wallColor: UIColor(red: 0.55, green: 0.38, blue: 0.18, alpha: 1),
                wallTopColor: UIColor(red: 0.78, green: 0.58, blue: 0.27, alpha: 1),
                groundColor: UIColor(red: 0.28, green: 0.20, blue: 0.13, alpha: 1),
                groundDetail: UIColor(red: 0.19, green: 0.13, blue: 0.08, alpha: 1),
                sandColor: UIColor(red: 0.66, green: 0.55, blue: 0.36, alpha: 1),
                sandDetail: UIColor(red: 0.54, green: 0.44, blue: 0.28, alpha: 1),
                mudColor: UIColor(red: 0.24, green: 0.20, blue: 0.13, alpha: 1),
                iceColor: UIColor(red: 0.74, green: 0.82, blue: 0.86, alpha: 1),
                waterColor: UIColor(red: 0.18, green: 0.30, blue: 0.32, alpha: 1),
                lavaColor: UIColor(red: 0.98, green: 0.56, blue: 0.14, alpha: 1),
                skyTop: UIColor(red: 0.22, green: 0.18, blue: 0.24, alpha: 1),
                skyHorizon: UIColor(red: 0.88, green: 0.64, blue: 0.33, alpha: 1),
                skyBottom: UIColor(red: 0.42, green: 0.29, blue: 0.20, alpha: 1),
                sunColor: UIColor(red: 1.0, green: 0.88, blue: 0.68, alpha: 1),
                sunIntensity: 4300,
                fillIntensity: 1500,
                accent: UIColor(red: 0.94, green: 0.70, blue: 0.22, alpha: 1),
                emissiveWalls: false,
                accentLights: true,
                starrySky: false,
                uiPrimary: Color(red: 0.52, green: 0.34, blue: 0.14),
                uiSecondary: Color(red: 0.92, green: 0.72, blue: 0.32)
            )
        case .storm:
            return CourseTheme(
                feltTop: UIColor(red: 0.20, green: 0.44, blue: 0.36, alpha: 1),
                feltStripe: UIColor(red: 0.24, green: 0.50, blue: 0.41, alpha: 1),
                wallColor: UIColor(red: 0.38, green: 0.42, blue: 0.46, alpha: 1),
                wallTopColor: UIColor(red: 0.54, green: 0.59, blue: 0.64, alpha: 1),
                groundColor: UIColor(red: 0.30, green: 0.34, blue: 0.36, alpha: 1),
                groundDetail: UIColor(red: 0.21, green: 0.25, blue: 0.28, alpha: 1),
                sandColor: UIColor(red: 0.68, green: 0.66, blue: 0.60, alpha: 1),
                sandDetail: UIColor(red: 0.54, green: 0.53, blue: 0.49, alpha: 1),
                mudColor: UIColor(red: 0.24, green: 0.29, blue: 0.24, alpha: 1),
                iceColor: UIColor(red: 0.70, green: 0.84, blue: 0.90, alpha: 1),
                waterColor: UIColor(red: 0.09, green: 0.29, blue: 0.42, alpha: 1),
                lavaColor: UIColor(red: 0.90, green: 0.42, blue: 0.12, alpha: 1),
                skyTop: UIColor(red: 0.16, green: 0.20, blue: 0.28, alpha: 1),
                skyHorizon: UIColor(red: 0.56, green: 0.62, blue: 0.68, alpha: 1),
                skyBottom: UIColor(red: 0.28, green: 0.35, blue: 0.40, alpha: 1),
                sunColor: UIColor(red: 0.86, green: 0.90, blue: 0.96, alpha: 1),
                sunIntensity: 3900,
                fillIntensity: 2000,
                accent: UIColor(red: 0.98, green: 0.80, blue: 0.20, alpha: 1),
                emissiveWalls: false,
                accentLights: false,
                starrySky: false,
                uiPrimary: Color(red: 0.16, green: 0.36, blue: 0.46),
                uiSecondary: Color(red: 0.58, green: 0.76, blue: 0.82)
            )
        case .cosmos:
            return CourseTheme(
                feltTop: UIColor(red: 0.15, green: 0.19, blue: 0.26, alpha: 1),
                feltStripe: UIColor(red: 0.19, green: 0.24, blue: 0.32, alpha: 1),
                wallColor: UIColor(red: 0.46, green: 0.50, blue: 0.58, alpha: 1),
                wallTopColor: UIColor(red: 0.72, green: 0.90, blue: 1.0, alpha: 1),
                groundColor: UIColor(red: 0.035, green: 0.035, blue: 0.07, alpha: 1),
                groundDetail: UIColor(red: 0.16, green: 0.32, blue: 0.52, alpha: 1),
                sandColor: UIColor(red: 0.42, green: 0.40, blue: 0.45, alpha: 1),
                sandDetail: UIColor(red: 0.31, green: 0.30, blue: 0.35, alpha: 1),
                mudColor: UIColor(red: 0.20, green: 0.20, blue: 0.26, alpha: 1),
                iceColor: UIColor(red: 0.62, green: 0.86, blue: 0.98, alpha: 1),
                waterColor: UIColor(red: 0.36, green: 0.18, blue: 0.72, alpha: 1),
                lavaColor: UIColor(red: 1.0, green: 0.32, blue: 0.34, alpha: 1),
                skyTop: UIColor(red: 0.015, green: 0.015, blue: 0.05, alpha: 1),
                skyHorizon: UIColor(red: 0.07, green: 0.09, blue: 0.20, alpha: 1),
                skyBottom: UIColor(red: 0.02, green: 0.02, blue: 0.07, alpha: 1),
                sunColor: UIColor(red: 0.90, green: 0.94, blue: 1.0, alpha: 1),
                sunIntensity: 3400,
                fillIntensity: 900,
                accent: UIColor(red: 0.25, green: 0.85, blue: 1.0, alpha: 1),
                emissiveWalls: true,
                accentLights: true,
                starrySky: true,
                uiPrimary: Color(red: 0.16, green: 0.40, blue: 0.72),
                uiSecondary: Color(red: 0.32, green: 0.86, blue: 0.98)
            )
        }
    }
}
