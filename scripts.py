#!/usr/bin/env python3
"""Neovim config manager with full uninstall - cross-platform."""

import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path


def get_dirs() -> tuple[Path, Path, Path]:
    cfg = Path(__file__).parent.resolve()
    if platform.system() == "Windows":
        localappdata = Path(
            os.getenv("LOCALAPPDATA") or r"~\AppData\Local"
        ).expanduser()
        data_base = Path(os.getenv("XDG_DATA_HOME") or localappdata).expanduser()
        state_base = Path(os.getenv("XDG_STATE_HOME") or localappdata).expanduser()
        data = data_base / "nvim-data"
        state = state_base / "nvim-data"
    else:
        data = (
            Path(os.getenv("XDG_DATA_HOME") or "~/.local/share").expanduser() / "nvim"
        )
        state = (
            Path(os.getenv("XDG_STATE_HOME") or "~/.local/state").expanduser() / "nvim"
        )
    return cfg, data, state


def run_git(cfg: Path) -> bool:
    try:
        res = subprocess.run(
            ["git", "pull", "--rebase", "--autostash"],
            cwd=cfg,
            capture_output=True,
            text=True,
            check=True,
        )
        out = res.stdout.strip()
        if out and "Already up to date." not in out:
            print(f"[+] Updated:\n    {out}")
            return True
        print("[+] Already up to date")
        return False
    except subprocess.CalledProcessError as e:
        print(f"[-] Git failed: {e.stderr.strip()}")
        sys.exit(1)


def clean_plugins(data: Path, state: Path, force: bool = False) -> None:
    candidates = [
        ("plugins", data / "site" / "pack"),
        ("resonance state", state / "resonance"),
    ]
    targets = [(name, path) for name, path in candidates if path.exists()]
    if not targets:
        print("[+] No plugin or resonance state directories found")
        return
    if not force:
        paths = ", ".join(str(path) for _, path in targets)
        print(f"[-] Use --force to delete: {paths}")
        sys.exit(1)
    for name, path in targets:
        print(f"[*] Removing {name}: {path}")
        shutil.rmtree(path, ignore_errors=True)
        print(f"[+] Cleaned {name}")


def clean_data(data: Path, state: Path, force: bool = False) -> None:
    targets = []
    if data.exists():
        targets.append(("share", data))
    if state != data and state.exists():
        targets.append(("state", state))
    if not targets:
        print("[+] No data/state directories found")
        return
    if not force:
        print("[-] Use --force to delete data/state directories")
        sys.exit(1)
    for name, path in targets:
        print(f"[*] Removing {name}: {path}")
        shutil.rmtree(path, ignore_errors=True)
        print(f"[+] Cleaned {name}")


def clean_config(cfg: Path, force: bool = False) -> None:
    if not cfg.exists():
        print("[+] Config directory does not exist")
        return
    if not force:
        print(f"[-] Use --force to delete config: {cfg}")
        sys.exit(1)
    print(f"[*] Removing config: {cfg}")
    script_path = Path(__file__).resolve()
    if script_path.is_relative_to(cfg):
        print("[!] Script is inside config dir - removing other files only")
        for item in cfg.iterdir():
            if item != Path(__file__).resolve():
                shutil.rmtree(
                    item, ignore_errors=True
                ) if item.is_dir() else item.unlink()
    else:
        shutil.rmtree(cfg, ignore_errors=True)
    print("[+] Cleaned config")


def full_uninstall(cfg: Path, data: Path, state: Path, force: int) -> None:
    if force < 2:
        print("[-] Full uninstall requires --force twice (e.g., --force --force)")
        sys.exit(1)
    print("[!] FULL UNINSTALL - removing everything:")
    clean_config(cfg, force=True)
    clean_data(data, state, force=True)


def main():
    import argparse

    p = argparse.ArgumentParser(description="Neovim Config Manager")
    p.add_argument("action", choices=["update", "clean", "both", "uninstall"])
    p.add_argument(
        "--force",
        action="count",
        default=0,
        help="Force destructive actions (use twice for uninstall)",
    )
    args = p.parse_args()

    cfg, data, state = get_dirs()

    if args.action in ("update", "both"):
        run_git(cfg)
    if args.action in ("clean", "both"):
        clean_plugins(data, state, force=args.force > 0)
    if args.action == "uninstall":
        full_uninstall(cfg, data, state, force=args.force)


if __name__ == "__main__":
    main()
