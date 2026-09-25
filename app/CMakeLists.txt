cmake_minimum_required(VERSION 3.24)

project(qlizzie LANGUAGES CXX)

include(CTest)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick)

qt_standard_project_setup(REQUIRES 6.9)

qt_add_executable(qlizzie
    src/appsettings.cpp
    src/appsettings.h
    src/enginecontroller.cpp
    src/enginecontroller.h
    src/engineanalysis.cpp
    src/engineanalysis.h
    src/candidatelayer.cpp
    src/candidatelayer.h
    src/engineprotocol.cpp
    src/engineprotocol.h
    src/main.cpp
    src/fileio.cpp
    src/fileio.h
    src/gomokuforbidden.cpp
    src/gomokuforbidden.h
)

set_target_properties(qlizzie PROPERTIES
    WIN32_EXECUTABLE TRUE
)

qt_add_qml_module(qlizzie
    URI QLizzie
    VERSION 1.0
    QML_FILES
        qml/AboutDialog.qml
        qml/AnalysisStatus.js
        qml/AnalysisCache.js
        qml/AnalysisSession.qml
        qml/AppButton.qml
        qml/AppCheckMark.qml
        qml/AppCheckBox.qml
        qml/AppComboBox.qml
        qml/AppDialog.qml
        qml/AppDialogFooter.qml
        qml/AppPopup.qml
        qml/AppRadioChoice.qml
        qml/AppScrollBar.qml
        qml/AppSpinBox.qml
        qml/AppTextArea.qml
        qml/AppTextField.qml
        qml/AppWindowDialog.qml
        qml/ApplicationMenuBar.qml
        qml/AnalysisToolbar.qml
        qml/BoardSizeDialog.qml
        qml/BoardSizeStepper.qml
        qml/BoardInteraction.js
        qml/BoardRenderer.js
        qml/BoardVisuals.js
        qml/BoardInputLayer.qml
        qml/BoardScene.qml
        qml/BranchPanel.qml
        qml/CandidateAnalysis.js
        qml/CandidateModel.js
        qml/CanvasTextCache.js
        qml/CandidateTable.js
        qml/CandidateListWindow.qml
        qml/CandidateMarkerView.qml
        qml/CommandToolbar.qml
        qml/CommonRulesPopup.qml
        qml/ConfirmDeleteNodeDialog.qml
        qml/CoordinateUtils.js
        qml/EnginePresets.js
        qml/EngineSpeed.js
        qml/EngineLogFormatter.js
        qml/EnginePlay.js
        qml/EngineSync.js
        qml/EngineSession.qml
        qml/EngineSessionState.js
        qml/EngineListDialog.qml
        qml/EngineSupport.js
        qml/EngineCommunicationWindow.qml
        qml/EngineFailureDialog.qml
        qml/EngineParametersDialog.qml
        qml/EngineRuleWarningDialog.qml
        qml/BeginnerTutorialDialog.qml
        qml/GameOverDialog.qml
        qml/GoRuleDialog.qml
        qml/GomokuRuleDialog.qml
        qml/NoRuleVariantDialog.qml
        qml/GameRuleComboBox.qml
        qml/GameRules.js
        qml/GameSession.qml
        qml/GameTree.js
        qml/HelpKeysDialog.qml
        qml/HiddenSettingsDialog.qml
        qml/InitialSetupDialog.qml
        qml/InfoPanel.qml
        qml/Main.qml
        qml/MovePreview.js
        qml/Ownership.js
        qml/RuleSupport.js
        qml/RuleChangeSaveDialog.qml
        qml/RuleSettingsPage.qml
        qml/RuleSelectionPopup.qml
        qml/SavePromptButton.qml
        qml/SettingsDialog.qml
        qml/SettingsStore.js
        qml/SettingsSchema.js
        qml/SgfSession.js
        qml/SgfUtils.js
        qml/Translations.js
        qml/TreeLayout.js
        qml/UnsavedSgfDialog.qml
        qml/WindowGeometry.js
        qml/rules/RuleCatalog.js
        qml/rules/RuleRegistry.js
        qml/rules/RulePreferences.js
)

qt_add_resources(qlizzie qlizzie_icons
    PREFIX "/"
    FILES
        resources/qlizzie-logo.png
        resources/qlizzie-logo.svg
)

qt_add_resources(qlizzie qlizzie_fonts
    PREFIX "/"
    FILES
        resources/fonts/JetBrainsMono-Regular.ttf
        resources/fonts/JetBrainsMono-OFL.txt
)

target_link_libraries(qlizzie
    PRIVATE
        Qt6::Core
        Qt6::Quick
)

if(BUILD_TESTING)
    find_package(Qt6 QUIET COMPONENTS QuickTest)
    if(TARGET Qt6::QuickTest)
        qt_add_executable(qlizzie_qml_tests
            tests/qmltests.cpp
            src/candidatelayer.cpp
            src/candidatelayer.h
        )
        target_include_directories(qlizzie_qml_tests PRIVATE src)
        set_target_properties(qlizzie_qml_tests PROPERTIES WIN32_EXECUTABLE FALSE)
        target_link_libraries(qlizzie_qml_tests PRIVATE Qt6::QuickTest Qt6::Quick)
    endif()
    find_package(Qt6 QUIET COMPONENTS Test)
    if(TARGET Qt6::Test)
        qt_add_executable(qlizzie_core_tests
            tests/coretests.cpp
            src/enginecontroller.cpp
            src/enginecontroller.h
            src/engineanalysis.cpp
            src/engineanalysis.h
            src/engineprotocol.cpp
            src/engineprotocol.h
            src/fileio.cpp
            src/fileio.h
        )

        target_include_directories(qlizzie_core_tests PRIVATE src)
        target_link_libraries(qlizzie_core_tests PRIVATE Qt6::Core Qt6::Test)

        add_test(NAME qlizzie_core_tests COMMAND qlizzie_core_tests)
        if(WIN32)
            set_tests_properties(qlizzie_core_tests PROPERTIES
                ENVIRONMENT_MODIFICATION
                    "PATH=path_list_prepend:$<TARGET_FILE_DIR:Qt6::Core>"
            )
        endif()
    endif()
endif()

if(WIN32)
    enable_language(RC)

    target_sources(qlizzie
        PRIVATE
            resources/qlizzie.rc
    )
    if(COMMAND qlizzie_enable_local_copy)
        qlizzie_enable_local_copy(qlizzie "bin/qlizzie.exe")
    endif()
endif()
