# DESIGN.md — Stripe Design System

> Inspired by Stripe. Signature purple gradient, weight-300 elegance, developer-focused SaaS.
> Source: https://getdesign.md/stripe/design-md (VoltAgent/awesome-design-md, MIT)

---

## 1. Theme

Elegant developer infrastructure. Stripe's visual language communicates
trust, precision, and subtle richness. The signature purple-to-blue gradient
on dark backgrounds, combined with an unusually light font weight (300),
creates a premium feel unlike most SaaS products. Documentation and developer
experience are first-class citizens — code is beautiful, not an afterthought.

Primary mood: premium developer, refined purple, elegant confidence.

---

## 2. Colors

| Token             | Value     | Usage                                    |
|-------------------|-----------|------------------------------------------|
| --bg-dark         | #0A2540   | Dark marketing background (deep navy)    |
| --bg-light        | #FFFFFF   | App / docs background                    |
| --bg-secondary    | #F6F9FC   | Section backgrounds on light             |
| --accent-primary  | #635BFF   | Primary purple (buttons, links)          |
| --accent-gradient | linear-gradient(135deg, #7C3AED 0%, #3B82F6 100%) | Hero gradient |
| --accent-hover    | #4F46E5   | Hover on primary purple                  |
| --text-dark       | #0A2540   | Body on light backgrounds                |
| --text-light      | #FFFFFF   | Body on dark backgrounds                 |
| --text-muted      | #425466   | Secondary text on light                  |
| --text-muted-dark | #8898AA   | Secondary text on dark                   |
| --border          | #E6EBF1   | Borders on light                         |
| --success         | #09825D   | Success states                           |
| --error           | #CC0000   | Error states                             |

---

## 3. Typography

**Font Stack**: `-apple-system` with Stripe's custom metrics.

```
heading: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif
body:    -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif
mono:    "SF Mono", SFMono-Regular, "Fira Code", monospace
```

| Style      | Size  | Weight | Line Height | Notes              |
|------------|-------|--------|-------------|--------------------|
| Display    | 64px  | 300    | 1.1         | Ultra-light hero   |
| H1         | 40px  | 300    | 1.2         | Signature weight   |
| H2         | 28px  | 400    | 1.3         |                    |
| H3         | 20px  | 500    | 1.4         |                    |
| Body       | 17px  | 400    | 1.7         | Slightly large     |
| Small      | 14px  | 400    | 1.5         |                    |
| Code       | 13px  | 400    | 1.6         | Mono               |

Weight 300 on large headings is Stripe's distinctive signature.

---

## 4. Components

**Button Primary**
- Background: --accent-primary (#635BFF)
- Text: #FFFFFF, 15px, weight 500
- Padding: 12px 24px
- Border-radius: 6px
- Hover: --accent-hover

**Button Secondary**
- Background: #FFFFFF
- Border: 1px solid --border
- Text: --text-dark, 15px
- Hover: --bg-secondary background

**Code Block**
- Background: #1A1F36 (dark navy)
- Text: #F6F9FC
- Font: SF Mono 13px
- Padding: 24px
- Border-radius: 8px
- Syntax highlighting: purple for keywords, teal for strings

**API Card**
- Background: #FFFFFF
- Border: 1px solid --border
- Border-radius: 8px
- Padding: 24px 32px
- Subtle shadow: 0 2px 6px rgba(10,37,64,0.06)

**Dashboard Widget**
- White background, 1px solid --border, 8px radius
- Header: 12px label weight 500 color --text-muted
- Value: 32px weight 600 --text-dark

---

## 5. Layout

- Max content width: 1440px (marketing), 1200px (docs/app)
- Page padding: 24px mobile, 48px tablet, 80px desktop
- Section gap: 96px (marketing), 48px (docs)
- Component gap: 24px
- Docs sidebar: 280px

Stripe uses large section gaps on marketing pages and tighter on docs.

---

## 6. Depth

Refined shadows with navy undertone (not pure black shadows).

| Level | Shadow | Usage                                      |
|-------|--------|--------------------------------------------|
| 0     | none   | Flat text, dividers                        |
| 1     | `0 2px 6px rgba(10,37,64,0.06)` | Default card  |
| 2     | `0 4px 16px rgba(10,37,64,0.1)` | Raised card   |
| 3     | `0 8px 32px rgba(10,37,64,0.16)` | Modal, drawer |

Shadows use deep navy (#0A2540) color, not black — keeps warm brand feel.

---

## 7. Do's and Don'ts

**Do:**
- Use weight 300 on large display headings — it's Stripe's signature
- Apply the purple gradient as a background on hero/feature sections
- Make code blocks beautiful — Stripe is a developer product
- Use 17px body text (larger than typical) for comfortable reading
- Use deep navy (#0A2540) instead of pure black for shadows/dark elements

**Don't:**
- Don't use weight 700+ for any heading — Stripe is elegant, not heavy
- Don't skip code formatting — even inline code matters
- Don't use pure black (#000000) anywhere — always deep navy
- Don't use rounded corners > 10px on main containers
- Don't use the gradient accent on more than one element per section

---

## 8. Responsive

| Breakpoint | Width   | Notes                                      |
|------------|---------|---------------------------------------------|
| Mobile     | <640px  | 24px padding, stacked sections             |
| Tablet     | 640px+  | 48px padding, 2-column possible            |
| Desktop    | 1024px+ | Full layout, sidebar docs                  |
| Wide       | 1440px+ | Full-bleed marketing sections              |

---

## 9. Agent Prompt Guide

**Hero section:**
> "Stripe-style hero: #0A2540 dark background, h1 64px weight 300 white,
> gradient text on key phrase (linear-gradient(135deg,#7C3AED,#3B82F6) clip),
> body 17px #8898AA, CTA button #635BFF with 6px radius, 12px vertical
> padding."

**API code block:**
> "Code block: #1A1F36 background, #F6F9FC text, SF Mono 13px line-height 1.6,
> 24px padding, 8px border-radius. Stripe style: purple for keywords, teal
> for strings, no line numbers, tabs not spaces."

**Color tokens:**
> "--bg-dark:#0A2540, --accent:#635BFF, --text-dark:#0A2540,
> --text-muted:#425466, --border:#E6EBF1, --bg-light:#FFFFFF"
