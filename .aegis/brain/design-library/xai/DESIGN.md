# DESIGN.md — xAI Design System

> Inspired by xAI (Grok). Terminal monochrome, bold type, high-contrast stark aesthetic.
> Source: https://getdesign.md/x.ai/design-md (VoltAgent/awesome-design-md, MIT)

---

## 1. Theme

Bold terminal authority. xAI's visual language is pure stark monochrome —
the starkest in the AI landscape. Black backgrounds, pure white text, maximum
contrast, zero decoration. Typography is heavy and oversized at display scale,
communicating raw computational power. The design references terminal aesthetics
but elevates them into a consumer interface. No warmth, no gradients,
no compromise.

Primary mood: terminal stark, bold monochrome, maximum contrast authority.

---

## 2. Colors

| Token          | Value   | Usage                              |
|----------------|---------|------------------------------------|
| --bg-primary   | #000000 | Page background (pure black)       |
| --bg-secondary | #0D0D0D | Subtle surface differentiation     |
| --bg-tertiary  | #1A1A1A | Hover states, cards                |
| --bg-input     | #111111 | Input fields, text areas           |
| --text-primary | #FFFFFF | All primary text (pure white)      |
| --text-muted   | #808080 | Secondary text, captions           |
| --text-dim     | #404040 | Placeholder, disabled              |
| --border       | #222222 | Component borders                  |
| --border-focus | #FFFFFF | Focus state borders                |
| --accent       | #FFFFFF | Interactive accent = white on black|
| --inverse-bg   | #FFFFFF | Inverse sections (rare)            |
| --inverse-text | #000000 | Text on inverse sections           |

There are no brand colors. The entire palette is black, white, and grays.

---

## 3. Typography

**Font Stack**: Bold system sans, terminal-adjacent.

```
heading: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Helvetica Neue", sans-serif
body:    -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif
mono:    "SF Mono", "Fira Code", "Cascadia Code", Menlo, monospace
```

| Style      | Size   | Weight | Line Height | Notes              |
|------------|--------|--------|-------------|--------------------|
| Display    | 80px   | 900    | 1.0         | Ultra-heavy        |
| H1         | 48px   | 800    | 1.1         | Bold, no tracking  |
| H2         | 32px   | 700    | 1.2         |                    |
| H3         | 20px   | 700    | 1.3         |                    |
| Body       | 16px   | 400    | 1.6         |                    |
| Small      | 14px   | 400    | 1.5         |                    |
| Mono       | 14px   | 400    | 1.5         | Terminal/code      |

Display at weight 900 (Black) is xAI's signature. Maximum typographic impact.

---

## 4. Components

**Button Primary**
- Background: #FFFFFF
- Text: #000000, 15px, weight 600
- Padding: 12px 24px
- Border-radius: 0px OR 4px (stark, barely rounded)
- Hover: background #E0E0E0

**Button Secondary**
- Background: transparent
- Border: 1px solid #FFFFFF
- Text: #FFFFFF, 15px
- Hover: background rgba(255,255,255,0.08)

**Input**
- Background: --bg-input (#111111)
- Border: 1px solid --border (#222222)
- Focus: border 1px solid #FFFFFF
- Border-radius: 4px
- Padding: 12px 16px
- Text: #FFFFFF
- Placeholder: #404040

**Chat Message (Grok)**
- User: right-aligned, #1A1A1A background, 4px radius
- Assistant: full-width, #0D0D0D background or no background
- Text: pure white, 16px, line-height 1.6
- No avatars or user icons by default

**Code Block**
- Background: #0D0D0D
- Border: 1px solid #222222
- Border-radius: 4px
- Font: SF Mono 14px #FFFFFF
- No syntax highlighting beyond italic comments

---

## 5. Layout

- Max content width: 800px (chat), 1200px (marketing)
- Page padding: 20px mobile, 40px desktop
- Section gap: 80px
- Component gap: 16px
- Chat input: fixed bottom, 800px max-width centered

Stark use of whitespace. Empty space is dramatic, not wasteful.

---

## 6. Depth

Zero decorative depth. Pure flat with black shadows (invisible on black bg).

| Level | Effect | Usage                                     |
|-------|--------|-------------------------------------------|
| 0     | none   | All primary surfaces                      |
| 1     | `border: 1px solid #222222` | Cards, panels  |
| 2     | `0 4px 16px rgba(0,0,0,0.8)` | Overlays     |
| 3     | `0 8px 32px rgba(0,0,0,0.9)` | Modals       |

Everything is flat and dark. Shadows are invisible against black — use borders.

---

## 7. Do's and Don'ts

**Do:**
- Use weight 900 (Black) for display headings — this is the signature
- Embrace stark maximum contrast (pure black / pure white)
- Use 0px or 4px border-radius maximum — very square elements
- Make whitespace dramatic; empty black space creates impact
- Use monospace for code and for UI elements that should feel terminal-adjacent

**Don't:**
- Don't introduce any brand color — the palette is strictly monochrome
- Don't use rounded corners > 4px on primary components
- Don't add gradients, textures, or decorative elements of any kind
- Don't soften the aesthetic with warm grays or off-whites
- Don't use weight < 700 for headings (everything needs authority)

---

## 8. Responsive

| Breakpoint | Width   | Notes                                      |
|------------|---------|---------------------------------------------|
| Mobile     | <640px  | 20px padding, full-width input             |
| Tablet     | 640px+  | 40px padding, centered chat column         |
| Desktop    | 1024px+ | 800px chat max-width, centered             |
| Wide       | 1440px+ | No change in chat width                    |

---

## 9. Agent Prompt Guide

**Chat interface:**
> "xAI/Grok chat: #000000 background, user messages #1A1A1A bg right-aligned,
> assistant messages full-width no background, text #FFFFFF 16px line-height 1.6,
> input bar fixed bottom #111111 bg 1px solid #222222 border 4px radius,
> pure white send button."

**Hero with bold type:**
> "xAI hero: pure black #000000, display heading 80px weight 900 #FFFFFF
> no letter-spacing, subheading 18px weight 400 #808080, CTA: white button
> 0px border-radius, #000000 text, no decorative elements."

**Color tokens:**
> "--bg-primary:#000000, --text-primary:#FFFFFF, --text-muted:#808080,
> --border:#222222, --bg-secondary:#0D0D0D, --bg-tertiary:#1A1A1A"
