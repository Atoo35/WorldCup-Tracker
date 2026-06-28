import SwiftUI

@main
struct WorldCupTrackerApp: App {
    @StateObject private var matchService = MatchService()
    @StateObject private var calendarSyncService = CalendarSyncService()
    @State private var syncScheduler: CalendarSyncScheduler?

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView()
                .environmentObject(matchService)
                .environmentObject(calendarSyncService)
        } label: {
            MenuBarLabel(liveCount: matchService.liveMatches.count)
                .onAppear {
                    if syncScheduler == nil {
                        syncScheduler = CalendarSyncScheduler(
                            matchService: matchService,
                            calendarSyncService: calendarSyncService
                        )
                    }
                }
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    let liveCount: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sportscourt.fill")
            if liveCount > 0 {
                Text("\(liveCount)")
                    .font(.caption2.weight(.semibold))
            }
        }
    }
}
