import Foundation
import CoreGraphics

final class BracketLayoutEngine {

    private let xSpacing: CGFloat = 260
    private let ySpacing: CGFloat = 90

    func layout(columns: [[BracketNode]]) -> [String: CGPoint] {

        var positions: [String: CGPoint] = [:]

        guard let r32 = columns.first else { return positions }

        // MARK: R32 base layout
        for (i, node) in r32.enumerated() {
            positions[node.id] = CGPoint(
                x: 0,
                y: CGFloat(i) * ySpacing
            )
        }

        // MARK: build upwards
        for col in 1..<columns.count {

            let prev = columns[col - 1]
            let curr = columns[col]

            for node in curr {

                guard
                    let leftID = node.leftChildID,
                    let rightID = node.rightChildID,
                    let left = positions[leftID],
                    let right = positions[rightID]
                else {
                    continue
                }

                positions[node.id] = CGPoint(
                    x: CGFloat(col) * xSpacing,
                    y: (left.y + right.y) / 2
                )
            }
        }

        return positions
    }
}
