// SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import CachyOS.UI

CachyScrollablePage {
    id: root

    title: i18n("About AudioTube Extended")
    objectName: "aboutPage"

    function close() {
        if (root.pageStack && root.pageStack.layers && root.pageStack.layers.depth > 0) {
            root.pageStack.layers.pop();
        } else if (root.parent && typeof root.parent.pop === "function") {
            root.parent.pop();
        } else if (typeof pageStack !== "undefined" && pageStack && pageStack.layers && pageStack.layers.depth > 0) {
            pageStack.layers.pop();
        } else if (typeof pageStack !== "undefined" && pageStack && pageStack.depth > 1) {
            pageStack.pop();
        }
    }

    header: Item {
        implicitHeight: 44
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: CachyTheme.marginWindow
            anchors.rightMargin: CachyTheme.marginWindow

            CachyHeading {
                Layout.fillWidth: true
                text: i18n("Acerca de")
                level: 3
            }

            CachyToolbarButton {
                iconName: "window-close-symbolic"
                tooltipText: i18n("Cerrar")
                onClicked: root.close()
            }
        }
    }

    contentColumn.spacing: CachyTheme.spacingLarge

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: CachyTheme.spacingLarge
        spacing: 10

        // Icono de la aplicación
        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 84
            Layout.preferredHeight: 84
            source: CachyTheme.iconUrl("org.kde.audiotube")
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        // Título del proyecto
        CachyHeading {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: i18n("AudioTube Extended")
            level: 1
        }

        // Etiqueta distintiva de bifurcación
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: forkLabel.implicitWidth + 16
            implicitHeight: 24
            radius: 12
            color: Qt.rgba(CachyTheme.accentColor.r, CachyTheme.accentColor.g, CachyTheme.accentColor.b, 0.16)
            border.width: 1
            border.color: Qt.rgba(CachyTheme.accentColor.r, CachyTheme.accentColor.g, CachyTheme.accentColor.b, 0.40)

            Controls.Label {
                id: forkLabel
                anchors.centerIn: parent
                text: i18n("Bifurcación CachyOS.UI Golden Gate")
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: CachyTheme.accentColor
            }
        }

        // Versión
        Controls.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: i18n("Versión %1", Qt.application.version || "24.08.0")
            font.pixelSize: 12
            color: CachyPalette.textMuted
        }

        // Descripción general
        Controls.Label {
            Layout.fillWidth: true
            Layout.leftMargin: CachyTheme.marginWindow
            Layout.rightMargin: CachyTheme.marginWindow
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: 13
            color: CachyPalette.textSecondary
            text: i18n("Cliente moderno de YouTube Music optimizado para el ecosistema CachyOS. Esta versión es una bifurcación (fork) y migración integral de la aplicación original AudioTube de KDE, adaptada a los estándares de diseño CachyOS.UI Golden Gate / Liquid Glass.")
        }
    }

    // =========================================================================
    // SECCIÓN 1: AUTOR DE LA MIGRACIÓN (César Conte)
    // =========================================================================
    CachyFormHeader {
        title: i18n("Migración y Adaptación a CachyOS.UI")
    }

    CachyFormCard {
        Layout.fillWidth: true
        Layout.leftMargin: CachyTheme.marginWindow
        Layout.rightMargin: CachyTheme.marginWindow

        CachyFormButtonDelegate {
            text: i18n("César Conte")
            description: i18n("Autor de la migración, rediseño Liquid Glass y mantenimiento del fork")
            icon.name: "user-identity"
            onClicked: Qt.openUrlExternally("https://github.com/cesarconte")
        }
    }

    // =========================================================================
    // SECCIÓN 2: AUTORES DE LA VERSIÓN ORIGINAL (KDE)
    // =========================================================================
    CachyFormHeader {
        title: i18n("Autores de la Versión Original (KDE)")
    }

    CachyFormCard {
        Layout.fillWidth: true
        Layout.leftMargin: CachyTheme.marginWindow
        Layout.rightMargin: CachyTheme.marginWindow

        CachyFormButtonDelegate {
            text: i18n("Jonah Brüchert")
            description: i18n("Autor y desarrollador principal de AudioTube original (KDE)")
            icon.name: "im-user"
            onClicked: Qt.openUrlExternally("mailto:jbb@kaidan.im")
        }

        CachyFormButtonDelegate {
            text: i18n("Mathis Brüchert")
            description: i18n("Diseñador de la versión original de AudioTube (KDE)")
            icon.name: "im-user"
            onClicked: Qt.openUrlExternally("mailto:mbb@kaidan.im")
        }

        CachyFormButtonDelegate {
            text: i18n("Comunidad KDE")
            description: i18n("Proyecto original AudioTube bajo licencia GPL-3.0")
            icon.name: "kde"
            onClicked: Qt.openUrlExternally("https://invent.kde.org/multimedia/audiotube")
        }
    }

    // =========================================================================
    // SECCIÓN 3: CÓDIGO FUENTE Y ENLACES
    // =========================================================================
    CachyFormHeader {
        title: i18n("Código Fuente y Enlaces")
    }

    CachyFormCard {
        Layout.fillWidth: true
        Layout.leftMargin: CachyTheme.marginWindow
        Layout.rightMargin: CachyTheme.marginWindow

        CachyFormButtonDelegate {
            text: i18n("Repositorio del Fork (GitHub)")
            description: "https://github.com/cesarconte/audiotube-extended"
            icon.name: "vcs-normal"
            onClicked: Qt.openUrlExternally("https://github.com/cesarconte/audiotube-extended")
        }

        CachyFormButtonDelegate {
            text: i18n("Reportar un Problema o Sugerencia")
            description: i18n("Seguimiento de incidencias en GitHub")
            icon.name: "tools-report-bug"
            onClicked: Qt.openUrlExternally("https://github.com/cesarconte/audiotube-extended/issues")
        }

        CachyFormButtonDelegate {
            text: i18n("Librería CachyOS.UI")
            description: i18n("Ecosistema de diseño Golden Gate / Liquid Glass")
            icon.name: "applications-development"
            onClicked: Qt.openUrlExternally("https://github.com/cesarconte/cachyos-ui")
        }
    }

    // =========================================================================
    // SECCIÓN 4: LICENCIA Y COMPONENTES
    // =========================================================================
    CachyFormHeader {
        title: i18n("Licencia y Componentes")
    }

    CachyFormCard {
        Layout.fillWidth: true
        Layout.leftMargin: CachyTheme.marginWindow
        Layout.rightMargin: CachyTheme.marginWindow

        CachyFormButtonDelegate {
            text: i18n("Licencia")
            description: i18n("GNU General Public License v3.0 o posterior")
            icon.name: "license"
            onClicked: Qt.openUrlExternally("https://www.gnu.org/licenses/gpl-3.0.html")
        }

        CachyFormButtonDelegate {
            text: "ytmusicapi"
            description: i18n("API no oficial en Python para YouTube Music")
            icon.name: "application-x-python"
            onClicked: Qt.openUrlExternally("https://github.com/sigma67/ytmusicapi")
        }
    }

    footer: Item {
        implicitHeight: 56

        CachyButton {
            anchors.centerIn: parent
            text: i18n("Cerrar")
            primary: true
            onClicked: root.close()
        }
    }
}
