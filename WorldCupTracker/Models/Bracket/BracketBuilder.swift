import Foundation

final class BracketBuilder {

    static func buildTree(from matches: [Match]) -> [[BracketNode]] {

        let grouped = Dictionary(grouping: matches) {
            ($0.type ?? "").uppercased()
        }

        let r32 = (grouped["R32"] ?? [])
        let r16 = (grouped["R16"] ?? [])
        let qf  = (grouped["QF"] ?? [])
        let sf  = (grouped["SF"] ?? [])
        let f   = (grouped["FINAL"] ?? grouped["F"] ?? [])

        let r32Nodes = r32.map(node)

        var r16Nodes: [BracketNode] = []
        var qfNodes: [BracketNode] = []
        var sfNodes: [BracketNode] = []
        var fNodes: [BracketNode] = []

        // MARK: R16 links to R32
        for i in 0..<r16.count {

            let left = i * 2 < r32Nodes.count ? r32Nodes[i * 2].id : nil
            let right = i * 2 + 1 < r32Nodes.count ? r32Nodes[i * 2 + 1].id : nil

            let match = r16[i]

            r16Nodes.append(
                BracketNode(
                    id: match.id ?? UUID().uuidString,
                    match: match,
                    round: .r16,
                    column: 1,
                    leftChildID: left,
                    rightChildID: right
                )
            )
        }

        // MARK: QF links to R16
        for i in 0..<qf.count {

            let left = i * 2 < r16Nodes.count ? r16Nodes[i * 2].id : nil
            let right = i * 2 + 1 < r16Nodes.count ? r16Nodes[i * 2 + 1].id : nil

            let match = qf[i]

            qfNodes.append(
                BracketNode(
                    id: match.id ?? UUID().uuidString,
                    match: match,
                    round: .qf,
                    column: 2,
                    leftChildID: left,
                    rightChildID: right
                )
            )
        }

        // MARK: SF links to QF
        for i in 0..<sf.count {

            let left = i * 2 < qfNodes.count ? qfNodes[i * 2].id : nil
            let right = i * 2 + 1 < qfNodes.count ? qfNodes[i * 2 + 1].id : nil

            let match = sf[i]

            sfNodes.append(
                BracketNode(
                    id: match.id ?? UUID().uuidString,
                    match: match,
                    round: .sf,
                    column: 3,
                    leftChildID: left,
                    rightChildID: right
                )
            )
        }

        // MARK: FINAL links to SF
        for i in 0..<f.count {

            let left = i * 2 < sfNodes.count ? sfNodes[i * 2].id : nil
            let right = i * 2 + 1 < sfNodes.count ? sfNodes[i * 2 + 1].id : nil

            let match = f[i]

            fNodes.append(
                BracketNode(
                    id: match.id ?? UUID().uuidString,
                    match: match,
                    round: .final,
                    column: 4,
                    leftChildID: left,
                    rightChildID: right
                )
            )
        }

        return [
            r32Nodes,
            r16Nodes,
            qfNodes,
            sfNodes,
            fNodes
        ]
    }

    private static func node(from match: Match) -> BracketNode {
        BracketNode(
            id: match.id ?? UUID().uuidString,
            match: match,
            round: KnockoutRound(rawValue: match.type ?? "") ?? .r32,
            column: column(for: match.type),
            leftChildID: nil,
            rightChildID: nil
        )
    }

    private static func column(for type: String?) -> Int {
        switch type?.lowercased() {
        case "r32": return 0
        case "r16": return 1
        case "qf": return 2
        case "sf": return 3
        default: return 4
        }
    }
}
