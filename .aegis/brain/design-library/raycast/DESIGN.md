# DESIGN.md — Raycast Design System

> Inspired by Raycast. Dark chrome aesthetic, gradient accents, power-user density.
> Source: https://getdesign.md/raycast/design-md (VoltAgent/awesome-design-md, MIT)

---

## 1. Theme

Power-user elegance. Raycast's design system is built for developers who
demand both beauty and speed. Dark chrome backgrounds with carefully crafted
gradient accents create a premium feel without sacrificing information density.
The aesthetic bridges the gap between a native macOS app and a polished web
product: every pixel is intentional, every interaction is satisfying.

Primary mood: premium dark, gradient accents, developer delight.

---

## 2. Colors

| Token            | Value                                   | Usage                          |
|------------------|-----------------------------------------|--------------------------------|
| --bg-primary     | #1C1C1E                                 | Page / app background          |
| --bg-secondary   | #2C2C2E                                 | Card backgrounds               |
| --bg-tertiary    | #3A3A3C                                 | Hover states                   |
| --accent-start   | #FF6363                                 | Gradient start (red-orange)    |
| --accent-end     | #FF9F63                                 | Gradient end (orange)          |
| --accent-alt     | #6E56CF                                 | Alternative accent (purple)    |
| --gradient       | linear-gradient(135deg, #FF6363, #FF9F63) | Primary gradient accent      |
| --text-primary   | #FFFFFF                                 | Primary text                   |
| --text-secondary | #EBEBF5CC                               | Secondary text (80% opacity)   |
| --text-muted     | #8E8E93                                 | Muted / disabled text          |
| --border         | rgba(255,255,255,0.08)                  | Subtle borders                 |
| --border-strong  | rgba(255,255,255,0.15)                  | Emphasized borders             |

Gradients are used for key highlights, icons, and callout backgrounds.

---

## 3. Typography

**Font Stack**: System font with SF Pro on macOS.

```
heading: "SF Pro Display", -apple-system, system-ui, sans-serif
body:    "SF Pro Text", -apple-system, system-ui, sans-serif
mono:    "SF Mono", "Fira Code", monospace
```

| Style      | Size  | Weight | Line Height |
|------------|-------|--------|-------------|
| Display    | 56px  | 700    | 1.1         |
| H1         | 32px  | 700    | 1.2         |
| H2         | 22px  | 600    | 1.3         |
| H3         | 17px  | 600    | 1.4         |
| Body       | 15px  | 400    | 1.6         |
| Small      | 13px  | 400    | 1.5         |
| Label      | 11px  | 500    | 1.4         |

---

## 4. Components

**Button Primary**
- Background: --gradient (linear-gradient(135deg, #FF6363, #FF9F63))
- Text: #FFFFFF, 14px, weight 600
- Padding: 10px 20px
- Border-radius: 8px
- Hover: brightness(1.1) on gradient

**Button Secondary**
- Background: --bg-tertiary
- Border: 1px solid --border-strong
- Text: --text-primary

**Command Input (spotlight style)**
- Background: rgba(255,255,255,0.05)
- Border: 1px solid --border-strong
- Border-radius: 12px
- Padding: 14px 18px
- Font: 18px, weight 400
- Placeholder: --text-muted

**Result Row**
- Height: 44px
- Background on hover: rgba(255,255,255,0.06)
- Icon: 20px, rounded 6px background
- Title: 15px --text-primary
- Subtitle: 13px --text-muted

**Extension Card**
- Background: --bg-secondary
- Border: 1px solid --border
- Border-radius: 12px
- Padding: 20px
- Icon: 40px with gradient or solid background

---

## 5. Layout

- Max content width: 1100px
- Page padding: 24px mobile, 40px desktop
- Section gap: 64px
- Component gap: 12px
- Command palette max-width: 640px (centered, floating)
- Extension grid: 3-4 columns, 16px gap

---

## 6. Depth

Multi-layered with glass and gradient effects.

| Level | Effect | Usage                                              |
|-------|--------|----------------------------------------------------|
| 0     | none   | Base layer                                         |
| 1     | rgba(255,255,255,0.03) bg | Subtle surface tinting          |
| 2     | `0 2px 20px rgba(0,0,0,0.4)` | Cards                          |
| 3     | `0 8px 40px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.08)` | Floating panels |

---

## 7. Do's and Don'ts

**Do:**
- Use the gradient accent on primary CTAs and key visual moments
- Apply glass-morphism (rgba backgrounds + blur) for overlay surfaces
- Use macOS-native rounded corners (10-12px) on cards
- Make icons 20-24px with a colored square background (4-6px radius)
- Create tactile hover states with very subtle brightness change

**Don't:**
- Don't use the gradient in more than one place per view
- Don't use light backgrounds — Raycast is always dark
- Don't strip the gradient from the primary brand elements
- Don't use flat rectangular buttons — always rounded
- Don't over-animate; transitions are 150ms max, ease-out

---

## 8. Responsive

| Breakpoint | Width   | Notes                                     |
|------------|---------|-------------------------------------------|
| Mobile     | <640px  | Command palette is full-width             |
| Tablet     | 640px+  | Standard floating command palette         |
| Desktop    | 1024px+ | Full layout, sidebar extensions           |
| Wide       | 1440px+ | No change in command palette width        |

Raycast is desktop-primary (macOS app). Web marketing is secondary surface.

---

## 9. Agent Prompt Guide

**Command palette component:**
> "Build a Raycast-style command palette: #1C1C1E background, 640px max-width,
> 12px border-radius, 1px solid rgba(255,255,255,0.15) border, input field
> 18px SF Pro at 14px padding, result rows 44px tall with rgba hover overlay,
> icons 20px with 4px-radius square gradient backgrounds."

**Hero section with gradient:**
> "Raycast hero: #1C1C1E page, h1 56px weight 700, gradient text on key phrase
> (linear-gradient(135deg,#FF6363,#FF9F63) + background-clip:text), body
> 15px #EBEBF5CC, CTA button uses full gradient fill."

**Color tokens:**
> "--bg-primary:#1C1C1E, --accent-gradient: linear-gradient(135deg,#FF6363,#FF9F63),
> --text-primary:#FFFFFF, --text-muted:#8E8E93, --border:rgba(255,255,255,0.08)"
