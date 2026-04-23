# DESIGN.md — Cohere Design System

> Inspired by Cohere. Enterprise AI, clean professional aesthetic, blue tones.
> Source: https://getdesign.md/cohere/design-md (VoltAgent/awesome-design-md, MIT)

---

## 1. Theme

Enterprise AI for serious work. Cohere's visual language communicates
professional credibility, enterprise reliability, and measured confidence.
The palette is blue-based with clean white surfaces — signals of a B2B
product that competes for procurement decisions, not consumer hearts.
Typography is readable and formal; the design never competes with the
technical content it frames.

Primary mood: enterprise credibility, clean professionalism, measured blue.

---

## 2. Colors

| Token            | Value     | Usage                                  |
|------------------|-----------|----------------------------------------|
| --bg-primary     | #FFFFFF   | Page background                        |
| --bg-secondary   | #F8F9FC   | Section backgrounds, alternate rows   |
| --bg-dark        | #0B1929   | Dark sections, footer, hero variants  |
| --accent         | #1464EC   | Primary blue (CTA, links, active)     |
| --accent-hover   | #0F52C8   | Hover on primary blue                 |
| --accent-light   | #E8F0FE   | Light accent tint (tag bg, highlights)|
| --text-primary   | #0B1929   | Main text (dark navy, not pure black) |
| --text-secondary | #4A5568   | Body copy, descriptions               |
| --text-muted     | #718096   | Captions, metadata                    |
| --text-light     | #FFFFFF   | Text on dark backgrounds              |
| --border         | #E2E8F0   | Dividers, card borders                |
| --success        | #38A169   | Success states                        |
| --warning        | #ECC94B   | Warning states                        |
| --error          | #E53E3E   | Error states                          |

---

## 3. Typography

**Font Stack**: Inter or system sans — professional clarity.

```
heading: "Inter", -apple-system, "Segoe UI", sans-serif
body:    "Inter", -apple-system, "Segoe UI", sans-serif
mono:    "Fira Code", "SF Mono", monospace
```

| Style      | Size  | Weight | Line Height |
|------------|-------|--------|-------------|
| Display    | 52px  | 700    | 1.1         |
| H1         | 36px  | 700    | 1.2         |
| H2         | 24px  | 600    | 1.3         |
| H3         | 18px  | 600    | 1.4         |
| H4         | 15px  | 600    | 1.5         |
| Body       | 16px  | 400    | 1.7         |
| Small      | 14px  | 400    | 1.5         |
| Caption    | 12px  | 400    | 1.4         |

Standard professional sizing. No unusual weights or letter-spacing.

---

## 4. Components

**Button Primary**
- Background: --accent (#1464EC)
- Text: #FFFFFF, 15px, weight 500
- Padding: 10px 24px
- Border-radius: 6px
- Hover: --accent-hover

**Button Secondary**
- Background: transparent
- Border: 1.5px solid --accent
- Text: --accent, 15px, weight 500
- Hover: --accent-light background

**Button Tertiary**
- Background: --bg-secondary
- Border: 1px solid --border
- Text: --text-primary

**Input**
- Background: #FFFFFF
- Border: 1px solid --border
- Focus: border 2px solid --accent
- Border-radius: 6px
- Padding: 10px 14px
- Label: 14px 500 above, 8px gap

**Data Table**
- Header: --bg-secondary, 14px 600 --text-secondary, 12px padding
- Row: 48px height, 1px solid --border bottom
- Hover: --bg-secondary
- Striped optional: even rows --bg-secondary

**Enterprise Card**
- White background, 1px solid --border, 8px radius
- Padding: 32px
- Header icon: 32px, --accent-light background
- Shadow: subtle (0 1px 4px rgba(11,25,41,0.06))

---

## 5. Layout

- Max content width: 1280px
- Page padding: 20px mobile, 40px tablet, 80px desktop
- Section gap: 80px (marketing), 40px (docs/app)
- Component gap: 24px
- Column grid: 12-column, 24px gutter

Enterprise layout is structured and aligned. No asymmetry.

---

## 6. Depth

Clean and subtle. Enterprise products use very conservative shadows.

| Level | Shadow | Usage                                   |
|-------|--------|-----------------------------------------|
| 0     | none   | Text, inline elements                   |
| 1     | `0 1px 4px rgba(11,25,41,0.06)` | Cards |
| 2     | `0 4px 16px rgba(11,25,41,0.10)` | Dropdowns, popovers |
| 3     | `0 8px 32px rgba(11,25,41,0.16)` | Modals |

---

## 7. Do's and Don'ts

**Do:**
- Use the blue accent for primary CTAs and navigation active states
- Apply enterprise spacing (32px padding on cards, 80px section gaps)
- Design for data tables — enterprise products live in tables
- Use consistent border treatment (1px solid --border everywhere)
- Include secondary and tertiary button variants for form hierarchies

**Don't:**
- Don't use gradients on primary surfaces — enterprise reads as clean
- Don't use colors outside the blue/navy palette for decorative purposes
- Don't use heavy typography weights beyond 700
- Don't collapse table headers or truncate data without ellipsis + tooltip
- Don't use casual, rounded aesthetics — maintain professional formality

---

## 8. Responsive

| Breakpoint | Width   | Notes                                      |
|------------|---------|---------------------------------------------|
| Mobile     | <640px  | 20px padding, stacked, single column        |
| Tablet     | 640px+  | 40px padding, 2-column layouts              |
| Desktop    | 1024px+ | Full grid, sidebar navigation               |
| Wide       | 1440px+ | Centered at 1280px max                      |

Enterprise products are desktop-primary. Mobile is secondary.

---

## 9. Agent Prompt Guide

**Enterprise dashboard card:**
> "Cohere enterprise card: #FFFFFF background, 1px solid #E2E8F0 border,
> 8px radius, 32px padding, 0 1px 4px rgba(11,25,41,0.06) shadow.
> Header: 32px icon with #E8F0FE background, title 18px 600 #0B1929,
> metric 36px 700 #1464EC, label 12px 400 #718096."

**Data table:**
> "Table header: #F8F9FC bg, 14px 600 #4A5568, 12px cell padding, 1px solid
> #E2E8F0 bottom. Rows: 48px height, 16px 400 #0B1929, hover #F8F9FC,
> 1px solid #E2E8F0 bottom border. Primary action: #1464EC text link."

**Color tokens:**
> "--bg-primary:#FFFFFF, --accent:#1464EC, --text-primary:#0B1929,
> --text-secondary:#4A5568, --border:#E2E8F0, --bg-secondary:#F8F9FC"
