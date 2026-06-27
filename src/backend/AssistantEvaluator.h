#ifndef ASSISTANTEVALUATOR_H
#define ASSISTANTEVALUATOR_H

#include <QObject>
#include <QProcess>
#include <QVariantList>
#include <functional>

class AssistantEvaluator : public QObject
{
    Q_OBJECT

public:
    explicit AssistantEvaluator(QObject *parent = nullptr);
    ~AssistantEvaluator() override;

    bool isAvailable() const { return m_available; }
    bool isBusy() const { return m_busy; }
    QString statusHint() const;
    QString welcomeMessage() const { return m_welcomeMessage; }

    void setMockResponder(const std::function<QString(const QString &, const QVariantList &)> &responder);

public slots:
    void sendMessage(const QString &message, const QVariantList &history);

signals:
    void availabilityChanged(bool available);
    void busyChanged(bool busy);
    void replyReady(const QString &reply);
    void replyFailed(const QString &reason);
    void welcomeMessageChanged();

private slots:
    void onProcessReadyRead();
    void onProcessFinished(int exitCode, QProcess::ExitStatus status);
    void onProcessError(QProcess::ProcessError error);

private:
    void startServer();
    void handleLine(const QString &line);
    void sendRequest(const QString &message, const QVariantList &history);
    void setBusy(bool busy);
    void setAvailable(bool available);

    QProcess *m_process = nullptr;
    QByteArray m_readBuffer;
    bool m_available = false;
    bool m_busy = false;
    bool m_serverStarting = false;
    QString m_statusHint;
    QString m_welcomeMessage;
    QString m_pendingMessage;
    QVariantList m_pendingHistory;
    std::function<QString(const QString &, const QVariantList &)> m_mockResponder;
};

#endif // ASSISTANTEVALUATOR_H
