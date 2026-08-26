# Modern Football.TXT to `fbtxt2sqlite` Compatibility Adapter

## Purpose

The project-owned adapter keeps the modern parsing stack intact while satisfying the two
legacy interfaces still consumed by `sportdb-models_v2 0.0.1`:

```text
Football.TXT 2026
  -> fbtok / fbtree 0.9.1
  -> Fbtxt::Parser 0.9.1 + SportDb::MatchTree 0.8.0
  -> project adapter
       SportDb::QuickLeagueOutline
       SportDb::MatchParser
  -> Sports::Match
  -> sportdb-models_v2 0.0.1
  -> fbtxt2sqlite 0.0.1
  -> SQLite
```

No installed gem, database schema, Football.TXT source, `sportdb-models_v2`, or
`fbtxt2sqlite` file is edited.

## Verified stack

```text
Ruby 3.4.10 + DevKit
fbtok 0.9.1
fbtree 0.9.1 (included with fbtok)
fbtxt-parser 0.9.1
fbtxt-document 0.9.1
sportdb-quick 0.8.0
sportdb-models_v2 0.0.1
fbtxt2sqlite 0.0.1
```

## Public command

```powershell
ruby compat\fbtxt2sqlite_compat.rb <database.sqlite3> <input.txt>
```

The wrapper loads `compat/openfootball_v2_legacy_adapter.rb`, installs the two required
legacy contracts, and then loads the official `fbtxt2sqlite` executable.

## Interfaces

### `SportDb::QuickLeagueOutline`

```ruby
outline = SportDb::QuickLeagueOutline.parse(text)
outline.each_sec do |section|
  section.league
  section.season
  section.stage
  section.lines
  section.text
end
```

It preserves H1 league/season and H2 stage partitions before the modern match converter
discards headings. Every section is fully preflighted before `MatchReader` persists its
first row, preventing partial domain imports when a later section in the same file is
unsupported.

### `SportDb::MatchParser`

```ruby
teams, matches, rounds, groups =
  SportDb::MatchParser.new(lines, season_start_date).parse
```

The return shape matches the legacy interface. `matches` contains official
`Sports::Match` values. The adapter maps only explicit values for:

- teams;
- date and time;
- round and explicitly nested group;
- section stage;
- canonical status;
- explicit `ft`, `ht`, `et`, and `p` integer pairs.

Group support is intentionally narrow: a declared `Group X` level-1 outline followed by
an explicit level-2 round is representable as separate `group` and `round` values. A group
without a round is rejected because `models_v2` cannot persist it safely without inventing
a round.

## Fail-closed matrix

| Input condition | Result |
| --- | --- |
| Generic plain/reported score | `COMPAT_UNSUPPORTED_REPORTED` |
| Aggregate score | `COMPAT_UNSUPPORTED_AGG` |
| Bye | `COMPAT_UNSUPPORTED_BYE` |
| Modern parser error | `COMPAT_PARSER_ERROR` |
| Modern converter attempts process exit | `COMPAT_CONVERTER_ABORT` |
| H2 stage whose match has no explicit round | `COMPAT_AMBIGUOUS_STAGE` |
| Group without definition or round | `COMPAT_AMBIGUOUS_GROUP` / `COMPAT_AMBIGUOUS_STRUCTURE` |
| Heading level 3 or unproven round nesting | `COMPAT_UNSUPPORTED_NESTING` |
| Unsupported parse-tree node | `COMPAT_UNSUPPORTED_STRUCTURE` |
| Missing team or date | `COMPAT_MISSING_TEAMS` / `COMPAT_MISSING_DATE` |
| Unknown or malformed score channel | `COMPAT_UNSUPPORTED_SCORE_KEYS` / `COMPAT_INVALID_*` |
| Unpinned gem version | `COMPAT_VERSION_MISMATCH` |

Failures exit nonzero. Rejection acceptance tests inspect `leagues`, `events`, `teams`, and
`matches` and require all four counts to remain zero.

## Deterministic load order

`sportdb-quick` must load first because its converter is used. It installs the deprecated
top-level `RaccMatchParser = SportDb::Parser`. The adapter then:

1. removes only that deprecated compatibility constant;
2. loads `fbtxt/parser`;
3. verifies `RaccMatchParser.equal?(Fbtxt::Parser)`;
4. installs the legacy adapter classes;
5. lets official `sportdb-models_v2` and `fbtok` load normally.

The adapter does not suppress the official Racc duplicate-constant warnings. Its assertion
proves which parser class the runtime converter will use.

## Tests and fixtures

```powershell
ruby tests\compatibility_adapter_test.rb
```

Supported fixtures cover:

- official minimal source extract;
- two H2 stages;
- declared group plus nested round;
- regular and final rounds;
- split season `2025/26`, including dates in 2025 and 2026;
- date, time, canonical status;
- `ft`, `ht`, `et`, and penalties.

Rejection fixtures cover reported scores, aggregate scores, byes, parser errors,
stage-without-round ambiguity, unsupported headings, and missing dates.

## Verified real smoke pipeline

Run from the workspace root:

```powershell
$fixture = (Resolve-Path 'tests\fixtures\footballtxt\minimal.txt').Path
$db = Join-Path (Resolve-Path 'build').Path 'footballtxt-smoke.sqlite3'
New-Item -ItemType Directory -Force 'build' | Out-Null
Remove-Item -LiteralPath $db -ErrorAction SilentlyContinue

& 'C:\Ruby34-x64\bin\fbtok.bat' $fixture
Get-Content -Raw $fixture | & 'C:\Ruby34-x64\bin\fbtree.bat' --json
& 'C:\Ruby34-x64\bin\ruby.exe' `
  'compat\fbtxt2sqlite_compat.rb' $db $fixture
```

Final verified exits on 2026-08-24:

```text
fbtok        0
fbtree       0
fbtxt2sqlite 0
```

The resulting SQLite database was queried rather than accepted by file existence:

```text
leagues=1
events=1
teams=2
matches=1
```

The complete acceptance suite result was:

```text
10 runs, 46 assertions, 0 failures, 0 errors, 0 skips
```

## Limitations

- This is a proven subset, not a universal converter for every Football.TXT 2026 node.
- Round definitions, match legs, detail lines, arbitrary notes, headings deeper than H2,
  and unproven nesting are rejected rather than approximated.
- The adapter guarantees preflight atomicity across all sections of one input file.
  The official CLI is not transactional across multiple independent input files; a later
  file can fail after an earlier file was committed.
- `models_v2` has no destination for aggregate or generic reported score semantics, so
  those constructs remain intentionally unsupported.
