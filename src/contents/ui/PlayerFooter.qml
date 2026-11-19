// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2021 Bart De Vries <bart@mogwai.be>
// SPDX-FileCopyrightText: 2020-2022 Devin Lin <devin@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls as Controls

import QtMultimedia

import org.kde.kirigami as Kirigami
import org.kde.audiotube
import CachyOS.UI

Flickable {
    id: footerItem

    property int footerSpacing: 0
    property bool maximized: contentY >= height * 0.5

    readonly property int progressBarHeight: 3
    readonly property int minimizedPlayerContentHeight: 64
    readonly property int minimizedPlayerHeight: minimizedPlayerContentHeight + progressBarHeight

    readonly property string thumbnail: thumbnailSource.cachedPath

    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function close() {
        toClose.restart();
    }

    function resetToBoundsOnFlick() {
        if (!atYBeginning || !atYEnd) {
            if (footerItem.verticalVelocity > 0) {
                toOpen.restart();
            } else if (footerItem.verticalVelocity < 0) {
                toClose.restart();
            } else { // i.e. when verticalVelocity === 0
                if (contentY > contentHeight / 4) {
                    toOpen.restart();
                } else  {
                    toClose.restart();
                }
            }
        }
    }

    function resetToBoundsOnResize() {
        if (contentY > contentHeight / 4) {
            contentY = contentHeight / 2;
        } else {
            contentY = 0;
        }
    }

    NumberAnimation on contentY {
        id: toOpen
        from: contentY
        to: contentHeight / 2
        duration: Kirigami.Units.longDuration * 2
        easing.type: Easing.OutCubic
        running: false
    }

    NumberAnimation on contentY {
        id: toClose
        from: contentY
        to: 0
        duration: Kirigami.Units.longDuration * 2
        easing.type: Easing.OutCubic
        running: false
    }

    // snap to end
    MouseArea {
        anchors.fill: footerLayout
        propagateComposedEvents: true
        onPressed: {
            toOpen.stop();
            toClose.stop();
            propagateComposedEvents = true;
        }
        onReleased: footerItem.resetToBoundsOnFlick()
    }

    onMovementStarted: {
        toOpen.stop();
        toClose.stop();
    }
    onFlickStarted: resetToBoundsOnFlick()
    onMovementEnded: resetToBoundsOnFlick()
    onHeightChanged: resetToBoundsOnResize()

    property var syncedLyricsModel: LyricsModel {
        id: syncedLyrics
    }

    property var videoInfoExtractor: VideoInfoExtractor {
        id: info

        videoId: UserPlaylistModel.currentVideoId
        onTitleChanged: {
            let index = UserPlaylistModel.index(UserPlaylistModel.currentIndex, 0)
            let videoId = UserPlaylistModel.data(index, UserPlaylistModel.VideoId)
            let title = UserPlaylistModel.data(index, UserPlaylistModel.Title)
            let artist = UserPlaylistModel.data(index, UserPlaylistModel.Artists)
            let artistId = UserPlaylistModel.data(index, UserPlaylistModel.ArtistId)
            let album = UserPlaylistModel.data(index, UserPlaylistModel.Album)
            let albumId = UserPlaylistModel.data(index, UserPlaylistModel.AlbumId)
            let duration = UserPlaylistModel.data(index, UserPlaylistModel.Duration)

            syncedLyrics.song = title
            syncedLyrics.artist = artist
            syncedLyrics.album = album
            syncedLyrics.duration = duration
            syncedLyrics.fetchLyrics()

            Library.addPlaybackHistoryItem(videoId, title, artist, artistId, album, albumId)
        }
    }

    ThumbnailSource {
        id: thumbnailSource
        videoId: UserPlaylistModel.currentVideoId
    }

    property MediaPlayer audioPlayer: audioLoader.item
    property AudioOutput audioOutput: audioLoader.item ? audioLoader.item.audioOutput : null

    Loader {
        id: audioLoader
        active: true
        asynchronous: false
        onLoaded: {
            if (audioLoader.item && info.audioUrl != "") {
                audioLoader.item.play();
            }
        }
        sourceComponent: MediaPlayer {
            id: audio

            property int prevPlaybackState: MediaPlayer.StoppedState
            source: info.audioUrl
            onSourceChanged: {
                if (source != "") {
                    play();
                }
            }

            onErrorOccurred: (error, errorString) => {
                console.warn("MediaPlayer errorOccurred:", error, errorString);
                if (info.tryNextFormat()) {
                    console.log("Retrying with fallback audio format...");
                    play();
                }
            }

            onPlaybackStateChanged: {
                if (mediaStatus == MediaPlayer.BufferingMedia && playbackState == MediaPlayer.StoppedState && prevPlaybackState == MediaPlayer.PlayingState) {
                    Qt.callLater(function() {
                        play()
                        console.log("force play on stuck with BufferingMedia & StoppedState");
                    })
                }
                prevPlaybackState = playbackState
            }

            onMediaStatusChanged: {
                if (mediaStatus === MediaPlayer.InvalidMedia) {
                    console.warn("MediaPlayer InvalidMedia detected");
                    if (info.tryNextFormat()) {
                        console.log("Retrying with fallback audio format...");
                        play();
                    }
                } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                    console.log("Song ended");
                    UserPlaylistModel.next();
                }
            }

            audioOutput: AudioOutput {
                id: audioOutput
            }
        }
    }

    contentHeight: height * 2

    ColumnLayout {
        id: footerLayout
        y:-footerSpacing
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // margin from top
        Item {
            Layout.minimumHeight: footerItem.height - footerItem.minimizedPlayerHeight
        }

        Controls.Control {
            Layout.fillWidth: true
            padding: 0
            implicitHeight: footerItem.minimizedPlayerHeight + footerSpacing
            visible: opacity > 0.005
            opacity: Math.max(0.0, 1.0 - (footerItem.contentY / Math.max(1, footerItem.minimizedPlayerHeight)))

            // Minimized player background: pure Liquid Glass surface with high contrast
            background: Rectangle {
                id: minPlayerBg
                color: CachyPalette.isDark
                    ? Qt.rgba(0.11, 0.11, 0.15, 0.86 + (CachyTheme.glassOpacity * 0.08))
                    : Qt.rgba(0.97, 0.97, 0.99, 0.88 + (CachyTheme.glassOpacity * 0.08))

                // Top 1px hard structural divider
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: CachyPalette.hardDividerColor
                    z: 10
                }

                // Top 1px specular refraction highlight below the divider
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.60)
                    z: 9
                }

                // Ambient artwork blur (subtle, non-darkening, visible only with track loaded)
                Item {
                    anchors.fill: parent
                    visible: thumbnailSource.cachedPath.length > 0 && info.title.length > 0
                    clip: true
                    opacity: CachyPalette.isDark ? 0.22 : 0.12

                    Image {
                        id: bgArt
                        anchors.fill: parent
                        source: thumbnailSource.cachedPath
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
                        layer.effect: MultiEffect {
                            blur: 1.0
                            blurMultiplier: 3.0
                            blurEnabled: true
                            autoPaddingEnabled: false
                        }
                    }
                }
            }

            MinimizedPlayerControls {
                progressBarHeight: footerItem.progressBarHeight
                minimizedPlayerContentHeight: footerItem.minimizedPlayerContentHeight
                height: footerItem.minimizedPlayerHeight

                focus: true
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                thumbnail: thumbnailSource.cachedPath
                info: footerItem.videoInfoExtractor
                audio: footerItem.audioPlayer

                onRequestOpen: toOpen.start();
            }
        }

        MaximizedPlayerPage {
            id: maximizedPlayerPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: footerItem.height

            thumbnail: footerItem.videoInfoExtractor.thumbnail
            info: footerItem.videoInfoExtractor
            audio: footerItem.audioPlayer
            syncedLyrics: footerItem.syncedLyricsModel

            onRequestClose: toClose.start();
        }
    }
}
