# DESIGN.md — Vercel Design System

> Inspired by Vercel. Monochrome precision, Geist typeface, black/white developer aesthetic.
> Source: https://getdesign.md/vercel/design-md (VoltAgent/awesome-design-md, MIT)

---

## 1. Theme

Pure precision. Vercel's visual language is black-and-white monochrome with
zero decorative elements. Everything that exists has functional purpose.
The black background on marketing pages and white backgrounds on app pages
create a high-contrast developer aesthetic that communicates performance
and reliability. Geist is the custom typeface that defines the brand.

Primary mood: technical precision, zero noise, monochrome authority.

---

## 2. Colors

| Token            | Value   | Usage                              |
|------------------|---------|------------------------------------|
| --bg-primary     | #000000 | Page background (marketing)        |
| --bg-app         | #FFFFFF | App/dashboard background           |
| --bg-secondary   | #111111 | Card backgrounds on dark           |
| --bg-tertiary    | #1A1A1A | Hover states on dark               |
| --accent         | #FFFFFF | Primary CTA on dark backgrounds    |
| --accent-dark    | #000000 | Primary CTA on light backgrounds   |
| --text-primary   | #FFFFFF | Body on dark / #000000 on light    |
| --text-muted     | #888888 | Secondary text, captions           |
| --border-dark    | #333333 | Dividers on dark                   |
| --border-light   | #EAEAEA | Dividers on light                  |
| --success        | #50E3C2 | Success states                     |
| --error          | #FF0000 | Error states                       |

Only black and white for interactive elements. Success/error are the only
non-monochrome colors.

---

## 3. Typography

**Font Stack**: Geist (Vercel's custom font), fallback to Inter.

```
heading: "Geist", "Inter", -apple-system, sans-serif
body:    "Geist", "Inter", -apple-system, sans-serif
mono:    "Geist Mono", "Fira Code", monospace
```

| Style        | Size  | Weight | Letter Spacing |
|--------------|-------|--------|----------------|
| Display      | 72px  | 700    | -0.04em        |
| Heading 1    | 48px  | 700    | -0.03em        |
| Heading 2    | 32px  | 700    | -0.02em        |
| Heading 3    | 20px  | 600    | -0.01em        |
| Body         | 16px  | 400    | 0              |
| Small        | 14px  | 400    | 0              |
| Code         | 14px  | 400    | 0              |

Negative letter-spacing is Vercel's signature — tighter at large sizes.

---

## 4. Components

**Button Primary (dark bg)**
- Background: #FFFFFF
- Text: #000000, 14px, weight 600
- Padding: 8px 16px
- Border-radius: 6px
- Hover: background #E5E5E5

**Button Primary (light bg)**
- Background: #000000
- Text: #FFFFFF, 14px, weight 600
- Border-radius: 6px

**Button Secondary**
- Background: transparent
- Border: 1px solid #333333 (dark) or #EAEAEA (light)
- Text: matching primary text color

**Input**
- Border: 1px solid --border
- Background: transparent
- Focus: border-color #FFFFFF (dark) or #000000 (light)
- Border-radius: 6px
- Padding: 8px 12px

**Card**
- Background: #111111 (dark) or #FAFAFA (light)
- Border: 1px solid --border
- Border-radius: 8px
- Padding: 24px

---

## 5. Layout

- Max content width: 1200px
- Page padding: 16px mobile, 24px tablet, 48px desktop
- Section gap: 80px between major sections
- Component gap: 16px
- Grid: 12-column fluid
- Hero sections: full viewport height on marketing pages

Vercel uses very wide layouts on marketing. App layouts are more contained.

---

## 6. Depth

Very flat. Dark borders define hierarchy, not shadows.

| Level | Shadow | Usage                              |
|-------|--------|------------------------------------|
| 0     | none   | Flat surfaces                      |
| 1     | none   | Cards use border                   |
| 2     | `0 0 0 1px rgba(255,255,255,0.1)` | Subtle glow on dark |
| 3     | `0 8px 30px rgba(0,0,0,0.5)` | Modals on dark      |

---

## 7. Do's and Don'ts

**Do:**
- Use negative letter-spacing for display-size headings
- Keep the monochrome palette strict — no colors except success/error
- Use Geist or Inter font exclusively
- Make heavy use of code blocks with Geist Mono
- Use sharp 6-8px border-radius consistently

**Don't:**
- Don't introduce brand colors (blue, purple, etc.) — this is monochrome
- Don't use shadows for card elevation on dark backgrounds
- Don't use letter-spacing: 0 on large display headings
- Don't use soft rounded corners (>10px) on buttons
- Don't use decorative gradients or textures

---

## 8. Responsive

| Breakpoint | Width   | Notes                                |
|------------|---------|--------------------------------------|
| Mobile     | <640px  | Single column, 16px padding          |
| Tablet     | 640px+  | Two columns possible, 24px padding   |
| Desktop    | 1024px+ | Full grid, 48px padding              |
| Wide       | 1440px+ | Max width 1200px, centered           |

---

## 9. Agent Prompt Guide

**Starting a new component:**
> "Create a [component] following the Vercel design system: black background
> (#000000), white text (#FFFFFF), monochrome only (no brand colors), Geist
> or Inter font, negative letter-spacing on headings (-0.02em), 6px
> border-radius, border-based card definition (1px solid #333333)."

**Dark/light surface toggle prompt:**
> "This component has a dark variant (#000 bg, #FFF text, #333 border) and
> a light variant (#FFF bg, #000 text, #EAEAEA border). Follow Vercel's
> monochrome pattern with no intermediate grays below #888."

**Code/terminal component:**
> "Use Geist Mono at 14px, #1A1A1A background, #FFFFFF text, 1px solid
> #333333 border, 8px border-radius. Vercel style: no line numbers by default."
