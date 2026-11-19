// SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import CachyOS.UI
import org.kde.audiotube

CachyScrollablePage {
    id: root

    title: i18n("Ajustes")
    objectName: "settingsPage"

    // Margen horizontal unificado de 36px acorde a CachyOS.UI Golden Gate
    readonly property int pageMargin: 36

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

    // Fondo opaco sólido para evitar transparencias o elementos fantasma
    Rectangle {
        anchors.fill: parent
        z: -1
        color: CachyPalette.isDark ? Qt.rgba(0.12, 0.12, 0.15, 1.0) : Qt.rgba(0.97, 0.97, 0.99, 1.0)
    }

    header: Item {
        implicitHeight: 52
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.pageMargin
            anchors.rightMargin: root.pageMargin

            CachyHeading {
                Layout.fillWidth: true
                text: i18n("Ajustes y Preferencias")
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

    // =========================================================================
    // CABECERA DESCRIPTIVA
    // =========================================================================
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: CachyTheme.spacingLarge
        spacing: 6

        CachyHeading {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: i18n("Configuración de AudioTube Extended")
            level: 2
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.leftMargin: root.pageMargin
            Layout.rightMargin: root.pageMargin
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: 13
            color: CachyPalette.textSecondary
            text: i18n("Personaliza el motor de renderizado gráfico, la calidad del flujo de audio y el comportamiento del entorno.")
        }
    }

    // =========================================================================
    // SECCIÓN 1: RENDIMIENTO Y GRÁFICOS (VULKAN / RHI / VA-API)
    // =========================================================================
    CachyFormHeader {
        title: i18n("Rendimiento y Gráficos")
        Layout.fillWidth: true
        Layout.leftMargin: root.pageMargin + 6
        Layout.rightMargin: root.pageMargin
        Layout.topMargin: 20
        Layout.bottomMargin: 6
    }

    CachyFormCard {
        Layout.fillWidth: true
        Layout.leftMargin: root.pageMargin
        Layout.rightMargin: root.pageMargin

        CachyFormComboBoxDelegate {
            id: rhiCombo
            label: i18n("Motor de renderizado (RHI)")
            description: i18n("Requiere reiniciar la aplicación para aplicar el cambio")
            model: [
                i18n("Automático (Predeterminado del sistema)"),
                i18n("Vulkan (Bajo uso de CPU y Wayland)"),
                i18n("OpenGL (Mesa Iris)"),
                i18n("Software (Renderizado por CPU)")
            ]
            currentIndex: {
                switch (StateConfig.renderingBackend) {
                case "vulkan": return 1;
                case "opengl": return 2;
                case "software": return 3;
                default: return 0;
                }
            }
            onActivated: (index) => {
                const backends = ["auto", "vulkan", "opengl", "software"];
                StateConfig.renderingBackend = backends[index] || "auto";
                StateConfig.save();
            }
        }

        CachyFormCheckDelegate {
            label: i18n("Aceleración por hardware de vídeo (VA-API)")
            description: i18n("Utiliza el decodificador por hardware Intel iHD en CachyOS")
            checked: StateConfig.hardwareAcceleration
            onToggled: (val) => {
                StateConfig.hardwareAcceleration = val;
                StateConfig.save();
            }
        }

        CachyFormCheckDelegate {
            label: i18n("Desenfoque ambiental Liquid Glass")
            description: i18n("Efecto difuminado dinámico de la portada en el reproductor maximizado")
            checked: StateConfig.ambientBlur
            onToggled: (val) => {
                StateConfig.ambientBlur = val;
                StateConfig.save();
            }
        }
    }

    // =========================================================================
    // SECCIÓN 2: REPRODUCCIÓN Y AUDIO
    // =========================================================================
    CachyFormHeader {
        title: i18n("Reproducción y Audio")
        Layout.fillWidth: true
        Layout.leftMargin: root.pageMargin + 6
        Layout.rightMargin: root.pageMargin
        Layout.topMargin: 20
        Layout.bottomMargin: 6
    }

    CachyFormCard {
        Layout.fillWidth: true
        Layout.leftMargin: root.pageMargin
        Layout.rightMargin: root.pageMargin

        CachyFormComboBoxDelegate {
            label: i18n("Calidad de audio preferida")
            description: i18n("Flujo de audio extraído desde YouTube Music")
            model: [
                i18n("Alta calidad (AAC HLS ~134 kbps)"),
                i18n("Estándar / Ahorro de datos (AAC/M4A ~48 kbps)")
            ]
            currentIndex: StateConfig.audioQuality === "standard" ? 1 : 0
            onActivated: (index) => {
                StateConfig.audioQuality = (index === 1) ? "standard" : "high";
                StateConfig.save();
            }
        }

        CachyFormCheckDelegate {
            label: i18n("Guardar historial de reproducción")
            description: i18n("Registrar canciones escuchadas en la biblioteca local")
            checked: StateConfig.saveHistory
            onToggled: (val) => {
                StateConfig.saveHistory = val;
                StateConfig.save();
            }
        }
    }

    // =========================================================================
    // SECCIÓN 3: INTERFAZ Y COMPORTAMIENTO
    // =========================================================================
    CachyFormHeader {
        title: i18n("Interfaz y Comportamiento")
        Layout.fillWidth: true
        Layout.leftMargin: root.pageMargin + 6
        Layout.rightMargin: root.pageMargin
        Layout.topMargin: 20
        Layout.bottomMargin: 6
    }

    CachyFormCard {
        Layout.fillWidth: true
        Layout.leftMargin: root.pageMargin
        Layout.rightMargin: root.pageMargin

        CachyFormComboBoxDelegate {
            label: i18n("Página al iniciar la aplicación")
            description: i18n("Vista que se abrirá al iniciar AudioTube")
            model: [
                i18n("Recordar última página abierta"),
                i18n("Página de inicio"),
                i18n("Biblioteca"),
                i18n("Explorar")
            ]
            currentIndex: {
                switch (StateConfig.startupPage) {
                case "home": return 1;
                case "libraryPage": return 2;
                case "explore": return 3;
                default: return 0;
                }
            }
            onActivated: (index) => {
                const pages = ["last", "home", "libraryPage", "explore"];
                StateConfig.startupPage = pages[index] || "last";
                StateConfig.save();
            }
        }

        CachyFormCheckDelegate {
            label: i18n("Notificaciones del sistema")
            description: i18n("Mostrar notificación emergente en Plasma al cambiar de canción")
            checked: StateConfig.trackNotifications
            onToggled: (val) => {
                StateConfig.trackNotifications = val;
                StateConfig.save();
            }
        }
    }

    footer: Item {
        implicitHeight: 64

        CachyButton {
            anchors.centerIn: parent
            text: i18n("Cerrar")
            primary: true
            onClicked: root.close()
        }
    }
}
