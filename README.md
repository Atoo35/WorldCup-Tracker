# World Cup Tracker

A lightweight macOS menu bar app for tracking FIFA World Cup 2026 live scores.

Click the soccer icon in the menu bar to see live matches, today's fixtures, and tomorrow's schedule.

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15 or later

## Run the app

1. Open `WorldCupTracker.xcodeproj` in Xcode.
2. Select **My Mac** as the run destination.
3. Press **Cmd+R** to build and run.
4. Click the **sportscourt** icon in the menu bar to open the score popover.

The app runs as a menu bar utility (no Dock icon). Use **Quit** in the popover footer to exit.

## Features

- **Live** — matches currently in progress, with minute indicator
- **Today** — all matches scheduled for today with scores or kickoff times
- **Tomorrow** — upcoming matches for the next day
- Auto-refreshes every 30 seconds while the popover is open
- Shows a live match count next to the menu bar icon when games are in play

## Data source

Match data is fetched from the free [worldcup26.ir](https://worldcup26.ir) API:

- Endpoint: `GET https://worldcup26.ir/get/games`
- No API key required for read access

Data attribution: [worldcup26.ir / rezarahiminia/worldcup2026](https://github.com/rezarahiminia/worldcup2026)

## Project structure

```
WorldCupTracker/
├── WorldCupTrackerApp.swift   # Menu bar entry point
├── Models/Match.swift         # Match model and display helpers
├── Services/MatchService.swift # API client and refresh logic
└── Views/                     # Popover UI
```
