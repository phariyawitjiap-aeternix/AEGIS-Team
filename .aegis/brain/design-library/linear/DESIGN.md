# DESIGN.md — Linear Design System

> Inspired by Linear. Ultra-minimal SaaS aesthetic, purple accent, Geist typeface.
> Source: https://getdesign.md/linear.app/design-md (VoltAgent/awesome-design-md, MIT)

---

## 1. Theme

Precision productivity. Linear's design communicates speed, focus, and
professional calm. Dark backgrounds with subtle gradients, a signature purple
accent, and razor-thin typography create the feeling of a tool that respects
your time. No decoration exists that doesn't serve navigation or information
hierarchy. The aesthetic targets power users who live inside the product.

Primary mood: focused, fast, quiet authority, professional minimalism.

---

## 2. Colors

| Token          | Value     | Usage                              |
|----------------|-----------|------------------------------------|
| --bg-primary   | #0F0F0F   | Page background                    |
| --bg-secondary | #1A1A1A   | Card and panel backgrounds         |
| --bg-tertiary  | #252525   | Hover states, nested panels        |
| --accent       | #5E6AD2   | Primary CTA, links, active states  |
| --accent-light | #7B87E0   | Hover on accent                    |
| --text-primary | #F2F2F2   | Primary text                       |
| --text-muted   | #8A8A8A   | Secondary text, timestamps         |
| --text-subtle  | #555555   | Disabled, placeholder              |
| --border       | #2A2A2A   | Component borders                  |
| --border-focus | #5E6AD2   | Focus rings                        |
| --success      | #4CAF50   | Status indicators                  |
| --warning      | #F59E0B   | Warning states                     |
| --error        | #EF4444   | Error states                       |

---

## 3. Typography

**Font Stack**: Geist or Inter, extremely precise sizing.

```
heading: "Geist", "Inter", system-ui, sans-serif
body:    "Geist", "Inter", system-ui, sans-serif
mono:    "Geist Mono", "SF Mono", monospace
```

| Style     | Size  | Weight | Line Height | Letter Spacing |
|-----------|-------|--------|-------------|----------------|
| Display   | 40px  | 600    | 1.1         | -0.03em        |
| H1        | 28px  | 600    | 1.2         | -0.02em        |
| H2        | 20px  | 600    | 1.3         | -0.01em        |
| H3        | 15px  | 600    | 1.4         | 0              |
| Body      | 14px  | 400    | 1.6         | 0              |
| Small     | 12px  | 400    | 1.5         | 0.01em         |
| Label     | 11px  | 500    | 1.4         | 0.04em         |

Label style (11px, 500, tracked) is used extensively for metadata.

---

## 4. Components

**Button Primary**
- Background: --accent (#5E6AD2)
- Text: #FFFFFF, 13px, weight 500
- Padding: 6px 14px
- Border-radius: 6px
- Height: 30px (compact by default)

**Button Secondary**
- Background: --bg-tertiary
- Border: 1px solid --border
- Text: --text-primary, 13px

**Input / Search**
- Background: --bg-secondary
- Border: 1px solid --border
- Focus: border-color --accent
- Border-radius: 6px
- Height: 32px
- Padding: 0 10px

**Issue Row (list item)**
- Height: 34px
- Hover: --bg-tertiary background
- No border between rows (tight list density)
- Status icon (16px) + text + metadata right-aligned

**Sidebar**
- Width: 220px
- Background: --bg-secondary
- Items: 28px height, 12px horizontal padding
- Active item: --accent text, subtle accent-tinted background

---

## 5. Layout

- Max content width: 1400px
- Sidebar: 220px fixed
- Main content: flexible remainder
- Section gap: 24px within views
- Component gap: 8px (dense, app-like)
- Row height: 34px for list items

Linear is an app, not a marketing site. Dense layouts with consistent 8px
grid spacing. No decorative whitespace.

---

## 6. Depth

Very flat with subtle borders. Dark mode makes all elevation implicit.

| Level | Shadow | Usage                                       |
|-------|--------|---------------------------------------------|
| 0     | none   | Inline elements, list rows                  |
| 1     | none   | Cards, panels (border only)                 |
| 2     | `0 0 0 1px rgba(255,255,255,0.08), 0 4px 16px rgba(0,0,0,0.4)` | Modals |
| 3     | `0 0 0 1px rgba(255,255,255,0.12), 0 8px 32px rgba(0,0,0,0.6)` | Command palette |

---

## 7. Do's and Don'ts

**Do:**
- Use the 8px spacing grid consistently throughout
- Keep component heights compact (28-34px for interactive elements)
- Use the label style (11px, 500, tracked) for metadata and counts
- Use --accent sparingly for active/selected states only
- Apply subtle border-based card definition

**Don't:**
- Don't use whitespace decoratively — Linear is a dense productivity tool
- Don't use font sizes > 28px in app views (display size is marketing-only)
- Don't add hover animations beyond background color change
- Don't use rounded corners > 8px
- Don't put gradients inside components (background only)

---

## 8. Responsive

| Breakpoint | Width   | Notes                                         |
|------------|---------|-----------------------------------------------|
| Mobile     | <768px  | Sidebar collapses to bottom tab bar           |
| Tablet     | 768px+  | Narrow sidebar (48px icon-only mode possible) |
| Desktop    | 1024px+ | Full sidebar + content                        |
| Wide       | 1440px+ | Optional detail panel opens on right          |

Linear is desktop-first. Mobile is a companion, not primary surface.

---

## 9. Agent Prompt Guide

**Issue list component:**
> "Build an issue list following Linear design: #0F0F0F background, rows 34px
> tall with 12px horizontal padding, hover: #252525, no row borders, status
> icon 16px left-aligned, title in #F2F2F2 at 14px weight 400, metadata
> right-aligned in #8A8A8A at 11px weight 500 tracked 0.04em."

**Sidebar nav:**
> "Sidebar: 220px wide, #1A1A1A background, 1px solid #2A2A2A right border,
> items 28px tall, active item text #5E6AD2, active item bg rgba(94,106,210,0.08),
> 8px border-radius on item, icon 16px + label 13px weight 400."

**Color tokens:**
> "--bg-primary:#0F0F0F, --accent:#5E6AD2, --text-primary:#F2F2F2,
> --text-muted:#8A8A8A, --border:#2A2A2A, --bg-secondary:#1A1A1A"
