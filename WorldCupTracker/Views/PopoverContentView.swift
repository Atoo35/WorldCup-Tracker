import AppKit
import SwiftUI

struct PopoverContentView: View {
    @EnvironmentObject private var matchService: MatchService
    @EnvironmentObject private var calendarSyncService: CalendarSyncService

    // Drill-down state
    @State private var selectedMatch: Match? = nil
    @State private var showingDetail = false
    @State private var showingPastMatches = false

    // Tab state
    @State private var selectedTab: Tab = .matches
    @State private var selectedGroup: String = "All"

    enum Tab: String, CaseIterable, Identifiable {
        case matches = "Matches"
        case upcoming = "Upcoming"
        case bracket = "Bracket"   // ✅ replaced standings

        var id: String { rawValue }
    }

    @Namespace private var tabAnimation

    var body: some View {
        ZStack {

            // MARK: - Main list
            VStack(alignment: .leading, spacing: 0) {
                header

                Divider()

                segmentedControl

                Divider()

                content
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                footer
            }
            .frame(width: 360, height: 380)

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
                .frame(width: 360, height: 380)
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
                .frame(width: 360, height: 380)
                .background(.regularMaterial)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            // Fetch immediately if data is stale
            if let lastRefresh = matchService.lastRefreshTime, Date().timeIntervalSince(lastRefresh) > 30 {
                Task { await matchService.fetchMatches() }
            }
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
                  matchService.tomorrowMatches.isEmpty,
                  matchService.upcomingMatches.isEmpty,
                  matchService.groups.isEmpty {
            VStack(spacing: 12) {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    Task { 
                        await matchService.fetchMatches() 
                        await matchService.fetchGroups()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        } else {
            if selectedTab == .bracket {
                KnockoutBracketView(
                    matches: matchService.allMatches,
                    teams: matchService.teams
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if let errorMessage = matchService.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 12)
                        }

                        if selectedTab == .matches {
                            matchSection(
                                title: "LIVE",
                                trailingText: matchService.isRefreshing ? "Updating..." : lastUpdatedText,
                                matches: matchService.liveMatches,
                                emptyText: "No live matches right now"
                            )
                            matchSection(title: "TODAY",    matches: matchService.todayMatches,    emptyText: "No matches today")
                            matchSection(title: "TOMORROW", matches: matchService.tomorrowMatches, emptyText: "No matches tomorrow")
                        } else {
                            upcomingMatchesContent
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
        }
    }

    // MARK: - Tabs and Upcoming Helpers

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                Text(tab.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    }
                    .background {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.primary.opacity(0.08))
                                .matchedGeometryEffect(id: "activeTab", in: tabAnimation)
                        }
                    }
            }
        }
        .padding(3)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func groupedMatches(for group: String) -> [(String, [Match])] {
        var groups: [String: [Match]] = [:]
        var dateOrder: [String] = []

        let matches = matchService.allMatches
            .filter { $0.group == group }
            .sorted {
                ($0.kickoffDate ?? .distantFuture) <
                ($1.kickoffDate ?? .distantFuture)
            }

        for match in matches {
            let dateStr = match.kickoffLongDateString

            if groups[dateStr] == nil {
                dateOrder.append(dateStr)
                groups[dateStr] = []
            }

            groups[dateStr]?.append(match)
        }

        return dateOrder.map { ($0, groups[$0] ?? []) }
    }
    
    private var groupedUpcomingMatches: [(String, [Match])] {
        var groups: [String: [Match]] = [:]
        var dateOrder: [String] = []

        for match in matchService.upcomingMatches {
            let dateStr = match.kickoffLongDateString
            if groups[dateStr] == nil {
                dateOrder.append(dateStr)
                groups[dateStr] = []
            }
            groups[dateStr]!.append(match)
        }

        return dateOrder.map { ($0, groups[$0]!) }
    }

    @ViewBuilder
    private var upcomingMatchesContent: some View {
        let groups = groupedUpcomingMatches
        if groups.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 28))
                    .foregroundStyle(.tertiary)
                Text("No upcoming matches")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        } else {
            ForEach(groups, id: \.0) { dateStr, matches in
                matchSection(
                    title: dateStr,
                    matches: matches,
                    emptyText: ""
                )
            }
        }
    }

    // MARK: - Helpers

    private var groupNames: [String] {
        if matchService.groups.isEmpty {
            return ["All", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"]
        } else {
            return ["All"] + matchService.groups.map(\.name).sorted()
        }
    }

    @ViewBuilder
    private var standingsScrollContent: some View {
        if matchService.groups.isEmpty {
            VStack(spacing: 8) {
                ProgressView()
                Text("Loading standings...")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 40)
        } else {
            if selectedGroup == "All" {
                ForEach(matchService.groups) { group in
                    GroupTableView(group: group, teams: matchService.teams)
                        .padding(.bottom, 12)
                }
            } else {
                if let group = matchService.groups.first(where: { $0.name == selectedGroup }) {
                    VStack(alignment: .leading, spacing: 16) {
                        GroupTableView(group: group, teams: matchService.teams)
                        
                        let groupedMatches = groupedMatches(for: selectedGroup)

                        if !groupedMatches.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Group \(selectedGroup) Matches")
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 14)
                                    .padding(.top, 4)

                                ForEach(groupedMatches, id: \.0) { dateStr, matches in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(dateStr)
                                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                                            .foregroundStyle(.tertiary)
                                            .padding(.horizontal, 14)

                                        ForEach(matches) { match in
                                            MatchRowView(
                                                match: match,
                                                teams: matchService.teams,
                                                onTap: {
                                                    selectedMatch = match
                                                    withAnimation(
                                                        .spring(
                                                            response: 0.35,
                                                            dampingFraction: 0.82
                                                        )
                                                    ) {
                                                        showingDetail = true
                                                    }
                                                }
                                            )
                                            .padding(.horizontal, 12)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

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
            
            if calendarSyncService.isSyncing {
                ProgressView()
                    .controlSize(.small)
                    .padding(.leading, 8)
            } else {
                Button(calendarSyncService.syncSuccess ? "Synced!" : "Sync Calendar") {
                    Task { await calendarSyncService.syncMatches(matchService.allMatches, teams: matchService.teams) }
                }
                .buttonStyle(.plain)
                .foregroundStyle(calendarSyncService.syncSuccess ? .green : .accentColor)
                .font(.callout)
                .disabled(matchService.allMatches.isEmpty)
                .padding(.leading, 8)
                
                if let error = calendarSyncService.syncError {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .help(error)
                }
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

// MARK: - Group Selector View

struct GroupSelectorView: View {
    let groups: [String]
    @Binding var selectedGroup: String
    @Namespace private var groupAnimation

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 6) {
                    ForEach(groups, id: \.self) { group in
                        Text(group == "All" ? "All" : "Group \(group)")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .foregroundStyle(selectedGroup == group ? .white : .secondary)
                            .background {
                                if selectedGroup == group {
                                    Capsule()
                                        .fill(Color.accentColor)
                                        .matchedGeometryEffect(id: "activeGroupTab", in: groupAnimation)
                                } else {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.04))
                                }
                            }
                            .contentShape(Capsule())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                    selectedGroup = group
                                }
                            }
                            .id(group)
                    }
                }
                .padding(.horizontal, 12)
                .onGroupChange(of: selectedGroup) { newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }
}

// MARK: - Group Table View

struct GroupTableView: View {
    let group: Group
    let teams: [String: Team]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Group Title
            Text("GROUP \(group.name)")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 4)

            // Table Header Row
            HStack(spacing: 8) {
                Text("#")
                    .frame(width: 20, alignment: .center)
                Text("Team")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("P")
                    .frame(width: 25, alignment: .center)
                Text("GD")
                    .frame(width: 30, alignment: .center)
                Text("PTS")
                    .frame(width: 30, alignment: .center)
            }
            .font(.system(.caption2, design: .rounded).weight(.bold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)

            // Table Rows
            VStack(spacing: 0) {
                ForEach(Array(group.teams.enumerated()), id: \.element.id) { index, groupTeam in
                    let rank = index + 1
                    let team = teams[groupTeam.team_id]
                    
                    HStack(spacing: 8) {
                        // Rank
                        Text("\(rank)")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(rank <= 2 ? .primary : .secondary)
                            .frame(width: 20, alignment: .center)
                        
                        // Flag & Name
                        HStack(spacing: 6) {
                            if let flagUrlStr = team?.flag, let flagUrl = URL(string: flagUrlStr) {
                                AsyncImage(url: flagUrl) { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.15)
                                }
                                .frame(width: 18, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius: 1.5))
                                .shadow(color: .black.opacity(0.1), radius: 1, y: 0.5)
                            } else {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 18, height: 12)
                            }
                            
                            Text(team?.name_en ?? "TBD")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Matches Played
                        Text(groupTeam.mp)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 25, alignment: .center)

                        // Goal Difference
                        let gdValue = Int(groupTeam.gd) ?? 0
                        let gdText = gdValue > 0 ? "+\(gdValue)" : "\(gdValue)"
                        Text(gdText)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(gdValue > 0 ? .green : (gdValue < 0 ? .red : .secondary))
                            .frame(width: 30, alignment: .center)

                        // Points
                        Text(groupTeam.pts)
                            .font(.system(.subheadline, design: .monospaced).weight(.bold))
                            .foregroundStyle(.primary)
                            .frame(width: 30, alignment: .center)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background {
                        if rank <= 2 {
                            // Subtly highlight the qualification rows
                            Color.green.opacity(0.02)
                        }
                    }
                    
                    if index < group.teams.count - 1 {
                        Divider()
                            .padding(.leading, 42)
                    }
                }
            }
            .background(Color.primary.opacity(0.015))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal, 12)
        }
    }
}

// MARK: - View Extensions

extension View {
    @ViewBuilder
    func onGroupChange<V>(of value: V, perform action: @escaping (V) -> Void) -> some View where V: Equatable {
        if #available(macOS 14.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value) { newValue in
                action(newValue)
            }
        }
    }
}
