pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var preferences
    required property string activeMode
    required property int displayWidth
    required property int displayHeight
    property color accentColor: Theme.accent
    // tessarchy-theme list rows: { name, mode, background, foreground, accent }.
    property var themes: []
    property string currentTheme: ""
    signal themeRequested(string name)
    signal endSessionRequested
    signal controlsRequested
    signal replayRequested
    spacing: 20

    RowLayout {
        Layout.fillWidth: true
        BrandMark {
            id: previewBrand
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            playOnStart: false
            reducedMotion: page.preferences.reducedMotion
        }
        ColumnLayout {
            Layout.fillWidth: true
            Text {
                text: "TESSARCHY"
                color: Theme.text
                font {
                    pixelSize: 20
                    bold: true
                    letterSpacing: 2
                }
            }
            Text {
                text: "One shell. Every screen."
                color: Theme.textMuted
                font.pixelSize: 13
            }
        }
    }
    Text {
        text: "WORKSPACE MODE"
        color: page.accentColor
        font {
            pixelSize: 11
            bold: true
            letterSpacing: 2
        }
    }
    Text {
        text: page.displayWidth + " × " + page.displayHeight + " logical pixels · " + page.activeMode
        color: Theme.textMuted
        font.pixelSize: 13
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
    GridLayout {
        columns: width >= 560 ? 4 : 2
        columnSpacing: 10
        rowSpacing: 10
        Layout.fillWidth: true
        Repeater {
            model: [
                {
                    value: "auto",
                    label: "Automatic",
                    icon: "auto"
                },
                {
                    value: "phone",
                    label: "Phone",
                    icon: "phone"
                },
                {
                    value: "tablet",
                    label: "Tablet",
                    icon: "tablet"
                },
                {
                    value: "desktop",
                    label: "Desktop",
                    icon: "desktop"
                }
            ]
            delegate: AppTile {
                required property var modelData
                text: modelData.label
                symbol: modelData.icon
                selected: page.preferences.layoutMode === modelData.value
                accentColor: page.accentColor
                implicitHeight: 100
                onClicked: {
                    page.preferences.layoutMode = modelData.value;
                    page.preferences.sync();
                }
            }
        }
    }
    Text {
        text: "Automatic follows the usable display size, including rotation. Override it to keep a layout. New apps fill Phone/Tablet layouts; Desktop starts apps tiled. Existing windows stay in place."
        color: Theme.textMuted
        font.pixelSize: 13
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
    Text {
        text: "APPEARANCE"
        color: page.accentColor
        font {
            pixelSize: 11
            bold: true
            letterSpacing: 2
        }
    }
    Text {
        text: "Theme · shell, keyboard and apps"
        color: Theme.textSecondary
        font.pixelSize: 14
    }
    GridLayout {
        columns: width >= 560 ? 3 : 2
        columnSpacing: 10
        rowSpacing: 10
        Layout.fillWidth: true
        Repeater {
            model: page.themes
            delegate: TouchButton {
                id: themeButton
                required property var modelData
                text: modelData.name
                Accessible.name: "Theme " + modelData.name
                selected: page.currentTheme === modelData.name
                accentColor: modelData.accent
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                // Each button previews its theme's own palette.
                contentItem: Text {
                    text: themeButton.modelData.name
                    color: themeButton.modelData.foreground
                    font.pixelSize: 15
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    radius: 12
                    color: themeButton.modelData.background
                    border.width: themeButton.selected ? 3 : 1
                    border.color: themeButton.selected ? themeButton.modelData.accent : Theme.selection
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 6
                        width: parent.width * 0.4
                        height: 4
                        radius: 2
                        color: themeButton.modelData.accent
                    }
                }
                onClicked: page.themeRequested(modelData.name)
            }
        }
    }
    Text {
        text: "Bar opacity · " + Math.round(page.preferences.barOpacity * 100) + "%"
        color: Theme.textSecondary
        font.pixelSize: 14
    }
    LevelSlider {
        from: 0.1
        to: 1
        value: page.preferences.barOpacity
        Layout.fillWidth: true
        Layout.minimumHeight: 56
        focusPolicy: Qt.NoFocus
        accentColor: page.accentColor
        Accessible.name: "Bar opacity"
        onMoved: page.preferences.barOpacity = value
    }
    Text {
        text: "Wallpaper shade · " + Math.round(page.preferences.wallpaperDim * 100) + "%"
        color: Theme.textSecondary
        font.pixelSize: 14
    }
    LevelSlider {
        from: 0
        to: 0.75
        value: page.preferences.wallpaperDim
        Layout.fillWidth: true
        Layout.minimumHeight: 56
        focusPolicy: Qt.NoFocus
        accentColor: page.accentColor
        Accessible.name: "Wallpaper shade"
        onMoved: page.preferences.wallpaperDim = value
    }
    TouchButton {
        text: page.preferences.showLabels ? "Navigation labels · On" : "Navigation labels · Off"
        selected: page.preferences.showLabels
        accentColor: page.accentColor
        Layout.fillWidth: true
        onClicked: {
            page.preferences.showLabels = !page.preferences.showLabels;
            page.preferences.sync();
        }
    }
    TouchButton {
        text: page.preferences.use24Hour ? "Clock · 24 hour" : "Clock · 12 hour"
        Layout.fillWidth: true
        onClicked: {
            page.preferences.use24Hour = !page.preferences.use24Hour;
            page.preferences.sync();
        }
    }
    Text {
        text: "MOTION"
        color: page.accentColor
        font {
            pixelSize: 11
            bold: true
            letterSpacing: 2
        }
    }
    TouchButton {
        text: page.preferences.reducedMotion ? "Reduced motion · On" : "Reduced motion · Off"
        selected: page.preferences.reducedMotion
        accentColor: page.accentColor
        Layout.fillWidth: true
        onClicked: {
            page.preferences.reducedMotion = !page.preferences.reducedMotion;
            page.preferences.sync();
        }
    }
    RowLayout {
        Layout.fillWidth: true
        BrandMark {
            id: motionPreview
            Layout.preferredWidth: 80
            Layout.preferredHeight: 80
            playOnStart: false
            reducedMotion: page.preferences.reducedMotion
        }
        TouchButton {
            text: "Replay logo"
            enabled: !page.preferences.reducedMotion
            Layout.fillWidth: true
            onClicked: {
                previewBrand.replay();
                motionPreview.replay();
                page.replayRequested();
            }
        }
    }
    Text {
        text: "SYSTEM"
        color: page.accentColor
        font {
            pixelSize: 11
            bold: true
            letterSpacing: 2
        }
    }
    TouchButton {
        text: "Sound & connections"
        Layout.fillWidth: true
        onClicked: page.controlsRequested()
    }
    TouchButton {
        text: "Session…"
        Layout.fillWidth: true
        onClicked: page.endSessionRequested()
    }
    Text {
        text: "Tessera 0.1 · Experimental Arch session"
        color: Theme.textMuted
        font.pixelSize: 12
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
}
