// Emergency lock screen (Syn's Noctalia): shown if the chosen qylock theme fails to load,
// so the lock can always be unlocked with your password.
import QtQuick
import QtQuick.Controls
import Quickshell

FocusScope {
    id: root
    anchors.fill: parent
    focus: true

    Rectangle { anchors.fill: parent; color: "#0b0b10" }

    Column {
        anchors.centerIn: parent
        spacing: 18
        width: 360

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#e8e6f0"; font.pixelSize: 72; font.weight: Font.Light
            text: Qt.formatTime(new Date(), "HH:mm")
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.text = Qt.formatTime(new Date(), "HH:mm") }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#8f8ca0"; font.pixelSize: 14
            text: "Locked (theme failed to load). Enter your password."
        }
        TextField {
            id: pw
            width: parent.width
            focus: true
            echoMode: TextInput.Password
            placeholderText: "Password"
            horizontalAlignment: TextInput.AlignHCenter
            color: "#e8e6f0"
            background: Rectangle { radius: 10; color: "#1a1a24"; border.color: pw.activeFocus ? "#a7c8ff" : "#33334a" }
            onAccepted: { status.text = "Checking…"; sddm.login(Quickshell.env("USER"), text, 0) }
        }
        Text { id: status; anchors.horizontalCenter: parent.horizontalCenter; color: "#eb6f92"; font.pixelSize: 14; text: "" }
    }

    Connections {
        target: sddm
        function onLoginFailed() { status.text = "Wrong password"; pw.text = ""; pw.forceActiveFocus() }
    }
    Component.onCompleted: pw.forceActiveFocus()
}
