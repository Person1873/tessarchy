import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def load_tessy():
    spec = importlib.util.spec_from_file_location("tessy_notify", ROOT / "scripts/tessy-notify.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


tessy = load_tessy()
SERVER = "https://github.com"
REPO = "thediamondsaint/tessarchy"


class Tessy(unittest.TestCase):
    def test_push_announcement_lists_commits_and_caps_long_pushes(self):
        commits = [{"id": "a" * 40, "message": f"change {i}\n\nbody", "url": f"{SERVER}/{REPO}/commit/{i}"}
                   for i in range(8)]
        event = {"ref": "refs/heads/main", "head_commit": {"id": "b" * 40}, "pusher": {"name": "dev"},
                 "commits": commits}
        payload = tessy.build_message("push", event, SERVER, REPO)
        embed = payload["embeds"][0]
        self.assertEqual(payload["username"], "Tessy")
        self.assertIn("main", embed["title"])
        self.assertIn("change 0", embed["description"])
        self.assertNotIn("body", embed["description"])
        self.assertIn("and 3 more commit(s)", embed["description"])

    def test_pull_request_states_map_to_distinct_colors(self):
        base = {"number": 7, "title": "Add thing", "html_url": f"{SERVER}/{REPO}/pull/7",
                "user": {"login": "dev"}, "body": "Summary line\n\nMore"}
        opened = tessy.build_message("pull_request", {"action": "opened", "pull_request": base},
                                     SERVER, REPO)["embeds"][0]
        self.assertEqual(opened["title"], "Opened PR #7: Add thing")
        self.assertEqual(opened["description"], "Summary line")
        merged = tessy.build_message("pull_request",
                                     {"action": "closed", "pull_request": dict(base, merged=True)},
                                     SERVER, REPO)["embeds"][0]
        self.assertTrue(merged["title"].startswith("Merged PR #7"))
        closed = tessy.build_message("pull_request",
                                     {"action": "closed", "pull_request": dict(base, merged=False)},
                                     SERVER, REPO)["embeds"][0]
        self.assertIn("without merging", closed["title"])
        self.assertNotEqual(merged["color"], closed["color"])

    def test_release_and_unannounced_events(self):
        release = tessy.build_message("release",
                                      {"action": "published",
                                       "release": {"tag_name": "v1", "html_url": f"{SERVER}/{REPO}/releases/tag/v1",
                                                   "prerelease": True, "body": "notes"}},
                                      SERVER, REPO)["embeds"][0]
        self.assertIn("prerelease v1", release["title"])
        self.assertIsNone(tessy.build_message("release", {"action": "edited", "release": {}}, SERVER, REPO))
        self.assertIsNone(tessy.build_message("watch", {}, SERVER, REPO))
        self.assertEqual(tessy.short("abcdef1234"), "abcdef1")

    def test_bot_transport_is_preferred_and_drops_the_username(self):
        url, headers, transform = tessy.transport({"DISCORD_BOT_TOKEN": "t0ken",
                                                   "DISCORD_CHANNEL_ID": "123",
                                                   "DISCORD_WEBHOOK_URL": "https://example/hook"})
        self.assertEqual(url, "https://discord.com/api/v10/channels/123/messages")
        self.assertEqual(headers["Authorization"], "Bot t0ken")
        self.assertNotIn("username", transform({"username": "Tessy", "embeds": []}))

    def test_webhook_transport_and_missing_transport(self):
        url, headers, transform = tessy.transport({"DISCORD_WEBHOOK_URL": "https://example/hook"})
        self.assertEqual(url, "https://example/hook")
        self.assertNotIn("Authorization", headers)
        self.assertIn("username", transform({"username": "Tessy"}))
        self.assertEqual(tessy.transport({}), (None, None, None))
        # A token without a channel falls back rather than posting nowhere.
        self.assertEqual(tessy.transport({"DISCORD_BOT_TOKEN": "t"}), (None, None, None))


if __name__ == "__main__":
    unittest.main()
