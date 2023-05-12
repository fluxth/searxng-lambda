#!/usr/bin/env python3

import re
import json
import subprocess
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
VERSION_FILE = PROJECT_ROOT / "version.json"


def exec(*args, **kwargs) -> str:
    return subprocess.run(
        *args,
        check=True,
        capture_output=True,
        encoding="utf-8",
        **kwargs,
    ).stdout.rstrip('\n')


def extract_runtime_tag() -> str:
    docker_import = exec(
        ["grep", "lambda/python", str(PROJECT_ROOT / "Dockerfile")]
    ).split("\n")[0]

    docker_import_parts = docker_import.split()
    assert len(docker_import_parts) >= 2

    docker_import_name = docker_import_parts[1]
    assert ":" in docker_import_name

    return docker_import_name.rsplit(":", maxsplit=1)[-1]


def extract_searxng_tag() -> str:
    docker_import = exec(
        [
            "grep",
            "DOCKER_TAG",
            str(PROJECT_ROOT / "searxng" / "searx" / "version_frozen.py"),
        ]
    ).split("\n")[0]
    return docker_import.split('"')[1]


if __name__ == "__main__":
    with open(VERSION_FILE, "r") as f:
        version_data = json.load(f)

    runtime_tag = extract_runtime_tag()
    searxng_tag = extract_searxng_tag()

    docker_tag = f"{searxng_tag}-{runtime_tag}"
    assert re.match(r"^[\w\d.-]+$", docker_tag)

    docker_hash = exec(
        ["docker", "images", "--no-trunc", "--quiet", "searxng-lambda:local-latest"]
    )

    revision = version_data["revision"]
    if docker_tag != version_data["docker_tag"]:
        revision = 1
    elif docker_hash != version_data["docker_hash"]:
        revision += 1

    version_string = f"{docker_tag}-{revision}-arm64"

    version_data = {
        "docker_tag": docker_tag,
        "docker_hash": docker_hash,
        "revision": revision,
        "version_string": version_string,
    }

    with open(VERSION_FILE, "w") as f:
        json.dump(version_data, f, indent=4)

    print(version_string)
