#!/usr/bin/env python3
"""Real sync/Git integration; fixture builder is not DTCG validation.

If powershell-yaml is unavailable, only the three fixture config scalars are
decoded by a strict test-local shim. Sync, ignore decisions and Git are real.
All fixtures (including sync clone TEMP/TMP/TMPDIR) stay under repository dist/.
"""
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import unittest
import uuid

ROOT = Path(__file__).resolve().parent.parent
BASH = r"C:\Program Files\Git\bin\bash.exe" if os.name == "nt" else "bash"
OUTPUTS = tuple(f"dist/tokens/{name}" for name in
                ("sheen.css", "sheen.js", "sheen.esm.js", "sheen.d.ts"))
RULES = "".join(f"/{path}\n" for path in OUTPUTS).encode()
SENTINELS = ("dist/app.txt", "dist/tokens/app.js", "dist/tokens/sheen.css.map",
             "app/dist/tokens/sheen.css", ".agents/skills/other/SKILL.md",
             "sheen/tokens/custom.json", "sheen/templates/custom.txt", ".sheen/consumer-state")


def run(args, cwd, env=None, check=True):
    result = subprocess.run(args, cwd=cwd, env=env, capture_output=True,
                            text=True, encoding="utf-8", errors="replace", timeout=90)
    if check and result.returncode:
        raise AssertionError(f"{args}: exit {result.returncode}\n{result.stdout}{result.stderr}")
    return result


def git(repo, *args):
    return run(["git", "-C", str(repo), *args], ROOT).stdout


def write(root, name, content):
    path = root / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content if isinstance(content, bytes) else content.encode())


def remove_fixture(root):
    def retry(function, path, error):
        if not isinstance(error[1], PermissionError):
            raise error[1]
        os.chmod(path, stat.S_IWRITE | stat.S_IREAD)
        function(path)
    shutil.rmtree(root, onerror=retry)


def init(repo):
    repo.mkdir()
    git(repo, "init", "--quiet", "-b", "main")
    git(repo, "config", "user.name", "Fixture")
    git(repo, "config", "user.email", "fixture@example.invalid")
    git(repo, "config", "core.autocrlf", "false")
    excludes = repo.parent / "empty-excludes"
    excludes.touch()
    git(repo, "config", "core.excludesFile", excludes.as_posix())


class TokenHygieneTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = ROOT / "dist" / f"token-hygiene-tests-{uuid.uuid4().hex}"
        cls.root.mkdir(parents=True)
        cls.addClassCleanup(remove_fixture, cls.root)
        clone_temp = cls.root / "clone-temp"
        clone_temp.mkdir()
        global_config = cls.root / "empty-gitconfig"
        global_config.touch()
        cls.env = dict(os.environ, TEMP=str(clone_temp), TMP=str(clone_temp),
                       TMPDIR=clone_temp.as_posix(), GIT_CONFIG_NOSYSTEM="1",
                       GIT_CONFIG_GLOBAL=global_config.as_posix())
        for key in ("SHEEN_REPO", "SHEEN_REF", "GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE"):
            cls.env.pop(key, None)
        cls.upstream = cls.root / "upstream"
        init(cls.upstream)
        write(cls.upstream, "tokens/fixture.json", '{"fixture": "source token payload"}\n')
        write(cls.upstream, "templates/fixture.txt", "source template\n")
        write(cls.upstream, "scripts/build-tokens.ps1", """param([string]$TokensDir, [string]$OutDir)
$ErrorActionPreference = 'Stop'
if (-not [System.IO.File]::Exists((Join-Path $TokensDir 'fixture.json'))) { throw 'Missing token source' }
[void][System.IO.Directory]::CreateDirectory($OutDir)
foreach ($name in @('sheen.css', 'sheen.js', 'sheen.esm.js', 'sheen.d.ts')) {
    [System.IO.File]::WriteAllText((Join-Path $OutDir $name), "regenerated $name`n")
}
""")
        git(cls.upstream, "add", "-A")
        git(cls.upstream, "commit", "--quiet", "-m", "Minimal local upstream")
        probe = run(["pwsh", "-NoProfile", "-NonInteractive", "-Command",
                     "if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) { exit 0 }; exit 3"],
                    ROOT, cls.env, check=False)
        if probe.returncode not in (0, 3):
            raise AssertionError(probe.stdout + probe.stderr)
        cls.launcher = cls.root / "run-sync.ps1"
        shim = ""
        if probe.returncode == 3:
            print("Boundary: powershell-yaml absent; strict fixture-only scalar decoder enabled.", flush=True)
            shim = r"""
function ConvertFrom-Yaml {
    param([Parameter(ValueFromPipeline)][string]$Yaml)
    process {
        $result = @{}
        foreach ($line in ($Yaml -split "`n")) {
            if (-not $line.Trim()) { continue }
            if ($line -notmatch '^(source|ref|materialize_tokens): (.+)$') {
                throw "Unsupported fixture config: $line"
            }
            $result[$Matches[1]] = $Matches[2].Trim()
        }
        return $result
    }
}
"""
        else:
            print("Boundary: real ConvertFrom-Yaml available; no config shim.", flush=True)
        cls.launcher.write_text(shim + "\n& $args[0]\n", encoding="utf-8")
        cls.mutants = {}
        for engine, invocation in (("ps1", "            Protect-GeneratedTokens\n"),
                                   ("sh", "    protect_generated_tokens\n")):
            source = (ROOT / f"sync.{engine}").read_text(encoding="utf-8")
            if source.count(invocation) != 1:
                raise AssertionError("Negative mutation must remove exactly one real hygiene invocation")
            mutant = cls.root / f"old-behavior-sync.{engine}"
            mutant.write_text(source.replace(invocation, ""), encoding="utf-8", newline="\n")
            cls.mutants[engine] = mutant

    def consumer(self, ignore=None, nested=None, tracked=False, enabled=True):
        repo = self.root / f"consumer-{uuid.uuid4().hex}"
        init(repo)
        write(repo, ".sheen.yml", f"source: {self.upstream.as_posix()}\nref: main\n"
              f"materialize_tokens: {str(enabled).lower()}\n")
        for name in SENTINELS:
            write(repo, name, f"untouched {name}\n")
        if ignore is not None:
            write(repo, ".gitignore", ignore)
        if nested is not None:
            write(repo, "dist/tokens/.gitignore", nested)
        if tracked:
            for name in OUTPUTS:
                write(repo, name, "previously tracked\n")
        git(repo, "add", "-f", ".")
        git(repo, "commit", "--quiet", "-m", "Consumer-owned baseline")
        # Untracked unrelated output must still participate in git add -A.
        write(repo, "dist/tokens/unrelated-new.js", "consumer output\n")
        return repo

    def sync(self, repo, engine, mutant=False):
        script = self.mutants[engine] if mutant else ROOT / f"sync.{engine}"
        args = (["pwsh", "-NoProfile", "-NonInteractive", "-File", str(self.launcher), str(script)]
                if engine == "ps1" else [BASH, script.as_posix()])
        result = run(args, repo, self.env)
        return result.stdout + result.stderr

    def assert_preserved(self, repo):
        for name in SENTINELS:
            self.assertEqual((repo / name).read_text(), f"untouched {name}\n")
        self.assertEqual((repo / "sheen/tokens/fixture.json").read_bytes(),
                         (self.upstream / "tokens/fixture.json").read_bytes())
        self.assertEqual((repo / "sheen/templates/fixture.txt").read_text(), "source template\n")
        files = json.loads((repo / ".sheen/manifest.json").read_text(encoding="utf-8-sig"))["files"]
        self.assertIn("sheen/tokens/fixture.json", files)
        self.assertIn("sheen/templates/fixture.txt", files)
        self.assertNotIn(".gitignore", files)
        self.assertTrue(set(OUTPUTS).isdisjoint(files))
        for name in OUTPUTS:
            self.assertEqual((repo / name).read_text(), f"regenerated {Path(name).name}\n")

    def test_real_sync_scenarios(self):
        scenarios = [
            ("missing", None, None, set(), False),
            ("empty", b"", None, set(), False),
            ("existing-partial", b"# app\n*.log\n/dist/tokens/sheen.css\n", None, set(), False),
            ("crlf-bom-no-final-newline", b"\xef\xbb\xbf# consumer\r\n*.log", None, set(), False),
            ("lf-no-final-newline", b"# keep this byte prefix", None, set(), False),
            ("broad", b"# already covered\ndist/\n", None, set(), False),
            ("exact", RULES, None, set(), False),
            ("negated-all", RULES + b"!/dist/tokens/sheen.*\n", None, set(OUTPUTS), False),
            ("negated-one", b"!/dist/tokens/sheen.css\n", None, {OUTPUTS[0]}, False),
            ("nested-override", b"/dist/tokens/*\n", b"!sheen.css\n", {OUTPUTS[0]}, False),
            ("nested-only", None, b"!sheen.js\n", {OUTPUTS[1]}, False),
            ("tracked", None, None, set(), True),
            ("tracked-included", RULES + b"!/dist/tokens/sheen.*\n", None, set(OUTPUTS), True),
        ]
        for engine in ("ps1", "sh"):
            for label, ignore, nested, included, tracked in scenarios:
                with self.subTest(engine=engine, scenario=label):
                    repo = self.consumer(ignore, nested, tracked)
                    index_before = (repo / ".git/index").read_bytes()
                    log = self.sync(repo, engine)
                    self.assertEqual((repo / ".git/index").read_bytes(), index_before)
                    self.assert_preserved(repo)
                    after = (repo / ".gitignore").read_bytes() if (repo / ".gitignore").exists() else None
                    if ignore is not None:
                        self.assertTrue(after.startswith(ignore))
                    if label in ("broad", "exact", "negated-all", "nested-override", "tracked-included"):
                        self.assertEqual(after, ignore)
                    if label == "missing":
                        self.assertEqual(after, RULES)
                    if label == "crlf-bom-no-final-newline":
                        self.assertEqual(after, ignore + b"\r\n" + RULES.replace(b"\n", b"\r\n"))
                    if label == "lf-no-final-newline":
                        self.assertEqual(after, ignore + b"\n" + RULES)
                    if nested is not None:
                        self.assertEqual((repo / "dist/tokens/.gitignore").read_bytes(), nested)
                    for path in OUTPUTS:
                        result = run(["git", "check-ignore", "--no-index", "--quiet", "--", path],
                                     repo, self.env, check=False)
                        self.assertEqual(result.returncode, 1 if path in included else 0, path)
                        if path in included:
                            self.assertIn(f"preserving explicit Git inclusion for {path}", log)
                            verbose = run(["git", "check-ignore", "--no-index", "--verbose", "--", path],
                                          repo, self.env, check=False)
                            self.assertEqual(verbose.returncode, 0, "Verbose negation is success, not ignored")
                    if tracked:
                        for path in OUTPUTS:
                            self.assertIn(f"already tracked: {path}", log)
                            self.assertIn(f"git rm --cached -- {path}", log)
                        self.assertIn("After confirming it regenerates", log)
                    for path in OUTPUTS:
                        write(repo, path, "stale output: repeat must rebuild even when ignored\n")
                    self.sync(repo, engine)
                    self.assertEqual((repo / ".gitignore").read_bytes(), after)
                    self.assertEqual((repo / ".git/index").read_bytes(), index_before)
                    self.assert_preserved(repo)
                    self.assertEqual(run(["git", "check-ignore", "--no-index", "--quiet", "--",
                                          "app/dist/tokens/sheen.css"], repo, self.env,
                                         check=False).returncode, 0 if label == "broad" else 1,
                                     "New rules must be root-anchored; consumer's broad rule stays effective")
                    git(repo, "add", "-A")
                    staged = set(git(repo, "diff", "--cached", "--name-only").splitlines())
                    self.assertEqual(staged.intersection(OUTPUTS), set(OUTPUTS) if tracked else included)
                    if after != ignore:
                        self.assertIn(".gitignore", staged, "Consumer workflow must stage new rules")
                    if label not in ("broad", "nested-override"):
                        self.assertIn("dist/tokens/unrelated-new.js", staged)
                    print(f"PASS {engine}: {label}; index preserved, repeat stable, Git staging verified", flush=True)

    def test_disabled_does_not_edit_ignore_or_build(self):
        for engine in ("ps1", "sh"):
            for ignore in (None, b"\xef\xbb\xbf# consumer\r\n*.log"):
                with self.subTest(engine=engine, ignore=ignore):
                    repo = self.consumer(ignore, enabled=False)
                    before = (repo / ".git/index").read_bytes()
                    self.sync(repo, engine)
                    path = repo / ".gitignore"
                    self.assertEqual(path.read_bytes() if path.exists() else None, ignore)
                    self.assertFalse((repo / "scripts/build-tokens.ps1").exists())
                    self.assertFalse(any((repo / path).exists() for path in OUTPUTS))
                    self.assertEqual((repo / ".git/index").read_bytes(), before)
                    print(f"PASS {engine}: disabled, {'existing' if ignore else 'missing'} ignore untouched", flush=True)

    def test_old_behavior_accidentally_stages_outputs(self):
        for engine in ("ps1", "sh"):
            with self.subTest(engine=engine):
                repo = self.consumer()
                self.sync(repo, engine, mutant=True)
                self.assertFalse((repo / ".gitignore").exists())
                git(repo, "add", "-A")
                staged = set(git(repo, "diff", "--cached", "--name-only").splitlines())
                self.assertTrue(set(OUTPUTS).issubset(staged))
                print(f"PASS {engine}: old-behavior mutation reproduces all four accidental staged outputs", flush=True)


if __name__ == "__main__":
    unittest.main(verbosity=2)
