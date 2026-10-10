#!/usr/bin/env python3
"""Exercise CI mirror selection/authentication without a network or real credentials."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="artcraft-mirror-test-") as directory:
    fixture = Path(directory)
    fake_git = fixture / "git"
    fake_git.write_text(f"#!{sys.executable}\n" + '''
import json, os, subprocess, sys
from pathlib import Path
args = sys.argv[1:]
record = {"args": args}
if "push" in args:
    helper = os.environ["GIT_ASKPASS"]
    user = subprocess.check_output([helper, "Username for HTTPS:"], text=True).strip()
    password = subprocess.check_output([helper, "Password for HTTPS:"], text=True).strip()
    record["user_valid"] = user in {"x-access-token", "bovfbovf"}
    record["token_valid"] = password == "fixture-mirror-token"
    record["prompt_disabled"] = os.environ["GIT_TERMINAL_PROMPT"] == "0"
    record["helper"] = helper
    if os.environ.get("FAIL_PUSH") == "1":
        sys.exit(7)
with Path(os.environ["GIT_RECORDS"]).open("a") as output:
    output.write(json.dumps(record) + "\\n")
''')
    fake_git.chmod(0o700)
    records = fixture / "records.jsonl"
    base = {k: v for k, v in os.environ.items() if not k.startswith(("CI_", "GITHUB_", "CODEBERG_", "GIT_"))}
    base.update(PATH=f"{fixture}:{os.environ['PATH']}", GIT_RECORDS=str(records),
                CI_PIPELINE_SOURCE="push", CI_COMMIT_BRANCH="main", CI_DEFAULT_BRANCH="main")

    def run(**overrides):
        records.unlink(missing_ok=True)
        result = subprocess.run(["bash", str(root / "ci/mirror.sh")], env=base | overrides,
                                capture_output=True, text=True)
        calls = [json.loads(line) for line in records.read_text().splitlines()] if records.exists() else []
        assert "fixture-mirror-token" not in result.stdout + result.stderr + json.dumps(calls)
        for call in calls:
            if "helper" in call:
                assert not Path(call["helper"]).exists(), "Temporary credential helper must be removed"
        return result, calls

    result, calls = run()
    assert result.returncode == 0 and len(calls) == 1 and "Skipping github" in result.stdout
    for variables in [{"CI_COMMIT_BRANCH": "feature"}, {"CI_PIPELINE_SOURCE": "merge_request_event"},
                      {"CI_PIPELINE_SOURCE": "schedule"}, {"CI_DEFAULT_BRANCH": ""}]:
        result, calls = run(**variables)
        assert result.returncode == 0 and not calls

    tokens = dict(GITHUB_TOKEN="fixture-mirror-token", CODEBERG_TOKEN="fixture-mirror-token")
    result, calls = run(**tokens)
    pushes = [c for c in calls if "push" in c["args"]]
    assert result.returncode == 0 and len(pushes) == 2
    assert calls[0]["args"] == ["checkout", "-B", "main", "origin/main"]
    for call, url in zip(pushes, ["https://github.com/bovf/artcraft-nix.git", "https://codeberg.org/bovfbovf/artcraft-nix.git"]):
        assert call["args"] == ["-c", "credential.helper=", "push", "--force", url, "main:main"]
        assert call["user_valid"] and call["token_valid"] and call["prompt_disabled"]

    result, calls = run(**tokens, GITHUB_MIRROR_REPO="owner/custom", CODEBERG_MIRROR_REPO="other/custom")
    assert result.returncode == 0 and "https://github.com/owner/custom.git" in calls[1]["args"]
    result, calls = run(**tokens, GITHUB_MIRROR_URL="git@github.com:owner/custom.git")
    assert result.returncode == 0 and "git@github.com:owner/custom.git" in calls[1]["args"]
    for url in ["https://x-access-token:fixture-mirror-token@github.com/owner/repo.git", "https://unexpected.example/repo.git"]:
        result, calls = run(**tokens, GITHUB_MIRROR_URL=url)
        assert result.returncode != 0 and not any("push" in c["args"] for c in calls)
    result, calls = run(**tokens, FAIL_PUSH="1")
    assert result.returncode == 7

print("PASS: default-branch gates, skips, destinations, credential-free Git argv, helper cleanup and push failure")
