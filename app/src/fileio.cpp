#include "fileio.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSaveFile>

FileIo::FileIo(QObject *parent)
    : QObject(parent)
{
}

QString FileIo::lastError() const
{
    return m_lastError;
}

QString FileIo::readTextFile(const QUrl &url)
{
    const QString path = url.isLocalFile() ? url.toLocalFile() : url.toString(QUrl::PreferLocalFile);
    if (path.isEmpty()) {
        setLastError(QStringLiteral("Empty file path."));
        return QString();
    }

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        setLastError(file.errorString());
        return QString();
    }

    const QByteArray bytes = file.readAll();
    if (file.error() != QFile::NoError) {
        setLastError(file.errorString());
        return QString();
    }

    setLastError(QString());
    return QString::fromUtf8(bytes);
}

bool FileIo::writeTextFile(const QUrl &url, const QString &text)
{
    const QString path = url.isLocalFile() ? url.toLocalFile() : url.toString(QUrl::PreferLocalFile);
    if (path.isEmpty()) {
        setLastError(QStringLiteral("Empty file path."));
        return false;
    }

    const QFileInfo info(path);
    const QDir dir = info.absoluteDir();
    if (!dir.exists() && !QDir().mkpath(dir.absolutePath())) {
        setLastError(QStringLiteral("Cannot create directory: %1").arg(dir.absolutePath()));
        return false;
    }

    QSaveFile file(path);
    file.setDirectWriteFallback(false);
    if (!file.open(QIODevice::WriteOnly)) {
        setLastError(file.errorString());
        return false;
    }

    const QByteArray bytes = text.toUtf8();
    if (file.write(bytes) != bytes.size()) {
        setLastError(file.errorString());
        return false;
    }

    if (!file.commit()) {
        setLastError(file.errorString());
        return false;
    }

    setLastError(QString());
    return true;
}

void FileIo::setLastError(const QString &message)
{
    if (m_lastError == message)
        return;

    m_lastError = message;
    emit lastErrorChanged();
}
