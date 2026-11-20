// SPDX-FileCopyrightText: 2023 Mathis Brüchert <mbb@kaidan.im>
// SPDX-FileCopyrightText: 2026 CachyOS UI contributors
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import CachyOS.UI
import org.kde.audiotube

Controls.Dialog {
    id: playlistsDialog

    title: i18n("Add Song to Playlist")
    anchors.centerIn: parent
    width: Math.min(parent ? parent.width - 32 : 380, 380)
    modal: true

    property string videoId
    property string songTitle
    property string artists
    property string artistId
    property string album: ""
    property string albumId

    standardButtons: Controls.Dialog.Close

    background: Rectangle {
        radius: CachyTheme.radiusLarge
        color: CachyTheme.isDark ? Qt.rgba(0.12, 0.12, 0.16, 0.98) : Qt.rgba(0.97, 0.98, 1.0, 0.98)
        border.width: 1
        border.color: CachyTheme.specularBorder
    }

    AddPlaylistDialog {
        id: addPlaylistDialog
        model: localPlaylistsModel
    }

    header: Item {
        width: parent.width
        implicitHeight: 48

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            Text {
                text: playlistsDialog.title
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: CachyTheme.textPrimary
                Layout.fillWidth: true
            }

            CachyButton {
                iconName: "add"
                text: i18n("New Playlist")
                primary: true
                implicitHeight: 28
                onClicked: addPlaylistDialog.open()
            }
        }
    }

    contentItem: ListView {
        id: playListView
        implicitHeight: Math.min(260, Math.max(120, count * 48))
        clip: true
        spacing: 4

        model: LocalPlaylistsModel {
            id: localPlaylistsModel
        }

        delegate: Rectangle {
            id: playlistDelegate
            required property string title
            required property string description
            required property int playlistId
            required property var thumbnailIds
            required property int index

            width: playListView.width
            height: 44
            radius: CachyTheme.radiusSmall
            color: delHover.hovered ? CachyTheme.cardBackgroundHover : "transparent"
            border.color: delHover.hovered ? CachyTheme.specularBorder : "transparent"
            border.width: 1

            Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

            HoverHandler { id: delHover }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10

                ThumbnailSource {
                    id: thumbnailSource1
                    videoId: playlistDelegate.thumbnailIds[0] ?? ""
                }
                ThumbnailSource {
                    id: thumbnailSource2
                    videoId: playlistDelegate.thumbnailIds[1] ?? playlistDelegate.thumbnailIds[0] ?? ""
                }
                ThumbnailSource {
                    id: thumbnailSource3
                    videoId: playlistDelegate.thumbnailIds[2] ?? playlistDelegate.thumbnailIds[0] ?? ""
                }
                ThumbnailSource {
                    id: thumbnailSource4
                    videoId: playlistDelegate.thumbnailIds[3] ?? playlistDelegate.thumbnailIds[0] ?? ""
                }

                PlaylistCover {
                    source1: thumbnailSource1.cachedPath
                    source2: thumbnailSource2.cachedPath
                    source3: thumbnailSource3.cachedPath
                    source4: thumbnailSource4.cachedPath
                    height: 32
                    width: 32
                    radius: 4
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: playlistDelegate.title
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: CachyTheme.textPrimary
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: playlistDelegate.description.length > 0
                        color: CachyTheme.textSecondary
                        text: playlistDelegate.description
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
            }

            TapHandler {
                onTapped: {
                    localPlaylistsModel.addPlaylistEntry(playlistDelegate.playlistId, playlistsDialog.videoId, playlistsDialog.songTitle, playlistsDialog.artists, playlistsDialog.artistId, playlistsDialog.album, playlistsDialog.albumId)
                    playlistsDialog.close()
                }
            }
        }
    }
}
