#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import json
import os
import re
import subprocess
import sys
from collections import OrderedDict
from pathlib import Path

args = set(sys.argv[1:])
json_mode = '--json' in args or '-json' in args
verbose = '--verbose' in args or '-verbose' in args

def run(cmd):
    return subprocess.check_output(cmd, text=True).strip()

try:
    repo_root = Path(run(['git', 'rev-parse', '--show-toplevel']))
except Exception:
    print('Run this inside a git repository', file=sys.stderr)
    sys.exit(2)

def rel(path):
    return path.resolve().relative_to(repo_root.resolve()).as_posix()

def now_utc():
    from datetime import datetime, timezone
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

def section(name):
    return OrderedDict(name=name, status='pass', valid=True, messages=[])

def add(section_obj, level, message, path=None):
    section_obj['messages'].append(OrderedDict(level=level, path=path, message=message))
    if level == 'error':
        section_obj['valid'] = False
        section_obj['status'] = 'error'
    elif level == 'warn' and section_obj['status'] == 'pass':
        section_obj['status'] = 'warn'

def frontmatter_lines(path: Path):
    if not path.exists():
        return None
    lines = path.read_text(encoding='utf-8').splitlines()
    if len(lines) < 3 or lines[0].strip() != '---':
        return None
    for i in range(1, len(lines)):
        if lines[i].strip() == '---':
            return lines[1:i]
    return None

def fm_scalar(lines, key):
    if not lines:
        return None
    pat = re.compile(rf'^\s*{re.escape(key)}:\s*(.*?)\s*(?:#.*)?$')
    for line in lines:
        m = pat.match(line)
        if m:
            val = m.group(1).strip()
            if re.fullmatch(r'\[.*\]', val):
                return None
            if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                val = val[1:-1]
            return val
    return None

def fm_list(lines, key):
    if not lines:
        return []
    out = []
    capture = False
    base_indent = 0
    for line in lines:
        if not capture:
            m = re.match(rf'^(\s*){re.escape(key)}:\s*(.*)$', line)
            if m:
                capture = True
                base_indent = len(m.group(1))
                rest = m.group(2).strip()
                if re.fullmatch(r'\[(.*)\]', rest):
                    for item in re.fullmatch(r'\[(.*)\]', rest).group(1).split(','):
                        item = item.strip().strip('"').strip("'")
                        if item:
                            out.append(item)
                    return out
            continue
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        m = re.match(r'^(\s*)-\s*(.*?)\s*(?:#.*)?$', line)
        if m and len(m.group(1)) > base_indent:
            item = m.group(2).strip().strip('"').strip("'")
            if item:
                out.append(item)
            continue
        if re.match(rf'^\s{{{base_indent + 1},}}\S', line):
            continue
        break
    return out

def parse_sheen_config(path: Path):
    data = OrderedDict()
    errors = []
    seen = set()
    if not path.exists():
        errors.append('.sheen.yml not found')
        return data, errors, seen
    lines = path.read_text(encoding='utf-8').splitlines()
    current = None
    current_indent = 0
    for idx, line in enumerate(lines, start=1):
        trim = line.strip()
        if not trim or trim.startswith('#'):
            continue
        if line.startswith('\t'):
            errors.append(f'Line {idx}: tabs are not valid YAML indentation')
            continue
        if current == 'sync':
            if re.match(r'^\s+\S', line):
                continue
            current = None
            # reprocess this line as a top-level line
            if idx > 0:
                # fall through by handling below
                pass
        m = re.match(r'^(\s*)([A-Za-z][A-Za-z0-9_-]*):\s*(.*)$', line)
        if m and not (current == 'sync' and len(m.group(1)) > current_indent):
            indent, key, rest = len(m.group(1)), m.group(2), m.group(3).strip()
            seen.add(key)
            if indent != 0 and current != 'sync':
                errors.append(f"Line {idx}: unexpected indentation for top-level key '{key}'")
                continue
            if rest == '':
                current = key
                current_indent = indent
                data.setdefault(key, OrderedDict() if key == 'sync' else [])
                continue
            inline = re.fullmatch(r'\[(.*)\]', rest)
            if inline:
                items = [x.strip().strip('"').strip("'") for x in inline.group(1).split(',') if x.strip()]
                data[key] = items
                current = None
                continue
            scalar = re.sub(r'\s+#.*$', '', rest).strip()
            if (scalar.startswith('"') and scalar.endswith('"')) or (scalar.startswith("'") and scalar.endswith("'")):
                scalar = scalar[1:-1]
            data[key] = scalar
            current = None
            continue
        if current == 'sync' and re.match(r'^\s+\S', line):
            continue
        if current in {'skills', 'agents', 'instructions', 'themes'}:
            item_match = re.match(r'^(\s*)-\s*(.*?)\s*(?:#.*)?$', line)
            if item_match and len(item_match.group(1)) > current_indent:
                item = item_match.group(2).strip().strip('"').strip("'")
                if item:
                    data.setdefault(current, []).append(item)
                continue
            current = None
        errors.append(f"Line {idx}: unable to parse YAML line '{trim}'")
    return data, errors, seen

def token_flat_map(node, prefix=''):
    result = OrderedDict()
    if isinstance(node, dict):
        for key, value in node.items():
            if key.startswith('$'):
                continue
            path = f'{prefix}.{key}' if prefix else key
            if isinstance(value, dict) and '$type' in value:
                result[path] = value
            elif isinstance(value, dict):
                result.update(token_flat_map(value, path))
    return result

def token_refs(value):
    refs = set()
    if isinstance(value, str):
        m = re.fullmatch(r'\{(.+)\}', value)
        if m:
            refs.add(m.group(1))
    elif isinstance(value, dict):
        for k, v in value.items():
            if k.startswith('$'):
                continue
            refs.update(token_refs(v))
    elif isinstance(value, list):
        for item in value:
            refs.update(token_refs(item))
    return refs

config = section('config')
structure = section('structure')
tokens = section('tokens')
collisions = section('collisions')

config_path = repo_root / '.sheen.yml'
config_display_path = '.sheen.yml'
if not config_path.exists() and (repo_root / '.sheen.yml.example').exists():
    config_path = repo_root / '.sheen.yml.example'
    config_display_path = '.sheen.yml.example'

config_data, config_errors, config_seen = parse_sheen_config(config_path)
for err in config_errors:
    add(config, 'error', err, config_display_path)

source = config_data.get('source')
ref = config_data.get('ref')
if not source:
    add(config, 'error', 'Missing required key source', config_display_path)
if not ref:
    add(config, 'error', 'Missing required key ref', config_display_path)

def asset_names(path: Path, pattern, transform=lambda p: p.name):
    if not path.exists():
        return set()
    return {transform(p) for p in path.glob(pattern)}

source_layout = (repo_root / 'skills').exists() or (repo_root / 'agents').exists() or (repo_root / 'tokens').exists()
skill_path = 'skills' if source_layout else '.github/skills'
agent_path = 'agents' if source_layout else '.github/agents'
instruction_path = 'instructions' if source_layout else '.github/instructions'
prompt_path = 'prompts' if source_layout else '.github/prompts'
template_path = 'templates' if source_layout else 'sheen/templates'
token_path = 'tokens' if source_layout else 'sheen/tokens'

skills = asset_names(repo_root / skill_path, '*', lambda p: p.name) if (repo_root / skill_path).exists() else set()
agents = asset_names(repo_root / agent_path, '*.agent.md', lambda p: p.name[:-9]) if (repo_root / agent_path).exists() else set()
instructions = asset_names(repo_root / instruction_path, '*.instructions.md', lambda p: p.name[:-15]) if (repo_root / instruction_path).exists() else set()
themes = asset_names(repo_root / token_path / 'themes', '*.tokens.json', lambda p: p.name[:-12]) if (repo_root / token_path / 'themes').exists() else set()

for key, names in [('skills', skills), ('agents', agents), ('instructions', instructions), ('themes', themes)]:
    if key in config_seen:
        for item in config_data.get(key, []):
            if item and item not in names:
                add(config, 'error', f"Allow-list entry '{item}' for {key} does not match any synced asset", config_display_path)

required_dirs = [
    (skill_path, 'skills' not in config_seen or len(config_data.get('skills', [])) > 0),
    (agent_path, 'agents' not in config_seen or len(config_data.get('agents', [])) > 0),
    (instruction_path, 'instructions' not in config_seen or len(config_data.get('instructions', [])) > 0),
    (prompt_path, True),
    (template_path, True),
    (token_path, True),
    (f'{token_path}/core', True),
    (f'{token_path}/semantic', True),
    (f'{token_path}/themes', 'themes' not in config_seen or len(config_data.get('themes', [])) > 0),
]
for path_str, required in required_dirs:
    if required and not (repo_root / path_str).exists():
        add(structure, 'error', 'Expected directory missing after sync', path_str)
    elif verbose and not required and (repo_root / path_str).exists():
        add(structure, 'warn', 'Optional directory present', path_str)

for skill_dir in sorted((repo_root / skill_path).glob('*')) if (repo_root / skill_path).exists() else []:
    if not skill_dir.is_dir():
        continue
    skill_file = skill_dir / 'SKILL.md'
    eval_file = skill_dir / 'eval.yaml'
    if not skill_file.exists():
        add(structure, 'error', 'Missing SKILL.md', rel(skill_dir))
        continue
    if not eval_file.exists():
        add(structure, 'error', 'Missing eval.yaml', rel(skill_dir))
    fm = frontmatter_lines(skill_file)
    if not fm:
        add(structure, 'error', 'Missing valid frontmatter', rel(skill_file))
        continue
    name = fm_scalar(fm, 'name')
    if not name:
        add(structure, 'error', 'Missing frontmatter name', rel(skill_file))
    elif name != skill_dir.name:
        add(structure, 'error', f"Frontmatter name '{name}' must match folder '{skill_dir.name}'", rel(skill_file))
    desc = fm_scalar(fm, 'description')
    if not desc:
        add(structure, 'error', 'Missing description', rel(skill_file))
    else:
        if 'USE FOR:' not in desc:
            add(structure, 'error', "Description missing 'USE FOR:' trigger phrases", rel(skill_file))
        if 'DO NOT USE FOR:' not in desc:
            add(structure, 'error', "Description missing 'DO NOT USE FOR:' anti-triggers", rel(skill_file))
    for ref_skill in fm_list(fm, 'skills'):
        if ref_skill not in skills:
            add(structure, 'error', f"Composed skill '{ref_skill}' does not resolve to an existing synced skill", rel(skill_file))
    for ref_instruction in fm_list(fm, 'instructions'):
        if ref_instruction not in instructions:
            add(structure, 'error', f"Composed instruction '{ref_instruction}' does not resolve to an existing synced instruction", rel(skill_file))
    if eval_file.exists():
        txt = eval_file.read_text(encoding='utf-8')
        pos = len(re.findall(r'expect_activation:\s*true', txt))
        neg = len(re.findall(r'expect_activation:\s*false', txt))
        if pos < 3 or neg < 2:
            add(structure, 'error', 'eval.yaml requires at least 3 positive and 2 negative scenarios', rel(eval_file))

for agent_file in sorted((repo_root / agent_path).glob('*.agent.md')) if (repo_root / agent_path).exists() else []:
    expected = agent_file.name[:-9]
    fm = frontmatter_lines(agent_file)
    if not fm:
        add(structure, 'error', 'Missing valid frontmatter', rel(agent_file))
        continue
    name = fm_scalar(fm, 'name')
    if not name:
        add(structure, 'error', 'Missing frontmatter name', rel(agent_file))
    elif name != expected:
        add(structure, 'error', f"Frontmatter name '{name}' must match file name '{expected}'", rel(agent_file))
    if not fm_scalar(fm, 'description'):
        add(structure, 'error', 'Missing description', rel(agent_file))
    for ref_skill in fm_list(fm, 'skills'):
        if ref_skill not in skills:
            add(structure, 'error', f"Composed skill '{ref_skill}' does not resolve to an existing synced skill", rel(agent_file))
    for ref_instruction in fm_list(fm, 'instructions'):
        if ref_instruction not in instructions:
            add(structure, 'error', f"Composed instruction '{ref_instruction}' does not resolve to an existing synced instruction", rel(agent_file))
    if not (agent_file.parent / f'{expected}.agent.eval.yaml').exists():
        add(structure, 'error', 'Missing eval file', rel(agent_file))

for ins_file in sorted((repo_root / instruction_path).glob('*.instructions.md')) if (repo_root / instruction_path).exists() else []:
    expected = ins_file.name[:-15]
    fm = frontmatter_lines(ins_file)
    if not fm:
        add(structure, 'error', 'Missing valid frontmatter', rel(ins_file))
        continue
    if not re.match(r'^sheen-\d{2}-[a-z0-9-]+\.instructions\.md$', ins_file.name):
        add(structure, 'error', 'Invalid instruction naming convention', rel(ins_file))
    if fm_scalar(fm, 'name') != expected:
        add(structure, 'error', 'Frontmatter name does not match file name', rel(ins_file))
    if not fm_scalar(fm, 'description'):
        add(structure, 'error', 'Missing description', rel(ins_file))
    if not fm_scalar(fm, 'applyTo'):
        add(structure, 'error', 'Missing applyTo', rel(ins_file))
    if not fm_scalar(fm, 'band'):
        add(structure, 'error', 'Missing metadata.band', rel(ins_file))
    if not fm_scalar(fm, 'layer'):
        add(structure, 'error', 'Missing metadata.layer', rel(ins_file))

core_map = OrderedDict()
semantic_map = OrderedDict()
theme_map = OrderedDict()
token_root = repo_root / token_path
if token_root.exists():
    token_files = list(token_root.rglob('*.tokens.json'))
    parsed = {}
    for file in token_files:
        try:
            parsed[file] = json.loads(file.read_text(encoding='utf-8'))
        except Exception as exc:
            add(tokens, 'error', f'Invalid JSON: {exc}', rel(file))
            continue
        flat = token_flat_map(parsed[file])
        relf = rel(file)
        if relf.startswith(f'{token_path}/core/'):
            for key in flat:
                for ref in token_refs(flat[key].get('$value')):
                    add(tokens, 'error', f"Core token '{key}' contains an alias reference '{{{ref}}}'", relf)
            core_map.update(flat)
        elif relf.startswith(f'{token_path}/semantic/'):
            for key in flat:
                for ref in token_refs(flat[key].get('$value')):
                    if ref not in core_map:
                        add(tokens, 'error', f"Semantic token '{key}' references missing core token '{{{ref}}}'", relf)
            semantic_map.update(flat)
        elif relf.startswith(f'{token_path}/themes/'):
            theme_map.update(flat)

    expected_themes = config_data.get('themes', ['light', 'dark', 'high-contrast']) if config_data.get('themes') else ['light', 'dark', 'high-contrast']
    for theme_name in expected_themes:
        if not (token_root / 'themes' / f'{theme_name}.tokens.json').exists():
            add(tokens, 'error', 'Expected theme file missing', rel(token_root / 'themes' / f'{theme_name}.tokens.json'))

    semantic_keys = set(semantic_map.keys())
    for theme_file in (token_root / 'themes').glob('*.tokens.json') if (token_root / 'themes').exists() else []:
        theme_name = theme_file.name[:-12]
        if config_data.get('themes') and theme_name not in config_data.get('themes', []):
            continue
        flat = token_flat_map(parsed.get(theme_file, {}))
        relf = rel(theme_file)
        for key in semantic_keys:
            if key not in flat:
                add(tokens, 'error', f"Theme is missing semantic token '{key}'", relf)
        for key in flat:
            if key not in semantic_map:
                add(tokens, 'error', f"Theme introduces non-semantic token '{key}'", relf)
        for key in flat:
            for ref in token_refs(flat[key].get('$value')):
                def resolve(ref_name, seen=None):
                    if seen is None:
                        seen = set()
                    if ref_name in seen:
                        return None
                    seen.add(ref_name)
                    for scope in (flat, semantic_map, core_map):
                        if ref_name in scope:
                            for nested in token_refs(scope[ref_name].get('$value')):
                                if resolve(nested, seen) is None:
                                    return None
                            return scope[ref_name].get('$value')
                    return '__MISSING__'
                resolved = resolve(ref)
                if resolved == '__MISSING__':
                    add(tokens, 'error', f"Theme token '{key}' references missing token '{{{ref}}}'", relf)
                elif resolved is None:
                    add(tokens, 'error', f"Theme token '{key}' contains a circular reference through '{{{ref}}}'", relf)

if (repo_root / 'vendor/basecoat').exists():
    vendor_skills = asset_names(repo_root / 'vendor/basecoat/skills', '*', lambda p: p.name) if (repo_root / 'vendor/basecoat/skills').exists() else set()
    vendor_agents = asset_names(repo_root / 'vendor/basecoat/agents', '*.agent.md', lambda p: p.name[:-9]) if (repo_root / 'vendor/basecoat/agents').exists() else set()
    for name in skills:
        if name.startswith('basecoat-'):
            add(collisions, 'error', f"Reserved prefix conflict: local skill '{name}' must not use basecoat-* naming", skill_path)
        if name in vendor_skills:
            add(collisions, 'error', f'Duplicate skill name collides with vendored basecoat: {name}', skill_path)
    for name in agents:
        if name.startswith('basecoat-'):
            add(collisions, 'error', f"Reserved prefix conflict: local agent '{name}' must not use basecoat-* naming", agent_path)
        if name in vendor_agents:
            add(collisions, 'error', f'Duplicate agent name collides with vendored basecoat: {name}', agent_path)

sections = [config, structure, tokens, collisions]
summary = OrderedDict(pass_=0, warn=0, error=0, exit_code=0)
for sec in sections:
    if sec['status'] == 'pass':
        summary['pass_'] += 1
    elif sec['status'] == 'warn':
        summary['warn'] += 1
    else:
        summary['error'] += 1
summary['exit_code'] = 1 if summary['error'] else 0

report = OrderedDict([
    ('timestamp', now_utc()),
    ('config', OrderedDict(valid=config['valid'], source=config_data.get('source'), ref=config_data.get('ref'), skills=len(config_data.get('skills', [])), agents=len(config_data.get('agents', [])), instructions=len(config_data.get('instructions', [])), themes=len(config_data.get('themes', [])), messages=config['messages'])),
    ('structure', OrderedDict(valid=structure['valid'], messages=structure['messages'])),
    ('tokens', OrderedDict(valid=tokens['valid'], themes=config_data.get('themes', ['light', 'dark', 'high-contrast']) if config_data.get('themes') else ['light', 'dark', 'high-contrast'], resolution=OrderedDict(core=len(core_map), semantic=len(semantic_map), themes=len(theme_map)), messages=tokens['messages'])),
    ('collisions', OrderedDict(found=(collisions['status'] == 'error'), details=collisions['messages'], messages=collisions['messages'])),
    ('summary', OrderedDict(pass_=summary['pass_'], warn=summary['warn'], error=summary['error'], exit_code=summary['exit_code']))
])

if json_mode:
    # Match the requested schema keys closely, while keeping the output valid JSON.
    report['summary']['pass'] = report['summary'].pop('pass_')
    report['config']['valid'] = bool(report['config']['valid'])
    report['structure']['valid'] = bool(report['structure']['valid'])
    report['tokens']['valid'] = bool(report['tokens']['valid'])
    print(json.dumps(report, indent=None))
else:
    print(f"sheen diagnostics: {summary['pass_']} pass, {summary['warn']} warn, {summary['error']} error")
    for sec in sections:
        print(f"[{sec['status'].upper()}] {sec['name']}")
        for msg in sec['messages']:
            prefix = {'pass': '[PASS]', 'warn': '[WARN]', 'error': '[ERROR]'}[msg['level']]
            if msg.get('path'):
                print(f"{prefix} {msg['path']} - {msg['message']}")
            else:
                print(f"{prefix} {msg['message']}")
    if summary['error'] == 0:
        print('Recommendations: keep the allow-lists pinned, re-run after each sync, and capture the JSON report in CI.')
    elif config['status'] == 'error':
        print('Recommendations: fix .sheen.yml first, then re-run diagnostics.')
    elif tokens['status'] == 'error':
        print('Recommendations: repair token references and theme completeness before rollout.')
    elif collisions['status'] == 'error':
        print('Recommendations: rename the colliding local asset or narrow the sync allow-list.')

sys.exit(summary['exit_code'])
PY
