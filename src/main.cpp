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
    // Optimización de aceleración por hardware en CachyOS (Intel Raptor Lake UHD 770 / VA-API)
    if (qEnvironmentVariableIsEmpty("LIBVA_DRIVER_NAME")) {
        qputenv("LIBVA_DRIVER_NAME", "iHD");
    }
    if (qEnvironmentVariableIsEmpty("VDPAU_DRIVER")) {
        qputenv("VDPAU_DRIVER", "va_gl");
    }

    QApplication app(argc, argv);
    KirigamiAppDefaults::apply(&app);

    // Allow QtMultimedia to use its default backend (FFmpeg on modern Linux)
    // which reliably streams DASH audio streams from YouTube without HTTP 403.

    QCoreApplication::setOrganizationName(QStringLiteral("CachyOS"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("cachyos.org"));
    QCoreApplication::setApplicationName(QStringLiteral("audiotube"));

    KLocalizedString::setApplicationDomain("audiotube");

    KAboutData about(QStringLiteral("audiotube"),
                     i18n("AudioTube Extended"),
                     QStringLiteral(AUDIOTUBE_VERSION_STRING),
                     i18n("Cliente moderno de YouTube Music para CachyOS. Bifurcación (fork) y migración de la aplicación original AudioTube de KDE adaptada a los estándares de diseño CachyOS.UI Golden Gate / Liquid Glass."),
                     KAboutLicense::GPL_V3,
                     i18n("© 2026 César Conte (migración CachyOS.UI)\n© 2021–2024 Jonah Brüchert, Mathis Brüchert, Comunidad KDE (versión original)"));

    // Autor de la migración CachyOS.UI
    about.addAuthor(i18n("César Conte"),
                    i18n("Autor de la migración y adaptación al ecosistema CachyOS.UI"),
                    QStringLiteral("yugurta@gmail.com"),
                    QStringLiteral("https://github.com/cesarconte"));

    // Autores de la versión original de KDE
    about.addCredit(i18n("Jonah Brüchert"),
                    i18n("Autor y mantenedor de la versión original de AudioTube (KDE)"),
                    QStringLiteral("jbb@kaidan.im"));
    about.addCredit(i18n("Mathis Brüchert"),
                    i18n("Diseñador de la versión original de AudioTube (KDE)"),
                    QStringLiteral("mbb@kaidan.im"));
    about.addCredit(i18n("Comunidad KDE"),
                    i18n("Creadores y mantenedores del proyecto original"));

    about.setTranslator(i18nc("NAME OF TRANSLATORS", "Your names"), i18nc("EMAIL OF TRANSLATORS", "Your emails"));
    about.setOrganizationDomain("cachyos.org");
    about.setHomepage(QStringLiteral("https://github.com/cesarconte/audiotube-extended"));
    about.setBugAddress("https://github.com/cesarconte/audiotube-extended/issues");
    about.setOtherText(i18n("Esta aplicación es una bifurcación (fork) independiente optimizada para CachyOS y el sistema de diseño CachyOS.UI Golden Gate / Liquid Glass. Todo el reconocimiento por la arquitectura base y la integración con YouTube Music pertenece a sus autores originales en KDE."));

    KAboutData::setApplicationData(about);

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
