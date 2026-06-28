import SwiftUI

struct KnockoutBracketView: View {

    let matches: [Match]
    let teams: [String: Team]

    @State private var cachedColumns: [[BracketNode]] = []
    @State private var cachedLayout: [String: CGPoint] = [:]

    @State private var contentSize: CGSize = .zero
    @State private var originOffset: CGPoint = .zero

    var body: some View {

        ScrollView([.horizontal, .vertical]) {

            ZStack(alignment: .topLeading) {

                Canvas { context, _ in
                    drawLines(context: context)
                }

                ForEach(cachedColumns.flatMap { $0 }) { node in
                    if let match = node.match,
                       let pos = cachedLayout[node.id] {

                        BracketMatchCard(match: match, teams: teams)
                            .position(offset(pos))
                    }
                }
            }
            .frame(width: contentSize.width,
                   height: contentSize.height,
                   alignment: .topLeading)
        }
        .onAppear { rebuildBracket() }
        .onChange(of: matches.count) { _ in rebuildBracket() }
    }

    // MARK: - BUILD

    private func rebuildBracket() {

        let columns = BracketBuilder.buildTree(from: matches)
        let layout = BracketLayoutEngine().layout(columns: columns)

        let (size, offset) = calculateBounds(layout: layout)

        DispatchQueue.main.async {
            self.cachedColumns = columns
            self.cachedLayout = layout
            self.contentSize = size
            self.originOffset = offset
        }
    }

    // MARK: - BOUNDS

    private func calculateBounds(layout: [String: CGPoint]) -> (CGSize, CGPoint) {

        guard let first = layout.values.first else {
            return (.zero, .zero)
        }

        var minX = first.x, maxX = first.x
        var minY = first.y, maxY = first.y

        for p in layout.values {
            minX = min(minX, p.x)
            maxX = max(maxX, p.x)
            minY = min(minY, p.y)
            maxY = max(maxY, p.y)
        }

        let padding: CGFloat = 120

        return (
            CGSize(
                width: maxX - minX + padding * 2,
                height: maxY - minY + padding * 2
            ),
            CGPoint(x: minX - padding, y: minY - padding)
        )
    }

    // MARK: - LINES (NOW STABLE)

    private func drawLines(context: GraphicsContext) {

        let allNodes = cachedColumns.flatMap { $0 }

        for node in allNodes {

            guard let parentPos = cachedLayout[node.id] else { continue }

            let children = allNodes.filter {
                $0.leftChildID == node.id || $0.rightChildID == node.id
            }

            for child in children {

                guard let childPos = cachedLayout[child.id] else { continue }

                drawConnection(
                    context: context,
                    from: offset(childPos),
                    to: offset(parentPos)
                )
            }
        }
    }

    // MARK: - HELPERS

    private func offset(_ p: CGPoint) -> CGPoint {
        CGPoint(
            x: p.x - originOffset.x,
            y: p.y - originOffset.y
        )
    }

    private func drawConnection(
        context: GraphicsContext,
        from child: CGPoint,
        to parent: CGPoint
    ) {
        var path = Path()

        let midX = (child.x + parent.x) / 2

        path.move(to: child)
        path.addLine(to: CGPoint(x: midX, y: child.y))
        path.addLine(to: CGPoint(x: midX, y: parent.y))
        path.addLine(to: parent)

        context.stroke(
            path,
            with: .color(.white.opacity(0.25)),
            lineWidth: 1
        )
    }
}
