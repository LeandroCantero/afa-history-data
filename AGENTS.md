# Instructions for AI Coding Agents (AFA History v2)

Welcome to **AFA History v2** (`afa-history-data`). All AI coding agents working on this codebase MUST strictly adhere to the following rules and workflows.

---

## 🛑 Core Repository Guardrails

1. **No External APIs or Proprietary References**:
   - Never mention private APIs, keys, or non-public services in documentation, code, or commits.
2. **Git Safety**:
   - Never execute `git commit` or `git push` unless explicitly commanded by the user in the prompt.
3. **Official Tooling Only**:
   - Use Gerald Bauer's official gem `rsssf` (`Rsssf::Fmtfix.fmtfix`), `fbtok`, and `fbtxt2sqlite`. Never write custom parser regex engines from scratch.
4. **Canonical Data Format**:
   - All processed files in `data/` must strictly conform to **Football.TXT 2026 Level 2** specification.

---

## 🔍 Agent Post-Season Audit Protocol (Read-Only & Report Mode)

When performing a review or audit of a processed season/tournament:

1. **Strict Read-Only Mode**:
   - During the audit/review phase, the AI agent **MUST NOT edit code or modify data files (`data/` or `scripts/`) automatically**.
2. **Factual Integrity Check**:
   - Compare the raw factual source (`sources/rsssf/<season>/...`) line-by-line against the processed dataset (`data/primera/<season>/...`).
   - Verify zero missing matches, exact match scores, penalties (`, 4-2 pen.`), dates, and stadium names (`@ venue`).
3. **Syntax & Level 2 Validation**:
   - Run `fbtok data/primera/<season>/*.txt` to ensure 0 syntax errors.
   - Verify `# Date`, `# Teams`, `# Matches`, and `# Stages` header metadata comments.
4. **Club Normalization Check**:
   - Ensure all clubs are resolved using `config/club_aliases.yml`.
5. **Mandatory Reporting to User**:
   - Present a clear, structured Markdown report to the user summarizing findings. If discrepancies exist, report them to the user for guidance rather than modifying files silently.
