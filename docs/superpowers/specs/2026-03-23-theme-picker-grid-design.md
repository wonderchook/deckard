# Theme Picker Grid

## Problem

The current theme picker is a table-based list showing only theme names — users can't tell what a theme looks like without selecting it. With 485 themes, this is tedious.

## Design

Replace the table-based theme picker in `SettingsWindow.swift` with a scrollable 3-column grid of theme cards. Each card renders a mini terminal preview using the theme's actual colors.

## Layout

- Search field at the top filters themes by name
- 3-column grid of theme cards inside an `NSScrollView`
- Grid scrolls vertically through all matching themes
- Clicking a card selects it (highlighted border) and applies the theme immediately
- The currently active theme is highlighted on load

## Card Design

Each card consists of:

1. **Mini terminal preview** — a colored box using the theme's background color, containing 4 lines of sample terminal text rendered with the theme's palette colors:
   ```
   ~ $ ls -la           (green prompt, foreground $, cyan command)
   drwxr-xr-x 5 user    (dim text, blue number, yellow username)
   error: something      (red error, foreground text)
   ~ $ ▌                 (green prompt, dim cursor)
   ```
   Colors used: palette[2] (green), palette[6] (cyan), palette[4] (blue), palette[3] (yellow), palette[1] (red), palette[0] or palette[8] (dim), foreground (default text).

2. **Theme name label** — below the preview, on a slightly darker/lighter background derived from the theme's background color.

3. **Selection indicator** — a colored border (accent color) when the card is the active theme.

## Implementation

### New file: `Sources/Window/ThemeCardView.swift`

Custom `NSView` subclass for a single theme card. Responsibilities:
- Accept a `TerminalColorScheme` (or parse a theme file path)
- Draw the mini terminal preview using `NSAttributedString` with monospace font
- Draw the theme name label
- Handle click (notify delegate)
- Show/hide selection border

### Modified file: `Sources/Window/SettingsWindow.swift`

Replace the theme picker section of `makeAppearancePane()`:
- Remove: `NSTableView`, table delegate/datasource, `themeTableView` property, `allThemeEntries` array, table-related methods
- Add: `NSCollectionView` with flow layout (3 columns, fixed item size), `NSScrollView` wrapper
- Collection view uses `ThemeCardView` as the item view
- Search field filters the collection view's data source
- Remove `NSTableViewDataSource`/`NSTableViewDelegate` conformance

### Data flow

1. `makeAppearancePane()` creates the collection view and populates it with all themes from `ThemeManager.shared.availableThemes`
2. Each item creates a `ThemeCardView` that parses its theme file via `TerminalColorScheme.parse(from:)`
3. Parsed schemes are cached to avoid re-parsing on scroll
4. On click, `ThemeManager.shared.applyTheme(name:)` is called
5. The grid highlights the selected card

### Card sizing

- Card width: `(collectionView.bounds.width - 2 * interItemSpacing) / 3`
- Preview height: ~80px (4 lines of 11px monospace text with padding)
- Name label height: ~24px
- Total card height: ~110px
- Inter-item spacing: 8px
- Section insets: 8px

## What stays the same

- Badge color grid below the theme picker (separated by divider)
- Search field behavior (filter by name, case-insensitive)
- Theme selection persistence (UserDefaults via ThemeManager)
- Theme change notification flow

## Out of scope

- Lazy loading / virtualization (NSCollectionView handles this natively)
- Theme preview animation
- Light/dark mode grouping
