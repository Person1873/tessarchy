import QtQuick
import Quickshell
import "../../shell/components"

ShellRoot {
    id: root
    CommunicationBackend { id: backend }
    property int step: 0
    Item {
        width: 760; height: 800
        PhoneApp { backend: backend; width: 400 }
        MessagesApp { backend: backend; width: 760 }
        CellularSettings { backend: backend; width: 400 }
        SoundSettings { backend: backend; width: 400 }
    }
    Connections {
        target: backend
        function onCompleted(action, success) {
            if (action === "status" && root.step === 0) {
                root.step = 1;
                backend.request("save-contact", {name: "Example", number: "+12025550123"});
            } else if (action === "save-contact") {
                if (!success || backend.state.contacts.length !== 1 || backend.state.contacts[0].name !== "Example") {
                    console.log("COMMUNICATIONS_TEST_FAIL: contact persistence");
                    Qt.quit();
                    return;
                }
                console.log("COMMUNICATIONS_TEST_PASS");
                Qt.quit();
            }
        }
    }
    Timer {
        interval: 10000; running: true
        onTriggered: { console.log("COMMUNICATIONS_TEST_FAIL: timeout"); Qt.quit(); }
    }
}
