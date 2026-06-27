#ifndef CRITIQUEEVALUATOR_H
#define CRITIQUEEVALUATOR_H

#include <QHash>
#include <QObject>
#include <QProcess>
#include <QString>
#include <functional>

class CritiqueEvaluator : public QObject
{
    Q_OBJECT

public:
    explicit CritiqueEvaluator(QObject *parent = nullptr);
    ~CritiqueEvaluator() override;

    bool isAvailable() const { return m_available; }
    bool isBusy() const { return m_busy; }

    bool hasCachedCritique(const QString &imagePath) const;
    QString cachedCritique(const QString &imagePath) const;
    double cachedCritiqueScore(const QString &imagePath) const;
    QString statusHint() const;

    void setMockGenerator(const std::function<QString(const QString &)> &generator);

public slots:
    void requestCritique(const QString &imagePath);

signals:
    void availabilityChanged(bool available);
    void busyChanged(bool busy);
    void critiqueReady(const QString &imagePath, const QString &text, double qsitScore);
    void critiqueFailed(const QString &imagePath, const QString &reason);

private slots:
    void onProcessReadyRead();
    void onProcessFinished(int exitCode, QProcess::ExitStatus status);
    void onProcessError(QProcess::ProcessError error);

private:
    void startServer();
    void handleLine(const QString &line);
    void sendRequest(const QString &imagePath);
    void setBusy(bool busy);
    void setAvailable(bool available);

    QProcess *m_process = nullptr;
    QHash<QString, QString> m_cache;
    QHash<QString, double> m_scoreCache;
    QString m_pendingPath;
    QByteArray m_readBuffer;
    bool m_available = false;
    bool m_busy = false;
    bool m_serverStarting = false;
    QString m_statusHint;
    std::function<QString(const QString &)> m_mockGenerator;
};

#endif // CRITIQUEEVALUATOR_H
