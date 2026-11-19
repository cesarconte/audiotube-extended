// SPDX-FileCopyrightText: 2020-2022 Devin Lin <devin@kde.org>
// SPDX-FileCopyrightText: 2026 CachyOS UI contributors
//
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtMultimedia

import org.kde.kirigami as Kirigami
import org.kde.audiotube
import CachyOS.UI

Item {
    id: root
    z: 2000

    required property int progressBarHeight
    required property int minimizedPlayerContentHeight

    required property VideoInfoExtractor info
    required property MediaPlayer audio
    required property string thumbnail

    readonly property bool isWidescreen: width >= 640
    readonly property bool hasMedia: info && info.title && info.title.length > 0

    signal requestOpen()

    Shortcut {
        sequence: "Ctrl+P"
        onActivated: root.requestOpen()
    }

    // ── SLIM PROGRESS BAR (Top Edge) ──
    Item {
        id: progressBarContainer
        z: 20
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.progressBarHeight > 0 ? root.progressBarHeight : 3

        Rectangle {
            id: trackBg
            anchors.fill: parent
            color: CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
        }

        Rectangle {
            id: progressFill
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            color: CachyTheme.accentColor
            width: {
                if (!root.audio || root.audio.duration <= 0) return 0;
                return Math.max(0, Math.min(progressBarContainer.width, progressBarContainer.width * (root.audio.position / root.audio.duration)));
            }

            Behavior on width {
                enabled: !progressMouse.pressed
                NumberAnimation { duration: 100 }
            }
        }

        MouseArea {
            id: progressMouse
            anchors.fill: parent
            anchors.topMargin: -4
            anchors.bottomMargin: -4
            cursorShape: Qt.PointingHandCursor
            enabled: root.audio && root.audio.duration > 0 && root.audio.seekable
            onClicked: mouse => {
                if (root.audio && root.audio.duration > 0) {
                    let target = Math.round((mouse.x / width) * root.audio.duration);
                    root.audio.setPosition(target);
                }
            }
        }
    }

    // ── MAIN CONTENT (Below Progress Bar) ──
    Item {
        id: barContent
        anchors.top: progressBarContainer.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        // ── LEFT ZONE: Artwork & Track Metadata ──
        Item {
            id: trackInfoBox
            anchors.left: parent.left
            anchors.leftMargin: CachyTheme.marginWindow
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: isWidescreen ? centerControlsHost.left : rightGroup.left
            anchors.rightMargin: CachyTheme.spacingMedium
            height: 48

            Rectangle {
                id: trackHoverPill
                anchors.fill: parent
                anchors.margins: -4
                radius: CachyTheme.radiusSmall
                color: trackArea.containsMouse ? (CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)) : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            RowLayout {
                anchors.fill: parent
                spacing: CachyTheme.spacingMedium

                // Album Artwork Frame
                Rectangle {
                    id: artworkFrame
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    Layout.alignment: Qt.AlignVCenter
                    radius: CachyTheme.radiusSmall
                    color: CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
                    border.width: 1
                    border.color: CachyPalette.specularBorder
                    clip: true

                    Image {
                        id: coverImage
                        anchors.fill: parent
                        source: root.thumbnail
                        visible: root.thumbnail.length > 0 && status === Image.Ready
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    CachyIcon {
                        anchors.centerIn: parent
                        visible: !coverImage.visible && !loadingSpinner.visible
                        name: "media-optical-audio"
                        size: 20
                        color: CachyPalette.textMuted
                    }

                    CachyBusyIndicator {
                        id: loadingSpinner
                        anchors.centerIn: parent
                        running: UserPlaylistModel.loading
                        visible: UserPlaylistModel.loading
                        size: 22
                    }
                }

                // Title and Artist Column
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Text {
                        id: songTitle
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: root.info.title ? root.info.title : i18n("No media playing")
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: root.hasMedia ? CachyPalette.text : CachyPalette.textMuted
                        elide: Text.ElideRight
                    }

                    Text {
                        id: songArtist
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        visible: root.hasMedia
                        text: root.info.artist ? root.info.artist : (root.info.channel ? root.info.channel : "")
                        font.pixelSize: 11
                        color: CachyPalette.textSecondary
                        elide: Text.ElideRight
                    }
                }
            }

            MouseArea {
                id: trackArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.requestOpen()
            }
        }

        // ── CENTER ZONE: Symmetrical Transport Controls (Widescreen) ──
        Item {
            id: centerControlsHost
            visible: root.isWidescreen
            anchors.centerIn: parent
            width: centerLayout.implicitWidth
            height: parent.height

            RowLayout {
                id: centerLayout
                anchors.centerIn: parent
                spacing: CachyTheme.spacingMedium

                // Position Timestamp
                Text {
                    id: posText
                    text: root.hasMedia && root.audio ? PlayerUtils.formatTimestamp(root.audio.position) : "--:--"
                    font.pixelSize: 11
                    color: CachyPalette.textSecondary
                    visible: root.hasMedia
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignRight
                }

                // Previous Track Button
                Rectangle {
                    id: prevButton
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    scale: prevTap.pressed ? 0.93 : (prevHover.hovered ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    color: {
                        if (prevTap.pressed) return CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.12);
                        if (prevHover.hovered) return CachyPalette.surfacePill;
                        return "transparent";
                    }
                    border.width: prevHover.hovered ? 1 : 0
                    border.color: CachyPalette.specularBorder

                    CachyIcon {
                        anchors.centerIn: parent
                        name: "media-skip-backward"
                        size: 14
                        color: UserPlaylistModel.canSkipBack ? CachyPalette.text : CachyPalette.textMuted
                    }

                    HoverHandler { id: prevHover; enabled: UserPlaylistModel.canSkipBack }
                    TapHandler {
                        id: prevTap
                        enabled: UserPlaylistModel.canSkipBack
                        onTapped: UserPlaylistModel.previous()
                    }
                }

                // Play / Pause Primary Circular Accent Button
                Rectangle {
                    id: playPauseButton
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 20
                    color: CachyTheme.accentColor
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.28)
                    scale: playTap.pressed ? 0.93 : (playHover.hovered ? 1.06 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

                    CachyIcon {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: (root.audio && root.audio.playbackState === MediaPlayer.PlayingState) ? 0 : 1
                        name: (root.audio && root.audio.playbackState === MediaPlayer.PlayingState) ? "media-playback-pause" : "media-playback-start"
                        size: 18
                        color: "#FFFFFF"
                    }

                    HoverHandler { id: playHover }
                    TapHandler {
                        id: playTap
                        onTapped: {
                            if (root.audio) {
                                if (root.audio.playbackState === MediaPlayer.PlayingState) {
                                    root.audio.pause();
                                } else {
                                    root.audio.play();
                                }
                            }
                        }
                    }
                }

                // Next Track Button
                Rectangle {
                    id: nextButton
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    scale: nextTap.pressed ? 0.93 : (nextHover.hovered ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    color: {
                        if (nextTap.pressed) return CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.12);
                        if (nextHover.hovered) return CachyPalette.surfacePill;
                        return "transparent";
                    }
                    border.width: nextHover.hovered ? 1 : 0
                    border.color: CachyPalette.specularBorder

                    CachyIcon {
                        anchors.centerIn: parent
                        name: "media-skip-forward"
                        size: 14
                        color: UserPlaylistModel.canSkip ? CachyPalette.text : CachyPalette.textMuted
                    }

                    HoverHandler { id: nextHover; enabled: UserPlaylistModel.canSkip }
                    TapHandler {
                        id: nextTap
                        enabled: UserPlaylistModel.canSkip
                        onTapped: UserPlaylistModel.next()
                    }
                }

                // Total Duration Timestamp
                Text {
                    id: durText
                    text: root.hasMedia && root.audio ? PlayerUtils.formatTimestamp(root.audio.duration) : "--:--"
                    font.pixelSize: 11
                    color: CachyPalette.textSecondary
                    visible: root.hasMedia
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        // ── RIGHT ZONE: Auxiliary Controls (Volume, Expand, Compact buttons) ──
        RowLayout {
            id: rightGroup
            anchors.right: parent.right
            anchors.rightMargin: CachyTheme.marginWindow
            anchors.verticalCenter: parent.verticalCenter
            spacing: CachyTheme.spacingSmall

            // Compact fallback controls when screen is narrow (< 640px)
            RowLayout {
                id: compactControls
                visible: !root.isWidescreen
                spacing: CachyTheme.spacingSmall

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: compactPrevHov.hovered ? CachyPalette.surfacePill : "transparent"
                    border.width: compactPrevHov.hovered ? 1 : 0
                    border.color: CachyPalette.specularBorder
                    CachyIcon {
                        anchors.centerIn: parent
                        name: "media-skip-backward"
                        size: 14
                        color: UserPlaylistModel.canSkipBack ? CachyPalette.text : CachyPalette.textMuted
                    }
                    HoverHandler { id: compactPrevHov }
                    TapHandler { enabled: UserPlaylistModel.canSkipBack; onTapped: UserPlaylistModel.previous() }
                }

                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: CachyTheme.accentColor
                    CachyIcon {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: (root.audio && root.audio.playbackState === MediaPlayer.PlayingState) ? 0 : 1
                        name: (root.audio && root.audio.playbackState === MediaPlayer.PlayingState) ? "media-playback-pause" : "media-playback-start"
                        size: 16
                        color: "#FFFFFF"
                    }
                    TapHandler {
                        onTapped: {
                            if (root.audio) {
                                if (root.audio.playbackState === MediaPlayer.PlayingState) root.audio.pause();
                                else root.audio.play();
                            }
                        }
                    }
                }

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: compactNextHov.hovered ? CachyPalette.surfacePill : "transparent"
                    border.width: compactNextHov.hovered ? 1 : 0
                    border.color: CachyPalette.specularBorder
                    CachyIcon {
                        anchors.centerIn: parent
                        name: "media-skip-forward"
                        size: 14
                        color: UserPlaylistModel.canSkip ? CachyPalette.text : CachyPalette.textMuted
                    }
                    HoverHandler { id: compactNextHov }
                    TapHandler { enabled: UserPlaylistModel.canSkip; onTapped: UserPlaylistModel.next() }
                }
            }

            // Volume Control Group (Widescreen only)
            RowLayout {
                id: volumeGroup
                visible: root.isWidescreen && root.audio && root.audio.audioOutput
                spacing: CachyTheme.spacingTiny

                Rectangle {
                    id: muteButton
                    width: 28
                    height: 28
                    radius: 14
                    color: muteHov.hovered ? CachyPalette.surfacePill : "transparent"
                    border.width: muteHov.hovered ? 1 : 0
                    border.color: CachyPalette.specularBorder

                    CachyIcon {
                        anchors.centerIn: parent
                        name: {
                            if (!root.audio || !root.audio.audioOutput) return "audio-volume-medium";
                            if (root.audio.audioOutput.muted || root.audio.audioOutput.volume === 0) return "audio-volume-muted";
                            if (root.audio.audioOutput.volume < 0.4) return "audio-volume-low";
                            if (root.audio.audioOutput.volume < 0.7) return "audio-volume-medium";
                            return "audio-volume-high";
                        }
                        size: 14
                        color: CachyPalette.textSecondary
                    }

                    HoverHandler { id: muteHov }
                    TapHandler {
                        onTapped: {
                            if (root.audio && root.audio.audioOutput) {
                                root.audio.audioOutput.muted = !root.audio.audioOutput.muted;
                            }
                        }
                    }
                }

                CachySlider {
                    id: volumeSlider
                    Layout.preferredWidth: 80
                    from: 0.0
                    to: 1.0
                    value: root.audio && root.audio.audioOutput ? root.audio.audioOutput.volume : 1.0
                    onMoved: {
                        if (root.audio && root.audio.audioOutput) {
                            root.audio.audioOutput.volume = value;
                            if (root.audio.audioOutput.muted && value > 0) {
                                root.audio.audioOutput.muted = false;
                            }
                        }
                    }
                }
            }

            // Maximize / Expand Full Player Button
            Rectangle {
                id: expandButton
                width: 28
                height: 28
                radius: 14
                color: expandHov.hovered ? CachyPalette.surfacePill : "transparent"
                border.width: expandHov.hovered ? 1 : 0
                border.color: CachyPalette.specularBorder
                scale: expandTap.pressed ? 0.94 : (expandHov.hovered ? 1.06 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }

                CachyIcon {
                    anchors.centerIn: parent
                    name: "arrow-up"
                    size: 14
                    color: CachyPalette.textSecondary
                }

                CachyTooltip {
                    text: i18n("Open player")
                    visible: expandHov.hovered
                }

                HoverHandler { id: expandHov }
                TapHandler {
                    id: expandTap
                    onTapped: root.requestOpen()
                }
            }
        }
    }
}
