import Foundation
import EventKit

let store = EKEventStore()
let sources = store.sources

for source in sources {
    print("Source: \(source.title), type: \(source.sourceType.rawValue)")
    for cal in source.calendars(for: .event) {
        print("  - Calendar: \(cal.title)")
    }
}
