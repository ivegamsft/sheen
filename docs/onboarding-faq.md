# Onboarding FAQ

## How long does setup take?

Most teams complete first-time setup in about 10 minutes: copy `.sheen.yml`,
run sync, verify landed assets, and choose an adoption mode.

## Can I adopt just tokens without skills?

Yes. Use the Token-only profile with `skills: []`, `agents: []`, and a themes
allow-list. See [Adoption Modes](adoption-modes.md#mode-2-token-only-design-system-governance-without-ai-assets).

## What if I already have basecoat?

Keep both `.basecoat.yml` and `.sheen.yml`. The namespaces are distinct
(`basecoat-*` and `sheen-*`), so you can sync both in the same consumer repo.

## How do I resolve `.sheen.yml` conflicts?

Treat `.sheen.yml` as a maintained config file. Resolve merge conflicts by
keeping the intended `source`, `ref`, and allow-lists, then run sync again to
reconcile the working tree.

## Can I customize asset subsets after sync?

Yes. Edit allow-lists (`skills`, `agents`, `instructions`, `themes`) and re-run
sync. You can start narrow, then expand as workflow needs become clearer.

## How often should I re-sync?

Use a regular cadence that matches your governance tolerance (for example,
weekly or per sprint), and pin `ref` to release tags when you need predictable
change windows.

## Where do I find the skill catalog?

Use [Skills Catalog](reference/skills-catalog.md) in docs, and the canonical
source at `skills/_catalog.md` in the repository.

## How do I report issues or request customization?

Open a GitHub issue in this repository with:

- Current `.sheen.yml` profile
- Expected vs. actual behavior
- Relevant sync output and consumer context

For custom org variants, maintain a fork and set `source` to that fork.

## Do I have to use all themes?

No. Set `themes` in `.sheen.yml` to only the themes you materialize. Omit
`themes` to include all available themes.

## Is `main` safe for production consumers?

`main` works for early adoption, but production consumers should pin `ref` to a
release tag for stability and controlled upgrades.
