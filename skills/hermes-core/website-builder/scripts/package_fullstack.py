#!/usr/bin/env python3
"""Package fetch-v1 sites without putting private backend code in public files.

This only builds an artifact. It never publishes, obtains credentials or executes
backend code. Publishing policy is enforced by the service.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile
import zipfile


def package(static, backend, output, max_files=None, max_artifact_size=None):
    # Deprecated arguments remain accepted for older callers; the service enforces policy.
    static, backend, output = Path(static).resolve(), Path(backend).resolve(), Path(output).absolute()
    if not static.is_dir() or not backend.is_file():
        raise ValueError('static directory and backend file required')
    if backend.is_relative_to(static) or output.resolve().is_relative_to(static):
        raise ValueError('backend and output must be outside the public tree')
    if output.exists():
        raise ValueError('output already exists; preserve previous artifacts for rollback')
    if backend.stat().st_size > 1024 * 1024:
        raise ValueError('backend bundle exceeds 1 MiB')
    code = backend.read_bytes()
    if not code:
        raise ValueError('empty backend bundle')
    code.decode('utf-8')
    index = static / 'index.html'
    if not index.is_file() or index.stat().st_size > 2 * 1024 * 1024:
        raise ValueError('index.html required and must not exceed 2 MiB')
    index_body = index.read_bytes()
    if not any(quote + b'__LIGHTVELA_RELEASE_ID__' + quote in index_body for quote in (b'"', b"'")):
        raise ValueError('index.html must pin __LIGHTVELA_RELEASE_ID__ as a quoted value')
    files = []
    for path in sorted(static.rglob('*')):
        name = path.relative_to(static).as_posix()
        if path.is_symlink():
            raise ValueError('symlinks are forbidden')
        if path.is_dir():
            continue
        if not path.is_file() or name.startswith('__backend/'):
            raise ValueError('reserved or unsupported public file')
        if any(part in ('.git', '.ssh') or part.startswith('.env') for part in path.relative_to(static).parts):
            raise ValueError('private configuration in public tree')
        if path.suffix.lower() in ('.pem', '.key', '.p12', '.pfx'):
            raise ValueError('private credential file in public tree')
        files.append((name, path))
    output.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix='.website-', suffix='.zip', dir=output.parent)
    os.close(fd)
    try:
        with zipfile.ZipFile(temp, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for name, path in files + [('__backend/app.mjs', backend)]:
                info = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.create_system = 3
                info.external_attr = 0o100644 << 16
                with archive.open(info, 'w') as dest, path.open('rb') as source:
                    while chunk := source.read(1024 * 1024):
                        dest.write(chunk)
        size = os.path.getsize(temp)
        digest = hashlib.sha256()
        with open(temp, 'rb') as source:
            while chunk := source.read(1024 * 1024):
                digest.update(chunk)
        # Exclusive hard link prevents accidentally overwriting a previous bundle.
        os.link(temp, output)
        return {'kind': 'fullstack', 'backend_sha256': hashlib.sha256(code).hexdigest(),
                'artifact_hash': digest.hexdigest(), 'artifact_size': size, 'file_count': len(files) + 1}
    finally:
        os.unlink(temp)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--static-dir', required=True)
    parser.add_argument('--backend', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--max-files', type=int, help=argparse.SUPPRESS)
    parser.add_argument('--max-artifact-size', type=int, help=argparse.SUPPRESS)
    args = parser.parse_args()
    try:
        result = package(args.static_dir, args.backend, args.output, args.max_files, args.max_artifact_size)
    except (OSError, ValueError) as exc:
        parser.error(str(exc))
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))


if __name__ == '__main__':
    main()
