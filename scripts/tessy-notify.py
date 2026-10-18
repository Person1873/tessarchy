#!/usr/bin/env python3
"""Tessy announces repository activity to the project Discord channel.

Posts a Discord message for pushes, pull-request activity and releases. Two
transports are supported:

* bot token -- DISCORD_BOT_TOKEN + DISCORD_CHANNEL_ID (preferred when both set)
* webhook   -- DISCORD_WEBHOOK_URL

Reads a GitHub Actions event from GITHUB_EVENT_PATH. With no transport
configured the script is a no-op so the workflow stays green until the channel
is wired up. See docs/tessy.md.
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

USERNAME = "Tessy"
DISCORD_API = "https://discord.com/api/v10"
USER_AGENT = "Tessy/1.0"
COLORS = {"push": 0x6FD8B8, "merged": 0x57F287, "pr": 0x5865F2,
          "release": 0xFEE75C, "closed": 0xED4245}
MAX_COMMITS = 5


def short(sha, length=7):
    """Return a shortened commit id for display."""
    return (sha or "")[:length]


def repo_url(server, repository):
    """Build the base repository URL."""
    return f"{server}/{repository}"


def build_message(event_name, event, server, repository):
    """Return a webhook payload dict, or None when the event is not announced."""
    url = repo_url(server, repository)
    if event_name == "push":
        branch = (event.get("ref") or "").removeprefix("refs/heads/")
        commits = event.get("commits") or []
        head = event.get("head_commit") or {}
        lines = []
        for commit in commits[:MAX_COMMITS]:
            message = (commit.get("message") or "").splitlines()[0]
            lines.append(f"[`{short(commit.get('id'))}`]({commit.get('url')}) {message}")
        if len(commits) > MAX_COMMITS:
            lines.append(f"and {len(commits) - MAX_COMMITS} more commit(s)")
        description = "\n".join(lines) or "No commit details in this event."
        return {
            "username": USERNAME,
            "embeds": [{
                "title": f"Pushed {len(commits)} commit(s) to {branch}",
                "url": f"{url}/commit/{head.get('id', '')}" if head.get("id") else url,
                "description": description,
                "color": COLORS["push"],
                "footer": {"text": f"{event.get('pusher', {}).get('name', 'someone')} · {repository}"},
            }],
        }
    if event_name == "pull_request":
        action = event.get("action")
        pr = event.get("pull_request") or {}
        merged = bool(pr.get("merged"))
        if action not in ("opened", "reopened", "closed"):
            return None
        if action == "closed" and not merged:
            title = f"Closed PR #{pr.get('number')} without merging"
            color = COLORS["closed"]
        elif merged:
            title = f"Merged PR #{pr.get('number')}: {pr.get('title', '')}"
            color = COLORS["merged"]
        else:
            title = f"{action.capitalize()} PR #{pr.get('number')}: {pr.get('title', '')}"
            color = COLORS["pr"]
        return {
            "username": USERNAME,
            "embeds": [{
                "title": title,
                "url": pr.get("html_url") or url,
                "description": (pr.get("body") or "").splitlines()[0][:280] if pr.get("body") else "",
                "color": color,
                "footer": {"text": f"by {pr.get('user', {}).get('login', 'someone')} · {repository}"},
            }],
        }
    if event_name == "release":
        action = event.get("action")
        release = event.get("release") or {}
        if action != "published":
            return None
        kind = "prerelease" if release.get("prerelease") else "release"
        return {
            "username": USERNAME,
            "embeds": [{
                "title": f"Published {kind} {release.get('tag_name', '')}",
                "url": release.get("html_url") or url,
                "description": (release.get("body") or "")[:280],
                "color": COLORS["release"],
                "footer": {"text": repository},
            }],
        }
    return None


def transport(env):
    """Return (url, headers, transform) for the configured Discord transport."""
    token = env.get("DISCORD_BOT_TOKEN")
    channel = env.get("DISCORD_CHANNEL_ID")
    if token and channel:
        url = f"{DISCORD_API}/channels/{channel}/messages"
        headers = {"Authorization": f"Bot {token}", "Content-Type": "application/json",
                   "User-Agent": USER_AGENT}
        # Bots cannot choose a message username; the bot account name is used.
        return url, headers, lambda payload: {k: v for k, v in payload.items() if k != "username"}
    webhook = env.get("DISCORD_WEBHOOK_URL")
    if webhook:
        return webhook, {"Content-Type": "application/json", "User-Agent": USER_AGENT}, lambda payload: payload
    return None, None, None


def deliver(url, headers, payload, attempts=3):
    """POST the payload, retrying transient failures; return True on success."""
    data = json.dumps(payload).encode()
    request = urllib.request.Request(url, data=data, headers=headers)
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(request, timeout=15) as response:
                return 200 <= response.status < 300
        except (urllib.error.URLError, OSError) as error:
            if attempt == attempts:
                print(f"Tessy could not post: {error}", file=sys.stderr)
                return False
            time.sleep(2 * attempt)
    return False


def main(env=None):
    env = dict(os.environ) if env is None else env
    path = env.get("GITHUB_EVENT_PATH")
    with open(path, encoding="utf-8") as handle:
        event = json.load(handle)
    event_name = env.get("GITHUB_EVENT_NAME", "")
    payload = build_message(event_name, event,
                            env.get("GITHUB_SERVER_URL", "https://github.com"),
                            env.get("GITHUB_REPOSITORY", ""))
    if payload is None:
        print(f"Tessy: nothing to announce for {event_name}")
        return 0
    url, headers, transform = transport(env)
    if url is None:
        print("Tessy: no Discord transport configured; skipping announcement")
        return 0
    if deliver(url, headers, transform(payload)):
        print("Tessy: announcement posted")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
