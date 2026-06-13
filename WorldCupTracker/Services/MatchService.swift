import Combine
import Foundation

@MainActor
final class MatchService: ObservableObject {
    @Published private(set) var liveMatches: [Match] = []
    @Published private(set) var todayMatches: [Match] = []
    @Published private(set) var tomorrowMatches: [Match] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published private(set) var teams: [String: Team] = [:]

    private static let gamesURL = URL(string: "https://worldcup26.ir/get/games")!
    private static let teamsURL = URL(string: "https://worldcup26.ir/get/teams")!

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
        }
    }
    
    func startAutoRefresh() {
           stopAutoRefresh()
           refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
               Task { @MainActor in
                   await self?.fetchMatches()
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
        } catch {
            print("Match fetch error:", error)
            isLoading = false

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
    }
}
