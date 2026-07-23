import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppDialog {
    id: noRuleVariantDialog

    modal: true
    title: app.trText("noRuleVariantTitle")
    preferredWidth: boundedPreferredWidth(420, 42)
    preferredHeight: boundedPreferredHeight(210, 42)
    dialogMinimumWidth: Math.min(360, preferredWidth)
    dialogMinimumHeight: Math.min(180, preferredHeight)

    contentItem: Label {
        text: app.trText("noRuleVariantBody")
        color: "#24313a"
        font.pixelSize: app.compactLayout ? 13 : 14
        wrapMode: Text.WordWrap
        verticalAlignment: Text.AlignVCenter
    }

    footer: AppDialogFooter {
        Item { Layout.fillWidth: true }
        AppButton {
            id: okButton

            text: noRuleVariantDialog.app.trText("confirm")
            Layout.preferredWidth: 110
            onClicked: noRuleVariantDialog.close()
        }
    }
}
