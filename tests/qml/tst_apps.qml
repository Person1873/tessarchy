import QtQuick
import QtTest
import "../../shell/AppPolicy.js" as Apps

TestCase {
    name: "PrimaryApplications"
    function entry(id, hidden) { return {id: id, name: id, noDisplay: !!hidden, command: ["test"]}; }
    function test_primary_roles_exclude_helpers_and_duplicate_browsers() {
        const entries = [entry("nm-applet"), entry("qt6ct"), entry("chromium"), entry("firefox.desktop"), entry("org.gnome.Nautilus"), entry("foot"), entry("blueman-manager"), entry("org.gnome.Calculator", true)];
        const selected = Apps.majorApplications(entries).map(e => e.id);
        compare(selected.join(","), "firefox.desktop,org.gnome.Nautilus,blueman-manager,foot");
    }
    function test_missing_and_hidden_apps_use_installed_alternatives() {
        const browser = entry("chromium");
        compare(Apps.majorApplications([entry("firefox", true), browser])[0], browser);
        compare(Apps.majorApplications([]).length, 0);
        compare(Apps.majorApplications([{id: "firefox", command: []}]).length, 0);
    }
}
