# DESIGN.md — Warp Design System

> Inspired by Warp. Modern terminal reimagined: neon accents, dark canvas, developer delight.
> Source: https://getdesign.md/warp/design-md (VoltAgent/awesome-design-md, MIT)

---

## 1. Theme

The modern terminal, elevated. Warp takes the dark canvas of a terminal and
adds gradient neon accents, polished UI chrome, and collaborative features
without losing terminal credibility. The aesthetic is darker than dark —
near-black backgrounds — with vibrant electric blue/purple gradient accents
that feel like a reimagined future for developer tooling. Dense but beautiful.

Primary mood: dark canvas, neon gradient, terminal reimagined.

---

## 2. Colors

| Token              | Value                                       | Usage                          |
|--------------------|---------------------------------------------|--------------------------------|
| --bg-primary       | #0D0F12                                     | Terminal background            |
| --bg-secondary     | #161920                                     | Panels, sidebars               |
| --bg-tertiary      | #1E2129                                     | Hover states, cards            |
| --bg-input         | #13161C                                     | Input areas                    |
| --accent-start     | #01A4FF                                     | Gradient start (electric blue) |
| --accent-end       | #9747FF                                     | Gradient end (purple)          |
| --accent-gradient  | linear-gradient(90deg, #01A4FF, #9747FF)    | Primary gradient accent        |
| --accent-solid     | #01A4FF                                     | Single-color accent            |
| --text-primary     | #E8EAED                                     | Primary terminal text          |
| --text-secondary   | #9AA0AD                                     | Secondary UI text              |
| --text-muted       | #5C6370                                     | Dim comments, disabled         |
| --border           | rgba(255,255,255,0.06)                      | Subtle borders                 |
| --border-strong    | rgba(255,255,255,0.12)                      | Visible borders                |
| --success          | #3DDC84                                     | Success / green (terminal)     |
| --error            | #FF5F57                                     | Error / red (terminal)         |
| --warning          | #FEBC2E                                     | Warning / yellow (terminal)    |

---

## 3. Typography

**Font Stack**: System sans for UI, JetBrains Mono for terminal.

```
ui:       -apple-system, BlinkMacSystemFont, "Inter", sans-serif
terminal: "JetBrains Mono", "Cascadia Code", "Fira Code", monospace
heading:  -apple-system, BlinkMacSystemFont, "Inter", sans-serif
```

| Style       | Size  | Weight | Line Height |
|-------------|-------|--------|-------------|
| H1          | 32px  | 700    | 1.2         |
| H2          | 22px  | 600    | 1.3         |
| H3          | 16px  | 600    | 1.4         |
| UI Body     | 14px  | 400    | 1.5         |
| Terminal    | 14px  | 400    | 1.4         |
| Small       | 12px  | 400    | 1.4         |

Terminal text at exactly 14px, line-height 1.4 — tight for density.

---

## 4. Components

**Button Primary**
- Background: --accent-gradient
- Text: #FFFFFF, 14px, weight 600
- Padding: 8px 18px
- Border-radius: 6px
- Hover: brightness(1.15) on gradient

**Button Secondary**
- Background: --bg-tertiary
- Border: 1px solid --border-strong
- Text: --text-primary, 14px
- Hover: --bg-tertiary + brightness(1.1)

**Terminal Block (command)**
- Background: --bg-primary
- Font: JetBrains Mono 14px, --text-primary
- Prompt: gradient-colored (▸ in gradient)
- Command: --text-primary weight 400
- Output: --text-secondary
- Error: --error (#FF5F57)

**Input Bar (Warp)**
- Background: --bg-input
- Border-top: 1px solid --border-strong
- Border-radius: 8px (inner input)
- Font: JetBrains Mono 14px
- Cursor: 2px solid --accent-solid, blinking

**Block (Warp's primary unit)**
- Background: rgba(255,255,255,0.02)
- Border: 1px solid --border
- Border-radius: 6px
- Padding: 12px 16px
- Selected: gradient left-border 2px, subtle gradient bg tint

**Sidebar / Drive**
- Background: --bg-secondary
- Width: 240px
- Item height: 28px
- Active: gradient text + left gradient border

---

## 5. Layout

- Full viewport terminal layout
- Sidebar (Warp Drive): 240px left
- Terminal area: remaining space
- Command palette: 600px centered, floating
- Page max-width: 1100px (marketing)
- Marketing padding: 24px mobile, 48px desktop

---

## 6. Depth

Dark depth with glass effects and neon glow for key elements.

| Level | Effect | Usage                                         |
|-------|--------|-----------------------------------------------|
| 0     | none   | Terminal surface                              |
| 1     | `rgba(255,255,255,0.02)` + border | Blocks  |
| 2     | `0 4px 24px rgba(0,0,0,0.6)` | Panels        |
| 3     | `0 0 0 1px --border-strong, 0 8px 40px rgba(0,0,0,0.8)` | Floating UI |
| glow  | `0 0 20px rgba(1,164,255,0.2)` | Accent glow  |

The accent glow (--accent-solid at 20% opacity) can be used on focused inputs.

---

## 7. Do's and Don'ts

**Do:**
- Use JetBrains Mono (or Fira Code) exclusively for terminal content
- Apply the blue-to-purple gradient for primary CTAs and key highlights
- Make terminal blocks the primary visual unit — not cards or panels
- Use the traffic-light color trio (#3DDC84, #FEBC2E, #FF5F57) for status
- Embrace the very dark backgrounds (#0D0F12) — don't lighten them

**Don't:**
- Don't use light backgrounds — Warp is always dark
- Don't use serif fonts anywhere in the terminal UI
- Don't apply the gradient to more than 1-2 elements per view
- Don't use thin borders in terminal areas — they break the monospace grid
- Don't add decorative shadows to terminal blocks (keep them flat)

---

## 8. Responsive

| Breakpoint | Width   | Notes                                     |
|------------|---------|-------------------------------------------|
| Mobile     | <768px  | Single column, no sidebar                 |
| Tablet     | 768px+  | Sidebar optional, collapsible            |
| Desktop    | 1024px+ | Full Warp Drive sidebar + terminal        |
| Wide       | 1440px+ | Additional right panel (AI/suggestions)  |

Warp is desktop-native. Terminal requires keyboard — mobile is not supported.

---

## 9. Agent Prompt Guide

**Terminal block:**
> "Warp terminal block: #0D0F12 background, rgba(255,255,255,0.02) block bg,
> 1px solid rgba(255,255,255,0.06) border, 6px radius, JetBrains Mono 14px,
> prompt symbol in gradient linear-gradient(90deg,#01A4FF,#9747FF), command
> text #E8EAED, output #9AA0AD, error #FF5F57, success #3DDC84."

**Hero with gradient:**
> "Warp hero: #0D0F12 background, h1 32px 700 #FFFFFF, gradient span on
> key phrase (linear-gradient(90deg,#01A4FF,#9747FF) background-clip:text),
> body 16px #9AA0AD, CTA uses full gradient background with 6px radius."

**Color tokens:**
> "--bg-primary:#0D0F12, --accent-gradient:linear-gradient(90deg,#01A4FF,#9747FF),
> --text-primary:#E8EAED, --text-muted:#5C6370, --border:rgba(255,255,255,0.06),
> --success:#3DDC84"
