import Foundation

enum KnockoutRound: String, CaseIterable {
    case r32 = "R32"
    case r16 = "R16"
    case qf = "QF"
    case sf = "SF"
    case final = "FINAL"
}

struct BracketMatch: Identifiable {
    let id: String
    let match: Match
    let round: KnockoutRound
}
