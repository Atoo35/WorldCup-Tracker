import Combine
import Foundation

@MainActor
final class MatchService: ObservableObject {
    @Published private(set) var liveMatches: [Match] = []
    @Published private(set) var todayMatches: [Match] = []
    @Published private(set) var tomorrowMatches: [Match] = []
    @Published private(set) var upcomingMatches: [Match] = []
    @Published private(set) var pastMatches: [Match] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastRefreshTime: Date?
    @Published private(set) var errorMessage: String?

    @Published private(set) var teams: [String: Team] = [:]
    @Published private(set) var groups: [Group] = []
    @Published private(set) var allMatches: [Match] = []

    private static let gamesURL = URL(string: "https://worldcup26.ir/get/games")!
    private static let teamsURL = URL(string: "https://worldcup26.ir/get/teams")!
    private static let groupsURL = URL(string: "https://worldcup26.ir/get/groups")!

    private var refreshTimer: Timer?
    private var cachedMatches: [Match] = []

    // ✅ FIXED CALENDAR (GMT)
    private static let matchCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }()

    init() {
        Task {
            await fetchTeams()
            await fetchMatches()
            await fetchGroups()
        }
    }
    
    func startAutoRefresh() {
           stopAutoRefresh()
           refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
               Task { @MainActor in
                   await self?.fetchMatches()
                   await self?.fetchGroups()
               }
           }
       }
   
    func stopAutoRefresh() {
       refreshTimer?.invalidate()
       refreshTimer = nil
    }
   

    // MARK: - Teams

    func fetchTeams() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: Self.teamsURL)
            let decoded = try JSONDecoder().decode(TeamsResponse.self, from: data)

            self.teams = Dictionary(uniqueKeysWithValues: decoded.teams.map { ($0.id, $0) })
        } catch {
            print("Team fetch error:", error)
        }
    }

    // MARK: - Matches

    func fetchMatches() async {
        isLoading = cachedMatches.isEmpty
        isRefreshing = true
        errorMessage = nil

        do {
            let (data, response) = try await URLSession.shared.data(from: Self.gamesURL)

            guard let http = response as? HTTPURLResponse,
                  http.statusCode == 200 else {
                throw NSError(domain: "invalid", code: 0)
            }

            let decoded = try JSONDecoder().decode(GamesResponse.self, from: data)
            cachedMatches = decoded.games

            categorize(decoded.games)

            isLoading = false
            isRefreshing = false
            lastRefreshTime = Date()
        } catch {
            print("Match fetch error:", error)
            isLoading = false
            isRefreshing = false

            if cachedMatches.isEmpty {
                errorMessage = "Could not load matches."
            }
        }
    }

    // MARK: - Categorisation

    private func categorize(_ matches: [Match]) {

        let calendar = Self.matchCalendar
        let now = Date()

        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        allMatches = matches

        liveMatches = matches.filter(\.isLive)
            .sorted { ($0.kickoffDate ?? .distantFuture) < ($1.kickoffDate ?? .distantFuture) }

        todayMatches = matches.filter {
            guard let d = $0.kickoffDate else { return false }
            return calendar.isDate(d, inSameDayAs: today)
        }
        .sorted { ($0.kickoffDate ?? .distantFuture) < ($1.kickoffDate ?? .distantFuture) }

        tomorrowMatches = matches.filter {
            guard let d = $0.kickoffDate else { return false }
            return calendar.isDate(d, inSameDayAs: tomorrow)
        }
        .sorted { ($0.kickoffDate ?? .distantFuture) < ($1.kickoffDate ?? .distantFuture) }

        pastMatches = matches.filter(\.isFinished)
            .sorted { ($0.kickoffDate ?? .distantPast) > ($1.kickoffDate ?? .distantPast) }

        upcomingMatches = matches.filter(\.isUpcoming)
            .sorted { ($0.kickoffDate ?? .distantFuture) < ($1.kickoffDate ?? .distantFuture) }
    }

    // MARK: - Groups Standings

    func fetchGroups() async {
        do {
            let (data, response) = try await URLSession.shared.data(from: Self.groupsURL)
            guard let http = response as? HTTPURLResponse,
                  http.statusCode == 200 else {
                return
            }
            let decoded = try JSONDecoder().decode(GroupsResponse.self, from: data)
            
            let sortedGroups = decoded.groups.map { group -> Group in
                var groupCopy = group
                groupCopy.teams.sort { t1, t2 in
                    if t1.ptsInt != t2.ptsInt {
                        return t1.ptsInt > t2.ptsInt
                    }
                    if t1.gdInt != t2.gdInt {
                        return t1.gdInt > t2.gdInt
                    }
                    if t1.gfInt != t2.gfInt {
                        return t1.gfInt > t2.gfInt
                    }
                    return t1.team_id < t2.team_id
                }
                return groupCopy
            }.sorted { $0.name < $1.name }
            
            self.groups = sortedGroups
        } catch {
            print("Group fetch error:", error)
        }
    }
}

// MARK: - Group Standings Models

struct GroupTeam: Decodable, Identifiable {
    var id: String { team_id }
    let team_id: String
    let mp: String
    let w: String
    let l: String
    let d: String
    let pts: String
    let gf: String
    let ga: String
    let gd: String

    var mpInt: Int { Int(mp) ?? 0 }
    var wInt: Int { Int(w) ?? 0 }
    var lInt: Int { Int(l) ?? 0 }
    var dInt: Int { Int(d) ?? 0 }
    var ptsInt: Int { Int(pts) ?? 0 }
    var gfInt: Int { Int(gf) ?? 0 }
    var gaInt: Int { Int(ga) ?? 0 }
    var gdInt: Int { Int(gd) ?? 0 }
}

struct Group: Decodable, Identifiable {
    var id: String { name }
    let name: String
    var teams: [GroupTeam]
}

struct GroupsResponse: Decodable {
    let groups: [Group]
}
