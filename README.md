<div align="center">

# 🏆 WorldCup Tracker

**A macOS menu bar app for tracking FIFA World Cup 2026 matches in real time**

![macOS](https://img.shields.io/badge/macOS-13%2B-black?style=flat-square&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-native-blue?style=flat-square)
![Vibecoded](https://img.shields.io/badge/100%25-vibecoded-blueviolet?style=flat-square)

</div>

---

> **⚠️ Fully Vibecoded** — This app was built entirely through vibes, intuition, and AI pair programming. No feelings were harmed in the making of this software.

---

## ✨ Features

- 🟢 **Live match scores** — updates every 30 seconds automatically
- 📅 **Today & Tomorrow** — see what's coming up at a glance
- ⚽ **Goal scorers** — tap any match to see who scored and when, with deduplication for multi-goal players (e.g. *F. Balogun 31', 45'+5'*)
- 🏳️ **Team flags** — rendered from live API data
- 🖥️ **Menu bar native** — lives quietly in your menu bar, out of the way until you need it
- 🔄 **Smart refresh** — auto-refreshes while open, pauses when closed to save resources

---

## 📡 APIs Used

All data is sourced from the **[worldcup26.ir](https://worldcup26.ir)** public API — a community-run REST API providing live FIFA World Cup 2026 data.

| Endpoint | Description |
|---|---|
| `GET https://worldcup26.ir/get/games` | Fetches all match data including scores, status, scorers, and kickoff times |
| `GET https://worldcup26.ir/get/teams` | Fetches team metadata including names, FIFA codes, and flag image URLs |

> No API key required. Both endpoints are public and unauthenticated.

### Data Notes
- Match timestamps are provided in local stadium time and converted to GMT for display
- Scorer data is returned as a raw string (e.g. `{"F. Balogun 31'","H. Pulisic 67'}`) and parsed client-side
- Stadium timezones are mapped manually (PT, CT, ET) for the three host countries: USA, Canada, and Mexico

---

## 🛠️ Building Locally

### Prerequisites

- **macOS 13 Ventura** or later
- **Xcode 15** or later
- No third-party dependencies — this project uses only Apple frameworks

### Steps

1. **Clone the repo**

   ```bash
   git clone https://github.com/your-username/WorldCup-Tracker.git
   cd WorldCup-Tracker
   ```

2. **Open in Xcode**

   ```bash
   open WorldCupTracker.xcodeproj
   ```

3. **Select your run destination**

   In Xcode's toolbar, select your **Mac** as the run target (My Mac).

4. **Build & Run**

   Press `⌘R` or click the **▶ Run** button.

   The app will appear as a ⚽ icon in your macOS menu bar. Click it to see live match data.

### Signing

If you encounter code signing errors, go to **Xcode → WorldCupTracker target → Signing & Capabilities** and set your personal Apple ID development team.

---

## 🗂️ Project Structure

```
WorldCupTracker/
├── Models/
│   ├── Match.swift         # Match data model + scorer parsing logic
│   └── Team.swift          # Team data model (name, flag, FIFA code)
├── Services/
│   └── MatchService.swift  # API fetching, caching & auto-refresh
├── Views/
│   ├── PopoverContentView.swift   # Main menu bar popover (live/today/tomorrow sections)
│   ├── MatchRowView.swift         # Compact match row with flag + score
│   └── MatchDetailView.swift      # Drill-down detail with goal scorers
└── WorldCupTrackerApp.swift       # App entry point & menu bar setup
```

---

## 🤖 Built With

- **SwiftUI** — declarative UI, animations, and navigation
- **Combine / async-await** — reactive data fetching and publishing
- **URLSession** — native HTTP networking (no third-party libraries)
- **MenuBarExtra** — native macOS menu bar integration (macOS 13+)

---

<div align="center">

Made with ⚽ and good vibes during FIFA World Cup 2026

</div>
