import SwiftUI

struct BracketMatchCard: View {

    let match: Match
    let teams: [String: Team]

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            // MARK: - KICKOFF (TOP CENTER)
            if let date = match.kickoffDate {
                Text(formatKickoff(date))
                    .font(.system(size: 9, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }

            // MARK: - TEAMS
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

    // MARK: - TEAM ROW (with flags)

    private func teamRow(name: String?, score: String?) -> some View {

        let team = teams.values.first(where: {
            $0.name_en.lowercased() == (name ?? "").lowercased()
        })

        return HStack(spacing: 6) {

            // FLAG
            if let flagURL = team?.flag,
               let url = URL(string: flagURL) {

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Color.gray.opacity(0.2)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:
                        Color.gray.opacity(0.3)

                    @unknown default:
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(width: 18, height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            } else {
                Color.gray.opacity(0.2)
                    .frame(width: 18, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }

            // NAME
            Text(displayName(name))
                .foregroundStyle(isPlaceholder(name) ? .secondary : .primary)

            Spacer()

            // SCORE
            Text(score ?? "-")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - HELPERS

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

    // MARK: - DATE FORMAT

    private func formatKickoff(_ date: Date) -> String {

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "d MMM • HH:mm"

        return formatter.string(from: date)
    }
}
