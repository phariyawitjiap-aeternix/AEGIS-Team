# DESIGN.md — Cursor Design System

> Inspired by Cursor. Dark IDE aesthetic, blue accent, developer-native interface.
> Source: https://getdesign.md/cursor/design-md (VoltAgent/awesome-design-md, MIT)

---

## 1. Theme

IDE-native design. Cursor's visual language is built from the inside out —
it is literally an editor, so the design system inherits VS Code DNA while
pushing it in a more polished direction. Dark gray backgrounds (not pure black),
blue accent, and dense information layouts reflect an environment where context
and code live side-by-side. Functional over decorative; every surface serves
a developer need.

Primary mood: IDE-native, dark functional, blue developer authority.

---

## 2. Colors

| Token            | Value     | Usage                              |
|------------------|-----------|------------------------------------|
| --bg-primary     | #1E1E1E   | Editor background                  |
| --bg-secondary   | #252526   | Side panel, activity bar           |
| --bg-tertiary    | #2D2D30   | Hover states, selected items       |
| --bg-elevated    | #333337   | Dropdowns, floating panels         |
| --accent         | #0E7CE8   | Links, active elements, focus      |
| --accent-hover   | #1488F0   | Hover on accent elements           |
| --text-primary   | #D4D4D4   | Body text (VS Code default gray)   |
| --text-heading   | #FFFFFF   | Headings, emphasis                 |
| --text-muted     | #858585   | Comments, inactive elements        |
| --text-inactive  | #6B6B6B   | Very low emphasis                  |
| --border         | #3C3C3C   | Component borders                  |
| --border-focus   | #0E7CE8   | Focus rings                        |
| --success        | #4EC9B0   | Success / teal (VS Code)           |
| --warning        | #CCA700   | Warning yellow                     |
| --error          | #F44747   | Error red                          |

---

## 3. Typography

**Font Stack**: Same as VS Code defaults.

```
heading: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif
body:    -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif
mono:    "Cascadia Code", "Fira Code", "SF Mono", Menlo, monospace
```

| Style    | Size  | Weight | Line Height |
|----------|-------|--------|-------------|
| H1       | 28px  | 600    | 1.3         |
| H2       | 20px  | 600    | 1.4         |
| H3       | 15px  | 600    | 1.4         |
| Body     | 13px  | 400    | 1.5         |
| Small    | 11px  | 400    | 1.4         |
| Code     | 13px  | 400    | 1.5         |
| Terminal | 13px  | 400    | 1.4         |

Note: 13px body is compact (IDE-standard), not 16px web-standard.

---

## 4. Components

**Button Primary**
- Background: --accent (#0E7CE8)
- Text: #FFFFFF, 13px, weight 400
- Padding: 4px 14px
- Border-radius: 2px (very tight — IDE style)
- Height: 28px

**Button Secondary**
- Background: --bg-tertiary
- Border: 1px solid --border
- Text: --text-primary, 13px
- Height: 28px

**Input**
- Background: --bg-secondary
- Border: 1px solid --border
- Focus: border-color --accent
- Border-radius: 2px
- Padding: 4px 8px
- Height: 26px (compact)

**Tab Bar**
- Background: --bg-secondary
- Active tab: --bg-primary, top 1px solid --accent border
- Inactive tab: --text-muted text
- Height: 35px
- Close button: appears on hover

**Side Panel**
- Width: 260px (default)
- Background: --bg-secondary
- Section header: 11px uppercase letter-spaced, --text-muted
- Tree item: 22px height, 8px icon + text

**Chat Panel (AI)**
- Background: --bg-secondary right panel
- Message bg: --bg-tertiary
- Code within: --bg-primary
- Width: 400px default

---

## 5. Layout

- Full viewport height app
- Activity bar: 48px wide (leftmost)
- Side panel: 260px
- Editor area: remaining width
- Status bar: 22px height (bottom)
- Tab bar: 35px height (top of editor)
- Panel (bottom): 200px default height

Dense, maximized layout. No marketing-style whitespace.

---

## 6. Depth

Very subtle depth. Dark backgrounds collapse visual layering.

| Level | Effect | Usage                                        |
|-------|--------|----------------------------------------------|
| 0     | none   | Editor surface                               |
| 1     | `--bg-secondary` color change | Side panels            |
| 2     | `0 2px 8px rgba(0,0,0,0.4)` | Dropdowns, notifications |
| 3     | `0 4px 20px rgba(0,0,0,0.6)` | Command palette, modals |

---

## 7. Do's and Don'ts

**Do:**
- Use 2px border-radius for IDE-native elements (buttons, inputs)
- Use 13px body text matching editor font size
- Apply the VS Code dark gray palette (#1E1E1E, #252526, #2D2D30)
- Make code syntax colors VS Code compatible (D4D4D4 text, 4EC9B0 teal)
- Design for maximum information density

**Don't:**
- Don't use web-standard large rounded corners (8-12px) on IDE components
- Don't use 16px body text — everything is compact at 13px
- Don't add decorative gradients or heavy shadows
- Don't use marketing-style whitespace — everything is utilitarian
- Don't deviate from VS Code gray palette without strong reason

---

## 8. Responsive

| Breakpoint | Width   | Notes                                     |
|------------|---------|-------------------------------------------|
| Mobile     | <768px  | Not primary target; panels collapse       |
| Tablet     | 768px+  | Minimal support; side panels collapsible  |
| Desktop    | 1024px+ | Primary surface; full IDE layout          |
| Wide       | 1440px+ | Full layout with chat panel open          |

Cursor is desktop-only. Do not optimize for mobile.

---

## 9. Agent Prompt Guide

**Editor-style component:**
> "Build a Cursor/VS Code style component: #1E1E1E background, #D4D4D4 text
> at 13px, #3C3C3C borders, 2px border-radius, compact 28px button height,
> blue accent #0E7CE8 for active states and focus rings. Dense layout,
> no decorative padding."

**Chat panel:**
> "AI chat panel: #252526 background, 400px wide, messages in #2D2D30 with
> 4px radius, code blocks in #1E1E1E with Cascadia Code 13px, user messages
> right-aligned, assistant messages full-width."

**Color tokens:**
> "--bg-primary:#1E1E1E, --accent:#0E7CE8, --text-primary:#D4D4D4,
> --text-muted:#858585, --border:#3C3C3C, --bg-secondary:#252526"
