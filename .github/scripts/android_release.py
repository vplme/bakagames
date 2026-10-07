"""Resolve release metadata without requiring Play credentials or network access."""

import os
import re
import time

EPOCH = 1577836800  # 2020-01-01 UTC; well below Play's 2,100,000,000 limit.


def resolve(event, ref, version, mode, now):
    if event == "push":
        if not ref.startswith("v"):
            raise ValueError("Release tags must start with v")
        version, mode = ref[1:], "upload"
    elif event == "workflow_dispatch":
        version = version.strip().removeprefix("v")
    else:
        raise ValueError("Only version tags and manual releases are supported")
    if not re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", version):
        raise ValueError("Version must be MAJOR.MINOR.PATCH, e.g. 1.0.0")
    if mode not in ("bootstrap", "build-only", "upload"):
        raise ValueError("Unknown release mode")
    code = 1 if mode == "bootstrap" else int(now) - EPOCH
    if not 1 <= code <= 2100000000:
        raise ValueError("Version code is outside Google Play's supported range")
    return {"version": version, "code": str(code), "upload": str(mode == "upload").lower()}


if __name__ == "__main__":
    try:
        values = resolve(
            os.environ["GITHUB_EVENT_NAME"], os.environ["GITHUB_REF_NAME"],
            os.environ.get("VERSION_INPUT", ""), os.environ.get("MODE_INPUT", ""),
            time.time(),
        )
    except ValueError as error:
        raise SystemExit(f"::error::{error}") from error
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        for key, value in values.items():
            output.write(f"{key}={value}\n")
    print(f"Android {values['version']} ({values['code']}), upload={values['upload']}")
