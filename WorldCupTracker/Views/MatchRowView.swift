import SwiftUI

struct MatchRowView: View {
    let match: Match
    let teams: [String: Team]
    let showScore: Bool
    let onTap: () -> Void

    init(
        match: Match,
        teams: [String: Team],
        showScore: Bool = true,
        onTap: @escaping () -> Void = {}
    ) {
        self.match = match
        self.teams = teams
        self.showScore = showScore
        self.onTap = onTap
    }

    private var hasScorers: Bool {
        (match.isLive || match.isFinished) &&
        (!match.groupedHomeScorers.isEmpty || !match.groupedAwayScorers.isEmpty)
    }

    var body: some View {
        HStack(spacing: 10) {

            // MARK: - Home
            HStack(spacing: 6) {
                AsyncImage(url: match.homeFlagURL(teams: teams)) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 18, height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 2))

                Text(match.homeTeamName ?? "TBD")
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // MARK: - Score / vs
            if showScore && !match.isUpcoming {
                Text(match.displayScore)
                    .font(.system(.body, design: .monospaced).weight(.semibold))
                    .frame(minWidth: 52)
            } else {
                Text("vs")
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 52)
            }

            // MARK: - Away
            HStack(spacing: 6) {
                Text(match.awayTeamName ?? "TBD")
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                AsyncImage(url: match.awayFlagURL(teams: teams)) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 18, height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            Spacer()

            // MARK: - Status + chevron
            HStack(spacing: 4) {
                Text(match.displayStatus)
                    .font(.caption)
                    .foregroundStyle(statusColor)

                if hasScorers {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(width: 52, alignment: .trailing)
        }
        .font(.callout)
        .contentShape(Rectangle())
        .onTapGesture {
            if hasScorers || !match.isUpcoming {
                onTap()
            }
        }
    }

    // MARK: - Status color

    private var statusColor: Color {
        if match.isLive { return .red }
        if match.isFinished { return .secondary }
        return .primary
    }
}
