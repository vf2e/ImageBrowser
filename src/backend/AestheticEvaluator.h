#ifndef AESTHETICEVALUATOR_H
#define AESTHETICEVALUATOR_H

#include <QHash>
#include <QObject>
#include <QProcess>
#include <QString>
#include <functional>

class AestheticEvaluator : public QObject
{
    Q_OBJECT

public:
    explicit AestheticEvaluator(QObject *parent = nullptr);
    ~AestheticEvaluator() override;

    bool isAvailable() const { return m_available; }
    bool isBusy() const { return m_busy; }

    bool hasCachedScore(const QString &imagePath) const;
    double cachedScore(const QString &imagePath) const;
    QString statusHint() const;

    void setMockScorer(const std::function<double(const QString &)> &scorer);

public slots:
    void requestScore(const QString &imagePath);

signals:
    void availabilityChanged(bool available);
    void busyChanged(bool busy);
    void scoreReady(const QString &imagePath, double score);
    void scoreFailed(const QString &imagePath, const QString &reason);

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

    QString findServerScript() const;
    QProcess *m_process = nullptr;
    QHash<QString, double> m_cache;
    QString m_pendingPath;
    QByteArray m_readBuffer;
    bool m_available = false;
    bool m_busy = false;
    bool m_serverStarting = false;
    QString m_statusHint;
    std::function<double(const QString &)> m_mockScorer;
};

#endif // AESTHETICEVALUATOR_H
