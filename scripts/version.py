#!/usr/bin/env python3

import subprocess
import sys
from pathlib import Path
from dataclasses import dataclass

PROJECT_ROOT = Path(__file__).parent.parent
ENV_PREFIX = "SEARXNG_LAMBDA"


@dataclass
class Version:
    major: int
    minor: int
    patch: int

    def __str__(self) -> str:
        return f"{self.major}.{self.minor}.{self.patch}"


def exec(*args, **kwargs) -> str:
    return subprocess.run(
        *args,
        check=True,
        capture_output=True,
        encoding="utf-8",
        **kwargs,
    ).stdout.rstrip("\n")


def extract_runtime_tag() -> tuple[str, str]:
    with open(PROJECT_ROOT / "Dockerfile", "r") as f:
        for line in f.read().splitlines():
            if "lambda/python" in line:
                image = [part for part in line.split() if "lambda/python" in part][0]
                tag = image.split("@")[0].rsplit(":", maxsplit=1)

                return (tag[0], tag[1])

    raise Exception("Could not extract runtime tag")


def extract_searxng_version() -> str:
    with open(PROJECT_ROOT / "searxng" / "searx" / "version_frozen.py", "r") as f:
        for line in f.read().splitlines():
            if "VERSION_STRING" in line:
                return line.split('"')[1]

    raise Exception("Could not extract searxng version")


def get_git_tags() -> list[Version]:
    result = exec(["git", "tag", "-l"])
    tags = [r for r in result.split("\n") if r != ""]

    versions = []
    for tag in tags:
        tag_parts = tag.split(".")
        if len(tag_parts) != 3:
            continue

        versions.append(
            Version(
                major=int(tag_parts[0]),
                minor=int(tag_parts[1]),
                patch=int(tag_parts[2]),
            )
        )

    return sorted(versions, key=lambda i: (i.major, i.minor, i.patch))


if __name__ == "__main__":
    latest_version = get_git_tags()[-1]
    print(f"{ENV_PREFIX}_LATEST_VERSION={str(latest_version)}")

    if len(sys.argv) > 1:
        if sys.argv[1] == "--bump":
            if len(sys.argv) < 3:
                print(f"usage: {sys.argv[0]} --bump [major,minor,patch]")
                exit(1)

            bump_type = sys.argv[2]

            next_version = latest_version
            match bump_type:
                case "major":
                    next_version.major += 1
                    next_version.minor = 0
                    next_version.patch = 0
                case "minor":
                    next_version.minor += 1
                    next_version.patch = 0
                case "patch":
                    next_version.patch += 1
                case _:
                    raise Exception(f"Unknown bump type: {bump_type}")

            print(f"{ENV_PREFIX}_NEXT_VERSION={str(next_version)}")

    runtime_image, runtime_tag = extract_runtime_tag()
    print(f"{ENV_PREFIX}_RUNTIME_IMAGE={runtime_image}")
    print(f"{ENV_PREFIX}_RUNTIME_TAG={runtime_tag}")
    print(f"{ENV_PREFIX}_APP_IMAGE=searxng/searxng")
    print(f"{ENV_PREFIX}_APP_VERSION={extract_searxng_version()}")
