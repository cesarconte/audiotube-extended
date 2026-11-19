// SPDX-FileCopyrightText: 2026 Tanveer Ahmed Mansuri
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects
import QtQuick.Templates as T
import CachyOS.UI

T.ItemDelegate {
    id: root
    
    required property int index
    required property string title
    required property string artistsDisplayString
    required property string thumbnailUrl

    property bool wide: false
    property bool tall: false
    property int radius: 10
    
    // Song-specific properties for menu
    required property string videoId
    required property var artists
    readonly property bool isSong: videoId !== ""

    function getCategoryData(name) {
        let n = (name || "").toLowerCase().trim();
        if (n.includes("chill")) return { c1: "#0072ff", c2: "#00c6ff", icon: "view-media-playlist" };
        if (n.includes("christmas")) return { c1: "#b71c1c", c2: "#1b5e20", icon: "starred-symbolic" };
        if (n.includes("commute")) return { c1: "#8e24aa", c2: "#d81b60", icon: "media-playlist-shuffle" };
        if (n.includes("energize") || n.includes("workout")) return { c1: "#ff3d00", c2: "#ff9100", icon: "run-build" };
        if (n.includes("feel good")) return { c1: "#00897b", c2: "#43a047", icon: "starred-symbolic" };
        if (n.includes("focus")) return { c1: "#1a237e", c2: "#3949ab", icon: "audio-headset" };
        if (n.includes("gaming")) return { c1: "#4a148c", c2: "#00e5ff", icon: "games-config" };
        if (n.includes("party")) return { c1: "#c2185b", c2: "#7b1fa2", icon: "rating" };
        if (n.includes("romance")) return { c1: "#ad1457", c2: "#f06292", icon: "love" };
        if (n.includes("sad")) return { c1: "#263238", c2: "#455a64", icon: "night" };
        if (n.includes("sleep")) return { c1: "#0d47a1", c2: "#311b92", icon: "night" };
        if (n.includes("rock") || n.includes("metal")) return { c1: "#b71c1c", c2: "#212121", icon: "media-optical-audio" };
        if (n.includes("pop")) return { c1: "#d81b60", c2: "#ff4081", icon: "media-playback-start" };
        if (n.includes("classical")) return { c1: "#4a148c", c2: "#d4af37", icon: "view-media-lyrics" };
        if (n.includes("jazz") || n.includes("blues")) return { c1: "#3e2723", c2: "#e65100", icon: "view-media-playlist" };
        if (n.includes("hip-hop") || n.includes("r&b")) return { c1: "#ff6f00", c2: "#ffb300", icon: "audio-volume-high" };
        if (n.includes("electronic") || n.includes("dance")) return { c1: "#00b0ff", c2: "#d500f9", icon: "media-playlist-append" };
        if (n.includes("latin") || n.includes("reggae")) return { c1: "#ff3d00", c2: "#ffd600", icon: "rating" };
        if (n.includes("indie") || n.includes("folk")) return { c1: "#00695c", c2: "#ff7043", icon: "audio-x-generic" };

        // Fallback dinámico con alta saturación y contraste armónico
        let hash = 0;
        for (let i = 0; i < n.length; i++) {
            hash = n.charCodeAt(i) + ((hash << 5) - hash);
        }
        let hue1 = Math.abs(hash) % 360;
        let hue2 = (hue1 + 40) % 360;
        return {
            c1: Qt.hsla(hue1 / 360.0, 0.75, 0.45, 1.0),
            c2: Qt.hsla(hue2 / 360.0, 0.85, 0.28, 1.0),
            icon: "view-media-playlist"
        };
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)
    
    hoverEnabled: true

    // Z-index elevation to prevent flickering (overlapping neighbors stealing hover)
    z: root.hovered ? 2 : 0

    // Layout properties for Bento Grid
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.rowSpan: tall ? 2 : 1
    Layout.columnSpan: wide ? 2 : 1
    Layout.preferredHeight: 180 * (tall ? 2.1 : 1.0)

    background: Kirigami.ShadowedRectangle {
        implicitWidth: 180 * (wide ? 2 : 1)
        implicitHeight: 180 * (tall ? 2 : 1)

        radius: root.radius
        color: Kirigami.Theme.backgroundColor
        
        scale: root.pressed ? 0.98 : (root.hovered ? 1.02 : 1.0)
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        
        shadow {
            size: root.hovered ? 30 : 15
            xOffset: root.hovered ? 10 : 5
            yOffset: root.hovered ? 10 : 5
            color: Qt.rgba(0,0,0, root.hovered ? 0.4 : 0.2)
        }
        
        Behavior on shadow.size { NumberAnimation { duration: Kirigami.Units.shortDuration } }
        Behavior on shadow.yOffset { NumberAnimation { duration: Kirigami.Units.shortDuration } }

        // Fondo estilizado para categorías sin carátula (Moods & Moments, Géneros) — Estilo Spotify / Apple Music
        Rectangle {
            id: categoryBg
            anchors.fill: parent
            radius: root.radius
            visible: root.thumbnailUrl === "" || img.status === Image.Error
            clip: true

            readonly property var catData: root.getCategoryData(root.title)

            gradient: Gradient {
                GradientStop { position: 0.0; color: categoryBg.catData.c1 }
                GradientStop { position: 1.0; color: categoryBg.catData.c2 }
            }

            // Borde especular interior de 1px
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.18)
            }

            // Icono marca de agua decorativo en la esquina inferior derecha
            CachyIcon {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: -8
                anchors.bottomMargin: -8
                width: 72
                height: 72
                name: categoryBg.catData.icon
                color: Qt.rgba(1, 1, 1, 0.22)
                rotation: -12
            }
        }

        Image {
            id: img
            anchors.fill: parent
            source: root.thumbnailUrl
            fillMode: Image.PreserveAspectCrop
            visible: root.thumbnailUrl !== "" && status === Image.Ready
            
            onSourceChanged: {
                if (root.thumbnailUrl) console.log("BentoCard: Image source changed to:", root.thumbnailUrl)
            }
            
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle { 
                    width: img.width
                    height: img.height
                    radius: root.radius
                    visible: false
                }
            }
        }
        
        // Gradient overlay for text readability
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.9) }
            }
        }

        // Highlight border on hover
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Kirigami.Theme.highlightColor
            border.width: 2
            radius: root.radius - 1
            opacity: root.hovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
        }
    }
    
    contentItem: Item {
        // Action Button Overlay (Fades in on hover)
        Rectangle {
            anchors.centerIn: parent
            height: 46
            width: 46
            radius: height / 2
            color: CachyTheme.accentColor
            visible: root.hovered
            opacity: root.hovered ? 1.0 : 0.0
            scale: root.hovered ? 1.0 : 0.8
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

            CachyIcon {
                name: (root.isSong || root.thumbnailUrl !== "") ? "media-playback-start" : "draw-arrow-forward"
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: (root.isSong || root.thumbnailUrl !== "") ? 1.5 : 0
                width: 22
                height: 22
                color: "white"
            }
        }
        
        // Overflow menu button (top-right, visible on hover for songs)
        Controls.RoundButton {
            id: overflowButton
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            visible: root.isSong && (root.hovered || hovered)
            opacity: (root.hovered || hovered) ? 1 : 0
            
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
            icon.name: "overflow-menu-symbolic"
            
            onClicked: root.Controls.ContextMenu.requested(Qt.point(0, 0))
            
            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: i18n("More options")
        }

        ColumnLayout {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: Kirigami.Units.gridUnit
            }
            spacing: Kirigami.Units.smallSpacing
            
            Controls.Label {
                text: root.title
                font.weight: Font.Bold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * (root.wide || root.tall ? 1.4 : 1.1)
                color: "white"
                elide: Text.ElideRight
                Layout.fillWidth: true
                maximumLineCount: 2
            }
            
            Controls.Label {
                text: root.artistsDisplayString
                visible: text !== ""
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                color: Qt.rgba(1,1,1,0.8)
                elide: Text.ElideRight
                Layout.fillWidth: true
                maximumLineCount: 1
            }
        }
    }
   
}
