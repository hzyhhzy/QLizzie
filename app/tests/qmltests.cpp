#include "candidatelayer.h"

#include <QtQuickTest/quicktest.h>
#include <qqml.h>

class QmlTestSetup : public QObject
{
    Q_OBJECT
public slots:
    void applicationAvailable()
    {
        qmlRegisterType<CandidateLayer>("QLizzie.Rendering", 1, 0, "CandidateLayer");
    }
};

QUICK_TEST_MAIN_WITH_SETUP(qlizzie, QmlTestSetup)
#include "qmltests.moc"
