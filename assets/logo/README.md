# AEGIS Logo Asset Pack

Brand assets for AEGIS v12.0 — the AI Agent Team Framework for Claude Code.

## Files

| File | Dimensions | Use case |
|------|-----------|----------|
| [`aegis-shield.svg`](aegis-shield.svg) | 256 × 320 | Primary logo — full color, agent-team dot pattern, "A" monogram. Use in README headers, dashboard, presentations. |
| [`aegis-wordmark.svg`](aegis-wordmark.svg) | 640 × 240 | Wide format — shield + "AEGIS" wordmark + tagline. Use in blog posts, social cards, wide headers. |
| [`aegis-mono.svg`](aegis-mono.svg) | 256 × 320 | Monochrome — uses `currentColor`, recolor via CSS. Use for single-color printing, embossing, dark themes. |
| [`aegis-favicon.svg`](aegis-favicon.svg) | 64 × 64 | Simplified shield — renders cleanly at 16–64px. Use as favicon, app icon, small UI contexts. |

## Design language

### Symbolism
- **Shield** — protection, framework as a defensive structure; echoes the 🛡️ emoji used throughout the codebase.
- **"A" monogram** — anchor letter of AEGIS, bold/heraldic to read at any scale.
- **8 orbiting dots** — the agent team as a constellation orbiting the framework core. (Eight was the original persona count in v6.0; the dot pattern remains the canonical visual motif even as agent count grew to 11.)
- **Gradient (sky → deep blue)** — trust + depth + technical gravitas without feeling sterile.

### Color palette

| Role | Hex | When |
|------|-----|------|
| Primary (shield body, top) | `#0ea5e9` (sky-500) | Gradient start, accent UI |
| Primary (shield body, mid) | `#1e40af` (blue-700) | Gradient body |
| Primary (shield body, bottom) | `#1e3a8a` (blue-900) | Gradient end, wordmark color |
| Stroke | `#0c4a6e` (sky-900) | Shield outline, wordmark on light bg |
| Monogram | `#fef3c7` (amber-100) | "A" letter, readable contrast on shield |
| Agent dots | `#fbbf24` (amber-400) | Orbiting agent markers |
| Tagline accent | `#0ea5e9` | Subtitle copy |
| Body text | `#475569` (slate-600) | Italic pull-quote |

All hex values map to the Tailwind default palette for easy theming.

### Typography (wordmark variant)

- **Wordmark**: Inter / Helvetica Neue / Arial, 900 weight, 96px, +12 tracking
- **Subtitle**: Inter / Helvetica Neue / Arial, 600 weight, 22px, +6 tracking, caps
- **Pull-quote**: Georgia / Times New Roman, italic, 18px

## Usage rules

**Do**:
- Use `aegis-shield.svg` for any context with room for a tall mark (README headers, splash screens).
- Use `aegis-wordmark.svg` when horizontal balance and the full brand name are both required.
- Scale uniformly — never stretch.
- Preserve at least 24px of clear space around the shield on all sides.

**Don't**:
- Do not replace the gradient with a flat color unless using `aegis-mono.svg`.
- Do not alter the 8-dot count or rearrange them — the constellation is canonical.
- Do not rotate the shield. The crown is always at top.
- Do not inject other brand marks (Marvel character emojis, etc.) inside the shield silhouette — those live alongside in text, not within the logo.

## Rendering to PNG

No PNG files are checked in — SVG scales losslessly. If you need rasters for a specific medium, generate on demand:

```bash
# Using Inkscape (recommended for clean rasterization)
inkscape assets/logo/aegis-shield.svg -o out.png -w 1024

# Using rsvg-convert
rsvg-convert -w 512 assets/logo/aegis-shield.svg -o out.png

# Using ImageMagick (lower quality but ubiquitous)
magick -background none -density 300 assets/logo/aegis-shield.svg -resize 512x out.png
```

## Integration

Referenced from:
- [`/README.md`](../../README.md) — repo header
- [`/install.sh`](../../install.sh) — ASCII shield banner (derived, not literal file include)
- [`/dashboard/`](../../dashboard/) — browser favicon (when dashboard is installed)

To use in a new context:

```html
<!-- HTML -->
<img src="assets/logo/aegis-shield.svg" alt="AEGIS" width="200"/>

<!-- Markdown -->
![AEGIS](assets/logo/aegis-shield.svg)

<!-- HTML with size constraint for README -->
<p align="center"><img src="assets/logo/aegis-wordmark.svg" alt="AEGIS" width="480"/></p>
```

## License

The AEGIS logo assets are released under the same MIT License as the framework. Attribution appreciated but not required. Do not use the logo to imply endorsement of a product or service not affiliated with the AEGIS framework.

## Version

- **v1.0** (2026-04-24) — Initial release. Shield silhouette, "A" monogram, 8-dot team constellation, wordmark variant, mono variant, favicon.
