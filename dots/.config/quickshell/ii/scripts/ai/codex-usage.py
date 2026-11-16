#!/usr/bin/env python3
import datetime
import json
import os
import shutil
import subprocess
import sys


def get_codex_bin():
    candidates = [
        os.path.expanduser("~/.cargo/bin/codex"),
        shutil.which("codex"),
        "/home/nicho/.cargo/bin/codex",
    ]
    for c in candidates:
        if c and os.path.exists(c) and os.access(c, os.X_OK):
            return c
    return None


def get_auth_cached():
    auth_file = os.path.expanduser("~/.codex/auth.json")
    if not os.path.exists(auth_file):
        return False, ""
    try:
        with open(auth_file, "r", encoding="utf-8") as f:
            data = json.load(f)
            tokens = data.get("tokens", {})
            if tokens.get("access_token") or tokens.get("id_token"):
                id_token = tokens.get("id_token")
                if id_token and "." in id_token:
                    import base64

                    parts = id_token.split(".")
                    if len(parts) >= 2:
                        payload = parts[1] + "=="
                        payload_data = json.loads(
                            base64.urlsafe_b64decode(payload)
                        )
                        email = payload_data.get("email", "")
                        return True, email
                return True, ""
    except Exception:
        pass
    return False, ""


def query_codex_app_server(codex_bin):
    try:
        p = subprocess.Popen(
            [codex_bin, "app-server", "--stdio"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except Exception as e:
        return None, None, str(e)

    # 1. Initialize Handshake
    p.stdin.write(
        json.dumps(
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "clientInfo": {
                        "name": "quickshell-usage",
                        "version": "1.0",
                    }
                },
            }
        )
        + "\n"
    )
    p.stdin.flush()

    # Wait for init response
    for line in p.stdout:
        try:
            if json.loads(line).get("id") == 1:
                break
        except Exception:
            continue

    # 2. Initialized notification & queries
    p.stdin.write(
        json.dumps({"jsonrpc": "2.0", "method": "initialized", "params": {}})
        + "\n"
    )
    p.stdin.write(
        json.dumps(
            {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "account/rateLimits/read",
                "params": {},
            }
        )
        + "\n"
    )
    p.stdin.write(
        json.dumps(
            {"jsonrpc": "2.0", "id": 3, "method": "account/read", "params": {}}
        )
        + "\n"
    )
    p.stdin.flush()

    rate_limits = None
    account_info = None
    seen = 0

    for line in p.stdout:
        try:
            msg = json.loads(line)
        except Exception:
            continue
        msg_id = msg.get("id")
        if msg_id == 2:
            rate_limits = msg.get("result", {}).get("rateLimits", {})
            seen += 1
        elif msg_id == 3:
            account_info = msg.get("result", {}).get("account", {})
            seen += 1
        if seen >= 2:
            break

    try:
        p.terminate()
        p.wait(timeout=2)
    except Exception:
        p.kill()

    return rate_limits, account_info, None


def main():
    codex_bin = get_codex_bin()
    signed_in_cached, user_cached = get_auth_cached()

    if not codex_bin:
        result = {
            "available": False,
            "signedIn": signed_in_cached,
            "user": user_cached,
            "planType": "",
            "primary": None,
            "secondary": None,
        }
        print(json.dumps(result))
        return

    rate_limits, account_info, err = query_codex_app_server(codex_bin)

    signed_in = signed_in_cached
    user_email = user_cached
    if account_info and account_info.get("email"):
        user_email = account_info.get("email")
        signed_in = True

    plan_type = ""
    if account_info and account_info.get("planType"):
        plan_type = account_info.get("planType")
    elif rate_limits and rate_limits.get("planType"):
        plan_type = rate_limits.get("planType")

    def format_window(bucket):
        if not bucket or not isinstance(bucket, dict):
            return None
        mins = bucket.get("windowDurationMins", 0)
        resets_at = bucket.get("resetsAt")
        iso_reset = ""
        if resets_at:
            try:
                iso_reset = datetime.datetime.fromtimestamp(
                    resets_at, tz=datetime.timezone.utc
                ).strftime("%Y-%m-%dT%H:%M:%SZ")
            except Exception:
                pass
        used = bucket.get("usedPercent", 0)
        rem = max(0.0, min(1.0, 1.0 - (used / 100.0)))
        return {
            "usedPercent": used,
            "remainingFraction": rem,
            "windowDurationMins": mins,
            "resetTime": iso_reset,
        }

    primary = format_window(rate_limits.get("primary")) if rate_limits else None
    secondary = (
        format_window(rate_limits.get("secondary")) if rate_limits else None
    )

    result = {
        "available": True,
        "signedIn": signed_in,
        "user": user_email,
        "planType": plan_type,
        "primary": primary,
        "secondary": secondary,
    }
    print(json.dumps(result))


if __name__ == "__main__":
    main()
