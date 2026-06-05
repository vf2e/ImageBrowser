#ifndef TESTFIXTURE_H
#define TESTFIXTURE_H

#include <QDir>
#include <QFile>
#include <QObject>
#include <QSettings>
#include <QTemporaryDir>
#include <QUuid>

#include "ImageBrowserBackend.h"

class TestFixture
{
public:
    explicit TestFixture(const QString &settingsKey = QString(),
                         bool clearSettings = true)
        : m_settingsKey(settingsKey.isEmpty()
                            ? QStringLiteral("UnitTest_%1").arg(QUuid::createUuid().toString())
                            : settingsKey)
    {
        m_tempDir = new QTemporaryDir();
        if (!m_tempDir->isValid()) {
            return;
        }

        if (clearSettings) {
            QSettings settings(QStringLiteral("ImageBrowserTests"), m_settingsKey);
            settings.clear();
            settings.sync();
        }

        m_backend = new ImageBrowserBackend(nullptr,
                                              QStringLiteral("ImageBrowserTests"),
                                              m_settingsKey);
        m_backend->setExportDestRoot(m_tempDir->path() + QStringLiteral("/exports"));
    }

    ~TestFixture()
    {
        delete m_backend;
        delete m_tempDir;
    }

    bool isValid() const { return m_tempDir && m_tempDir->isValid(); }
    ImageBrowserBackend *backend() const { return m_backend; }
    QString rootPath() const { return m_tempDir->path(); }

    QString createFolder(const QString &name) const
    {
        const QString path = rootPath() + QLatin1Char('/') + name;
        QDir().mkpath(path);
        return path;
    }

    QString createImageFile(const QString &folder,
                            const QString &fileName,
                            const QByteArray &content = QByteArray("fake-image")) const
    {
        const QString path = folder + QLatin1Char('/') + fileName;
        QFile file(path);
        if (file.open(QIODevice::WriteOnly)) {
            file.write(content);
            file.close();
        }
        return path;
    }

    QString writeTextFile(const QString &folder,
                          const QString &fileName,
                          const QString &content) const
    {
        const QString path = folder + QLatin1Char('/') + fileName;
        QFile file(path);
        if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            file.write(content.toUtf8());
            file.close();
        }
        return path;
    }

    bool fileExists(const QString &path) const
    {
        return QFile::exists(path);
    }

    QString readTextFile(const QString &path) const
    {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            return QString();
        }
        return QString::fromUtf8(file.readAll());
    }

private:
    QTemporaryDir *m_tempDir = nullptr;
    ImageBrowserBackend *m_backend = nullptr;
    QString m_settingsKey;
};

#endif // TESTFIXTURE_H
