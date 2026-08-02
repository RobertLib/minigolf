//
//  LevelLibrary.swift
//  Minigolf
//
//  Index over the hand-crafted holes. Each world lives in its own file under
//  Models/Levels; difficulty ramps up inside a world and across the run of them,
//  in the order `CourseType` lists.
//

import Foundation
import simd

enum LevelLibrary {

    static func levels(for course: CourseType) -> [LevelDefinition] {
        switch course {
        case .garden: return GardenCourse.holes
        case .desert: return DesertCourse.holes
        case .jungle: return JungleCourse.holes
        case .ice: return IceCourse.holes
        case .neon: return NeonCourse.holes
        case .volcano: return VolcanoCourse.holes
        case .clockwork: return ClockworkCourse.holes
        case .storm: return StormCourse.holes
        case .cosmos: return CosmosCourse.holes
        }
    }

    /// Holes on a course; every world currently has the same length, but the
    /// game never assumes so.
    static func holeCount(_ course: CourseType) -> Int {
        levels(for: course).count
    }

    static func level(course: CourseType, number: Int) -> LevelDefinition {
        let holes = levels(for: course)
        return holes[min(max(number, 1), holes.count) - 1]
    }

    static func coursePar(_ course: CourseType) -> Int {
        levels(for: course).reduce(0) { $0 + $1.par }
    }

    /// Holes on a course that hide a bonus star.
    static func bonusStarCount(_ course: CourseType) -> Int {
        levels(for: course).count { $0.bonusStar != nil }
    }

    static var totalPar: Int {
        CourseType.allCases.reduce(0) { $0 + coursePar($1) }
    }

    static var totalHoles: Int {
        CourseType.allCases.reduce(0) { $0 + holeCount($1) }
    }

    static var totalBonusStars: Int {
        CourseType.allCases.reduce(0) { $0 + bonusStarCount($1) }
    }
}
