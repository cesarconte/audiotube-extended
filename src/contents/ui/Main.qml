// SPDX-FileCopyrightText: 2021 Jonah Brüchert <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtMultimedia

import org.kde.audiotube
import org.kde.config as KConfig
import CachyOS.UI

CachyWindow {
    id: root

    title: i18n("AudioTube")
    width: 1080
    height: 720
    minimumWidth: 420
    minimumHeight: 480

    showTrafficLights: true
    showTitleBarDivider: true
    showWindowFrame: true
    resizable: true
    cornerRadius: CachyTheme.radiusWindow
    contentPadded: false
    sidebarCollapsible: true
    sidebarVisible: wideScreen

    readonly property alias pageStack: pageStack
    property alias searchField: searchLoader
    property bool wideScreen: width >= 600
    property bool showSearch: false

    function applicationWindow() {
        return root;
    }

    KConfig.WindowStateSaver {
        configGroupName: "MainWindow"
    }

    Kirigami.PagePool {
        id: pool
        onLastLoadedItemChanged: if (lastLoadedItem) {
            if (['homePage', 'libraryPage', 'favourites', 'explorePage', 'history', 'playlists'].includes(lastLoadedItem.objectName)) {
                StateConfig.lastOpenedPage = lastLoadedItem.objectName;
                StateConfig.save();
            }
        }
    }

    Loader {
        id: shareMenu
        active: false
        sourceComponent: ShareMenu {}
    }

    function openShareMenu(inputTitle: string, url: string) {
        shareMenu.active = true
        shareMenu.item.inputTitle = inputTitle
        shareMenu.item.url = url
        shareMenu.item.open()
    }

    function play(videoId) {
        UserPlaylistModel.initialVideoId = videoId
    }

    function playPlaylist(playlistId) {
        UserPlaylistModel.playlistId = playlistId
    }

    function playShufflePlaylist(playlistId) {
        UserPlaylistModel.shuffle = true
        UserPlaylistModel.playlistId = playlistId
    }

    function playFavourites(shuffle) {
        UserPlaylistModel.playFavourites(Library.favourites, shuffle)
    }

    function playPlaybackHistory(model, shuffle) {
        UserPlaylistModel.playPlaybackHistory(model, shuffle)
    }

    function focusSearch() {
        searchLoader.forceFocus()
    }

    function showPassiveNotification(message, timeoutMs) {
        toast.show(message, "info", timeoutMs !== undefined ? timeoutMs : 3000)
    }

    Connections {
        target: ErrorHandler
        function onErrorOccurred(error) {
            showPassiveNotification(error)
        }
    }

    // =========================================================================
    // CABECERA — Navegación y control de barra lateral
    // =========================================================================
    headerLeading: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Control universal nativo de barra lateral (CachyOS.UI)
            CachySidebarToggleButton {
                visible: root.wideScreen
            }

            CachyToolbarButton {
                iconName: "draw-arrow-back"
                tooltipText: i18nc("@action:button", "Back")
                enabled: pageStack.depth > 1
                visible: root.wideScreen || pageStack.depth > 1
                onClicked: pageStack.goBack()
            }
            CachyToolbarButton {
                iconName: "draw-arrow-forward"
                tooltipText: i18nc("@action:button", "Forward")
                enabled: pageStack.currentIndex < pageStack.depth - 1
                visible: root.wideScreen
                onClicked: pageStack.goForward()
            }
        }
    ]

    // =========================================================================
    // CABECERA — Campo de búsqueda integrado en el centro
    // =========================================================================
    headerCenter: [
        Item {
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            width: Math.min(420, root.width - (root.wideScreen ? 340 : 120))

            SearchWithDropdown {
                id: searchLoader
                anchors.centerIn: parent
                width: parent.width
                height: 32
                visible: root.wideScreen || root.showSearch
            }
        }
    ]

    // =========================================================================
    // BARRA LATERAL — Contenido del menú de navegación
    // =========================================================================
    sidebar: [
        Sidebar {
            id: sidebar
        }
    ]

    // =========================================================================
    // CONTENIDO PRINCIPAL — Pila de páginas y reproductor multimedia
    // =========================================================================
    contentData: [
        Item {
            anchors.fill: parent

            CachyPageStack {
                id: pageStack
                anchors.fill: parent
                anchors.bottomMargin: root.wideScreen ? playerFooter.minimizedPlayerHeight : (playerFooter.minimizedPlayerHeight + bottombar.height)
            }

            NavigationBar {
                id: bottombar
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                visible: !root.wideScreen
            }

            // Reproductor multimedia inferior
            PlayerFooter {
                id: playerFooter
                anchors.fill: parent
                footerSpacing: root.wideScreen ? 0 : bottombar.height
                z: (contentY === 0) ? -1 : 999
            }

            // Notificación flotante Liquid Glass (reemplaza Kirigami.PassiveNotification)
            CachyToast {
                id: toast
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: playerFooter.minimizedPlayerHeight + 20
                z: 10000
            }
        }
    ]

    Component {
        id: searchAlbum

        ColumnLayout {
            id: mpdelegateItem

            required property string videoId
            required property string title

            width: 90
            Layout.maximumWidth: 70

            Kirigami.ShadowedRectangle {
                id: recCover
                MouseArea {
                    id: recArea
                    anchors.fill: parent
                    onClicked: play(mpdelegateItem.videoId)
                    hoverEnabled: !Kirigami.Settings.hasTransientTouchInput
                    onEntered: {
                        if (!Kirigami.Settings.hasTransientTouchInput) {
                            recSelected.visible = true
                            searchTitle.color = Kirigami.Theme.hoverColor
                            searchTitle.font.bold = true
                        }
                    }
                    onExited: {
                        recSelected.visible = false
                        searchTitle.color = Kirigami.Theme.textColor
                        searchTitle.font.bold = false
                    }
                }
                Layout.margins: 5

                width: 70
                height: 70
                radius: 10
                shadow.size: 15
                shadow.xOffset: 5
                shadow.yOffset: 5
                shadow.color: Qt.rgba(0, 0, 0, 0.2)
                Rectangle {
                    width: 70
                    height: 70
                    color: "transparent"

                    ThumbnailSource {
                        id: thumbnailSource
                        videoId: mpdelegateItem.videoId
                    }
                    RoundedImage {
                        source: thumbnailSource.cachedPath
                        height: parent.height
                        width: height
                        radius: 10
                    }
                    Rectangle {
                        id: recSelected
                        Rectangle {
                            anchors.fill: parent
                            color: Kirigami.Theme.hoverColor
                            radius: 10
                            opacity: 0.2
                        }
                        visible: false
                        anchors.fill: parent
                        radius: 9
                        border.color: Kirigami.Theme.hoverColor
                        border.width: 2
                        color: "transparent"
                    }
                }
            }
            Controls.Label {
                id: searchTitle
                leftPadding: 5
                Layout.maximumWidth: 70
                text: mpdelegateItem.title
                elide: Qt.ElideRight
                wrapMode: Text.WordWrap
                Layout.maximumHeight: 40
            }
            Item {
                height: 5
            }
        }
    }

    MprisPlayer {
        id: mprisPlayer
        serviceName: "AudioTube"

        property string artist: playerFooter.videoInfoExtractor.artist
        property string songTitle: playerFooter.videoInfoExtractor.title ? playerFooter.videoInfoExtractor.title : i18n("No song playing")
        property int songLength: playerFooter.audioPlayer.duration * 1000
        property alias thumbnail: playerFooter.thumbnail

        function next() {
            if (UserPlaylistModel.canSkip) {
                UserPlaylistModel.next()
            } else {
                playerFooter.audioPlayer.stop()
            }
        }

        // Mpris2 Root interface
        identity: root.title
        supportedUriSchemes: []
        supportedMimeTypes: []
        desktopEntry: "org.kde.audiotube"

        // Mpris2 Player Interface
        canControl: true
        canGoNext: UserPlaylistModel.canSkip
        canGoPrevious: UserPlaylistModel.canSkipBack
        canPause: playerFooter.audioPlayer ? playerFooter.audioPlayer.status !== MediaPlayer.NoMedia : false
        canPlay: playerFooter.audioPlayer ? playerFooter.audioPlayer.status !== MediaPlayer.NoMedia : false
        canSeek: false

        playbackStatus: (playerFooter.audioPlayer && playerFooter.audioPlayer.playbackState === MediaPlayer.PlayingState) ? Mpris.Playing : ((playerFooter.audioPlayer && playerFooter.audioPlayer.playbackState === MediaPlayer.PausedState) ? Mpris.Paused : Mpris.Stopped)
        shuffle: false
        volume: playerFooter.audioOutput ? (playerFooter.audioOutput.muted ? 0.0 : playerFooter.audioOutput.volume) : 1.0
        position: playerFooter.audioPlayer ? playerFooter.audioPlayer.position * 1000 : 0

        onPauseRequested: if (playerFooter.audioPlayer) playerFooter.audioPlayer.pause()
        onPlayRequested: if (playerFooter.audioPlayer) playerFooter.audioPlayer.play()
        onPlayPauseRequested: {
            if (playerFooter.audioPlayer) {
                if (playerFooter.audioPlayer.playbackState === MediaPlayer.PlayingState) {
                    playerFooter.audioPlayer.pause()
                } else {
                    playerFooter.audioPlayer.play()
                }
            }
        }
        onStopRequested: if (playerFooter.audioPlayer) playerFooter.audioPlayer.stop()
        onNextRequested: {
            next()
        }
        onPreviousRequested: {
            if (UserPlaylistModel.canSkipBack) {
                UserPlaylistModel.previous()
            } else {
                playerFooter.audioPlayer.stop()
            }
        }
        onSeekRequested: {
            if (canSeek) {
                if (playerFooter.audioPlayer.position + offset/1000 < 0) {
                    playerFooter.audioPlayer.seek(0)
                } else if (playerFooter.audioPlayer.position + offset/1000 > playerFooter.audioPlayer.duration) {
                    next()
                } else {
                    playerFooter.audioPlayer.seek(Math.floor(playerFooter.audioPlayer.position + offset/1000));
                }
                emitSeeked()
            }
        }
        onSetPositionRequested: {
            if (canSeek) {
                if (position >= 0 && position/1000 <= playerFooter.audioPlayer.duration) {
                    playerFooter.audioPlayer.seek(Math.floor(position/1000))
                    emitSeeked()
                }
            }
        }
        onShuffleRequested: {
            UserPlaylistModel.shufflePlaylist()
        }

        onArtistChanged: {
            var metadata = mprisPlayer.metadata
            metadata[Mpris.metadataToString(Mpris.Artist)] = [artist]
            mprisPlayer.metadata = metadata
        }
        onSongTitleChanged: {
            var metadata = mprisPlayer.metadata
            metadata[Mpris.metadataToString(Mpris.Title)] = songTitle
            mprisPlayer.metadata = metadata
        }
        onSongLengthChanged: {
            var metadata = mprisPlayer.metadata
            metadata[Mpris.metadataToString(Mpris.Length)] = songLength
            mprisPlayer.metadata = metadata
        }
        onThumbnailChanged: {
            var metadata = mprisPlayer.metadata
            metadata[Mpris.metadataToString(Mpris.ArtUrl)] = thumbnail
            mprisPlayer.metadata = metadata
        }
    }

    Component.onCompleted: {
        let page = null;
        switch (StateConfig.lastOpenedPage) {
        case 'libraryPage':
            page = pool.loadPage(Qt.resolvedUrl('./LibraryPage.qml'));
            break;
        case 'homePage':
            page = pool.loadPage(Qt.resolvedUrl('./HomePage.qml'));
            break;
        case 'favourites':
            page = pool.loadPageWithProperties(Qt.resolvedUrl('./PlaybackHistory.qml#favourites'), {
                "title": i18n("Favorites"),
                "objectName": "favourites"
            });
            break;
        case 'history':
            page = pool.loadPageWithProperties(Qt.resolvedUrl('./PlaybackHistory.qml#history'), {
                "title": i18n("Played Songs"),
                "objectName": "history"
            });
            break;
        case 'explorePage':
            page = pool.loadPage(Qt.resolvedUrl('./ExplorePage.qml'));
            break;
        case 'playlists':
            page = pool.loadPageWithProperties(Qt.resolvedUrl("./LocalPlaylistsPage.qml"), {
                "objectName": "playlists"
            });
            break;
        default:
            page = pool.loadPage(Qt.resolvedUrl('./HomePage.qml'));
        }
        if (page) {
            pageStack.push(page);
        }
    }
}
