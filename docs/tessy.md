# Tessy — Discord announcements

Tessy announces repository activity to the project Discord channel. It is a
GitHub Actions job (`.github/workflows/tessy.yml`) that posts a Discord webhook
message; there is no server to host and no bot token to store.

## What it announces

- **Pushes** to `main`: the number of commits, the head commit link and up to
  five commit summaries.
- **Pull requests**: opened, reopened, merged and closed-without-merge, each
  with the pull request title, link and author.
- **Releases**: a published release or prerelease with its tag and link.

`build/live-iso` synchronizations are not announced separately, because that
branch mirrors `main`.

## Setup

1. In the Discord channel open **Edit Channel → Integrations → Webhooks → New
   Webhook**, name it `Tessy`, and copy the webhook URL.
2. In the repository open **Settings → Secrets and variables → Actions → New
   repository secret**, name it `DISCORD_WEBHOOK_URL`, and paste the URL.

The secret is only readable inside Actions, never in logs or pull request runs
from forks. Until the secret is set the job runs and skips with a notice, so an
unconfigured channel never turns a push red.

## Testing

Send a synthetic event without touching the repository:

```bash
DISCORD_WEBHOOK_URL='<webhook url>' \
GITHUB_EVENT_NAME=push GITHUB_REPOSITORY=thediamondsaint/tessarchy \
GITHUB_SERVER_URL=https://github.com GITHUB_EVENT_PATH=/tmp/event.json \
python3 scripts/tessy-notify.py
```

where `/tmp/event.json` is a saved webhook payload. `tests/test_tessy.py`
covers the payload builder for pushes, pull requests and releases.

## Disabling

Remove the repository secret to stop announcements; the job then skips. Delete
`.github/workflows/tessy.yml` to remove the workflow entirely.
