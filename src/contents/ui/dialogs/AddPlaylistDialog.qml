// SPDX-FileCopyrightText: 2023 Mathis Brüchert <mbb@kaidan.im>
// SPDX-FileCopyrightText: 2026 CachyOS UI contributors
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import CachyOS.UI

Controls.Dialog {
    id: addPlaylistDialog
    property QtObject model

    title: i18n("Add playlist")
    standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
    anchors.centerIn: parent
    width: Math.min(parent ? parent.width - 32 : 360, 360)
    modal: true

    background: Rectangle {
        radius: CachyTheme.radiusLarge
        color: CachyTheme.isDark ? Qt.rgba(0.12, 0.12, 0.16, 0.98) : Qt.rgba(0.97, 0.98, 1.0, 0.98)
        border.width: 1
        border.color: CachyTheme.specularBorder
    }

    onOpened: {
        titleField.text = ""
        descriptionField.text = ""
        titleField.forceActiveFocus()
    }

    contentItem: ColumnLayout {
        spacing: 12
        width: parent.width

        Text {
            text: i18n("Playlist Title")
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: CachyTheme.textSecondary
        }

        CachyTextField {
            id: titleField
            Layout.fillWidth: true
            placeholderText: i18n("Title...")
        }

        Text {
            text: i18n("Playlist Description")
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: CachyTheme.textSecondary
        }

        CachyTextField {
            id: descriptionField
            Layout.fillWidth: true
            placeholderText: i18n("Description...")
        }
    }

    onAccepted: {
        if (model && titleField.text.trim().length > 0) {
            model.addPlaylist(titleField.text.trim(), descriptionField.text.trim())
        }
    }
}
