# Troubleshooting

## Sync ran but nothing changed

- check that the source URL and `ref` are correct
- confirm the allow-list includes the asset family you expect
- re-run sync from the consumer repo root

## Token validation failed

- verify that semantic tokens still point to valid core values
- check theme completeness for the target surface
- review `checks.json` for the gate that failed

## Docs build failed

- confirm new pages are in the `nav` in `mkdocs.yml`
- make sure links point to the correct folder path
- run `mkdocs build` locally before opening a PR

## Search does not find a page

- check the page title and heading text
- make sure the page is linked from the nav or a hub page
- use the homepage cards to reach the right section fast
