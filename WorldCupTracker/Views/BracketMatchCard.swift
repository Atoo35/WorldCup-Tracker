import SwiftUI

struct BracketMatchCard: View {

    let match: Match
    let teams: [String: Team]

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            teamRow(
                name: match.homeTeamName,
                score: match.homeScore
            )

            teamRow(
                name: match.awayTeamName,
                score: match.awayScore
            )
        }
        .font(.system(size: 10, weight: .medium, design: .rounded))
        .padding(8)
        .frame(width: 150)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Row

    private func teamRow(name: String?, score: String?) -> some View {

        HStack {
            Text(displayName(name))
                .foregroundStyle(isPlaceholder(name) ? .secondary : .primary)

            Spacer()

            Text(score ?? "-")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func isPlaceholder(_ name: String?) -> Bool {
        guard let name = name else { return true }
        return name.lowercased().contains("winner") ||
               name.lowercased().contains("tbd")
    }

    private func displayName(_ name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "TBD" }
        return name
    }

    private var backgroundColor: Color {
        Color.primary.opacity(0.05)
    }
}
