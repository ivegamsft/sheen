# Installation & Setup

Use this page when you want to inspect the repository locally or prepare the
docs site for a clean build.

## 1. Clone and inspect

```bash
git clone https://github.com/ivegamsft/sheen.git
cd basecoat-sheen
```

## 2. Understand the source map

Start with the highest-signal files:

- `SPEC.md` and `specs/` for normative contracts
- `.lexicon.md` for canonical vocabulary
- `tokens/` for DTCG foundations
- `skills/_catalog.md` and `agents/` for available capabilities

## 3. Build the docs site locally

If you are updating docs, build the site from the repo root:

```bash
mkdocs build
```

Use `mkdocs serve` when you want live preview during editing.

## 4. Use in a consumer repo

1. Copy `.sheen.yml.example` to `.sheen.yml`.
2. Set `source` and pin `ref` to a release tag for stability.
3. Run `sync.ps1` (Windows) or `sync.sh` (POSIX).
4. Validate with your CI and `scripts/validate-tokens.ps1`.

## 5. Author changes

- Add or update skills under `skills/<name>/`.
- Keep frontmatter and eval contracts aligned to `specs/02`.
- Run targeted checks before opening a PR.
