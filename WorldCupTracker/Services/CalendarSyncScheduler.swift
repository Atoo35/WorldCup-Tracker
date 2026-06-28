import Foundation
import Combine

@MainActor
final class CalendarSyncScheduler {
    private let matchService: MatchService
    private let calendarSyncService: CalendarSyncService
    private var cancellables = Set<AnyCancellable>()
    
    private let syncInterval: TimeInterval = 6 * 3600 // 6 hours
    private let lastSyncKey = "LastCalendarSyncTime"
    
    init(matchService: MatchService, calendarSyncService: CalendarSyncService) {
        self.matchService = matchService
        self.calendarSyncService = calendarSyncService
        
        setupObservation()
    }
    
    private func setupObservation() {
        // Whenever MatchService refreshes matches, check if we should auto-sync the calendar
        matchService.$lastRefreshTime
            .compactMap { $0 }
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.checkAndSyncIfNeeded()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkAndSyncIfNeeded() async {
        // 1. Only sync if the user has authorized calendar access to avoid background prompts
        guard calendarSyncService.isAuthorized else { return }
        
        // 2. Only sync if we have matches to sync
        let matches = matchService.allMatches
        guard !matches.isEmpty else { return }
        
        // 3. Check time elapsed since last successful sync
        let now = Date()
        if let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            let elapsed = now.timeIntervalSince(lastSync)
            guard elapsed >= syncInterval else { return }
        }
        
        // 4. Trigger sync
        await calendarSyncService.syncMatches(matches, teams: matchService.teams)
    }
}
