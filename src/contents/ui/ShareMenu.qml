// SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-FileCopyrightText: 2023 Mathis Brüchert <mbb@kaidan.im>
// SPDX-FileCopyrightText: 2026 CachyOS UI contributors
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQuick
import QtQuick.Window

import org.kde.kirigami as Kirigami
import org.kde.kirigami.delegates as KirigamiDelegates
import org.kde.kirigamiaddons.components as Components
import org.kde.purpose as Purpose
import CachyOS.UI

import org.kde.audiotube

Item {
    id: root
    property url url
    property string inputTitle

    function open() {
        if (Kirigami.Settings.isMobile) {
            inputDrawer.open()
            inputDrawer.interactive = true
            drawerView.inputData = {
                "urls": [root.url.toString()],
                "title": root.inputTitle.length > 0 ? root.inputTitle : "Title"
            }
        } else {
            inputSheet.open()
            view.inputData = {
                "urls": [root.url.toString()],
                "title": root.inputTitle.length > 0 ? root.inputTitle : "Title"
            }
        }
    }

    Controls.Dialog {
        id: inputSheet
        title: i18n("Share to")
        anchors.centerIn: parent
        width: Math.min(parent ? parent.width - 32 : 360, 360)
        modal: true
        standardButtons: Controls.Dialog.Close

        background: Rectangle {
            radius: CachyTheme.radiusLarge
            color: CachyTheme.isDark ? Qt.rgba(0.12, 0.12, 0.16, 0.98) : Qt.rgba(0.97, 0.98, 1.0, 0.98)
            border.width: 1
            border.color: CachyTheme.specularBorder
        }

        contentItem: Purpose.AlternativesView {
            id: view
            implicitHeight: 220
            pluginType: "ShareUrl"
            clip: true

            delegate: Controls.ItemDelegate {
                id: shareDelegate
                required property string iconName
                required property int index
                required property string actionDisplay

                onClicked: view.createJob(shareDelegate.index)
                width: parent.width

                contentItem: RowLayout {
                    spacing: 8
                    CachyIcon {
                        name: shareDelegate.iconName
                        size: 16
                        color: CachyTheme.textPrimary
                    }
                    Text {
                        Layout.fillWidth: true
                        text: shareDelegate.actionDisplay
                        font.pixelSize: 13
                        color: CachyTheme.textPrimary
                        elide: Text.ElideRight
                    }
                    CachyIcon {
                        name: "chevron-right"
                        size: 12
                        color: CachyPalette.textMuted
                    }
                }
            }

            onFinished: inputSheet.close()
        }
    }

    Components.BottomDrawer {
        id: inputDrawer

        parent: applicationWindow().overlayItem

        drawerContentItem: Purpose.AlternativesView {
            id: drawerView
            pluginType: "ShareUrl"
            clip: true
            Layout.fillHeight: true
            Layout.fillWidth: true
            delegate: Controls.ItemDelegate {
                id: shareDrawerDelegate

                required property string iconName
                required property int index
                required property string actionDisplay

                onClicked: view.createJob(shareDelegate.index)
                width: parent.width

                contentItem: KirigamiDelegates.IconTitleSubtitle {
                    title: shareDrawerDelegate.actionDisplay
                    Keys.onReturnPressed: view.createJob(shareDrawerDelegate.index)
                    Keys.onEnterPressed: view.createJob(shareDrawerDelegate.index)
                    icon.name: shareDrawerDelegate.iconName

                    Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                        source: "arrow-right"
                    }
                }
            }
            onFinished: inputDrawer.close()
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
