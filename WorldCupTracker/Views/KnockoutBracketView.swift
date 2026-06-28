import SwiftUI

struct KnockoutBracketView: View {

    let matches: [Match]
    let teams: [String: Team]

    @State private var cachedColumns: [[BracketNode]] = []
    @State private var cachedLayout: [String: CGPoint] = [:]

    @State private var contentSize: CGSize = .zero
    @State private var originOffset: CGPoint = .zero

    // MARK: - ZOOM / PAN
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    @State private var didInitialScroll = false

    private let cardSize = CGSize(width: 180, height: 70)
    private let xSpacing: CGFloat = 260

    var body: some View {

        ScrollViewReader { proxy in

            ScrollView([.horizontal, .vertical]) {

                ZStack(alignment: .topLeading) {

                    // TOP-LEFT ANCHOR
                    Color.clear
                        .frame(width: 1, height: 1)
                        .id("TOP_LEFT")

                    // LINES
                    Canvas { context, _ in
                        drawLines(context: context)
                    }

                    // MATCH CARDS
                    ForEach(cachedColumns.flatMap { $0 }) { node in
                        if let match = node.match,
                           let pos = cachedLayout[node.id] {

                            BracketMatchCard(match: match, teams: teams)
                                .position(offset(pos))
                        }
                    }

                    // HEADERS
                    ForEach(Array(cachedColumns.enumerated()), id: \.offset) { index, _ in

                        Text(roundTitle(for: index))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .position(
                                offset(
                                    CGPoint(
                                        x: CGFloat(index) * xSpacing,
                                        y: -60
                                    )
                                )
                            )
                    }
                }
                .frame(width: contentSize.width,
                       height: contentSize.height,
                       alignment: .topLeading)

                .scaleEffect(scale)
                .offset(offset)
                .gesture(combinedGesture)
            }
            .onAppear {
                rebuildBracket()

                // RESET CAMERA
                scale = 1.0
                lastScale = 1.0
                offset = .zero
                lastOffset = .zero

                didInitialScroll = false
            }
            .onChange(of: cachedLayout) { _ in
                performInitialScroll(proxy: proxy)
            }
            .onChange(of: matches.count) { _ in
                didInitialScroll = false
                rebuildBracket()
            }
        }
    }

    // MARK: - INITIAL SCROLL FIX

    private func performInitialScroll(proxy: ScrollViewProxy) {
        guard !didInitialScroll,
              !cachedLayout.isEmpty else { return }

        didInitialScroll = true

        DispatchQueue.main.async {
            withAnimation(.none) {
                proxy.scrollTo("TOP_LEFT", anchor: .topLeading)
            }
        }
    }

    // MARK: - GESTURES

    private var combinedGesture: some Gesture {

        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    let delta = value / lastScale
                    lastScale = value
                    scale *= delta
                }
                .onEnded { _ in
                    lastScale = 1.0
                },

            DragGesture()
                .onChanged { value in
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    lastOffset = offset
                }
        )
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

    // MARK: - ROUND TITLES

    private func roundTitle(for index: Int) -> String {
        switch index {
        case 0: return "Round of 32"
        case 1: return "Round of 16"
        case 2: return "Quarter Finals"
        case 3: return "Semi Finals"
        default: return "Final"
        }
    }

    // MARK: - LINES

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

    private func drawConnection(
        context: GraphicsContext,
        from child: CGPoint,
        to parent: CGPoint
    ) {
        var path = Path()

        let half = cardSize.width / 2
        let isLeftToRight = child.x < parent.x

        let startX = child.x + (isLeftToRight ? half : -half)
        let endX   = parent.x - (isLeftToRight ? half : -half)

        let midX = (startX + endX) / 2

        path.move(to: CGPoint(x: startX, y: child.y))
        path.addLine(to: CGPoint(x: midX, y: child.y))
        path.addLine(to: CGPoint(x: midX, y: parent.y))
        path.addLine(to: CGPoint(x: endX, y: parent.y))

        context.stroke(
            path,
            with: .color(.white.opacity(0.25)),
            lineWidth: 1
        )
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

    // MARK: - OFFSET

    private func offset(_ p: CGPoint) -> CGPoint {
        CGPoint(
            x: p.x - originOffset.x,
            y: p.y - originOffset.y
        )
    }
}
