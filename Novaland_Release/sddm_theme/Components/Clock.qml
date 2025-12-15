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
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Window 2.2 // Thêm cái này để dùng Screen.height chuẩn

Column {
    id: container
    spacing: 0

    Label {
        id: time
        anchors.horizontalCenter: parent.horizontalCenter
        color: config.MainColor
        text: Qt.formatTime(new Date(), "hh:mm")
        font.family: config.Font
        font.bold: true
        
        // --- CHỈNH CỠ CHỮ GIỜ ---
        // Dùng Screen.height (S viết hoa) hoặc số cứng.
        // 1366 / 8 = ~170px (Rất to)
        font.pixelSize: Screen.height ? (Screen.height / 8) : 150
    }

    Label {
        id: date
        anchors.horizontalCenter: parent.horizontalCenter
        color: config.MainColor
        text: Qt.formatDate(new Date(), "dddd, d of MMMM")
        font.family: config.Font
        font.bold: true
        
        // --- CHỈNH CỠ CHỮ NGÀY ---
        // 1366 / 30 = ~45px
        font.pixelSize: Screen.height ? (Screen.height / 30) : 40
    }

    Label {
        id: greeting
        anchors.horizontalCenter: parent.horizontalCenter
        color: config.MainColor
        font.family: config.Font
        font.bold: true
        
        // --- CHỈNH CỠ CHỮ LỜI CHÀO ---
        // Để bằng kích thước ngày (45px)
        font.pixelSize: Screen.height ? (Screen.height / 30) : 40

        text: {
            var d = new Date();
            var h = d.getHours();
            if (h >= 5 && h < 12) return "Good morning!";
            else if (h >= 12 && h < 18) return "Good afternoon!";
            else return "Good evening!";
        }
    }
}
