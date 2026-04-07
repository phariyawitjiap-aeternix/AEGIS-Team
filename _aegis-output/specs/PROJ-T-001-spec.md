# Spec: PROJ-T-001 -- install.sh copies ALL files including PM state files

## Summary
The installer creates directory structure but does not copy ISO 29110 document
templates (PM-01 through PM-04, SI-01 through SI-07) or the doc-registry.json
into the target project. Users who install AEGIS get empty iso-docs/ with no
templates, breaking the Scribe agent's ability to generate compliance documents.

## Acceptance Criteria
1. install.sh copies all 11 ISO doc subdirectories (PM-01..PM-04, SI-01..SI-07)
   with their template files (current.md, changelog.md, v1.md) into target
2. install.sh copies doc-registry.json into target iso-docs/
3. On --upgrade, existing ISO docs are preserved (not overwritten) unless
   the user explicitly wants fresh templates
4. The copy uses the same copy_dir_contents pattern already in the script
   for consistency

## Implementation Notes
- Add a new section after the skill installation that copies ISO doc templates
- Use recursive copy for the subdirectory structure
- On upgrade mode, skip copying if ISO docs already exist (preserve user data)

## Havoc Finding Reference
H-001: install.sh missing v7.0 skills (CRITICAL) -- extended to include all
framework files that the installer should provide.
