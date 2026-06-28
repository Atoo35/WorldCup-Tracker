import Foundation

struct BracketNode: Identifiable {

    let id: String

    let match: Match?
    let round: KnockoutRound
    let column: Int

    let leftChildID: String?
    let rightChildID: String?
}
