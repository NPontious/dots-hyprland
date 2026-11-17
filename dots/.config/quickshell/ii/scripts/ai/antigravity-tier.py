#!/usr/bin/env python3
import json
import os
import pty
import re
import select
import sys
import time

CACHE_DIR = os.path.expanduser("~/.cache/quickshell")
CACHE_FILE = os.path.join(CACHE_DIR, "antigravity_tier.json")
CACHE_TTL_SECS = 86400  # 24 hours


def get_cached_info():
    if os.path.exists(CACHE_FILE):
        try:
            mtime = os.path.getmtime(CACHE_FILE)
            if time.time() - mtime < CACHE_TTL_SECS:
                with open(CACHE_FILE, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if data and data.get("tier"):
                        return data
        except Exception:
            pass
    return None


def fetch_from_cli():
    master, slave = pty.openpty()
    pid = os.fork()
    if pid == 0:
        os.close(master)
        os.setsid()
        os.dup2(slave, 0)
        os.dup2(slave, 1)
        os.dup2(slave, 2)
        os.close(slave)
        # Execute agy in pseudo-terminal to trigger interactive banner rendering
        os.execlp("agy", "agy")
    else:
        os.close(slave)
        output = b""
        start = time.time()
        email = ""
        tier = ""
        # agy banner prints within ~1.5s
        while time.time() - start < 3.0:
            r, _, _ = select.select([master], [], [], 0.2)
            if master in r:
                try:
                    data = os.read(master, 1024)
                    if not data:
                        break
                    output += data
                    clean = re.sub(
                        r"\x1b\[[0-9;?]*[a-zA-Z]",
                        "",
                        output.decode("utf-8", errors="ignore"),
                    )
                    if not email:
                        em = re.search(r"([\w\.-]+@[\w\.-]+)", clean)
                        if em:
                            email = em.group(1)
                    # Look for tier inside parentheses in the banner, e.g. (Google AI Pro)
                    tier_match = re.search(
                        r"\((Google AI[^)]*)\)", clean
                    ) or re.search(
                        r"\(([^)]*(?:Pro|Ultra|Plus|Team|Standard)[^)]*)\)",
                        clean,
                    )
                    if tier_match:
                        tier = tier_match.group(1).strip()
                        break
                except OSError:
                    break
        os.close(master)
        try:
            os.kill(pid, 9)
        except Exception:
            pass

        result = {
            "email": email,
            "tier": tier if tier else "Consumer",
        }
        try:
            os.makedirs(CACHE_DIR, exist_ok=True)
            with open(CACHE_FILE, "w", encoding="utf-8") as f:
                json.dump(result, f)
        except Exception:
            pass
        return result


def main():
    force_refresh = "--refresh" in sys.argv
    if not force_refresh:
        cached = get_cached_info()
        if cached:
            print(json.dumps(cached))
            return

    info = fetch_from_cli()
    print(json.dumps(info))


if __name__ == "__main__":
    main()
