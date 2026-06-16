#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>

#ifdef Q_OS_WIN
#include <qt_windows.h>
#endif

#include "appsettings.h"
#include "enginecontroller.h"
#include "fileio.h"
#include "gomokuforbidden.h"

namespace {

bool launchedInnerPortableAppDirectly()
{
#ifdef Q_OS_WIN
    const QString appDirPath = QCoreApplication::applicationDirPath();
    const QFileInfo appDirInfo(appDirPath);
    if (appDirInfo.fileName().compare(QStringLiteral("bin"), Qt::CaseInsensitive) != 0)
        return false;

    return qEnvironmentVariable("QLIZZIE_LAUNCHED_BY_LAUNCHER") != QStringLiteral("1");
#else
    return false;
#endif
}

void showLauncherRequiredMessage()
{
#ifdef Q_OS_WIN
    MessageBoxW(nullptr,
                L"请从上一级目录的 QLizzie.exe 启动，不要直接打开 bin\\qlizzie.exe。\n\n"
                L"Please start QLizzie.exe from the package root instead of running bin\\qlizzie.exe directly.",
                L"QLizzie",
                MB_ICONINFORMATION | MB_OK);
#endif
}

} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("QLizzie"));
    QCoreApplication::setApplicationName(QStringLiteral("QLizzie"));
    app.setWindowIcon(QIcon(QStringLiteral(":/resources/qlizzie-logo.png")));

    if (launchedInnerPortableAppDirectly()) {
        showLauncherRequiredMessage();
        return 1;
    }

    QQmlApplicationEngine engine;
    AppSettings appSettings;
    FileIo fileIo;
    EngineController engineController;
    GomokuForbidden gomokuForbidden;
    engine.rootContext()->setContextProperty(QStringLiteral("appSettings"), &appSettings);
    engine.rootContext()->setContextProperty(QStringLiteral("fileIo"), &fileIo);
    engine.rootContext()->setContextProperty(QStringLiteral("engineController"), &engineController);
    engine.rootContext()->setContextProperty(QStringLiteral("gomokuForbidden"), &gomokuForbidden);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.load(QUrl(QStringLiteral("qrc:/QLizzie/qml/Main.qml")));

    return app.exec();
}
