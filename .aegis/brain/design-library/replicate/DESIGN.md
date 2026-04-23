# DESIGN.md — Replicate Design System

> Inspired by Replicate. ML-native, documentation-heavy, clean API surface design.
> Source: https://getdesign.md/replicate/design-md (VoltAgent/awesome-design-md, MIT)

---

## 1. Theme

Documentation-first ML platform. Replicate's design is built around the
model card — a dense but scannable unit that presents a model's metadata,
examples, and API surface. The aesthetic is clean and utilitarian with a
dark sidebar, light content area, and functional typography. The design
respects the technical user: no marketing fluff, just accurate information
presented clearly.

Primary mood: ML-native, documentation-first, functional precision.

---

## 2. Colors

| Token            | Value     | Usage                              |
|------------------|-----------|------------------------------------|
| --bg-primary     | #FFFFFF   | Main content area                  |
| --bg-secondary   | #F5F5F5   | Section backgrounds, card alt      |
| --bg-sidebar     | #0F0F0F   | Left sidebar (dark)                |
| --bg-code        | #1A1A1A   | Code block backgrounds             |
| --accent         | #0EA5E9   | Links, active states (sky blue)    |
| --accent-hover   | #0284C7   | Hover on accent                    |
| --text-primary   | #111111   | Body text                          |
| --text-secondary | #4B5563   | Captions, metadata                 |
| --text-muted     | #9CA3AF   | Timestamps, disabled               |
| --text-sidebar   | #D1D5DB   | Sidebar text (on dark)             |
| --border         | #E5E7EB   | Card borders, section dividers     |
| --border-code    | #2D2D2D   | Code block border                  |
| --tag-bg         | #EFF6FF   | Model tag backgrounds              |
| --tag-text       | #1D4ED8   | Model tag text                     |

---

## 3. Typography

**Font Stack**: Clean system sans with monospace for code.

```
heading: "Inter", -apple-system, system-ui, sans-serif
body:    "Inter", -apple-system, system-ui, sans-serif
mono:    "Fira Code", "SF Mono", "Cascadia Code", monospace
```

| Style    | Size  | Weight | Line Height |
|----------|-------|--------|-------------|
| H1       | 30px  | 700    | 1.2         |
| H2       | 22px  | 600    | 1.3         |
| H3       | 17px  | 600    | 1.4         |
| Body     | 15px  | 400    | 1.7         |
| Small    | 13px  | 400    | 1.5         |
| Code     | 13px  | 400    | 1.5         |
| Label    | 11px  | 600    | 1.4         |

Long-form documentation reads best at 15px with 1.7 line-height.

---

## 4. Components

**Model Card**
- White background, 1px solid --border, 8px radius
- Header row: model name (18px 600) + owner (14px muted)
- Tags: inline chips, --tag-bg background, 4px radius, 12px font
- Description: 15px body, max 3 lines with expand
- Run button: --accent background, right-aligned

**API Code Block**
- Background: --bg-code (#1A1A1A)
- Border: 1px solid --border-code
- Border-radius: 8px
- Copy button: top-right, appears on hover
- Language tab: 11px uppercase, --text-muted

**Input (Playground)**
- White background, 1px solid --border, 6px radius
- Label: 13px 600 above input
- Description: 12px --text-secondary below
- Focus: --accent border color

**Sidebar Navigation**
- Background: --bg-sidebar (#0F0F0F)
- Width: 240px
- Section headers: 11px uppercase tracked, #6B7280
- Items: 14px, #D1D5DB, 32px height
- Active: white text, subtle left border in --accent

**Output Display**
- Image outputs: responsive grid, no overflow
- Text outputs: monospace, --bg-code background

---

## 5. Layout

- Content max-width: 960px (docs), 1200px (gallery)
- Sidebar: 240px fixed (dark)
- Main area: white, padding 32px
- Section gap: 32px
- Component gap: 16px
- Model grid: 3 columns, 16px gap (desktop)

---

## 6. Depth

Flat with border-based definition. ML content is the visual hierarchy.

| Level | Shadow | Usage                                |
|-------|--------|--------------------------------------|
| 0     | none   | Body, sidebar                        |
| 1     | `0 1px 3px rgba(0,0,0,0.08)` | Model cards   |
| 2     | `0 4px 12px rgba(0,0,0,0.12)` | Dropdowns     |
| 3     | `0 8px 24px rgba(0,0,0,0.16)` | Modals        |

---

## 7. Do's and Don'ts

**Do:**
- Make code blocks prominent — API usage is the primary CTA
- Use model tags generously (task type, framework, license)
- Show run counts and timestamps as metadata
- Design the model card as the primary unit of information
- Keep the dark sidebar + light content pattern consistent

**Don't:**
- Don't hide the API code — it should be immediately visible
- Don't use marketing gradients or decorative backgrounds
- Don't truncate model descriptions aggressively (3 lines minimum)
- Don't use more than 2 colors in tag system
- Don't break the dark sidebar / light content split

---

## 8. Responsive

| Breakpoint | Width   | Notes                                     |
|------------|---------|-------------------------------------------|
| Mobile     | <768px  | Sidebar becomes bottom nav or drawer      |
| Tablet     | 768px+  | Narrow sidebar (200px)                    |
| Desktop    | 1024px+ | Full layout, model grid visible           |
| Wide       | 1440px+ | Model grid expands to 4 columns           |

---

## 9. Agent Prompt Guide

**Model card:**
> "Replicate model card: white #FFFFFF background, 1px solid #E5E7EB border,
> 8px radius, header row with model name 18px 600 + owner 14px #4B5563,
> tags in #EFF6FF background #1D4ED8 text 11px 600 4px radius, run button
> #0EA5E9 right-aligned."

**API code block:**
> "#1A1A1A background, 1px solid #2D2D2D border, 8px radius, Fira Code 13px
> #D1D5DB text, copy-on-hover top-right, language label 11px uppercase #9CA3AF
> in top-left, 20px horizontal padding."

**Color tokens:**
> "--bg-primary:#FFFFFF, --accent:#0EA5E9, --text-primary:#111111,
> --text-secondary:#4B5563, --border:#E5E7EB, --bg-sidebar:#0F0F0F"
