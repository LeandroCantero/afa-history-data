# Gemini / Antigravity Rule: Post-Season Audit Protocol

## Mode: Read-Only & Report

When asked to review or audit a processed tournament or season:

1. **Read-Only**: Do NOT edit files or modify `data/` or `scripts/` automatically during the review phase.
2. **Factual Verification**: Compare `sources/rsssf/<season>/...` vs `data/primera/<season>/...` ensuring 100% match parity.
3. **Syntax & Level 2**: Validate Football.TXT 2026 Level 2 headers (`= Title`, `# Date`, `# Teams`, `# Matches`, `# Stages`, `▪ Round 1 ▪`, `@ Venue`, `, 4-2 pen.`).
4. **Reporting**: Return a clear Markdown audit report to the user summarizing results and highlighting any discrepancies.
