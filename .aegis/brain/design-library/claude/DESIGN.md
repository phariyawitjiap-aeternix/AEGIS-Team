# DESIGN.md — Claude Design System

> Inspired by Anthropic's Claude. Warm terracotta accent, clean editorial layout.
> Source: https://getdesign.md/claude/design-md (VoltAgent/awesome-design-md, MIT)

---

## 1. Theme

Warm, intellectual, and trustworthy. Claude's visual language communicates
clarity and approachability without sacrificing depth. The palette centers on
warm off-white backgrounds with a terracotta/coral accent that reads as human
and grounded. Editorial typography and generous whitespace signal thoughtful
communication over dense data display.

Primary mood: editorial warmth, considered minimalism, soft authority.

---

## 2. Colors

| Token          | Value     | Usage                              |
|----------------|-----------|------------------------------------|
| --bg-primary   | #FAF9F7   | Page background, off-white warm    |
| --bg-secondary | #F0EDE8   | Card backgrounds, subtle elevation |
| --accent       | #D97757   | Primary CTA, links, highlights     |
| --accent-hover | #C9623F   | Hover state for accent             |
| --text-primary | #1A1A1A   | Body copy, headings                |
| --text-muted   | #6B6460   | Secondary text, captions           |
| --border       | #E5E0D8   | Dividers, input borders            |
| --white        | #FFFFFF   | Modal surfaces, overlays           |

Do not use pure black (#000000) for body copy. Use --text-primary.
The terracotta accent (#D97757) is the only bright color; use sparingly.

---

## 3. Typography

**Font Stack**: System serif for headings, system sans for body.

```
heading: "Georgia", "Times New Roman", serif
body:    -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif
mono:    "SF Mono", "Fira Code", "Consolas", monospace
```

| Style        | Size  | Weight | Line Height |
|--------------|-------|--------|-------------|
| Display      | 48px  | 400    | 1.15        |
| Heading 1    | 32px  | 400    | 1.25        |
| Heading 2    | 24px  | 500    | 1.3         |
| Heading 3    | 18px  | 600    | 1.4         |
| Body         | 16px  | 400    | 1.7         |
| Small        | 14px  | 400    | 1.5         |
| Caption      | 12px  | 400    | 1.4         |

Use weight 400 (regular) for most headings — editorial style avoids heavy bold.

---

## 4. Components

**Button Primary**
- Background: --accent (#D97757)
- Text: #FFFFFF, 14px, weight 600
- Padding: 10px 20px
- Border-radius: 6px
- Hover: --accent-hover, subtle lift (translateY -1px)

**Button Secondary**
- Background: transparent
- Border: 1px solid --border
- Text: --text-primary, 14px
- Hover: --bg-secondary background

**Input**
- Border: 1px solid --border
- Background: #FFFFFF
- Focus: border-color --accent, no box-shadow
- Border-radius: 6px
- Padding: 10px 14px

**Card**
- Background: --bg-secondary
- Border: 1px solid --border
- Border-radius: 10px
- Padding: 24px
- No heavy shadow — use border for definition

**Message Bubble (AI)**
- Background: #FFFFFF
- Border: 1px solid --border
- Max-width: 80%
- Padding: 16px 20px
- Border-radius: 12px

---

## 5. Layout

- Max content width: 720px (editorial reading line)
- Page padding: 24px mobile, 48px tablet, 80px desktop
- Section gap: 48px between major sections
- Component gap: 16px between related elements
- Grid: 12-column with 24px gutters
- Sidebar width (if used): 280px, separated by --border

Generous whitespace is part of the aesthetic. Do not compress.

---

## 6. Depth

Minimal depth hierarchy. Elevation is expressed through color, not shadows.

| Level | Shadow | Usage                              |
|-------|--------|------------------------------------|
| 0     | none   | Flat elements, backgrounds         |
| 1     | none   | Cards (use border instead)         |
| 2     | `0 2px 8px rgba(0,0,0,0.06)` | Dropdowns, tooltips  |
| 3     | `0 8px 24px rgba(0,0,0,0.08)` | Modals, drawers     |

Avoid hard drop shadows. Prefer very soft, low-opacity shadows.

---

## 7. Do's and Don'ts

**Do:**
- Use generous whitespace to create editorial breathing room
- Use the terracotta accent sparingly — one accent per section max
- Use serif fonts for headings to maintain editorial warmth
- Keep interactive elements understated; let content lead
- Use --bg-secondary for subtle card differentiation over heavy shadows

**Don't:**
- Don't use pure white (#FFFFFF) as the page background (use --bg-primary)
- Don't stack multiple accent-colored elements
- Don't use bold (700+) weight for headings in Claude style
- Don't use border-radius > 12px on interactive components
- Don't add heavy shadows or dramatic elevation changes

---

## 8. Responsive

| Breakpoint | Width  | Notes                                |
|------------|--------|--------------------------------------|
| Mobile     | <640px | Single column, 24px page padding     |
| Tablet     | 640px+ | Max-width 720px, 48px padding        |
| Desktop    | 1024px+| Centered column, optional sidebar    |
| Wide       | 1440px+| No change in content width           |

Navigation collapses to hamburger below 640px.
Font sizes do not scale down below mobile — editorial scale is preserved.

---

## 9. Agent Prompt Guide

When building UI for this design system, use these prompts:

**Starting a new component:**
> "Create a [component] following the Claude design system: warm off-white
> background (#FAF9F7), terracotta accent (#D97757), serif headings at weight
> 400, generous whitespace (48px section gaps), border-based card definition
> (no shadows), 6px border-radius on interactive elements."

**Adjusting existing UI:**
> "Update this component to match Claude aesthetic: replace any heavy shadows
> with 1px solid #E5E0D8 borders, change accent colors to #D97757, increase
> whitespace between sections to 48px, switch heading font to Georgia serif
> at normal weight (400)."

**Color token prompt:**
> "Use these CSS custom properties: --bg-primary:#FAF9F7, --accent:#D97757,
> --text-primary:#1A1A1A, --border:#E5E0D8, --text-muted:#6B6460"
