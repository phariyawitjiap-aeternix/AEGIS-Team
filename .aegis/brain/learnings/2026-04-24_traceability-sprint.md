# Learnings: Sprint v10-01 Traceability Wiki

> Date: 2026-04-24

## L1: JSON generation in bash requires a serializer
**Context**: First FUNC catalog implementation used printf for JSON emission.
Failed on agent capability names containing parentheses and special chars.
**Lesson**: For any JSON generation with untrusted/variable input, use a real
serializer (python3 json.dump) rather than bash string formatting.
**Applies to**: All future tool scripts that emit JSON.

## L2: Hash-based IDs need sufficient length
**Context**: 4 hex char FUNC IDs (65536 values) hit collision at ~420 entries.
**Lesson**: For hash-based identifiers, use 6+ hex chars (16M values) minimum.
Birthday paradox makes collisions likely much sooner than the ID space suggests.
**Applies to**: Any future auto-ID generation.

## L3: "File reference" needs precise definition in audits
**Context**: Trace audit check 2 extracted backtick-enclosed `.md` names,
matching bare filenames like `loki.md` as if they were file paths.
**Lesson**: When auditing file references, require the path to contain `/`
(indicating it's a relative/absolute path, not just a mention of a filename).
**Applies to**: Any future static analysis tools.

## L4: TSV intermediate for bash-to-python data handoff
**Context**: Needed to pass structured data from bash scan loops to python3
JSON serializer. TSV is simple, universal, and avoids escaping issues.
**Lesson**: TSV intermediate file + python3 conversion is a reliable pattern
for bash tools that need to emit structured data. Environment variables must
be exported for heredoc-embedded python to read them.
**Applies to**: Future tools that combine bash scanning with structured output.

## L5: Dogfood catches real bugs
**Context**: Running aegis-trace-audit.sh on its own sprint found 2 ghost
references in SI.02 (pm-state.json at wrong path, architecture-decisions.md
in archived location). Both were genuine errors.
**Lesson**: Self-referential validation (dogfooding) catches real issues that
design-time thinking misses. Always run new audit tools on their own output.
**Applies to**: All future audit/verification tools.
