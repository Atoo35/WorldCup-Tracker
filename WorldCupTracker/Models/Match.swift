import Foundation

struct GamesResponse: Decodable {
    let games: [Match]
}

struct Match: Decodable, Identifiable {
    let id: String

    let stadium_id: String?
    let home_team_id: String?
    let away_team_id: String?

    let homeTeamName: String?
    let awayTeamName: String?
    let homeScore: String?
    let awayScore: String?
    let finished: String
    let timeElapsed: String
    let localDate: String
    let group: String?
    let type: String?

    let homeScorers: String?
    let awayScorers: String?

    var round: String? { group ?? type }
    
    let homeTeamLabel: String?
    let awayTeamLabel: String?

    enum CodingKeys: String, CodingKey {
        case id
        case stadium_id
        case home_team_id
        case away_team_id

        case homeTeamName = "home_team_name_en"
        case awayTeamName = "away_team_name_en"
        case homeScore = "home_score"
        case awayScore = "away_score"
        case finished
        case timeElapsed = "time_elapsed"
        case localDate = "local_date"
        case group
        case type

        case homeScorers = "home_scorers"
        case awayScorers = "away_scorers"
        
        case homeTeamLabel = "home_team_label"
        case awayTeamLabel = "away_team_label"
    }

    // MARK: - State

    var isFinished: Bool {
        finished.uppercased() == "TRUE" ||
        timeElapsed.lowercased() == "finished"
    }

    var isLive: Bool {
        !isFinished && timeElapsed.lowercased() != "notstarted"
    }

    var isUpcoming: Bool {
        !isFinished && timeElapsed.lowercased() == "notstarted"
    }

    // MARK: - Display

    var displayScore: String {
        isUpcoming ? "vs" : "\(homeScore ?? "0") - \(awayScore ?? "0")"
    }

    var displayStatus: String {
        if isLive { return timeElapsed }
        if isFinished { return "FT" }
        return kickoffTimeString ?? timeElapsed
    }

    // MARK: - Date

    var kickoffDate: Date? {
        Self.makeFormatter(timeZone: apiTimeZone)
            .date(from: localDate)
    }

    var kickoffTimeString: String? {
        guard let date = kickoffDate else { return nil }
        return Self.gmtFormatter.string(from: date)
    }

    var kickoffLongDateString: String {
        guard let date = kickoffDate else { return "Date TBD" }
        return Self.longDateFormatter.string(from: date)
    }

    // MARK: - Flags

    func homeFlagURL(teams: [String: Team]) -> URL? {
        guard let id = home_team_id,
              let team = teams[id] else { return nil }
        return URL(string: team.flag)
    }

    func awayFlagURL(teams: [String: Team]) -> URL? {
        guard let id = away_team_id,
              let team = teams[id] else { return nil }
        return URL(string: team.flag)
    }

    // MARK: - Scorers

    /// Raw parsed list — one entry per goal event (may contain duplicate names)
    var parsedHomeScorers: [String] { parseScorers(homeScorers) }
    var parsedAwayScorers: [String] { parseScorers(awayScorers) }

    /// Grouped list — duplicate names collapsed e.g. "F. Balogun 31', 45'+5'"
    var groupedHomeScorers: [String] { groupScorers(parsedHomeScorers) }
    var groupedAwayScorers: [String] { groupScorers(parsedAwayScorers) }

    private func groupScorers(_ scorers: [String]) -> [String] {
        var nameOrder: [String] = []
        var timesByName: [String: [String]] = [:]

        for scorer in scorers {
            if let (name, time) = splitScorerNameAndTime(scorer) {
                if timesByName[name] == nil {
                    nameOrder.append(name)
                    timesByName[name] = []
                }
                timesByName[name]!.append(time)
            } else {
                // Can't split — show as-is
                if timesByName[scorer] == nil {
                    nameOrder.append(scorer)
                    timesByName[scorer] = []
                }
            }
        }

        return nameOrder.compactMap { name in
            guard let times = timesByName[name] else { return nil }
            return times.isEmpty ? name : "\(name) \(times.joined(separator: ", "))"
        }
    }

    /// Splits "F. Balogun 45'+5'" -> ("F. Balogun", "45'+5'")
    private func splitScorerNameAndTime(_ scorer: String) -> (name: String, time: String)? {
        guard let regex = try? NSRegularExpression(pattern: #"^(.*)\s+(\d.+)$"#),
              let match = regex.firstMatch(in: scorer, range: NSRange(scorer.startIndex..., in: scorer)),
              match.numberOfRanges == 3,
              let nameRange = Range(match.range(at: 1), in: scorer),
              let timeRange = Range(match.range(at: 2), in: scorer)
        else { return nil }
        return (String(scorer[nameRange]), String(scorer[timeRange]))
    }

    private func parseScorers(_ scorersStr: String?) -> [String] {
        guard var str = scorersStr, str != "null", !str.isEmpty else { return [] }

        if str.hasPrefix("{") { str.removeFirst() }
        if str.hasSuffix("}") { str.removeLast() }

        // Strip outer quote chars and unescape inner single quotes
        let quotes = CharacterSet(charactersIn: "\"\\")
        return str.components(separatedBy: ",").compactMap { part in
            var cleaned = part.trimmingCharacters(in: .whitespacesAndNewlines)
            cleaned = cleaned.trimmingCharacters(in: quotes)
            cleaned = cleaned.replacingOccurrences(of: "\\'", with: "'")
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? nil : cleaned
        }
    }

    // MARK: - Timezone

    private var apiTimeZone: TimeZone {
        let offset = Self.stadiumTimezones[stadium_id ?? ""] ?? -8
        return TimeZone(secondsFromGMT: offset * 3600)!
    }

    private static let stadiumTimezones: [String: Int] = [
        "13": -8, "14": -8, "15": -8, "16": -8,
        "1": -6, "2": -6, "3": -6, "4": -6, "5": -6, "6": -6,
        "7": -5, "8": -5, "9": -5, "10": -5, "11": -5, "12": -5
    ]

    private static func makeFormatter(timeZone: TimeZone) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = timeZone
        return f
    }

    private static let gmtFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    private static let longDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
}
