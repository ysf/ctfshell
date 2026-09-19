#!/usr/bin/env python3
"""Check the staged snapshot, never print matched private values."""
import pathlib
import re
import subprocess
import sys
import tempfile


def git(*args):
    return subprocess.check_output(['git', *args])


def main():
    root = pathlib.Path(git('rev-parse', '--show-toplevel').decode().strip())
    allow = {
        line[2:] for line in git('show', ':.gitignore').decode().splitlines()
        if line.startswith('!/') and not line.endswith('/')
    }
    private = []
    config = root / 'config.local.yaml'
    if config.exists():
        for line in config.read_text().splitlines():
            match = re.match(r'^(domain|ctf_user|ssh_key_name):\s*[\"\']?([^\"\'\s#]+)', line)
            if match:
                value = match[2]
                if value not in ('example.com', 'ctf'):
                    private.append(value.encode().lower())
    origin = subprocess.run(
        ['git', 'config', '--get', 'remote.origin.url'], capture_output=True, text=True
    ).stdout.strip()
    public_repo = re.fullmatch(
        r'(?:git@github\.com:|https://github\.com/)([\w.-]+/[\w.-]+?)(?:\.git)?', origin
    )
    with tempfile.TemporaryDirectory(prefix='public-check-') as directory:
        for entry in git('ls-files', '--stage', '-z').split(b'\0'):
            if not entry:
                continue
            metadata, raw_path = entry.split(b'\t', 1)
            mode, oid, stage = metadata.split()
            path = raw_path.decode()
            if path not in allow or mode not in (b'100644', b'100755') or stage != b'0':
                sys.exit('blocked: unreviewed path, symlink, submodule or merge conflict: ' + path)
            data = git('cat-file', 'blob', oid.decode())
            identifiers = data.lower()
            # The selected public repository URL is intentional, not a host identifier.
            if path == 'README.md' and public_repo:
                repo = public_repo[1].lower().encode()
                identifiers = identifiers.replace(b'https://github.com/' + repo + b'.git', b'')
                identifiers = identifiers.replace(b'git@github.com:' + repo + b'.git', b'')
            if any(value in identifiers or value in raw_path.lower() for value in private):
                sys.exit('blocked: private identifier in ' + path)
            destination = pathlib.Path(directory) / path
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(data)
        result = subprocess.run(
            ['gitleaks', 'dir', '--redact', '--no-banner', directory],
            capture_output=True,
        )
        if result.returncode:
            sys.exit('blocked: gitleaks failed or found a secret; inspect locally with gitleaks dir --redact')
    print('public snapshot: allowlist, private identifiers and gitleaks passed')


if __name__ == '__main__':
    main()
