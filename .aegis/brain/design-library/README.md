# AEGIS Design Library

## Provenance

Sourced from **VoltAgent/awesome-design-md** (MIT license).
Upstream repository: https://github.com/VoltAgent/awesome-design-md

The canonical design content is maintained by the VoltAgent team and published
at https://getdesign.md. The DESIGN.md files in this directory are curated
snapshots authored to match the aesthetic specifications documented by the
upstream project for each brand.

## License

MIT — see upstream LICENSE at
https://github.com/VoltAgent/awesome-design-md/blob/main/LICENSE

## Curation Rationale

10 files selected to cover 5 aesthetic axes:

| Slug     | Category    | Aesthetic Axis           |
|----------|-------------|--------------------------|
| claude   | AI/LLM      | Warm + editorial         |
| vercel   | Dev tools   | Monochrome precision     |
| linear   | SaaS        | Ultra-minimal            |
| raycast  | Dev tools   | Dark chrome + gradients  |
| stripe   | SaaS        | Purple + elegant         |
| cursor   | Dev tools   | IDE-native dark          |
| replicate| AI/LLM      | Documentation-first      |
| cohere   | AI/LLM      | Enterprise clean         |
| xai      | AI/LLM      | Bold monochrome          |
| warp     | Terminal    | Neon + dark canvas       |

## Usage

- **Reference only**: do NOT edit files in this directory in-place.
  Copy to your project root and customize there. The library files are
  immutable references (guard-write protection added in S3-03).
- **Re-seed**: run `tools/aegis-design-fetch.sh --seed-all` to refresh
  all 10 files from upstream.
- **Fetch one**: run `tools/aegis-design-fetch.sh --project <slug>`
  to update a single file.
- **Init project**: run `tools/aegis-design-init.sh --from <slug>`
  or `tools/aegis-design-init.sh --vibe <keyword>` to copy a reference
  to `./DESIGN.md` in your project root.

## Refresh Policy

Files are snapshots. Upstream content may evolve. Re-seed periodically:

    tools/aegis-design-fetch.sh --seed-all

To check if any files have drifted from upstream availability:

    tools/aegis-design-fetch.sh --verify-library

## Note on Upstream Structure

The VoltAgent upstream repository stores redirect stubs in
`design-md/<slug>/README.md` that point to https://getdesign.md.
The full DESIGN.md content is served via the getdesign.md web app.
The fetch tool uses `--slug` to map to the correct upstream identifier
(note: `linear` maps to upstream slug `linear.app`, `xai` maps to `x.ai`).
