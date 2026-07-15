#include "engineprotocol.h"
#include "fileio.h"

#include <QDir>
#include <QFile>
#include <QTest>
#include <QUrl>

class CoreTests : public QObject
{
    Q_OBJECT

private slots:
    void parsesGtpResponses();
    void rejectsFailedHandshake();
    void keepsUnrelatedResponsesOutOfAnalysisTransaction();
    void rejectsAnalysisWhenAnySyncCommandFails();
    void propagatesMovePreludeFailure();
    void completesAndCancelsMoveRequests();
    void writesTextThroughCommittedSaveFile();
};

void CoreTests::parsesGtpResponses()
{
    const EngineProtocolState::Response success = EngineProtocolState::parseResponse(QStringLiteral(" = D4 "));
    QCOMPARE(success.type, EngineProtocolState::ResponseType::Success);
    QCOMPARE(success.payload, QStringLiteral("D4"));

    const EngineProtocolState::Response error = EngineProtocolState::parseResponse(QStringLiteral("? illegal move"));
    QCOMPARE(error.type, EngineProtocolState::ResponseType::Error);
    QCOMPARE(error.payload, QStringLiteral("illegal move"));

    QVERIFY(!EngineProtocolState::parseResponse(QStringLiteral("info move D4")).isResponse());
}

void CoreTests::rejectsFailedHandshake()
{
    EngineProtocolState state;
    state.beginMove(0, 17);
    state.beginHandshake();

    const EngineProtocolState::Outcome outcome = state.consumeLine(QStringLiteral("? unknown command"));
    QCOMPARE(outcome.event, EngineProtocolState::Event::HandshakeCompleted);
    QVERIFY(!outcome.success);
    QVERIFY(!state.handshakePending());
    QVERIFY(!state.acceptsCandidateInfo());

    const EngineProtocolState::Outcome cancelled = state.cancelMove(QStringLiteral("handshake failed"));
    QCOMPARE(cancelled.event, EngineProtocolState::Event::MoveCompleted);
    QCOMPARE(cancelled.requestId, 17);
    QVERIFY(!cancelled.success);
}

void CoreTests::keepsUnrelatedResponsesOutOfAnalysisTransaction()
{
    EngineProtocolState state;
    state.beginAnalysis(1);
    state.expectResponse(EngineProtocolState::ResponseRole::Ignored);
    state.expectResponse(EngineProtocolState::ResponseRole::AnalysisSync);

    const EngineProtocolState::Outcome unrelated = state.consumeLine(QStringLiteral("= initialization"));
    QCOMPARE(unrelated.event, EngineProtocolState::Event::None);
    QVERIFY(unrelated.handled);
    QVERIFY(!state.acceptsCandidateInfo());

    const EngineProtocolState::Outcome synchronized = state.consumeLine(QStringLiteral("="));
    QCOMPARE(synchronized.event, EngineProtocolState::Event::AnalysisSyncCompleted);
    QVERIFY(synchronized.success);
    QVERIFY(state.acceptsCandidateInfo());
}

void CoreTests::rejectsAnalysisWhenAnySyncCommandFails()
{
    EngineProtocolState state;
    state.beginAnalysis(2);
    state.expectResponse(EngineProtocolState::ResponseRole::AnalysisSync);
    state.expectResponse(EngineProtocolState::ResponseRole::AnalysisSync);

    QVERIFY(state.consumeLine(QStringLiteral("= stopped")).handled);
    const EngineProtocolState::Outcome outcome = state.consumeLine(QStringLiteral("? unsupported rules"));

    QCOMPARE(outcome.event, EngineProtocolState::Event::AnalysisSyncCompleted);
    QVERIFY(!outcome.success);
    QCOMPARE(outcome.rawLine, QStringLiteral("? unsupported rules"));
    QVERIFY(!state.acceptsCandidateInfo());
}

void CoreTests::propagatesMovePreludeFailure()
{
    EngineProtocolState state;
    state.beginMove(2, 73);
    state.expectResponse(EngineProtocolState::ResponseRole::MovePrelude);
    const EngineProtocolState::Outcome firstPrelude = state.consumeLine(QStringLiteral("="));
    QCOMPARE(firstPrelude.event, EngineProtocolState::Event::None);
    QVERIFY(firstPrelude.handled);

    state.expectResponse(EngineProtocolState::ResponseRole::MovePrelude);
    const EngineProtocolState::Outcome outcome = state.consumeLine(QStringLiteral("? board mismatch"));

    QCOMPARE(outcome.event, EngineProtocolState::Event::MovePreludeFailed);
    QCOMPARE(outcome.requestId, 73);
    QVERIFY(!outcome.success);
    QCOMPARE(outcome.rawLine, QStringLiteral("? board mismatch"));
    QVERIFY(!state.hasActiveMove());
}

void CoreTests::completesAndCancelsMoveRequests()
{
    EngineProtocolState state;
    state.beginMove(1, 91);
    state.expectResponse(EngineProtocolState::ResponseRole::MovePrelude);
    const EngineProtocolState::Outcome prelude = state.consumeLine(QStringLiteral("="));
    QCOMPARE(prelude.event, EngineProtocolState::Event::None);
    QVERIFY(prelude.handled);

    state.expectResponse(EngineProtocolState::ResponseRole::MoveGenerate);

    const EngineProtocolState::Outcome completed = state.consumeLine(QStringLiteral("="));
    QCOMPARE(completed.event, EngineProtocolState::Event::MoveCompleted);
    QCOMPARE(completed.requestId, 91);
    QVERIFY(completed.success);
    QCOMPARE(completed.payload, QStringLiteral("pass"));

    state.beginMove(0, 92);
    state.expectResponse(EngineProtocolState::ResponseRole::MoveGenerate);
    const EngineProtocolState::Outcome cancelled = state.cancelMove(QStringLiteral("Engine exited (0)"));
    QCOMPARE(cancelled.event, EngineProtocolState::Event::MoveCompleted);
    QCOMPARE(cancelled.requestId, 92);
    QVERIFY(!cancelled.success);
    QCOMPARE(cancelled.rawLine, QStringLiteral("Engine exited (0)"));

    state.expectResponse(EngineProtocolState::ResponseRole::Ignored);
    const EngineProtocolState::Outcome cancelledMoveResponse = state.consumeLine(QStringLiteral("= Q16"));
    QCOMPARE(cancelledMoveResponse.event, EngineProtocolState::Event::None);
    QVERIFY(cancelledMoveResponse.handled);
    const EngineProtocolState::Outcome stopResponse = state.consumeLine(QStringLiteral("="));
    QCOMPARE(stopResponse.event, EngineProtocolState::Event::None);
    QVERIFY(stopResponse.handled);
}

void CoreTests::writesTextThroughCommittedSaveFile()
{
    const QString path = QDir::current().filePath(QStringLiteral("qlizzie-fileio-test.sgf"));
    QFile::remove(path);
    FileIo fileIo;
    QVERIFY2(fileIo.writeTextFile(QUrl::fromLocalFile(path), QStringLiteral("(;GM[1]C[initial])")),
             qPrintable(fileIo.lastError()));
    QCOMPARE(fileIo.lastError(), QString());

    QFile file(path);
    QVERIFY(file.open(QIODevice::ReadOnly));
    QCOMPARE(QString::fromUtf8(file.readAll()), QStringLiteral("(;GM[1]C[initial])"));
    file.close();

    QVERIFY2(fileIo.writeTextFile(QUrl::fromLocalFile(path), QStringLiteral("(;GM[1]C[updated])")),
             qPrintable(fileIo.lastError()));
    QVERIFY(file.open(QIODevice::ReadOnly));
    QCOMPARE(QString::fromUtf8(file.readAll()), QStringLiteral("(;GM[1]C[updated])"));
    file.close();
    QVERIFY(QFile::remove(path));
}

QTEST_APPLESS_MAIN(CoreTests)

#include "coretests.moc"
