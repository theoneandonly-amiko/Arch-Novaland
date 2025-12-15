//
// This file is part of SDDM Sugar Candy.
// A theme for the Simple Display Desktop Manager.
//
// Copyright (C) 2018–2020 Marian Arlt
//
// SDDM Sugar Candy is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the
// Free Software Foundation, either version 3 of the License, or any later version.
//
// You are required to preserve this and any additional legal notices, either
// contained in this file or in other files that you received along with
// SDDM Sugar Candy that refer to the author(s) in accordance with
// sections §4, §5 and specifically §7b of the GNU General Public License.
//
// SDDM Sugar Candy is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with SDDM Sugar Candy. If not, see <https://www.gnu.org/licenses/>
//

import QtQuick 2.0
import QtQuick.Layouts 1.2
import SddmComponents 2.0 as SDDM

ColumnLayout {
    id: formContainer
    SDDM.TextConstants { id: textConstants }

    property int p: config.ScreenPadding
    property string a: config.FormPosition
    property alias systemButtonVisibility: systemButtons.visible
    property alias clockVisibility: clock.visible
    property bool virtualKeyboardActive

    // --- SPACER 1: ĐỆM TRÊN CÙNG ---
    // Giữ tỉ lệ nhỏ để Đồng hồ nằm cao hơn
    Item {
        Layout.fillHeight: true
        Layout.preferredHeight: 2
    }

    Clock {
        id: clock
        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
        Layout.preferredHeight: root.height / 5
        Layout.leftMargin: p != "0" ? a == "left" ? -p : a == "right" ? p : 0 : 0
    }

    // --- SPACER 2: LÒ XO Ở GIỮA (QUAN TRỌNG) ---
    // Cái này sẽ đẩy Đồng hồ lên và Login xuống -> Tách chúng ra xa nhau
    Item {
        Layout.fillHeight: true
        Layout.preferredHeight: 3  // Tăng số này nếu muốn khoảng cách xa hơn nữa
    }

    Input {
        id: input
        Layout.alignment: Qt.AlignVCenter

        // --- TĂNG ĐỘ DÀY LOGIN ---
        // Cũ: / 6 -> Mới: / 4 (To gấp rưỡi, rất dày và dễ bấm)
        Layout.preferredHeight: root.height / 4

        Layout.leftMargin: p != "0" ? a == "left" ? -p : a == "right" ? p : 0 : 0
        Layout.topMargin: virtualKeyboardActive ? -height * 1.5 : 0
    }

    // --- SPACER 3: ĐỆM DƯỚI CÙNG ---
    // Giữ Login không bị tụt quá sâu xuống đáy
    Item {
        Layout.fillHeight: true
        Layout.preferredHeight: 2
    }

    Item {
        id: systemButtons
        visible: false
        Layout.preferredHeight: 0
    }
}
