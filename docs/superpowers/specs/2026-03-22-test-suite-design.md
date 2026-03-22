# Comprehensive Test Suite

## Goal

Add a comprehensive XCTest suite covering every file in `Sources/` (except `main.swift`), and run it in CI. The suite should surface bugs through thorough testing of parsing, state management, event routing, and UI data logic.

## Test Target Setup

Add an XCTest target `DeckardTests` to `Deckard.xcodeproj`. Tests use `@testable import Deckard` to access internal APIs. Test files live in `Tests/`.

CI: add a `test` job to `.github/workflows/ci.yml` running `xcodebuild test`.

---

## Tier 1: Pure Logic (zero mocks)

### ThemeColors
- `init(background:foreground:)` produces correct derived colors for dark backgrounds
- `init(background:foreground:)` produces correct derived colors for light backgrounds
- `isDark` threshold at luminance 0.5
- `luminance` computation matches WCAG formula for known RGB values
- `adjustedBrightness(by:)` clamps to 0...1
- `adjustedBrightness(by:)` shifts correctly for mid-range values
- `.default` produces valid system colors

### TerminalColorScheme
- `parseHex` parses `#RRGGBB` format
- `parseHex` parses `RRGGBB` without hash
- `parseHex` returns nil for invalid strings (wrong length, non-hex chars)
- `parse(from:)` extracts background, foreground from a theme file
- `parse(from:)` extracts all 16 palette colors
- `parse(from:)` extracts cursor-color, cursor-text, selection-background
- `parse(from:)` ignores comments and blank lines
- `parse(from:)` fills missing palette indices with defaults
- `parse(from:)` returns nil when background or foreground missing
- `parse(from:)` ignores selection-foreground (unsupported)
- `.default` has non-nil background and foreground
- `defaultAnsiColors()` returns exactly 16 colors

### SessionState
- `DeckardState` encodes and decodes roundtrip
- `ProjectState` encodes and decodes roundtrip
- `TabState` encodes and decodes roundtrip
- Empty state (no projects) roundtrips
- State with multiple projects and tabs roundtrips
- Missing optional fields decode with defaults (sessionId nil, selectedTabIndex 0)
- `SessionManager.save()` writes valid JSON to disk (temp file)
- `SessionManager.load()` reads it back correctly
- `SessionManager.load()` returns empty state for missing file
- `SessionManager.load()` returns empty state for corrupt JSON

---

## Tier 2: Logic with File I/O

### ThemeManager
- `loadAvailableThemes()` discovers themes from a fixture directory
- `loadAvailableThemes()` deduplicates themes across multiple search directories
- `loadAvailableThemes()` sorts alphabetically case-insensitive
- `loadAvailableThemes()` skips dotfiles and LICENSE files
- `loadAvailableThemes()` handles empty directory
- `loadAvailableThemes()` handles missing directory
- `applyTheme(name:)` with valid theme updates `currentScheme` and `currentColors`
- `applyTheme(name:)` with nil reverts to default and removes UserDefaults key
- `applyTheme(name:)` with unknown name reverts to default
- `applySavedTheme()` applies the persisted theme name
- `applyTheme` posts `.deckardThemeChanged` notification with scheme and colors

### ContextMonitor
- Parses a JSONL session file with token usage entries
- Extracts `cacheCreationInputTokens`, `inputTokens`, `outputTokens` from JSON
- Calculates percentage correctly (used / limit)
- Returns 0 for empty session file
- Returns 0 for session file with no usage entries
- Handles malformed JSON lines gracefully (skips them)
- Model limit lookup returns correct values for known models
- Model limit lookup returns default for unknown models

### DiagnosticLog
- Log line format: `[timestamp] [category] [buildTag] message`
- Build tag includes version and executable mod date
- Truncation keeps last 100KB when file exceeds 200KB
- Truncation preserves complete lines (no partial line at start)
- Session header written on init
- Thread safety: concurrent log calls don't crash (stress test)

### DeckardHooksInstaller
- Hook script content includes socket path placeholder
- JSON settings merge adds hooks without overwriting existing keys
- JSON settings merge creates file if it doesn't exist
- JSON settings merge preserves existing user settings
- Handles corrupt JSON settings file gracefully

---

## Tier 3: Event Routing

### HookHandler
- `register-pid` message registers PID with ProcessMonitor
- `update-badge` message with `thinking` state routes correctly
- `update-badge` message with `waiting` state routes correctly
- `update-badge` message with missing surfaceId is handled gracefully
- `list-tabs` returns tab info array
- `create-tab` opens project
- `rename-tab` renames the correct tab
- `context-update` routes percentage to window controller
- Unknown message type returns ok:true (no crash)

### ControlSocket Messages
- `ControlMessage` decodes all known message types
- `ControlMessage` decodes with optional fields missing
- `ControlResponse` encodes ok:true
- `ControlResponse` encodes ok:true with tabs array
- `TabInfo` encodes all fields correctly
- Roundtrip: encode response → decode → matches original

---

## Tier 4: UI Data Logic

### DeckardWindowController
- Tab name generation: first Claude tab → "Claude #1", second → "Claude #2"
- Tab name generation: first Terminal tab → "Terminal #1"
- Tab name generation: custom name overrides default
- Tab selection: next tab wraps around
- Tab selection: prev tab wraps around
- Tab selection: by index clamps to valid range
- Tab selection: by index with empty tabs does nothing
- Close tab: selects previous tab when closing last
- Close tab: selects next tab when closing middle
- Close tab: empty project after closing only tab
- Project management: add project increments count
- Project management: remove project decrements count
- Project management: select project updates selectedProjectIndex
- Surface closed by ID: removes correct tab from correct project
- Surface closed by ID: unknown ID does nothing
- Title update by surface ID: updates correct tab's title
- Title update by surface ID: unknown ID does nothing
- Session state capture: produces correct ProjectState/TabState arrays
- Session restore: creates correct number of tabs from state
- Badge state: updates correctly for known surface IDs
- Badge state: unknown surface ID does nothing

### SettingsWindow
- Theme list includes "System Default" as first entry
- Theme search filters by name case-insensitively
- Theme search with empty string shows all themes
- Badge color persistence: save and load roundtrip via UserDefaults
- Badge animate toggle: save and load roundtrip

### ProjectPicker
- Recent projects loaded from fixture directory
- Fuzzy search filters project list
- Projects sorted by recency
- Empty search shows all projects
- No-match search shows empty list

### TerminalSurface
- Environment variable construction includes DECKARD_SURFACE_ID
- Environment variable construction includes DECKARD_TAB_ID when set
- Environment variable construction includes DECKARD_SOCKET_PATH
- Environment variable construction includes TERM=xterm-256color
- Custom env vars override defaults
- `isAlive` returns true before process exits
- `isAlive` returns false after terminate
- Double-terminate doesn't crash (guard works)

### CrashReporter
- Crash report path computation
- Previous crash detection: returns true when report file exists
- Previous crash detection: returns false when no report
- Crash report content includes backtrace format

---

## CI Integration

Add to `.github/workflows/ci.yml`:

```yaml
test:
  name: Test
  runs-on: macos-15
  steps:
    - uses: actions/checkout@v4
    - name: Select Xcode 26
      run: sudo xcode-select -s /Applications/Xcode_26.2.app
    - name: Resolve SPM dependencies
      run: xcodebuild -resolvePackageDependencies -project Deckard.xcodeproj
    - name: Run tests
      run: |
        xcodebuild test \
          -project Deckard.xcodeproj \
          -scheme Deckard \
          -destination 'platform=macOS' \
          -resultBundlePath TestResults.xcresult
    - name: Upload test results
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: test-results
        path: TestResults.xcresult
```

## Test Fixtures

`Tests/Fixtures/` directory containing:
- Sample Ghostty theme files (valid, missing fields, corrupt)
- Sample JSONL session files (valid usage, empty, malformed)
- Sample DeckardState JSON (valid, corrupt, empty)
- Sample theme directories (for ThemeManager discovery tests)
