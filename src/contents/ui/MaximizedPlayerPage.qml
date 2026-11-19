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
import org.kde.kirigamiaddons.components as Components
import org.kde.audiotube
import CachyOS.UI

Item {
    id: root

    required property VideoInfoExtractor info
    required property MediaPlayer audio
    required property LyricsModel syncedLyrics
    required property string thumbnail
    readonly property bool isWidescreen: width >= Kirigami.Units.gridUnit * 50
    readonly property bool wideScreen: isWidescreen

    signal requestClose()

    onWidthChanged: { sideDrawer.Layout.minimumWidth = -1 }

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
                Layout.preferredWidth: Math.min(mainContent.width - 48, 540)
                spacing: 0

                // A. Carátula del álbum o Letras (SwipeView)
                SwipeView {
                    id: swipeView
                    interactive: false
                    clip: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(mainContent.width - 48, 500)
                    Layout.preferredHeight: currentIndex === 1
                        ? Math.min(mainContent.height * 0.45, 340)
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
                                Math.max(160, (mainContent.height - 310) * 0.70),
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

                // F. Barra de acciones de utilidad (Favoritos, Volumen, Letras, Compartir, Playlist, Cola)
                RowLayout {
                    id: actionToolbar
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 14

                    // Favorito
                    CachyToolbarButton {
                        id: favouriteButton
                        implicitWidth: 32
                        implicitHeight: 32
                        readonly property QtObject favouriteWatcher: Library.favouriteWatcher(root.info.videoId)
                        iconName: favouriteWatcher && favouriteWatcher.isFavourite ? "starred-symbolic" : "non-starred-symbolic"
                        tooltipText: favouriteWatcher && favouriteWatcher.isFavourite ? i18n("Remove from Favorites") : i18n("Add to Favorites")
                        onClicked: {
                            if (favouriteWatcher) {
                                if (favouriteWatcher.isFavourite) {
                                    Library.removeFavourite(root.info.videoId);
                                } else {
                                    let index = UserPlaylistModel.index(UserPlaylistModel.currentIndex, 0);
                                    let videoId = UserPlaylistModel.data(index, UserPlaylistModel.VideoId);
                                    let title = UserPlaylistModel.data(index, UserPlaylistModel.Title);
                                    let artist = UserPlaylistModel.data(index, UserPlaylistModel.Artists);
                                    let artistId = UserPlaylistModel.data(index, UserPlaylistModel.ArtistId);
                                    let album = UserPlaylistModel.data(index, UserPlaylistModel.Album);
                                    let albumId = UserPlaylistModel.data(index, UserPlaylistModel.AlbumId);
                                    Library.addFavourite(videoId, title, artist, artistId, album, albumId);
                                }
                            }
                        }
                    }

                    // Control de volumen integrado
                    RowLayout {
                        spacing: 6
                        visible: root.isWidescreen

                        CachyToolbarButton {
                            id: muteButton
                            implicitWidth: 32
                            implicitHeight: 32
                            iconName: {
                                if (!root.audio || !root.audio.audioOutput) return "audio-volume-medium";
                                if (root.audio.audioOutput.muted || root.audio.audioOutput.volume === 0) return "audio-volume-muted";
                                if (root.audio.audioOutput.volume < 0.4) return "audio-volume-low";
                                if (root.audio.audioOutput.volume < 0.7) return "audio-volume-medium";
                                return "audio-volume-high";
                            }
                            tooltipText: (root.audio && root.audio.audioOutput && root.audio.audioOutput.muted) ? i18n("Unmute") : i18n("Mute")
                            onClicked: {
                                if (root.audio && root.audio.audioOutput) {
                                    root.audio.audioOutput.muted = !root.audio.audioOutput.muted;
                                }
                            }
                        }

                        CachySlider {
                            id: volumeSlider
                            Layout.preferredWidth: 84
                            accentColor: CachyTheme.accentColor
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

                    // Conmutador de Letras
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

                    // Compartir Canción
                    CachyToolbarButton {
                        id: shareButton
                        implicitWidth: 32
                        implicitHeight: 32
                        iconName: "document-share"
                        tooltipText: i18n("Share Song")
                        enabled: root.info.title ? root.info.title.length > 0 : false
                        onClicked: openShareMenu(root.info.title, UserPlaylistModel.webUrl)
                    }

                    // Añadir a lista de reproducción local
                    CachyToolbarButton {
                        id: addToPlaylistButton
                        implicitWidth: 32
                        implicitHeight: 32
                        iconName: "media-playlist-append"
                        tooltipText: i18n("Add to a local playlist")
                        enabled: root.info.videoId ? root.info.videoId.length > 0 : false
                        onClicked: {
                            let index = UserPlaylistModel.index(UserPlaylistModel.currentIndex, 0);
                            playlistsDialog.videoId = UserPlaylistModel.data(index, UserPlaylistModel.VideoId);
                            playlistsDialog.songTitle = UserPlaylistModel.data(index, UserPlaylistModel.Title);
                            playlistsDialog.artists = UserPlaylistModel.data(index, UserPlaylistModel.Artists);
                            playlistsDialog.artistId = UserPlaylistModel.data(index, UserPlaylistModel.ArtistId);
                            playlistsDialog.album = UserPlaylistModel.data(index, UserPlaylistModel.Album);
                            playlistsDialog.albumId = UserPlaylistModel.data(index, UserPlaylistModel.AlbumId);
                            playlistsDialog.open();
                        }
                    }

                    // Conmutador de Cola de reproducción
                    CachyToolbarButton {
                        id: queueButton
                        implicitWidth: 32
                        implicitHeight: 32
                        iconName: "amarok_playlist"
                        tooltipText: sideDrawer.visible ? i18n("Hide Queue") : i18n("Show Queue")
                        checkable: true
                        checked: sideDrawer.visible && !sideDrawer.collapsed
                        onClicked: {
                            if (root.wideScreen) {
                                if (!sideDrawer.collapsed && sideDrawer.visible) {
                                    collapse.running = true;
                                    sideDrawer.collapsed = true;
                                } else {
                                    sideDrawer.visible = true;
                                    show.running = true;
                                    sideDrawer.collapsed = false;
                                }
                            } else {
                                queueDrawer.open();
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

        Item {
            onWidthChanged: {
                if (!wideScreen) {
                    collapse.running=true
                    collapsed=true
                    queueButton.checked=false
                }
            }
            property bool collapsed: true
            id: sideDrawer
            Layout.fillWidth: true
            Layout.maximumWidth: -1
            Layout.preferredWidth: Math.max(350, root.width/3)

            Layout.fillHeight: true
            visible: false
            NumberAnimation on Layout.maximumWidth {
                id: collapse
                easing.type: Easing.OutCubic
                running: false
                from: Math.min(sideDrawer.Layout.preferredWidth, sideDrawer.Layout.maximumWidth); to: 0
                onFinished: { sideDrawer.visible=false}
            }
            NumberAnimation on Layout.maximumWidth {
                id: show
                easing.type: Easing.OutCubic
                running: false
                from: 0; to: Math.min(sideDrawer.Layout.preferredWidth, root.width - mainContent.Layout.minimumWidth)
                //onFinished: { sideDrawer.visible=false}
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
                color: CachyPalette.isDark ? Qt.rgba(0.09, 0.09, 0.13, 0.94) : Qt.rgba(0.96, 0.96, 0.98, 0.94)
            }

            MouseArea {
                id: queueResizer

                anchors.horizontalCenter: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Kirigami.Units.gridUnit

                cursorShape: Qt.SplitHCursor
                onPositionChanged: (mouse) => {
                    if(Math.max(sideDrawer.width - (mouse.x - width/2), queueFooter.Layout.minimumWidth) + mainContent.Layout.minimumWidth < root.width){
                        sideDrawer.Layout.preferredWidth = sideDrawer.Layout.minimumWidth = sideDrawer.Layout.maximumWidth = Math.max(sideDrawer.width - (mouse.x - width/2), queueFooter.Layout.minimumWidth)
                    }
                }
            }

            ColumnLayout {
                spacing: 0
                anchors.fill: parent
                ScrollView {
                    id: playListScrollView

                    contentWidth: availableWidth

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin:10

                    ListView {
                        id: playListView

                        reuseItems: true

                        spacing: 5
                        rightMargin: 10
                        topMargin:10
                        bottomMargin: 10
                        clip: true
                        contentWidth: playListScrollView.contentWidth - rightMargin - leftMargin

                        Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
                        Kirigami.Theme.inherit: false

                        BusyIndicator {
                            anchors.centerIn: parent
                            visible: UserPlaylistModel.loading || UserPlaylistModel.loading
                        }

                        model: UserPlaylistModel

                        moveDisplaced: Transition {
                            YAnimator {
                                duration: Kirigami.Units.mediumDuration
                                easing.type: Easing.InOutQuad
                            }
                        }

                        delegate: Item{
                            //listItemDragHandle requires queueEntry to be a child of the delegate, and not the delegate itself
                            id: delegateItem

                            required property string title
                            required property string videoId
                            required property string artists
                            required property bool isCurrent
                            required property int index
                            width: queueEntry.implicitWidth
                            height: queueEntry.implicitHeight

                            ItemDelegate {
                                id: queueEntry

                                width: playListView.contentWidth

                                background: Rectangle{
                                    radius: 7
                                    color:
                                    if (parent.down) {
                                        Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.hoverColor, "transparent", 0.3)
                                    } else if (parent.hovered) {
                                        Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.hoverColor, "transparent", 0.7)
                                    } else if (parent.highlighted) {
                                        Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.hoverColor, "transparent", 0.7)
                                    } else {
                                        Qt.rgba(0, 0, 0, 0.4)
                                    }

                                    border.color:
                                    if (parent.down){
                                        Kirigami.Theme.hoverColor
                                    } else if (parent.hovered) {
                                        Kirigami.Theme.hoverColor
                                    } else {
                                        Qt.rgba(1, 1, 1, 0)
                                    }

                                    border.width: 1
                                }
                                highlighted: isCurrent
                                onClicked: UserPlaylistModel.skipTo(videoId)
                                contentItem: RowLayout {
                                    id: contentLayout

                                    Item {
                                        width: handle.width
                                        height: handle.height
                                        Kirigami.ListItemDragHandle {
                                            id: handle
                                            Layout.fillHeight: true
                                            listItem: queueEntry
                                            listView: playListView
                                            onMoveRequested: UserPlaylistModel.moveRow(oldIndex, newIndex)
                                        }
                                        Rectangle {
                                            visible: GraphicsInfo.api !== GraphicsInfo.Software
                                            anchors.fill: handle
                                            layer.enabled: true
                                            layer.effect: MultiEffect {
                                                maskSource: handle
                                                maskEnabled: true
                                            }
                                        }
                                    }
                                    ThumbnailSource {
                                        id: delegateThumbnailSource
                                        videoId: delegateItem.videoId
                                    }
                                    RoundedImage {
                                        source: delegateThumbnailSource.cachedPath
                                        Layout.margins: 2.5
                                        height: column.implicitHeight
                                        width: column.implicitHeight
                                        radius: 5
                                    }

                                    ColumnLayout {
                                        id: column
                                        Layout.margins: 5

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        Kirigami.Heading {
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            level: 2
                                            text: delegateItem.title

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                ToolTip.text: parent.text
                                                ToolTip.delay: Kirigami.Units.toolTipDelay
                                                ToolTip.visible: parent.truncated ? (Kirigami.Settings.isMobile ? containsPress : containsMouse) : false
                                            }
                                        }

                                        Label {
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            color: Kirigami.Theme.disabledTextColor
                                            text: delegateItem.artists
                                        }

                                    }
                                    ToolButton {
                                        text: i18n("Remove Song")
                                        icon.name: "list-remove"
                                        icon.color: "white"
                                        display: AbstractButton.IconOnly
                                        onClicked: UserPlaylistModel.remove(delegateItem.videoId)
                                    }
                                }
                            }
                        }
                    }
                }


                Kirigami.Separator {
                    color: "white"
                    opacity: 0.3
                    Layout.fillWidth: true
                }

                RowLayout {
                    id: queueFooter

                    Layout.margins: Kirigami.Units.gridUnit * 0.5
                    enabled: playListView.count != 0
                    Item {
                        Layout.fillWidth: true
                    }

                    ToolButton {
                        id: clearPlaylistButton

                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
                        Layout.maximumWidth: height
                        Layout.preferredWidth: height

                        text: i18n("Clear Queue")
                        icon {
                            name: "edit-clear-all"
                            color: "white"
                        }
                        display: AbstractButton.IconOnly

                        ToolTip.text: text
                        ToolTip.delay: Kirigami.Units.toolTipDelay
                        ToolTip.visible: Kirigami.Settings.isMobile ? pressed : hovered

                        onClicked: UserPlaylistModel.clearExceptCurrent()

                        Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
                        Kirigami.Theme.inherit: false
                    }

                    ToolButton {
                        id: shuffleButton
                        Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 2.5)
                        Layout.maximumWidth: height
                        Layout.preferredWidth: height

                        onClicked: UserPlaylistModel.shufflePlaylist()

                        text: i18n("Shuffle Queue")

                        ToolTip.text: text
                        ToolTip.delay: Kirigami.Units.toolTipDelay
                        ToolTip.visible: Kirigami.Settings.isMobile ? pressed : hovered

                        icon {
                            name: "media-playlist-shuffle"
                            color: "white"
                        }
                        display: AbstractButton.IconOnly
                        Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
                        Kirigami.Theme.inherit: false
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Components.BottomDrawer {
            id: queueDrawer

            parent: applicationWindow().overlayItem ? applicationWindow().overlayItem : applicationWindow()

            onClosed:{sideDrawer.collapsed=true}
            height: applicationWindow().height - 50
            interactive: true

            headerContentItem: RowLayout {
                Kirigami.Heading {
                    text: i18n("Upcoming Songs")
                    elide: Qt.ElideRight
                    Layout.margins: 0
                    Layout.fillWidth: true
                }
                Item {
                    Layout.fillWidth: true
                }
                ToolButton {
                    Layout.topMargin: 0
                    Layout.bottomMargin: 0
                    Layout.maximumWidth: height
                    Layout.preferredWidth: height
                    text: clearPlaylistButton.text

                    ToolTip.text: text
                    ToolTip.delay: Kirigami.Units.toolTipDelay
                    ToolTip.visible: Kirigami.Settings.isMobile ? pressed : hovered

                    icon.name: "edit-clear-all"
                    display: clearPlaylistButton.display
                    onClicked: {
                        UserPlaylistModel.clearExceptCurrent()
                    }
                    enabled: playListView.count != 0
                }

                ToolButton {
                    Layout.topMargin: 0
                    Layout.bottomMargin: 0
                    Layout.maximumWidth: height
                    Layout.preferredWidth: height
                    icon.name: "media-playlist-shuffle"
                    text: shuffleButton.text
                    display: shuffleButton.display

                    ToolTip.text: text
                    ToolTip.delay: Kirigami.Units.toolTipDelay
                    ToolTip.visible: Kirigami.Settings.isMobile ? pressed : hovered

                    onClicked: {
                        UserPlaylistModel.shufflePlaylist()
                    }
                    enabled: playListView.count != 0
                }
            }

            drawerContentItem: ScrollView {
                ListView {
                    id: drawerListView
                    topMargin: 10
                    clip: true

                    reuseItems: true

                    BusyIndicator {
                        anchors.centerIn: parent
                        visible: UserPlaylistModel.loading || UserPlaylistModel.loading
                    }

                    model: UserPlaylistModel

                    moveDisplaced: Transition {
                        YAnimator {
                            duration: Kirigami.Units.mediumDuration
                            easing.type: Easing.InOutQuad
                        }
                    }

                    delegate: Item {
                        id: drawerDelegateItem
                        required property string title
                        required property string videoId
                        required property string artists
                        required property bool isCurrent
                        required property int index

                        width: drawerListView.width
                        height: drawerQueueEntry.height

                        ItemDelegate {
                            id: drawerQueueEntry

                            width: parent.width

                            highlighted: drawerDelegateItem.isCurrent
                            onClicked: {
                                queueDrawer.close()
                                UserPlaylistModel.skipTo(drawerDelegateItem.videoId)
                            }
                            contentItem: RowLayout {
                                Layout.fillWidth: true
                                Item {
                                    width: drawerHandle.width
                                    height: drawerHandle.height
                                    Kirigami.ListItemDragHandle {
                                        id: drawerHandle
                                        Layout.fillHeight: true
                                        listItem: drawerQueueEntry
                                        listView: drawerListView
                                        onMoveRequested: UserPlaylistModel.moveRow(oldIndex, newIndex)
                                    }

                                    Rectangle {
                                        visible: GraphicsInfo.api !== GraphicsInfo.Software
                                        anchors.fill: drawerHandle
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            maskSource: drawerHandle
                                            maskEnabled: true
                                        }
                                    }
                                }
                                ThumbnailSource {
                                    id: drawerDelegateThumbnailSource
                                    videoId: drawerDelegateItem.videoId
                                }
                                RoundedImage {
                                    source: drawerDelegateThumbnailSource.cachedPath

                                    height: 50
                                    width: height
                                    radius: 5
                                }

                                ColumnLayout {
                                    Layout.margins: 5
                                    Layout.fillWidth: true
                                    Kirigami.Heading {
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        level: 2
                                        text: drawerDelegateItem.title

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            ToolTip.text: parent.text
                                            ToolTip.delay: Kirigami.Units.toolTipDelay
                                            ToolTip.visible: parent.truncated ? (Kirigami.Settings.isMobile ? containsPress : containsMouse) : false
                                        }
                                    }

                                    Label {
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        color: Kirigami.Theme.disabledTextColor
                                        text: drawerDelegateItem.artists
                                    }
                                }

                                ToolButton {
                                    text: i18n("Remove Song")
                                    icon.name: "list-remove"
                                    display: AbstractButton.IconOnly
                                    onClicked: UserPlaylistModel.remove(drawerDelegateItem.videoId)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
