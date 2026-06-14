import AppKit
import SwiftUI

struct PopoverContentView: View {
    @EnvironmentObject private var matchService: MatchService

    // Drill-down state
    @State private var selectedMatch: Match? = nil
    @State private var showingDetail = false
    @State private var showingPastMatches = false

    var body: some View {
        ZStack {

            // MARK: - Main list
            VStack(alignment: .leading, spacing: 0) {
                header

                Divider()

                content
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                footer
            }
            .frame(width: 360, height: 340)

            // MARK: - Past Matches overlay (slides in from right)
            if showingPastMatches {
                VStack(alignment: .leading, spacing: 0) {
                    PastMatchesView(
                        matches: matchService.pastMatches,
                        teams: matchService.teams,
                        onBack: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                showingPastMatches = false
                            }
                        },
                        onSelectMatch: { match in
                            selectedMatch = match
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                showingDetail = true
                            }
                        }
                    )

                    Divider()

                    footer
                }
                .frame(width: 360, height: 340)
                .background(.regularMaterial)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .trailing).combined(with: .opacity)
                ))
            }

            // MARK: - Detail overlay (slides in from right)
            if showingDetail, let match = selectedMatch {
                VStack(alignment: .leading, spacing: 0) {
                    MatchDetailView(
                        match: match,
                        teams: matchService.teams,
                        onBack: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                showingDetail = false
                            }
                        }
                    )

                    Divider()

                    footer
                }
                .frame(width: 360, height: 340)
                .background(.regularMaterial)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            matchService.startAutoRefresh()
            Task { await matchService.fetchMatches() }
        }
        .onDisappear {
            matchService.stopAutoRefresh()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("FIFA World Cup 2026")
                .font(.headline)
                .opacity(matchService.isRefreshing ? 0.4 : 1.0)
                .animation(
                    matchService.isRefreshing 
                        ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) 
                        : .easeOut(duration: 0.3),
                    value: matchService.isRefreshing
                )
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    showingPastMatches = true
                }
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Past Matches")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if matchService.isLoading {
            ProgressView("Loading matches…")
                .frame(maxWidth: .infinity)
                .padding(24)
        } else if let errorMessage = matchService.errorMessage,
                  matchService.liveMatches.isEmpty,
                  matchService.todayMatches.isEmpty,
                  matchService.tomorrowMatches.isEmpty {
            VStack(spacing: 12) {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    Task { await matchService.fetchMatches() }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let errorMessage = matchService.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 12)
                    }

                    matchSection(
                        title: "LIVE",
                        trailingText: matchService.isRefreshing ? "Updating..." : lastUpdatedText,
                        matches: matchService.liveMatches,
                        emptyText: "No live matches right now"
                    )
                    matchSection(title: "TODAY",    matches: matchService.todayMatches,    emptyText: "No matches today")
                    matchSection(title: "TOMORROW", matches: matchService.tomorrowMatches, emptyText: "No matches tomorrow")
                }
                .padding(.vertical, 10)
            }
            .frame(maxHeight: 380)
        }
    }

    // MARK: - Helpers

    private var lastUpdatedText: String? {
        guard let date = matchService.lastRefreshTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Updated \(formatter.string(from: date))"
    }

    // MARK: - Section builder

    private func matchSection(title: String, trailingText: String? = nil, matches: [Match], emptyText: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                if let trailingText {
                    Spacer()
                    Text(trailingText)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .animation(.easeInOut, value: trailingText)
                }
            }
            .padding(.horizontal, 12)

            if matches.isEmpty {
                Text(emptyText)
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 12)
            } else {
                ForEach(matches) { match in
                    MatchRowView(
                        match: match,
                        teams: matchService.teams,
                        onTap: {
                            selectedMatch = match
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                showingDetail = true
                            }
                        }
                    )
                    .padding(.horizontal, 12)
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("Refresh") {
                Task { await matchService.fetchMatches() }
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - PastMatchesView

struct PastMatchesView: View {
    let matches: [Match]
    let teams: [String: Team]
    let onBack: () -> Void
    let onSelectMatch: (Match) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
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

                Text("Past Matches")
                    .font(.headline)

                Spacer()
                
                // Balance back button width visually
                Text("Back")
                    .font(.callout)
                    .opacity(0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Content
            if matches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sportscourt")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("No past matches yet")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(matches) { match in
                            MatchRowView(
                                match: match,
                                teams: teams,
                                onTap: {
                                    onSelectMatch(match)
                                }
                            )
                            .padding(.horizontal, 12)
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
