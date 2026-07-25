import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppWindowDialog {
    id: hiddenDialog

    required property var controller

    modal: true
    title: app.trText("hiddenSettingsTitle")
    closePolicy: Popup.CloseOnEscape
    preferredWidth: boundedPreferredWidth(760, 70)
    preferredHeight: boundedPreferredHeight(640, 70)
    dialogMinimumWidth: Math.min(620, preferredWidth)
    dialogMinimumHeight: Math.min(480, preferredHeight)

    function openDialog() {
        syncFields()
        open()
    }

    function syncFields() {
        packageModeCombo.currentIndex = app.packageMode
    }

    function applyCommunicationLogLimits() {
        app.applyEngineCommunicationLogLimits()
        app.savePersistentSettings()
    }

    onOpened: syncFields()
    onClosed: {
        if (!app.applicationShutdownPrepared)
            app.focusBoardInput()
    }

    dialogBody: ColumnLayout {
        implicitWidth: 700
        implicitHeight: 390
        spacing: 12

        Label {
            Layout.fillWidth: true
            text: app.trText("hiddenSettingsWarning")
            color: "#9b241c"
            font.pixelSize: 15
            font.bold: true
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: app.trText("packageMode")
                color: "#24313a"
                font.pixelSize: 14
                Layout.preferredWidth: 100
            }

            AppComboBox {
                id: packageModeCombo
                model: [
                    app.trText("packageModeUniversal"),
                    app.trText("packageModeGo"),
                    app.trText("packageModeSix")
                ]
                Layout.preferredWidth: 210
                onActivated: function(index) {
                    app.packageMode = index
                    hiddenDialog.syncFields()
                }
            }

            Label {
                text: app.packageModeText(app.packageMode)
                color: "#51616b"
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            AppCheckBox {
                id: ignoreGtpErrorsCheckBox
                text: app.trText("ignoreGtpErrors")
                checked: app.ignoreGtpErrors
                onToggled: app.ignoreGtpErrors = checked
                onClicked: app.savePersistentSettings()
            }

            Label {
                Layout.fillWidth: true
                Layout.leftMargin: ignoreGtpErrorsCheckBox.indicatorSize
                                   + ignoreGtpErrorsCheckBox.spacing
                text: app.trText("ignoreGtpErrorsTip")
                color: "#51616b"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Label {
                text: app.trText("candidateTableRowLimit")
                color: "#24313a"
                Layout.fillWidth: true
            }

            AppSpinBox {
                from: 1
                to: app.maxCandidateTableRowLimit
                editable: true
                value: app.candidateTableRowLimit
                Layout.preferredWidth: 150
                onValueModified: {
                    app.candidateTableRowLimit = value
                    app.savePersistentSettings()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: app.trText("engineLogLimitsTitle")
                color: "#24313a"
                font.pixelSize: 14
                font.bold: true
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 12
                rowSpacing: 8

                Label {
                    text: app.trText("engineLogMaxLines")
                    color: "#24313a"
                    Layout.fillWidth: true
                }

                AppSpinBox {
                    from: 1
                    to: app.maxEngineCommunicationLogLines
                    value: app.engineCommunicationLogLimit
                    Layout.preferredWidth: 150
                    onValueModified: {
                        app.engineCommunicationLogLimit = value
                        hiddenDialog.applyCommunicationLogLimits()
                    }
                }

                Label {
                    text: app.trText("engineLogMaxCharacters")
                    color: "#24313a"
                    Layout.fillWidth: true
                }

                AppSpinBox {
                    from: 1024
                    to: app.maxEngineCommunicationLogCharacters
                    stepSize: 1024
                    value: app.engineCommunicationLogCharacterLimit
                    Layout.preferredWidth: 150
                    onValueModified: {
                        app.engineCommunicationLogCharacterLimit = value
                        hiddenDialog.applyCommunicationLogLimits()
                    }
                }

                Label {
                    text: app.trText("engineLogMaxLineCharacters")
                    color: "#24313a"
                    Layout.fillWidth: true
                }

                AppSpinBox {
                    from: 128
                    to: Math.min(app.maxEngineCommunicationLineCharacters,
                                 Math.max(128,
                                          app.engineCommunicationLogCharacterLimit - 1))
                    stepSize: 128
                    value: app.engineCommunicationLineCharacterLimit
                    Layout.preferredWidth: 150
                    onValueModified: {
                        app.engineCommunicationLineCharacterLimit = value
                        hiddenDialog.applyCommunicationLogLimits()
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: app.trText("engineLogLimitsTip")
                color: "#9b5b18"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            SavePromptButton {
                text: app.trText("close")
                primary: true
                onClicked: hiddenDialog.closeDialog()
            }
        }
    }

}
