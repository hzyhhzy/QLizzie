import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AppDialog {
    id: ruleChangeSaveDialog

    property bool explicitClose: false

    modal: true
    title: app.pendingClearTitle()
    closePolicy: Popup.CloseOnEscape
    preferredWidth: Math.max(400, boundedPreferredWidth(480, 80))
    dialogMinimumWidth: Math.min(400, preferredWidth)
    dialogMinimumHeight: Math.min(230, preferredHeight)

    onOpened: explicitClose = false
    onClosed: {
        if (explicitClose) {
            explicitClose = false
            return
        }
        app.clearPendingClearAction()
        app.onSettingsDialogClosed()
        app.focusBoardInput()
    }

    contentItem: Rectangle {
        implicitWidth: 440
        implicitHeight: Math.max(72, messageLabel.implicitHeight + 24)
        color: "#f8fbfd"

        Label {
            id: messageLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            text: app.pendingClearMessage()
            color: "#17212a"
            wrapMode: Text.WordWrap
            font.pixelSize: 15
            lineHeight: 1.12
        }
    }

    footer: AppDialogFooter {
        Item { Layout.fillWidth: true }

        SavePromptButton {
            text: app.trText("save")
            primary: true
            onClicked: {
                ruleChangeSaveDialog.explicitClose = true
                ruleChangeSaveDialog.close()
                app.openSaveSgfDialog(app.saveContinuationPendingAction)
            }
        }

        SavePromptButton {
            text: app.trText("dontSave")
            onClicked: {
                ruleChangeSaveDialog.explicitClose = true
                ruleChangeSaveDialog.close()
                app.applyPendingClearAction()
            }
        }

        SavePromptButton {
            text: app.trText("cancel")
            onClicked: {
                ruleChangeSaveDialog.explicitClose = true
                ruleChangeSaveDialog.close()
                app.clearPendingClearAction()
                app.onSettingsDialogClosed()
                app.focusBoardInput()
            }
        }
    }
}
