import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppDialog {
    id: noRuleVariantDialog

    modal: true
    title: app.trText("noRuleVariantTitle")
    width: Math.min(420, app.width - 42)
    height: Math.min(210, app.height - 42)

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
