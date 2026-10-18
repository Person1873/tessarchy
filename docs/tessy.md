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

## Transports

Tessy uses the first transport that is configured:

1. **Bot** — `DISCORD_BOT_TOKEN` + `DISCORD_CHANNEL_ID`.
2. **Webhook** — `DISCORD_WEBHOOK_URL`.

## Option A — bot account

Use this when you cannot create a channel webhook. Inviting a bot needs the
**Manage Server** permission on the server; after that the token is yours and no
per-channel permission is required.

1. Open <https://discord.com/developers/applications> → **New Application**, name
   it `Tessy`.
2. **Bot** tab → **Add Bot** → **Reset Token** → copy the token.
3. **OAuth2 → URL Generator**: scope `bot`, permissions **Send Messages** and
   **Embed Links**. Open the generated URL, choose the server, **Authorize**.
4. Enable **Developer Mode** in Discord (User Settings → Advanced), then
   right-click the target channel → **Copy Channel ID**.
5. Add repository secrets: `DISCORD_BOT_TOKEN` (the token) and
   `DISCORD_CHANNEL_ID` (the channel id).

A bot cannot set a per-message name, so rename the application/bot to `Tessy`
in the Developer Portal to control the display name.

## Option B — channel webhook

Needs the **Manage Webhooks** permission in the channel.

1. **Edit Channel → Integrations → Webhooks → New Webhook**, name it `Tessy`,
   copy the URL.
2. Add the repository secret `DISCORD_WEBHOOK_URL`.

## Adding secrets

Repository: **Settings → Secrets and variables → Actions → New repository
secret**. From a terminal (the value is hidden, never echoed):

```bash
gh secret set DISCORD_BOT_TOKEN --repo thediamondsaint/tessarchy
gh secret set DISCORD_CHANNEL_ID --repo thediamondsaint/tessarchy
# or
gh secret set DISCORD_WEBHOOK_URL --repo thediamondsaint/tessarchy
```

Secrets are only readable inside Actions, so forked pull-request runs never
post. Until a transport is configured the job runs and skips with a notice, so
an unconfigured channel never turns a push red.

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
