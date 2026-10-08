#!/usr/bin/env python3
"""
Neovim Configuration Updater & Manager
A standalone script to safely update the Git repository and manage Neovim plugins.
"""

import os
import platform
import shutil
import subprocess
import sys


def get_paths():
    """Resolve Neovim config and data directories based on the OS."""
    # Since this script is in the nvim config root, we can get the exact config path
    config_dir = os.path.dirname(os.path.abspath(__file__))

    system = platform.system()
    if system == "Windows":
        localappdata = os.environ.get(
            "LOCALAPPDATA", os.path.expanduser("~\\AppData\\Local")
        )
        data_dir = os.path.join(localappdata, "nvim-data")
    else:
        # Linux / macOS
        data_home = os.environ.get(
            "XDG_DATA_HOME", os.path.expanduser("~/.local/share")
        )
        data_dir = os.path.join(data_home, "nvim")

    return config_dir, data_dir


def run_git_update(config_dir):
    """Run git pull with rebase and autostash."""
    print("\n[*] Fetching latest updates from Git...")
    try:
        if not os.path.exists(os.path.join(config_dir, ".git")):
            print("[-] Error: This directory is not a Git repository.")
            return False

        result = subprocess.run(
            ["git", "pull", "--rebase", "--autostash"],
            cwd=config_dir,
            capture_output=True,
            text=True,
            check=True,
        )

        output = result.stdout.strip()
        print("[+] Git pull successful!")
        if output:
            print(f"    {output}")

        if "Already up to date." not in output:
            print("\n[!] IMPORTANT: The repository was updated.")
            print(
                "[!] If 'updater.py' was changed, the current running script is outdated."
            )
            print(
                "[!] Exiting to ensure you use the latest updater logic on the next run."
            )
            return True

        return False

    except subprocess.CalledProcessError as e:
        print("[-] Git update failed! Please resolve conflicts manually.")
        if e.stderr:
            print(f"    Error details: {e.stderr.strip()}")
        return False
    except FileNotFoundError:
        print("[-] Git is not installed or not added to your system PATH.")
        return False


def clean_plugins(data_dir):
    """Delete the plugin directory to wipe out ghost plugins."""
    # Target: ~/.local/share/nvim/site/pack/core (or Windows equivalent)
    target_dir = os.path.join(data_dir, "site", "pack", "core")

    print(f"\n[*] Checking plugin directory: {target_dir}")
    if os.path.exists(target_dir):
        print("    WARNING: This will delete all installed plugins.")
        print("    Resonance.nvim will automatically redownload them on next startup.")
        confirm = input("    Proceed with deletion? (y/n): ").strip().lower()

        if confirm == "y":
            try:
                shutil.rmtree(target_dir)
                print("[+] Successfully wiped plugin directory.")
            except Exception as e:
                print(f"[-] Failed to delete directory: {e}")
        else:
            print("[*] Plugin cleanup cancelled.")
    else:
        print("[+] Plugin directory does not exist. Nothing to clean.")


def main():
    config_dir, data_dir = get_paths()

    while True:
        print("\n=========================================")
        print("    Neovim Configuration Manager")
        print("=========================================")
        print("1. Update Config (Git pull --rebase --autostash)")
        print("2. Clean Plugins (Wipe site/pack/core)")
        print("3. Execute Both (Update & Clean)")
        print("4. Exit")
        print("=========================================")

        choice = input("Select an action (1-4): ").strip()

        if choice == "1":
            was_updated = run_git_update(config_dir)
            if was_updated:
                sys.exit(0)

        elif choice == "2":
            clean_plugins(data_dir)

        elif choice == "3":
            was_updated = run_git_update(config_dir)
            clean_plugins(data_dir)
            if was_updated:
                print("\n[*] Update and clean complete. Exiting for safety...")
                sys.exit(0)

        elif choice == "4":
            print("[*] Exiting...")
            sys.exit(0)
        else:
            print("[-] Invalid choice. Please enter a number between 1 and 4.")

        input("\nPress Enter to continue...")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[*] Interrupted by user. Exiting...")
        sys.exit(0)
