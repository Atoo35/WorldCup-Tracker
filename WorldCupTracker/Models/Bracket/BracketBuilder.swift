import Foundation

final class BracketBuilder {

    static func buildTree(from matches: [Match]) -> [[BracketNode]] {

        let grouped = Dictionary(grouping: matches) {
            ($0.type ?? "").uppercased()
        }

        let qf  = (grouped["QF"]  ?? []).sorted { (Int($0.id) ?? 0) < (Int($1.id) ?? 0) }
        let sf  = (grouped["SF"]  ?? []).sorted { (Int($0.id) ?? 0) < (Int($1.id) ?? 0) }
        let f   = (grouped["FINAL"] ?? grouped["F"] ?? []).sorted { (Int($0.id) ?? 0) < (Int($1.id) ?? 0) }

        var qfNodes  = buildRound(qf,  round: .qf,    column: 2)
        var sfNodes  = buildRound(sf,  round: .sf,    column: 3)
        var fNodes   = buildRound(f,   round: .final, column: 4)

        // MARK: - Reorder every round to match the actual bracket tree

        // Sorting by `id` only tells us *which* matches exist in a round —
        // it says nothing about visual top-to-bottom order. The real order
        // is defined by the tree itself: walking down from the Final,
        // visiting left child before right child, puts every pair of
        // matches that feed the same parent next to each other. We use
        // that walk to reorder every column, instead of trusting `id` sort
        // past the point of grouping matches into rounds.

        let allNodes = qfNodes + sfNodes + fNodes
        let nodesByID = Dictionary(uniqueKeysWithValues: allNodes.map { ($0.id, $0) })

        let roots: [BracketNode] =
            !fNodes.isEmpty   ? fNodes   :
            !sfNodes.isEmpty  ? sfNodes  : qfNodes

        let visitOrder = treeVisitOrder(roots: roots, nodesByID: nodesByID)

        func reorder(_ nodes: [BracketNode]) -> [BracketNode] {
            nodes.sorted {
                (visitOrder[$0.id] ?? Int.max) < (visitOrder[$1.id] ?? Int.max)
            }
        }

        qfNodes  = reorder(qfNodes)
        sfNodes  = reorder(sfNodes)
        fNodes   = reorder(fNodes)

        return [ qfNodes, sfNodes, fNodes]
    }

    // MARK: - Round builder

    private static func buildRound(
        _ matches: [Match],
        round: KnockoutRound,
        column: Int
    ) -> [BracketNode] {
        matches.map { match in
            BracketNode(
                id: match.id,
                match: match,
                round: round,
                column: column,
                leftChildID: referencedMatchID(from: match.homeTeamLabel),
                rightChildID: referencedMatchID(from: match.awayTeamLabel)
            )
        }
    }

    /// Parses strings like "Winner Match 86" -> "86".
    /// Returns nil for labels with no match reference (e.g. "Winner Group J")
    /// — those nodes correctly stay leaves.
    private static func referencedMatchID(from label: String?) -> String? {
        guard let label = label else { return nil }
        guard let range = label.range(of: #"Match\s+(\d+)"#, options: .regularExpression) else {
            return nil
        }
        let digits = label[range].filter(\.isNumber)
        return digits.isEmpty ? nil : digits
    }

    // MARK: - Tree traversal ordering

    /// Walks the bracket from the deepest available round (normally the
    /// Final) down to the leaves, visiting the left child before the right
    /// child at every node. Because siblings in the tree are visited
    /// consecutively, this produces the correct top-to-bottom visual order
    /// for *every* round — not just the leaves.
    private static func treeVisitOrder(
        roots: [BracketNode],
        nodesByID: [String: BracketNode]
    ) -> [String: Int] {

        var order: [String: Int] = [:]
        var sequence = 0

        func visit(_ node: BracketNode) {
            guard order[node.id] == nil else { return } // guard against cycles/dupes
            order[node.id] = sequence
            sequence += 1

            if let leftID = node.leftChildID, let left = nodesByID[leftID] {
                visit(left)
            }
            if let rightID = node.rightChildID, let right = nodesByID[rightID] {
                visit(right)
            }
        }

        for root in roots {
            visit(root)
        }

        return order
    }
}
