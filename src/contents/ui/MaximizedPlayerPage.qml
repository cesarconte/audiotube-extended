// SPDX-FileCopyrightText: 2020-2022 Devin Lin <devin@kde.org>
// SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Controls as Controls
import QtQuick.Layouts

import QtMultimedia

import org.kde.kirigami as Kirigami
import org.kde.audiotube
import CachyOS.UI

Item {
    id: root

    required property VideoInfoExtractor info
    required property MediaPlayer audio
    required property LyricsModel syncedLyrics
    required property string thumbnail
    readonly property bool wideScreen: root.width >= 540

    signal requestClose()

    onWidthChanged: {
        if (sideDrawer.visible && !sideDrawer.collapsed && !sideDrawer.isAnimating) {
            if (root.width >= 540) {
                let maxAllowed = root.width - 280;
                if (sideDrawer.targetWidth > maxAllowed) {
                    sideDrawer.targetWidth = Math.max(260, maxAllowed);
                }
                sideDrawer.Layout.preferredWidth = sideDrawer.targetWidth;
            } else {
                sideDrawer.Layout.preferredWidth = root.width;
            }
        }
    }

    // =========================================================================
    // FONDO — Base opaca Liquid Glass + Ambient Artwork Blur + Divisores
    // =========================================================================

    // 1. Base opaca Liquid Glass para evitar filtración de la página subyacente
    Rectangle {
        anchors.fill: parent
        color: CachyPalette.isDark ? Qt.rgba(0.08, 0.08, 0.12, 0.96) : Qt.rgba(0.95, 0.95, 0.97, 0.96)
        z: -3
    }

    // 2. Capa ambiental difuminada de la portada
    Item {
        id: bg
        anchors.fill: parent
        clip: true
        z: -2
        opacity: CachyPalette.isDark ? 0.28 : 0.16

        Image {
            anchors.fill: parent
            asynchronous: true
            source: root.thumbnail
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 512
            sourceSize.height: 512
            layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
            layer.effect: MultiEffect {
                blur: 1.0
                blurMax: 48
                blurMultiplier: 3.5
                blurEnabled: true
                autoPaddingEnabled: false
                saturation: 0.6
                brightness: CachyPalette.isDark ? -0.1 : 0.0
            }
        }
    }

    // 3. Viñeta oscura sutil
    Rectangle {
        anchors.fill: parent
        z: -1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.12) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.40) }
        }
    }

    // 4. Divisor superior de 1px
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: CachyPalette.hardDividerColor
        z: 10
    }

    // 5. Reflejo especular superior de 1px
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.50)
        z: 9
    }

    PlaylistDialog {
        id: playlistsDialog
    }

    // =========================================================================
    // CONTENIDO — Estructura centrada simétrica según CachyOS.UI Golden Gate
    // =========================================================================
    RowLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            id: mainContent
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // 1. Barra superior: botón de colapsar centrado
            Item {
                id: topBar
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                Layout.topMargin: 4

                CachyToolbarButton {
                    id: closeButton
                    anchors.centerIn: parent
                    iconName: "arrow-down"
                    tooltipText: i18n("Close Maximized Player")
                    onClicked: root.requestClose()
                }
            }

            // Espaciador elástico superior: centra los controles en la vertical
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // 2. Grupo principal de reproducción (centrado horizontal y verticalmente)
            ColumnLayout {
                id: playbackCenterGroup
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.maximumWidth: 540
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                spacing: 0

                // A. Carátula del álbum o Letras (SwipeView)
                SwipeView {
                    id: swipeView
                    interactive: false
                    clip: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: 500
                    Layout.preferredHeight: currentIndex === 1
                        ? Math.min(root.height * 0.45, 340)
                        : artworkCard.artworkSize

                    // Página 0: Portada del álbum perfectamente centrada
                    Item {
                        id: coverArtPage
                        width: swipeView.width
                        height: swipeView.height

                        Rectangle {
                            id: artworkCard
                            readonly property real artworkSize: Math.min(
                                swipeView.width - 32,
                                Math.max(160, (root.height - 310) * 0.70),
                                300
                            )
                            anchors.centerIn: parent
                            width: artworkSize
                            height: artworkSize
                            radius: CachyTheme.radiusLarge
                            color: Qt.rgba(1, 1, 1, 0.06)
                            clip: true

                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.14)

                            Image {
                                anchors.fill: parent
                                source: root.thumbnail
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: root.thumbnail.length > 0
                            }

                            CachyIcon {
                                anchors.centerIn: parent
                                name: "audio-x-generic"
                                width: 64
                                height: 64
                                visible: root.thumbnail.length === 0
                                color: Qt.rgba(1, 1, 1, 0.40)
                            }
                        }
                    }

                    // Página 1: Letras sincronizadas o estáticas
                    ColumnLayout {
                        width: swipeView.width
                        height: swipeView.height

                        ScrollView {
                            visible: root.syncedLyrics.count > 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignHCenter
                            clip: true

                            ListView {
                                id: syncedView
                                model: root.syncedLyrics

                                NumberAnimation {
                                    id: smoothScroll
                                    target: syncedView
                                    property: "contentY"
                                    duration: 250
                                }

                                delegate: Controls.Label {
                                    id: lineLabel
                                    required property string line
                                    required property int index
                                    required property int start
                                    required property int end

                                    property bool active: (start < audio.position / 1000 && end > audio.position / 1000)

                                    color: active ? "#FFFFFF" : Qt.rgba(1, 1, 1, 0.55)
                                    text: line
                                    font.pixelSize: active ? 17 : 14
                                    font.weight: active ? Font.Bold : Font.Normal
                                    horizontalAlignment: Text.AlignHCenter
                                    width: parent ? parent.width : 0
                                    wrapMode: Text.Wrap

                                    onActiveChanged: {
                                        if (active) {
                                            var pos = syncedView.contentY;
                                            syncedView.positionViewAtIndex(Math.max(0, index - 2), ListView.Beginning);
                                            smoothScroll.from = pos;
                                            smoothScroll.to = syncedView.contentY;
                                            smoothScroll.running = true;
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.audio.position = lineLabel.start * 1000
                                    }
                                }
                            }
                        }

                        ScrollView {
                            visible: root.syncedLyrics.count === 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignHCenter
                            clip: true

                            Controls.Label {
                                id: lyrics
                                padding: 16
                                width: parent ? parent.width : 0
                                font.pixelSize: 15
                                text: UserPlaylistModel.lyrics
                                color: "#FFFFFF"
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }

                // Separador entre carátula y texto
                Item {
                    height: 18
                    Layout.preferredHeight: 18
                }

                // B. Título de la pista (alto contraste, centrado)
                Text {
                    id: mainLabel
                    text: root.info.title ? root.info.title : i18n("No media playing")
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    color: "#FFFFFF"
                    font.pixelSize: 19
                    font.weight: Font.Bold
                }

                // Separador de 4px
                Item {
                    height: 4
                    Layout.preferredHeight: 4
                }

                // C. Artista y Álbum (centrado, interactivo)
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: playbackCenterGroup.width
                    spacing: 6

                    Text {
                        id: authorLabel
                        text: root.info.artist ? root.info.artist : (root.info.channel ? root.info.channel : "")
                        color: Qt.rgba(1, 1, 1, 0.75)
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        maximumLineCount: 1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: root.info.artistId !== ""
                            onClicked: {
                                pageStack.push("qrc:/qt/qml/org/kde/audiotube/contents/ui/ArtistPage.qml", {
                                    "channelId": root.info.artistId
                                });
                                root.requestClose();
                            }
                        }
                    }

                    Text {
                        text: "•"
                        visible: authorLabel.text.length > 0 && albumLabel.text.length > 0
                        color: Qt.rgba(1, 1, 1, 0.40)
                        font.pixelSize: 12
                    }

                    Text {
                        id: albumLabel
                        text: root.info.album ? root.info.album : ""
                        visible: text.length > 0
                        color: Qt.rgba(1, 1, 1, 0.60)
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        maximumLineCount: 1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: root.info.albumId !== ""
                            onClicked: {
                                pageStack.push("qrc:/qt/qml/org/kde/audiotube/contents/ui/AlbumPage.qml", {
                                    "browseId": root.info.albumId
                                });
                                root.requestClose();
                            }
                        }
                    }
                }

                // Separador antes de los controles de reproducción
                Item {
                    height: 18
                    Layout.preferredHeight: 18
                }

                // D. Botones de transporte (Skip Prev, Play/Pause 56px acento, Skip Next)
                RowLayout {
                    id: controlButtonBox
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 24

                    // Skip Previous (38px circular pill)
                    Rectangle {
                        id: prevBtn
                        width: 38
                        height: 38
                        radius: 19
                        color: prevMouse.pressed
                            ? Qt.rgba(1, 1, 1, 0.22)
                            : (prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08))
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        scale: prevMouse.pressed ? 0.94 : (prevMouse.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        opacity: UserPlaylistModel.canSkipBack ? 1.0 : 0.4
                        enabled: UserPlaylistModel.canSkipBack

                        CachyIcon {
                            anchors.centerIn: parent
                            name: "media-skip-backward"
                            width: 18
                            height: 18
                            color: "#FFFFFF"
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: UserPlaylistModel.previous()
                        }
                    }

                    // Play/Pause Primary Accent Button (56px círculo)
                    Rectangle {
                        id: playPauseBtn
                        width: 56
                        height: 56
                        radius: 28
                        color: CachyTheme.accentColor
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.22)
                        scale: playPauseMouse.pressed ? 0.93 : (playPauseMouse.containsMouse ? 1.05 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

                        CachyIcon {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: (root.audio.playbackState === MediaPlayer.PlayingState) ? 0 : 1.5
                            name: (root.audio.playbackState === MediaPlayer.PlayingState)
                                ? "media-playback-pause"
                                : "media-playback-start"
                            width: 24
                            height: 24
                            color: "#FFFFFF"
                        }

                        MouseArea {
                            id: playPauseMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.audio.playbackState === MediaPlayer.PlayingState) {
                                    root.audio.pause();
                                } else {
                                    root.audio.play();
                                }
                            }
                        }
                    }

                    // Skip Next (38px circular pill)
                    Rectangle {
                        id: nextBtn
                        width: 38
                        height: 38
                        radius: 19
                        color: nextMouse.pressed
                            ? Qt.rgba(1, 1, 1, 0.22)
                            : (nextMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08))
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        scale: nextMouse.pressed ? 0.94 : (nextMouse.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        opacity: UserPlaylistModel.canSkip ? 1.0 : 0.4
                        enabled: UserPlaylistModel.canSkip

                        CachyIcon {
                            anchors.centerIn: parent
                            name: "media-skip-forward"
                            width: 18
                            height: 18
                            color: "#FFFFFF"
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: UserPlaylistModel.next()
                        }
                    }
                }

                // Separador antes de la línea de tiempo
                Item {
                    height: 16
                    Layout.preferredHeight: 16
                }

                // E. Barra de progreso y marcas de tiempo
                RowLayout {
                    id: timelineRow
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        id: elapsedText
                        text: PlayerUtils.formatTimestamp(root.audio.position)
                        font.pixelSize: 12
                        font.family: "monospace"
                        color: Qt.rgba(1, 1, 1, 0.75)
                        Layout.minimumWidth: 42
                        horizontalAlignment: Text.AlignRight
                    }

                    CachySlider {
                        id: timelineSlider
                        Layout.fillWidth: true
                        accentColor: CachyTheme.accentColor
                        from: 0
                        to: Math.max(1, root.audio.duration)
                        value: root.audio.position
                        enabled: root.audio.seekable
                        onMoved: {
                            root.audio.position = Math.floor(value);
                        }
                    }

                    Text {
                        id: durationText
                        text: PlayerUtils.formatTimestamp(root.audio.duration)
                        font.pixelSize: 12
                        font.family: "monospace"
                        color: Qt.rgba(1, 1, 1, 0.75)
                        Layout.minimumWidth: 42
                        horizontalAlignment: Text.AlignLeft
                    }
                }

                // Separador antes de las acciones inferiores
                Item {
                    height: 16
                    Layout.preferredHeight: 16
                }

                // F. Barra de las 5 acciones principales (Favoritos, Letras, Compartir, Playlist, Cola)
                RowLayout {
                    id: actionToolbar
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    // 1. Favorito
                    CachyToolbarButton {
                        id: favouriteButton
                        implicitWidth: 32
                        implicitHeight: 32
                        readonly property QtObject favouriteWatcher: Library.favouriteWatcher(root.info.videoId)
                        iconName: (favouriteWatcher && favouriteWatcher.isFavourite) ? "starred-symbolic" : "non-starred-symbolic"
                        tooltipText: (favouriteWatcher && favouriteWatcher.isFavourite) ? i18n("Remove from Favorites") : i18n("Add to Favorites")
                        onClicked: {
                            if (favouriteWatcher && favouriteWatcher.isFavourite) {
                                Library.removeFavourite(root.info.videoId);
                            } else {
                                let index = UserPlaylistModel.index(UserPlaylistModel.currentIndex, 0);
                                let videoId = (index.valid ? UserPlaylistModel.data(index, UserPlaylistModel.VideoId) : "") || root.info.videoId;
                                let title = (index.valid ? UserPlaylistModel.data(index, UserPlaylistModel.Title) : "") || root.info.title;
                                let artist = (index.valid ? UserPlaylistModel.data(index, UserPlaylistModel.Artists) : "") || root.info.artist;
                                let artistId = (index.valid ? UserPlaylistModel.data(index, UserPlaylistModel.ArtistId) : "") || root.info.artistId;
                                let album = (index.valid ? UserPlaylistModel.data(index, UserPlaylistModel.Album) : "") || root.info.album;
                                let albumId = (index.valid ? UserPlaylistModel.data(index, UserPlaylistModel.AlbumId) : "") || root.info.albumId;
                                if (videoId && videoId.length > 0) {
                                    Library.addFavourite(videoId, title, artist, artistId, album, albumId);
                                }
                            }
                        }
                    }

                    // 2. Conmutador de Letras
                    CachyToolbarButton {
                        id: lyricsButton
                        implicitWidth: 32
                        implicitHeight: 32
                        iconName: "view-media-lyrics"
                        tooltipText: swipeView.currentIndex === 1 ? i18n("Hide Lyrics") : i18n("Show Lyrics")
                        checkable: true
                        checked: swipeView.currentIndex === 1
                        enabled: UserPlaylistModel.lyrics.length > 0 || root.syncedLyrics.count > 0
                        onClicked: {
                            if (swipeView.currentIndex === 1) {
                                swipeView.setCurrentIndex(0);
                            } else {
                                swipeView.setCurrentIndex(1);
                            }
                        }

                        Connections {
                            target: UserPlaylistModel
                            function onNoLyrics() {
                                if (swipeView.currentIndex === 1 && root.syncedLyrics.count === 0) {
                                    swipeView.setCurrentIndex(0);
                                }
                            }
                        }
                    }

                    // 3. Compartir Canción
                    CachyToolbarButton {
                        id: shareButton
                        implicitWidth: 32
                        implicitHeight: 32
                        iconName: "document-share"
                        tooltipText: i18n("Share Song")
                        enabled: (root.info.title && root.info.title.length > 0) || (root.info.videoId && root.info.videoId.length > 0)
                        onClicked: {
                            let songUrl = UserPlaylistModel.webUrl;
                            if (!songUrl || songUrl.length === 0) {
                                songUrl = "https://music.youtube.com/watch?v=" + root.info.videoId;
                            }
                            openShareMenu(root.info.title, songUrl);
                        }
                    }

                    // 4. Añadir a lista de reproducción local
                    CachyToolbarButton {
                        id: addToPlaylistButton
                        implicitWidth: 32
                        implicitHeight: 32
                        iconName: "media-playlist-append"
                        tooltipText: i18n("Add to a local playlist")
                        enabled: root.info.videoId ? root.info.videoId.length > 0 : false
                        onClicked: {
                            let index = UserPlaylistModel.index(UserPlaylistModel.currentIndex, 0);
                            playlistsDialog.videoId = (index.valid ? UserPlaylistModel.data(index, UserPlaylistModel.VideoId) : "") || root.info.videoId;
                            playlistsDialog.songTitle = (index.valid ? UserPlaylistModel.data(index, UserPlaylistModel.Title) : "") || root.info.title;
                            playlistsDialog.artists = (index.valid ? UserPlaylistModel.data(index, UserPlaylistModel.Artists) : "") || root.info.artist;
                            playlistsDialog.artistId = (index.valid ? UserPlaylistModel.data(index, UserPlaylistModel.ArtistId) : "") || root.info.artistId;
                            playlistsDialog.album = (index.valid ? UserPlaylistModel.data(index, UserPlaylistModel.Album) : "") || root.info.album;
                            playlistsDialog.albumId = (index.valid ? UserPlaylistModel.data(index, UserPlaylistModel.AlbumId) : "") || root.info.albumId;
                            playlistsDialog.open();
                        }
                    }

                    // 5. Conmutador de Cola de reproducción
                    CachyToolbarButton {
                        id: queueButton
                        implicitWidth: 32
                        implicitHeight: 32
                        iconName: "view-media-playlist"
                        tooltipText: (sideDrawer.visible && !sideDrawer.collapsed) ? i18n("Hide Queue") : i18n("Show Queue")
                        checkable: true
                        checked: sideDrawer.visible && !sideDrawer.collapsed
                        onClicked: {
                            if (sideDrawer.visible && !sideDrawer.collapsed) {
                                sideDrawer.closeDrawer();
                            } else {
                                sideDrawer.openDrawer();
                            }
                        }
                    }
                }
            }

            // Espaciador elástico inferior: garantiza centrado vertical perfecto
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        // =====================================================================
        // PANEL LATERAL DE LA COLA (Queue Drawer) — CachyOS.UI Golden Gate
        // =====================================================================
        Item {
            id: sideDrawer
            property bool collapsed: true
            property bool isAnimating: showAnim.running || collapseAnim.running
            property real targetWidth: root.width < 540 ? root.width : Math.min(420, Math.max(300, root.width * 0.36))

            visible: false
            clip: true
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.preferredWidth: 0

            NumberAnimation {
                id: showAnim
                target: sideDrawer
                property: "Layout.preferredWidth"
                from: 0
                to: sideDrawer.targetWidth
                duration: 220
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                id: collapseAnim
                target: sideDrawer
                property: "Layout.preferredWidth"
                from: sideDrawer.Layout.preferredWidth
                to: 0
                duration: 180
                easing.type: Easing.OutCubic
                onFinished: {
                    sideDrawer.visible = false;
                    sideDrawer.collapsed = true;
                }
            }

            function openDrawer() {
                collapseAnim.stop();
                visible = true;
                collapsed = false;
                targetWidth = root.width < 540 ? root.width : Math.min(420, Math.max(300, root.width * 0.36));
                showAnim.to = targetWidth;
                showAnim.restart();
            }

            function closeDrawer() {
                showAnim.stop();
                collapseAnim.from = Layout.preferredWidth;
                collapseAnim.restart();
            }

            // Divisor estructural izquierdo de 1px
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: CachyPalette.hardDividerColor
                z: 10
            }

            // Fondo Liquid Glass de la barra lateral de cola
            Rectangle {
                anchors.fill: parent
                color: CachyPalette.isDark ? Qt.rgba(0.09, 0.09, 0.13, 0.96) : Qt.rgba(0.96, 0.96, 0.98, 0.96)
            }

            // Tirador interactivo de redimensionamiento
            MouseArea {
                id: queueResizer
                anchors.horizontalCenter: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 8
                z: 20
                cursorShape: Qt.SplitHCursor
                enabled: root.width >= 540
                onPositionChanged: (mouse) => {
                    let newW = sideDrawer.width - mouse.x;
                    if (newW >= 260 && newW <= (root.width - 280)) {
                        sideDrawer.targetWidth = newW;
                        sideDrawer.Layout.preferredWidth = newW;
                    }
                }
            }

            ColumnLayout {
                spacing: 0
                anchors.fill: parent

                // 1. Cabecera superior de la Cola (44px)
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 6

                        Controls.Label {
                            text: i18n("Upcoming Songs")
                            font.weight: Font.DemiBold
                            font.pixelSize: 14
                            color: CachyPalette.text
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        CachyToolbarButton {
                            implicitWidth: 30
                            implicitHeight: 30
                            iconName: "media-playlist-shuffle"
                            tooltipText: i18n("Shuffle Queue")
                            enabled: playListView.count > 1
                            onClicked: UserPlaylistModel.shufflePlaylist()
                        }

                        CachyToolbarButton {
                            implicitWidth: 30
                            implicitHeight: 30
                            iconName: "edit-clear-all"
                            tooltipText: i18n("Clear Queue")
                            enabled: playListView.count > 1
                            onClicked: UserPlaylistModel.clearExceptCurrent()
                        }

                        CachyToolbarButton {
                            implicitWidth: 30
                            implicitHeight: 30
                            iconName: "window-close-symbolic"
                            tooltipText: i18n("Close Queue")
                            onClicked: sideDrawer.closeDrawer()
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: CachyPalette.hardDividerColor
                    }
                }

                // 2. Lista de canciones en la Cola
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ScrollView {
                        id: playListScrollView
                        anchors.fill: parent
                        clip: true

                        ListView {
                            id: playListView
                            reuseItems: true
                            spacing: 4
                            topMargin: 8
                            bottomMargin: 8
                            leftMargin: 8
                            rightMargin: 8
                            clip: true

                            model: UserPlaylistModel

                            moveDisplaced: Transition {
                                YAnimator {
                                    duration: Kirigami.Units.mediumDuration
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            delegate: Item {
                                id: delegateItem
                                required property string title
                                required property string videoId
                                required property string artists
                                required property bool isCurrent
                                required property int index
                                width: playListView.width - 16
                                height: queueEntry.implicitHeight

                                ItemDelegate {
                                    id: queueEntry
                                    width: parent.width
                                    padding: 6
                                    highlighted: delegateItem.isCurrent
                                    onClicked: UserPlaylistModel.skipTo(delegateItem.videoId)

                                    background: Rectangle {
                                        radius: CachyTheme.radiusMedium
                                        color: {
                                            if (delegateItem.isCurrent) {
                                                return Qt.rgba(CachyTheme.accentColor.r, CachyTheme.accentColor.g, CachyTheme.accentColor.b, CachyPalette.isDark ? 0.22 : 0.14);
                                            }
                                            if (queueEntry.down) {
                                                return CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08);
                                            }
                                            if (queueEntry.hovered) {
                                                return CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04);
                                            }
                                            return "transparent";
                                        }
                                        border.width: delegateItem.isCurrent ? 1 : 0
                                        border.color: delegateItem.isCurrent ? Qt.rgba(CachyTheme.accentColor.r, CachyTheme.accentColor.g, CachyTheme.accentColor.b, 0.50) : "transparent"
                                    }

                                    contentItem: RowLayout {
                                        spacing: 8

                                        Item {
                                            width: handle.width
                                            height: handle.height
                                            Kirigami.ListItemDragHandle {
                                                id: handle
                                                Layout.fillHeight: true
                                                listItem: queueEntry
                                                listView: playListView
                                                onMoveRequested: (oldIndex, newIndex) => UserPlaylistModel.moveRow(oldIndex, newIndex)
                                            }
                                        }

                                        ThumbnailSource {
                                            id: delegateThumbnailSource
                                            videoId: delegateItem.videoId
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 38
                                            Layout.preferredHeight: 38
                                            radius: CachyTheme.radiusSmall
                                            clip: true
                                            color: Qt.rgba(1, 1, 1, 0.08)

                                            Image {
                                                anchors.fill: parent
                                                source: delegateThumbnailSource.cachedPath
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Controls.Label {
                                                Layout.fillWidth: true
                                                text: delegateItem.title
                                                font.weight: delegateItem.isCurrent ? Font.DemiBold : Font.Normal
                                                font.pixelSize: 13
                                                color: delegateItem.isCurrent ? CachyTheme.accentColor : CachyPalette.text
                                                elide: Text.ElideRight
                                            }

                                            Controls.Label {
                                                Layout.fillWidth: true
                                                text: delegateItem.artists
                                                font.pixelSize: 11
                                                color: CachyPalette.textSecondary
                                                elide: Text.ElideRight
                                            }
                                        }

                                        CachyToolbarButton {
                                            implicitWidth: 26
                                            implicitHeight: 26
                                            iconName: "list-remove"
                                            tooltipText: i18n("Remove Song")
                                            onClicked: UserPlaylistModel.remove(delegateItem.videoId)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Estado vacío cuando la cola no tiene elementos
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: playListView.count === 0 && !UserPlaylistModel.loading
                        spacing: 8

                        CachyIcon {
                            Layout.alignment: Qt.AlignHCenter
                            name: "view-media-playlist"
                            width: 44
                            height: 44
                            color: CachyPalette.textMuted
                        }

                        Controls.Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: i18n("Queue is empty")
                            font.pixelSize: 13
                            color: CachyPalette.textSecondary
                        }
                    }

                    // Indicador de carga
                    BusyIndicator {
                        anchors.centerIn: parent
                        running: UserPlaylistModel.loading
                        visible: UserPlaylistModel.loading
                    }
                }
            }
        }
    }
}
