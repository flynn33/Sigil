import Foundation
import RFCoreModels

protocol Sigil9DGeometryBuilding: Sendable {
    func buildSegments(vector: CanonicalVector) -> [SigilLine]
}

struct PortableSigil9DGeometryBuilder: Sigil9DGeometryBuilding {
    private let planeWeights: [Double] = [1.0, 0.35, 0.95, 0.9, 0.88, 0.92, 0.42, 0.86, 0.58]
    private let rotations: [PortableGivensRotation] = [
        PortableGivensRotation(i: 0, j: 2, angle: 0.22),
        PortableGivensRotation(i: 1, j: 3, angle: -0.18),
        PortableGivensRotation(i: 0, j: 5, angle: 0.11),
        PortableGivensRotation(i: 1, j: 6, angle: 0.14),
        PortableGivensRotation(i: 0, j: 8, angle: -0.09),
        PortableGivensRotation(i: 1, j: 7, angle: 0.13)
    ]
    private let strokeBlueprint = PortableSigilBlueprint()

    func buildSegments(vector: CanonicalVector) -> [SigilLine] {
        let matrix = PortableProjectionMatrixBuilder().makeMatrix(
            rotations: rotations,
            planeWeights: planeWeights
        )
        let hiddenProfiles = PortableHiddenDimensionProfileFactory().makeProfiles(
            vector: vector,
            planeWeights: planeWeights
        )
        let projector = PortableSigil9DProjector(matrix: matrix, hiddenProfiles: hiddenProfiles)
        let strokes = strokeBlueprint.makeStrokes()

        guard !strokes.isEmpty else { return [] }

        let totalStrokeCount = Double(strokes.count)
        var lines: [SigilLine] = []

        for (strokeIndex, stroke) in strokes.enumerated() {
            let sampleCount = max(2, stroke.sampleCount)
            let points: [(x: Double, y: Double)] = (0..<sampleCount).map { sampleIndex in
                let localT = sampleCount == 1 ? 0.0 : Double(sampleIndex) / Double(sampleCount - 1)
                let globalT = (Double(strokeIndex) + localT) / totalStrokeCount
                let p2 = stroke.point(at: localT)
                return projector.project(point2D: p2, globalT: globalT)
            }

            guard points.count >= 2 else { continue }
            for index in 0..<(points.count - 1) {
                let start = points[index]
                let end = points[index + 1]
                lines.append(
                    SigilLine(
                        startX: start.x,
                        startY: start.y,
                        endX: end.x,
                        endY: end.y
                    )
                )
            }

            if stroke.isClosed, let first = points.first, let last = points.last {
                lines.append(
                    SigilLine(
                        startX: last.x,
                        startY: last.y,
                        endX: first.x,
                        endY: first.y
                    )
                )
            }
        }

        return lines
    }
}

private struct PortableSigil9DProjector: Sendable {
    let matrix: PortableProjectionMatrix2x9
    let hiddenProfiles: [PortableHiddenDimensionProfile]

    func project(point2D: (x: Double, y: Double), globalT: Double) -> (x: Double, y: Double) {
        var vector = [Double](repeating: 0.0, count: 9)
        vector[0] = point2D.x
        vector[1] = point2D.y

        for profile in hiddenProfiles {
            let signal = profile.amplitude * sin(2.0 * Double.pi * profile.frequency * globalT + profile.phase)
            vector[profile.dimension] = signal
        }

        return matrix.project(vector)
    }
}

private struct PortableProjectionMatrix2x9: Sendable {
    let rowX: [Double]
    let rowY: [Double]

    func project(_ vector: [Double]) -> (x: Double, y: Double) {
        (dot(rowX, vector), dot(rowY, vector))
    }

    private func dot(_ lhs: [Double], _ rhs: [Double]) -> Double {
        zip(lhs, rhs).reduce(0.0) { partial, pair in
            partial + pair.0 * pair.1
        }
    }
}

private struct PortableGivensRotation: Sendable {
    let i: Int
    let j: Int
    let angle: Double
}

private struct PortableProjectionMatrixBuilder: Sendable {
    func makeMatrix(rotations: [PortableGivensRotation], planeWeights: [Double]) -> PortableProjectionMatrix2x9 {
        var basis = identity(size: 9)

        for rotation in rotations {
            apply(rotation, to: &basis)
        }

        var rowX = basis[0]
        var rowY = basis[1]
        for index in 0..<9 {
            rowX[index] *= planeWeights[safe: index] ?? 1.0
            rowY[index] *= planeWeights[safe: index] ?? 1.0
        }

        return PortableProjectionMatrix2x9(rowX: rowX, rowY: rowY)
    }

    private func identity(size: Int) -> [[Double]] {
        var matrix = Array(repeating: Array(repeating: 0.0, count: size), count: size)
        for index in 0..<size {
            matrix[index][index] = 1.0
        }
        return matrix
    }

    private func apply(_ rotation: PortableGivensRotation, to matrix: inout [[Double]]) {
        guard (0..<9).contains(rotation.i), (0..<9).contains(rotation.j), rotation.i != rotation.j else {
            return
        }

        let c = cos(rotation.angle)
        let s = sin(rotation.angle)
        let rowI = matrix[rotation.i]
        let rowJ = matrix[rotation.j]

        for column in 0..<9 {
            matrix[rotation.i][column] = c * rowI[column] - s * rowJ[column]
            matrix[rotation.j][column] = s * rowI[column] + c * rowJ[column]
        }
    }
}

private struct PortableHiddenDimensionProfile: Sendable {
    let dimension: Int
    let amplitude: Double
    let frequency: Double
    let phase: Double
}

private struct PortableHiddenDimensionProfileFactory: Sendable {
    func makeProfiles(vector: CanonicalVector, planeWeights: [Double]) -> [PortableHiddenDimensionProfile] {
        let h = vector.H_entropy.clamped(to: 0...1)
        let k = vector.K_complexity.clamped(to: 0...1)
        let d = ((vector.D_fractal_dim - 1.0) / 1.5).clamped(to: 0...1)
        let s = vector.S_symmetry.clamped(to: 0...1)
        let l = (Double(vector.L_generator_length - 1) / 998.0).clamped(to: 0...1)

        let components: [Double] = [
            h,
            k,
            d,
            s,
            l,
            0.5 * (k + s),
            0.5 * (1.0 - h + s)
        ]

        return components.enumerated().map { offset, component in
            let dimension = offset + 2
            let amplitude = (0.020 + 0.060 * component) * (planeWeights[safe: dimension] ?? 1.0)
            let frequency = 1.00 + 0.37 * Double(offset) + 0.25 * component
            let phase = Double(offset) * .pi / 7.0
            return PortableHiddenDimensionProfile(
                dimension: dimension,
                amplitude: amplitude,
                frequency: frequency,
                phase: phase
            )
        }
    }
}

private protocol PortableSigilStroke2D: Sendable {
    var sampleCount: Int { get }
    var isClosed: Bool { get }
    func point(at t: Double) -> (x: Double, y: Double)
}

private struct PortableLineStroke2D: PortableSigilStroke2D {
    let start: (x: Double, y: Double)
    let end: (x: Double, y: Double)
    let sampleCount: Int
    let isClosed = false

    func point(at t: Double) -> (x: Double, y: Double) {
        let u = t.clamped(to: 0...1)
        return (
            x: start.x + (end.x - start.x) * u,
            y: start.y + (end.y - start.y) * u
        )
    }
}

private struct PortableEllipseStroke2D: PortableSigilStroke2D {
    let center: (x: Double, y: Double)
    let radiusX: Double
    let radiusY: Double
    let thetaStart: Double
    let thetaEnd: Double
    let sampleCount: Int
    let isClosed: Bool

    func point(at t: Double) -> (x: Double, y: Double) {
        let u = t.clamped(to: 0...1)
        let theta = thetaStart + (thetaEnd - thetaStart) * u
        return (
            x: center.x + radiusX * cos(theta),
            y: center.y + radiusY * sin(theta)
        )
    }
}

private struct PortableCurlStroke2D: PortableSigilStroke2D {
    let center: (x: Double, y: Double)
    let thetaStart: Double
    let thetaEnd: Double
    let radiusStart: Double
    let radiusEnd: Double
    let xSign: Double
    let sampleCount: Int
    let isClosed = false

    func point(at t: Double) -> (x: Double, y: Double) {
        let u = t.clamped(to: 0...1)
        let theta = thetaStart + (thetaEnd - thetaStart) * u
        let radius = radiusStart + (radiusEnd - radiusStart) * u
        return (
            x: center.x + xSign * radius * cos(theta),
            y: center.y + radius * sin(theta)
        )
    }
}

private struct PortablePolylineStroke2D: PortableSigilStroke2D {
    let points: [(x: Double, y: Double)]
    let sampleCount: Int
    let isClosed: Bool

    func point(at t: Double) -> (x: Double, y: Double) {
        guard points.count > 1 else {
            return points.first ?? (0.0, 0.0)
        }

        let u = t.clamped(to: 0...1)
        let segmentCount = points.count - 1
        let position = u * Double(segmentCount)
        let segmentIndex = min(Int(floor(position)), segmentCount - 1)
        let localT = position - Double(segmentIndex)

        let start = points[segmentIndex]
        let end = points[segmentIndex + 1]
        return (
            x: start.x + (end.x - start.x) * localT,
            y: start.y + (end.y - start.y) * localT
        )
    }
}

private struct PortableSigilBlueprint: Sendable {
    func makeStrokes() -> [any PortableSigilStroke2D] {
        let namedPoints: [String: (Double, Double)] = [
            "A": (-0.48, 0.70),
            "B": (0.48, 0.70),
            "C": (0.0, 0.28),
            "D": (-0.18, -0.03),
            "E": (0.18, -0.03),
            "F": (-0.24, -0.28),
            "G": (0.24, -0.28),
            "H": (0.0, -0.57),
            "I": (-0.24, -0.86),
            "J": (0.24, -0.86),
            "K": (0.0, -1.02)
        ]

        let strokeList: [any PortableSigilStroke2D] = [
            PortableLineStroke2D(
                start: (0.0, 0.18),
                end: namedPoints["K"] ?? (0.0, -1.02),
                sampleCount: 54
            ),
            PortableLineStroke2D(start: namedPoints["A"]!, end: namedPoints["B"]!, sampleCount: 48),
            PortableLineStroke2D(start: namedPoints["A"]!, end: namedPoints["C"]!, sampleCount: 36),
            PortableLineStroke2D(start: namedPoints["B"]!, end: namedPoints["C"]!, sampleCount: 36),
            PortableLineStroke2D(start: namedPoints["C"]!, end: namedPoints["D"]!, sampleCount: 28),
            PortableLineStroke2D(start: namedPoints["C"]!, end: namedPoints["E"]!, sampleCount: 28),
            PortableLineStroke2D(start: namedPoints["F"]!, end: namedPoints["H"]!, sampleCount: 30),
            PortableLineStroke2D(start: namedPoints["G"]!, end: namedPoints["H"]!, sampleCount: 30),
            PortableLineStroke2D(start: namedPoints["H"]!, end: namedPoints["I"]!, sampleCount: 32),
            PortableLineStroke2D(start: namedPoints["H"]!, end: namedPoints["J"]!, sampleCount: 32),
            PortableEllipseStroke2D(
                center: (0.0, 0.86),
                radiusX: 0.07,
                radiusY: 0.11,
                thetaStart: 0.0,
                thetaEnd: 2.0 * Double.pi,
                sampleCount: 120,
                isClosed: true
            ),
            PortableCurlStroke2D(
                center: (-0.32, -0.6),
                thetaStart: 0.7853981633974483,
                thetaEnd: 4.869468613064179,
                radiusStart: 0.02,
                radiusEnd: 0.08,
                xSign: 1.0,
                sampleCount: 92
            ),
            PortableCurlStroke2D(
                center: (0.32, -0.6),
                thetaStart: 0.7853981633974483,
                thetaEnd: 4.869468613064179,
                radiusStart: 0.02,
                radiusEnd: 0.08,
                xSign: -1.0,
                sampleCount: 92
            ),
            PortablePolylineStroke2D(
                points: [
                    (0.0, -1.02),
                    (0.018, -0.97),
                    (0.0, -0.92),
                    (-0.018, -0.97),
                    (0.0, -1.02)
                ],
                sampleCount: 70,
                isClosed: true
            )
        ]

        return strokeList
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
