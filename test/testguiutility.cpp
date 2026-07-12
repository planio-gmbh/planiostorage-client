/*
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.
*/

#include <QtTest>

#include <QDesktopServices>

#include "gui/guiutility.h"

using namespace OCC;

class TestGuiUtility : public QObject
{
    Q_OBJECT

public Q_SLOTS:
    void handleUrl(const QUrl &url) { _handledUrls.append(url); }

private Q_SLOTS:
    void init() { _handledUrls.clear(); }

    void testOpenBrowserAllowedSchemes_data()
    {
        QTest::addColumn<QUrl>("url");
        QTest::newRow("http") << QUrl(QStringLiteral("http://example.com"));
        QTest::newRow("https") << QUrl(QStringLiteral("https://example.com/path?query=1"));
    }

    void testOpenBrowserAllowedSchemes()
    {
        QFETCH(QUrl, url);
        // the handler stands in for the real browser
        QDesktopServices::setUrlHandler(url.scheme(), this, "handleUrl");
        QVERIFY(Utility::openBrowser(url, nullptr));
        QCOMPARE(_handledUrls, QList<QUrl> { url });
        QDesktopServices::unsetUrlHandler(url.scheme());
    }

    void testOpenBrowserForbiddenSchemes_data()
    {
        QTest::addColumn<QUrl>("url");
        QTest::newRow("file") << QUrl(QStringLiteral("file:///etc/passwd"));
        QTest::newRow("smb") << QUrl(QStringLiteral("smb://host/share"));
        QTest::newRow("scheme-less") << QUrl(QStringLiteral("example.com"));
    }

    void testOpenBrowserForbiddenSchemes()
    {
        QFETCH(QUrl, url);
        // a registered handler would make QDesktopServices::openUrl() succeed,
        // so this proves openBrowser() rejects the URL before opening anything
        if (!url.scheme().isEmpty()) {
            QDesktopServices::setUrlHandler(url.scheme(), this, "handleUrl");
        }
        QVERIFY(!Utility::openBrowser(url, nullptr));
        QVERIFY(_handledUrls.isEmpty());
        if (!url.scheme().isEmpty()) {
            QDesktopServices::unsetUrlHandler(url.scheme());
        }
    }

private:
    QList<QUrl> _handledUrls;
};

QTEST_GUILESS_MAIN(TestGuiUtility)
#include "testguiutility.moc"
