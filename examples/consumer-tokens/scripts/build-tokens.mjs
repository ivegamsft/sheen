import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const exampleRoot = path.resolve(__dirname, '..');
const repoRoot = path.resolve(exampleRoot, '..', '..');

const args = new Map();
for (let i = 2; i < process.argv.length; i += 1) {
  const current = process.argv[i];
  if (current.startsWith('--')) {
    args.set(current.slice(2), process.argv[i + 1] && !process.argv[i + 1].startsWith('--') ? process.argv[++i] : true);
  }
}

const theme = args.get('theme') || 'light';
const tokenRoot = path.resolve(args.get('tokens') || path.join(repoRoot, 'tokens'));
const outDir = path.resolve(args.get('out') || path.join(exampleRoot, 'dist'));
const outFile = path.join(outDir, `tokens-${theme}.css`);

async function readJson(file) {
  return JSON.parse(await readFile(file, 'utf8'));
}

async function readTokenFolder(folder) {
  const entries = await readdir(folder, { withFileTypes: true });
  const tokens = {};
  for (const entry of entries) {
    if (entry.isFile() && entry.name.endsWith('.tokens.json')) {
      Object.assign(tokens, flattenTokens(await readJson(path.join(folder, entry.name))));
    }
  }
  return tokens;
}

function flattenTokens(node, prefix = '', output = {}) {
  for (const [key, value] of Object.entries(node)) {
    if (key.startsWith('$')) continue;
    const tokenPath = prefix ? `${prefix}.${key}` : key;
    if (value && typeof value === 'object' && '$value' in value) {
      output[tokenPath] = value.$value;
    } else if (value && typeof value === 'object') {
      flattenTokens(value, tokenPath, output);
    }
  }
  return output;
}

function resolveValue(value, dictionary, seen = new Set()) {
  if (typeof value === 'string') {
    return value.replace(/\{([^}]+)\}/g, (_, ref) => {
      if (seen.has(ref)) throw new Error(`Circular token reference: ${[...seen, ref].join(' -> ')}`);
      if (!(ref in dictionary)) throw new Error(`Missing token reference: ${ref}`);
      return resolveValue(dictionary[ref], dictionary, new Set([...seen, ref]));
    });
  }

  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return Object.fromEntries(Object.entries(value).map(([key, inner]) => [key, resolveValue(inner, dictionary, seen)]));
  }

  return value;
}

function toKebab(name) {
  return name.replace(/\./g, '-').replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
}

function emitCssVariables(tokens) {
  const lines = [`:root,`, `[data-theme="${theme}"] {`];
  for (const [name, value] of Object.entries(tokens).sort(([a], [b]) => a.localeCompare(b))) {
    if (value && typeof value === 'object') {
      for (const [part, partValue] of Object.entries(value)) {
        lines.push(`  --sheen-${toKebab(name)}-${toKebab(part)}: ${partValue};`);
      }
    } else {
      lines.push(`  --sheen-${toKebab(name)}: ${value};`);
    }
  }
  lines.push('}', '');
  return lines.join('\n');
}

const core = await readTokenFolder(path.join(tokenRoot, 'core'));
const semantic = await readTokenFolder(path.join(tokenRoot, 'semantic'));
const themeTokens = flattenTokens(await readJson(path.join(tokenRoot, 'themes', `${theme}.tokens.json`)));
const dictionary = { ...core, ...semantic, ...themeTokens };
const resolved = Object.fromEntries(Object.entries({ ...semantic, ...themeTokens }).map(([key, value]) => [key, resolveValue(value, dictionary)]));

await mkdir(outDir, { recursive: true });
await writeFile(outFile, emitCssVariables(resolved), 'utf8');
console.log(`Wrote ${path.relative(process.cwd(), outFile)}`);
