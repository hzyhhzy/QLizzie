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
        qml/CandidateMarkerView.qml
        qml/CommandToolbar.qml
        qml/ConfirmDeleteNodeDialog.qml
        qml/CoordinateUtils.js
        qml/EnginePresets.js
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
        qml/HelpKeysDialog.qml
        qml/HiddenSettingsDialog.qml
        qml/InitialSetupDialog.qml
        qml/InfoPanel.qml
        qml/Main.qml
        qml/RuleSupport.js
        qml/RuleChangeSaveDialog.qml
        qml/RuleSettingsPage.qml
        qml/SavePromptButton.qml
        qml/SettingsDialog.qml
        qml/SettingsStore.js
        qml/SgfSession.js
        qml/SgfUtils.js
        qml/Translations.js
        qml/TreeLayout.js
        qml/UnsavedSgfDialog.qml
        qml/rules/RuleCatalog.js
        qml/rules/RuleRegistry.js
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
    find_package(Qt6 QUIET COMPONENTS Test)
    if(TARGET Qt6::Test)
        qt_add_executable(qlizzie_core_tests
            tests/coretests.cpp
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
endif()
