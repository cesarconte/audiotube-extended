// SPDX-FileCopyrightText: 2020-2022 Devin Lin <devin@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls
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

    readonly property bool isWidescreen: width >= Kirigami.Units.gridUnit * 50
    signal requestOpen()
    Shortcut {
        sequence: "Ctrl+P"
        onActivated: root.requestOpen()
    }
    Rectangle {
        id: miniProgressBar
        z: 1
        anchors.top: parent.top
        anchors.left: parent.left
        height: root.progressBarHeight
        color: CachyTheme.accentColor
        width: parent.width * (audio?.position / audio?.duration)
    }

    states: [
        State {
            when: root.isWidescreen
            AnchorChanges {
                target: controlButtonBox
                anchors.horizontalCenter: root.horizontalCenter
            }
        },
        State {
            when: true // default (fallback) state
            AnchorChanges {
                target: controlButtonBox
                anchors.right: root.right
            }
        }
    ]

    Rectangle {
        id: trackInfoLayout

        anchors {
            top: parent.top
            left: parent.left
            bottom: parent.bottom

            right: controlButtonBox.left
            rightMargin: Kirigami.Units.largeSpacing
        }

        color: Qt.rgba(0, 0, 0, trackClick.containsMouse ? 0.1 : trackClick.pressed ? 0.3 : 0)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            // track image
            Item {
                property double imageSize: root.height - Kirigami.Units.largeSpacing * 2

                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: imageSize
                Layout.preferredWidth: imageSize
                Layout.maximumHeight: imageSize
                Layout.minimumHeight: imageSize

                RoundedImage {
                    id: mainIcon
                    anchors.fill: parent
                    visible: !loadingIndicator.visible && source.toString() !== ""
                    source: root.thumbnail
                    radius: 5
                }

                BusyIndicator {
                    id: loadingIndicator
                    anchors.centerIn: parent
                    visible: UserPlaylistModel.loading
                    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
                    Kirigami.Theme.inherit: false
                }
            }

            // track information
            ColumnLayout {
                Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
                Layout.fillWidth: true
                Layout.fillHeight: true

                Label {
                    id: mainLabel
                    text: info.title ? info.title : i18n("No media playing")
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    color: CachyPalette.text
                    font.weight: Font.Bold
                }

                Label {
                    id: authorLabel
                    text: info.artist ? info.artist : info.channel
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    color: CachyPalette.textSecondary
                }
            }
        }
        MouseArea {
            id: trackClick
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.requestOpen()
        }
    }

    RowLayout {
        id: controlButtonBox

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        // horizontal anchors (center or right) are managed by state
        // transitions at the root component

        spacing: 2

        Label {
            color: CachyPalette.textSecondary
            visible: info.title && root.isWidescreen
            text: PlayerUtils.formatTimestamp(audio.position)
            Layout.rightMargin: 16
        }

        Button {
            id: skipBackwardButton
            implicitHeight: 36
            implicitWidth: 38
            Layout.fillHeight: !isWidescreen

            enabled: UserPlaylistModel.canSkipBack
            onClicked: UserPlaylistModel.previous()

            contentItem: Item {
                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "media-skip-backward"
                    color: skipBackwardButton.enabled ? CachyPalette.text : CachyPalette.textMuted
                    width: 16
                    height: 16
                }
            }

            background: Kirigami.ShadowedRectangle {
                corners.topLeftRadius: isWidescreen ? 8 : 0
                corners.bottomLeftRadius: isWidescreen ? 8 : 0

                color: {
                    if (skipBackwardButton.down) return CachyTheme.withAlpha(CachyTheme.accentColor, 0.3);
                    if (skipBackwardButton.hovered) return CachyPalette.surfacePill;
                    return isWidescreen ? (CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent";
                }
            }
        }

        Button {
            id: playPauseButton
            implicitHeight: 36
            implicitWidth: 50
            Layout.fillHeight: !isWidescreen

            onClicked: audio.playbackState === MediaPlayer.PlayingState ? audio.pause() : audio.play()
            contentItem: Item {
                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: audio.playbackState === MediaPlayer.PlayingState ? "media-playback-pause" : "media-playback-start"
                    color: CachyPalette.text
                    width: 18
                    height: 18
                }
            }

            background: Kirigami.ShadowedRectangle {
                color: {
                    if (playPauseButton.down) return CachyTheme.withAlpha(CachyTheme.accentColor, 0.3);
                    if (playPauseButton.hovered) return CachyPalette.surfacePill;
                    return isWidescreen ? (CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent";
                }
            }
        }

        Button {
            id: skipForwardButton
            implicitHeight: 36
            implicitWidth: 38
            Layout.fillHeight: !isWidescreen
            Layout.rightMargin: isWidescreen ? 0 : 10

            enabled: UserPlaylistModel.canSkip
            onClicked: UserPlaylistModel.next()
            contentItem: Item {
                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "media-skip-forward"
                    color: skipForwardButton.enabled ? CachyPalette.text : CachyPalette.textMuted
                    width: 16
                    height: 16
                }
            }
            background: Kirigami.ShadowedRectangle {
                corners.topRightRadius: isWidescreen ? 8 : 0
                corners.bottomRightRadius: isWidescreen ? 8 : 0
                color: {
                    if (skipForwardButton.down) return CachyTheme.withAlpha(CachyTheme.accentColor, 0.3);
                    if (skipForwardButton.hovered) return CachyPalette.surfacePill;
                    return isWidescreen ? (CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent";
                }
            }
        }

        Label {
            color: CachyPalette.textSecondary
            visible: info.title && root.isWidescreen
            text: PlayerUtils.formatTimestamp(audio.duration)
            Layout.leftMargin: 16
        }
    }
}
