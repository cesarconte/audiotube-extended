// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include <QSortFilterProxyModel>
#include <QUrl>
#include <QQuickWindow>
#include <QQuickStyle>
#include <QStyle>
#include <QStyleFactory>

#include <KAboutData>
#include <KCrash>
#include <KIconTheme>
#include <KLocalizedQmlContext>
#include <KLocalizedString>
#include <KirigamiAddons/App/KirigamiAppDefaults>

#include <ThreadedDatabase>

#include "asyncytmusic.h"

using namespace Qt::StringLiterals;

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    KirigamiAppDefaults::apply(&app);

    // Allow QtMultimedia to use its default backend (FFmpeg on modern Linux)
    // which reliably streams DASH audio streams from YouTube without HTTP 403.

    QCoreApplication::setOrganizationName(QStringLiteral("KDE"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("kde.org"));
    QCoreApplication::setApplicationName(QStringLiteral("audiotube"));

    KLocalizedString::setApplicationDomain("audiotube");

    KAboutData about(QStringLiteral("audiotube"),
                     i18n("AudioTube"),
                     QStringLiteral(AUDIOTUBE_VERSION_STRING),
                     i18nc("YouTube Music is a music streaming service by Google", "Stream music from YouTube Music"),
                     KAboutLicense::GPL_V3,
                     i18n("© 2021–2024 Jonah Brüchert, 2021–2024 KDE Community"));
    about.addAuthor(i18n("Jonah Brüchert"), i18n("Maintainer"), QStringLiteral("jbb@kaidan.im"));
    about.addAuthor(i18n("Mathis Brüchert"), i18n("Designer"), QStringLiteral("mbb@kaidan.im"));
    about.setTranslator(i18nc("NAME OF TRANSLATORS", "Your names"), i18nc("EMAIL OF TRANSLATORS", "Your emails"));
    about.setOrganizationDomain("kde.org");
    about.setBugAddress("https://bugs.kde.org/describecomponents.cgi?product=audiotube");
    auto future = YTMusicThread::instance()->version();
    QCoro::connect(std::move(future), &app, [&about](const auto &version) {
        about.addComponent(QStringLiteral("ytmusicapi"),
                           i18nc("YouTube Music is a music streaming service by Google",
                                 "Unofficial API for YouTube Music"),
                           version);
        KAboutData::setApplicationData(about);
    });

    QGuiApplication::setWindowIcon(QIcon::fromTheme(QStringLiteral("org.kde.audiotube")));

    QQmlApplicationEngine engine;

    KLocalization::setupLocalizedContext(&engine);
    engine.loadFromModule("org.kde.audiotube", "Main");

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
