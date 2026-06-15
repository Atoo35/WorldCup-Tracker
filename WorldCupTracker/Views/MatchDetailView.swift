import SwiftUI

struct MatchDetailView: View {
    let match: Match
    let teams: [String: Team]
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Navigation bar
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(.callout)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                // Status badge
                Text(match.displayStatus)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.12), in: Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // MARK: - Score hero
            VStack(spacing: 8) {
                HStack(alignment: .center, spacing: 0) {

                    // Home team
                    VStack(spacing: 6) {
                        AsyncImage(url: match.homeFlagURL(teams: teams)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 40, height: 27)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)

                        Text(match.homeTeamName ?? "TBD")
                            .font(.caption.weight(.medium))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 80)
                    }
                    .frame(maxWidth: .infinity)

                    // Score / vs
                    if match.isUpcoming {
                        Text("vs")
                            .font(.title2.weight(.light))
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 64)
                    } else {
                        Text("\(match.homeScore ?? "0")  –  \(match.awayScore ?? "0")")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .frame(minWidth: 64)
                    }

                    // Away team
                    VStack(spacing: 6) {
                        AsyncImage(url: match.awayFlagURL(teams: teams)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 40, height: 27)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)

                        Text(match.awayTeamName ?? "TBD")
                            .font(.caption.weight(.medium))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 80)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 14)

                // Group / type badge
                if let group = match.group {
                    Text("Group \(group)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                        .kerning(0.5)
                }
            }

            // MARK: - Scorers
            if (match.isLive || match.isFinished) &&
               (!match.groupedHomeScorers.isEmpty || !match.groupedAwayScorers.isEmpty) {

                Divider()
                    .padding(.top, 4)

                HStack(alignment: .top, spacing: 0) {

                    // Home scorers (left)
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(match.groupedHomeScorers, id: \.self) { scorer in
                            HStack(spacing: 5) {
                                Image(systemName: "soccerball")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                Text(scorer)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.primary.opacity(0.85))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                        .frame(height: max(CGFloat(max(match.groupedHomeScorers.count,
                                                       match.groupedAwayScorers.count)) * 22, 22))

                    // Away scorers (right)
                    VStack(alignment: .trailing, spacing: 5) {
                        ForEach(match.groupedAwayScorers, id: \.self) { scorer in
                            HStack(spacing: 5) {
                                Text(scorer)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.primary.opacity(0.85))
                                    .lineLimit(1)
                                Image(systemName: "soccerball")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

            } else if match.isUpcoming {
                Divider()
                    .padding(.top, 4)
                Text(match.kickoffTimeString.map { "Kicks off at \($0) GMT" } ?? "Time TBD")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 16)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        if match.isLive { return .red }
        if match.isFinished { return .secondary }
        return .accentColor
    }
}
