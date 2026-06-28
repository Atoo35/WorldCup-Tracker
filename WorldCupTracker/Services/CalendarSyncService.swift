import EventKit
import Combine
import AppKit

@MainActor
final class CalendarSyncService: ObservableObject {
    @Published var isSyncing = false
    @Published var syncError: String?
    @Published var syncSuccess = false
    
    private let eventStore = EKEventStore()
    private let calendarName = "World Cup 2026"
    
    var isAuthorized: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14.0, *) {
            return status == .authorized || status == .fullAccess
        } else {
            return status == .authorized
        }
    }
    
    func syncMatches(_ matches: [Match], teams: [String: Team]) async {
        isSyncing = true
        syncError = nil
        syncSuccess = false
        
        do {
            try await requestAccess()
            
            let calendar = try getOrCreateCalendar()
            
            // Fetch existing events in this calendar (for updating)
            let startDate = Date().addingTimeInterval(-60 * 24 * 3600) // 60 days ago
            let endDate = Date().addingTimeInterval(365 * 24 * 3600) // 1 year ahead
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
            let existingEvents = eventStore.events(matching: predicate)
            
            // The caller provides the matches, but we will double check they are from round of 32 onwards
            // (e.g. type != "group")
            let knockoutMatches = matches.filter { match in
                guard let type = match.type?.lowercased() else { return false }
                return type != "group"
            }
            
            for match in knockoutMatches {
                guard let kickoffDate = match.kickoffDate else { continue }
                
                let matchIdentifier = "[MatchID: \(match.id)]"
                let existingEvent = existingEvents.first { $0.notes?.contains(matchIdentifier) == true }
                
                let event = existingEvent ?? EKEvent(eventStore: eventStore)
                event.calendar = calendar
                
                let homeTeam = match.homeTeamName ?? match.homeTeamLabel ?? "TBD"
                let awayTeam = match.awayTeamName ?? match.awayTeamLabel ?? "TBD"
                
                var homeFlag = ""
                if let id = match.home_team_id, let team = teams[id], let flag = team.iso2.flagEmoji {
                    homeFlag = "\(flag) "
                }
                
                var awayFlag = ""
                if let id = match.away_team_id, let team = teams[id], let flag = team.iso2.flagEmoji {
                    awayFlag = "\(flag) "
                }
                
                var title = "\(homeFlag)\(homeTeam) vs \(awayFlag)\(awayTeam)"
                if let group = match.group {
                    title += " (\(group.uppercased()))"
                }
                
                event.title = title
                event.startDate = kickoffDate
                // Assume match takes about 2 hours
                event.endDate = kickoffDate.addingTimeInterval(2 * 3600)
                
                var notes = matchIdentifier
                if let stadium = match.stadium_id {
                    notes += "\nStadium ID: \(stadium)"
                }
                event.notes = notes
                
                try eventStore.save(event, span: .thisEvent)
            }
            
            // Commit all changes
            try eventStore.commit()
            syncSuccess = true
            UserDefaults.standard.set(Date(), forKey: "LastCalendarSyncTime")
            
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    self.syncSuccess = false
                }
            }
            
        } catch {
            print("Calendar sync error:", error)
            syncError = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    private func requestAccess() async throws {
        if #available(macOS 14.0, *) {
            let granted = try await eventStore.requestFullAccessToEvents()
            if !granted {
                throw NSError(domain: "CalendarSync", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied."])
            }
        } else {
            let granted = try await eventStore.requestAccess(to: .event)
            if !granted {
                throw NSError(domain: "CalendarSync", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied."])
            }
        }
    }
    
    private func getOrCreateCalendar() throws -> EKCalendar {
        let calendars = eventStore.calendars(for: .event)
        let sources = eventStore.sources
        
        // Broaden search for the google account
        let preferredSource = sources.first(where: { 
            let t = $0.title.lowercased()
            return t.contains("adrooney322") || t.contains("google") || t.contains("gmail")
        })
        
        if let preferred = preferredSource {
            // If the preferred source exists, force using/creating the calendar there
            if let existing = calendars.first(where: { $0.title == calendarName && $0.source == preferred }) {
                return existing
            }
        } else {
            // Fallback: If no google source found, use any existing calendar with this name
            if let existing = calendars.first(where: { $0.title == calendarName }) {
                return existing
            }
        }
        
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = calendarName
        
        if let preferred = preferredSource {
            newCalendar.source = preferred
        } else if let iCloudSource = sources.first(where: { $0.sourceType == .calDAV && $0.title == "iCloud" }) {
            newCalendar.source = iCloudSource
        } else if let localSource = sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = localSource
        } else if let defaultSource = eventStore.defaultCalendarForNewEvents?.source {
            newCalendar.source = defaultSource
        } else {
            throw NSError(domain: "CalendarSync", code: 2, userInfo: [NSLocalizedDescriptionKey: "No calendar source found."])
        }
        
        newCalendar.cgColor = NSColor.systemBlue.cgColor
        
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
        } catch let error as NSError where error.domain == EKErrorDomain && error.code == 17 {
            throw NSError(domain: "CalendarSync", code: 3, userInfo: [NSLocalizedDescriptionKey: "Your Google account doesn't allow creating calendars from third-party apps. Please create a calendar named 'World Cup 2026' manually in Google Calendar, then try syncing again."])
        }
        
        return newCalendar
    }
}

extension String {
    var flagEmoji: String? {
        guard count == 2 else { return nil }
        let base: UInt32 = 127397
        var s = ""
        for v in self.uppercased().unicodeScalars {
            guard let scalar = UnicodeScalar(base + v.value) else { return nil }
            s.unicodeScalars.append(scalar)
        }
        return s
    }
}
