// SPDX-FileCopyrightText: 2022 Mathis Brüchert <mbb@kaidan.im>
// SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.audiotube
import CachyOS.UI

Item {
    id: sidebar

    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 4

        Controls.ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Controls.ScrollBar.vertical.policy: Controls.ScrollBar.AlwaysOff
            Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
            contentWidth: -1

            ColumnLayout {
                id: column
                width: scrollView.width
                spacing: 4

                CachySidebarItem {
                    id: homeButton
                    text: i18n("Home")
                    iconName: "user-home-symbolic"
                    selected: pageStack.currentItem && pageStack.currentItem.objectName === "homePage"
                    onClicked: {
                        pageStack.clear();
                        pageStack.push(pool.loadPage(Qt.resolvedUrl("./HomePage.qml")));
                    }
                }

                CachySidebarItem {
                    id: libraryButton
                    text: i18n("Library")
                    iconName: "file-library-symbolic"
                    selected: pageStack.currentItem && pageStack.currentItem.objectName === "libraryPage"
                    onClicked: {
                        pageStack.clear();
                        pageStack.push(pool.loadPage(Qt.resolvedUrl("./LibraryPage.qml")));
                    }
                }

                CachySidebarItem {
                    id: searchButton
                    text: i18n("Search")
                    iconName: "edit-find-symbolic"
                    selected: pageStack.currentItem && pageStack.currentItem.objectName === "searchPage"
                    onClicked: {
                        searchField.forceActiveFocus();
                        focusSearch();
                    }
                }

                CachySidebarItem {
                    id: favouritesButton
                    text: i18n("Favorites")
                    iconName: "non-starred-symbolic"
                    selected: pageStack.currentItem && pageStack.currentItem.objectName === "favourites"
                    onClicked: {
                        pageStack.clear();
                        pageStack.push(pool.loadPageWithProperties(Qt.resolvedUrl("./PlaybackHistory.qml#favourites"), {
                            "title": i18n("Favorites"),
                            "objectName": "favourites"
                        }));
                    }
                }

                CachySidebarItem {
                    id: exploreButton
                    text: i18n("Explore")
                    iconName: "globe-symbolic"
                    selected: pageStack.currentItem && pageStack.currentItem.objectName === "explorePage"
                    onClicked: {
                        pageStack.clear();
                        pageStack.push(pool.loadPage(Qt.resolvedUrl("./ExplorePage.qml")));
                    }
                }

                CachySidebarItem {
                    id: historyButton
                    text: i18n("Played Songs")
                    iconName: "edit-undo-history"
                    selected: pageStack.currentItem && pageStack.currentItem.objectName === "history"
                    onClicked: {
                        pageStack.clear();
                        pageStack.push(pool.loadPageWithProperties(Qt.resolvedUrl("./PlaybackHistory.qml#history"), {
                            "title": i18n("Played Songs"),
                            "objectName": "history"
                        }));
                    }
                }

                CachySidebarItem {
                    id: playlistsButton
                    text: i18n("Playlists")
                    iconName: "amarok_playlist"
                    selected: pageStack.currentItem && pageStack.currentItem.objectName === "playlists"
                    onClicked: {
                        pageStack.clear();
                        pageStack.push(pool.loadPageWithProperties(Qt.resolvedUrl("./LocalPlaylistsPage.qml"), {
                            "objectName": "playlists"
                        }));
                    }
                }
            }
        }

        CachyDivider {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
        }

        CachySidebarItem {
            id: settingsButton
            text: i18n("Ajustes")
            iconName: "settings-configure-symbolic"
            selected: false
            onClicked: {
                pageStack.pushDialogLayer(Qt.resolvedUrl("SettingsPage.qml"));
            }
        }

        CachySidebarItem {
            id: aboutButton
            text: i18n("About")
            iconName: "help-about-symbolic"
            selected: false
            onClicked: {
                pageStack.pushDialogLayer(Qt.resolvedUrl("AboutPage.qml"));
            }
        }
    }
}
