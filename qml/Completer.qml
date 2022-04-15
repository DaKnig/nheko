// SPDX-FileCopyrightText: 2021 Nheko Contributors
// SPDX-FileCopyrightText: 2022 Nheko Contributors
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import im.nheko
import im.nheko

import "./ui/"

Control {
    id: popup

    property alias currentIndex: listView.currentIndex
    property string completerName
    property var completer
    property bool bottomToTop: true
    property bool fullWidth: false
    property bool centerRowContent: true
    property int avatarHeight: 24
    property int avatarWidth: 24
    property int rowMargin: 0
    property int rowSpacing: 5
    property alias count: listView.count

    signal completionClicked(string completion)
    signal completionSelected(string id)

    function up() {
        if (bottomToTop)
            down_();
        else
            up_();
    }

    function down() {
        if (bottomToTop)
            up_();
        else
            down_();
    }

    function up_() {
        currentIndex = currentIndex - 1;
        if (currentIndex == -2)
            currentIndex = listView.count - 1;

    }

    function down_() {
        currentIndex = currentIndex + 1;
        if (currentIndex >= listView.count)
            currentIndex = -1;

    }

    function currentCompletion() {
        if (currentIndex > -1 && currentIndex < listView.count)
            return completer.completionAt(currentIndex);
        else
            return null;
    }

    function finishCompletion() {
        if (popup.completerName == "room")
            popup.completionSelected(listView.itemAtIndex(currentIndex).modelData.roomid);

    }

    onCompleterNameChanged: {
        if (completerName) {
            completer = TimelineManager.completerFor(completerName, completerName == "room" ? "" : room.roomId);
            completer.setSearchString("");
        } else {
            completer = undefined;
        }
        currentIndex = -1
    }

    bottomPadding: 1
    leftPadding: 1
    topPadding: 1
    rightPadding: 1

    contentItem: ListView {
        id: listView

        // If we have fewer than 7 items, just use the list view's content height.  
        // Otherwise, we want to show 7 items.  Each item consists of row spacing between rows, row margins
        // on each side of a row, 1px of padding above the first item and below the last item, and nominally
        // some kind of content height.  avatarHeight is used for just about every delegate, so we're using
        // that until we find something better.  Put is all together and you have the formula below!
        implicitHeight: Math.min(contentHeight, 6*rowSpacing + 7*(popup.avatarHeight + 2*rowMargin))
        clip: true 

        Timer {
            id: deadTimer
            interval: 50
        }

        onContentYChanged: deadTimer.restart()

        reuseItems: true
        implicitWidth: listView.contentItem.childrenRect.width
        model: completer
        verticalLayoutDirection: popup.bottomToTop ? ListView.BottomToTop : ListView.TopToBottom
        spacing: rowSpacing
        pixelAligned: true
        highlightFollowsCurrentItem: true

        delegate: Rectangle {
            property variant modelData: model

            color: model.index == popup.currentIndex ? timelineRoot.palette.highlight : timelineRoot.palette.base
            height: chooser.child.implicitHeight + 2 * popup.rowMargin
            implicitWidth: fullWidth ? ListView.view.width : chooser.child.implicitWidth + 4

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: if (!listView.moving && !deadTimer.running) popup.currentIndex = model.index
                onClicked: {
                     popup.completionClicked(completer.completionAt(model.index));
                     if (popup.completerName == "room")
                         popup.completionSelected(model.roomid);
                }
            }
            Ripple {
                color: Qt.rgba(timelineRoot.palette.base.r, timelineRoot.palette.base.g, timelineRoot.palette.base.b, 0.5)
            }

            DelegateChooser {
                id: chooser

                roleValue: popup.completerName
                anchors.fill: parent
                anchors.margins: popup.rowMargin
                enabled: false

                DelegateChoice {
                    roleValue: "user"

                    RowLayout {
                        id: del

                        anchors.centerIn: parent
                        spacing: rowSpacing

                        Avatar {
                            height: popup.avatarHeight
                            width: popup.avatarWidth
                            displayName: model.displayName
                            userid: model.userid
                            url: model.avatarUrl.replace("mxc://", "image://MxcImage/")
                            onClicked: popup.completionClicked(completer.completionAt(model.index))
                        }

                        Label {
                            text: model.displayName
                            color: model.index == popup.currentIndex ? timelineRoot.palette.highlightedText : timelineRoot.palette.text
                        }

                        Label {
                            text: "(" + model.userid + ")"
                            color: model.index == popup.currentIndex ? timelineRoot.palette.highlightedText : timelineRoot.palette.placeholderText
                        }

                    }

                }

                DelegateChoice {
                    roleValue: "emoji"

                    RowLayout {
                        id: del

                        anchors.centerIn: parent
                        spacing: rowSpacing

                        Label {
                            text: model.unicode
                            color: model.index == popup.currentIndex ? timelineRoot.palette.highlightedText : timelineRoot.palette.text
                            font: Settings.emojiFont
                        }

                        Label {
                            text: model.shortName
                            color: model.index == popup.currentIndex ? timelineRoot.palette.highlightedText : timelineRoot.palette.text
                        }

                    }

                }

                DelegateChoice {
                    roleValue: "customEmoji"

                    RowLayout {
                        id: del

                        anchors.centerIn: parent
                        spacing: rowSpacing

                        Avatar {
                            height: popup.avatarHeight
                            width: popup.avatarWidth
                            displayName: model.shortcode
                            //userid: model.shortcode
                            url: model.url.replace("mxc://", "image://MxcImage/")
                            onClicked: popup.completionClicked(completer.completionAt(model.index))
                            crop: false
                        }

                        Label {
                            text: model.shortcode
                            color: model.index == popup.currentIndex ? timelineRoot.palette.highlightedText : timelineRoot.palette.text
                        }

                        Label {
                            text: "(" + model.packname + ")"
                            color: model.index == popup.currentIndex ? timelineRoot.palette.highlightedText : timelineRoot.palette.placeholderText
                        }

                    }

                }

                DelegateChoice {
                    roleValue: "room"

                    RowLayout {
                        id: del

                        anchors.centerIn: centerRowContent ? parent : undefined
                        spacing: rowSpacing

                        Avatar {
                            height: popup.avatarHeight
                            width: popup.avatarWidth
                            displayName: model.roomName
                            roomid: model.roomid
                            url: model.avatarUrl.replace("mxc://", "image://MxcImage/")
                            onClicked: {
                                popup.completionClicked(completer.completionAt(model.index));
                                popup.completionSelected(model.roomid);
                            }
                        }

                        Label {
                            text: model.roomName
                            font.pixelSize: popup.avatarHeight * 0.5
                            color: model.index == popup.currentIndex ? timelineRoot.palette.highlightedText : timelineRoot.palette.text
                            textFormat: Text.RichText
                        }

                    }

                }

                DelegateChoice {
                    roleValue: "roomAliases"

                    RowLayout {
                        id: del

                        anchors.centerIn: parent
                        spacing: rowSpacing

                        Avatar {
                            height: popup.avatarHeight
                            width: popup.avatarWidth
                            displayName: model.roomName
                            roomid: model.roomid
                            url: model.avatarUrl.replace("mxc://", "image://MxcImage/")
                            onClicked: popup.completionClicked(completer.completionAt(model.index))
                        }

                        Label {
                            text: model.roomName
                            color: model.index == popup.currentIndex ? timelineRoot.palette.highlightedText : timelineRoot.palette.text
                            textFormat: Text.RichText
                        }

                        Label {
                            text: "(" + model.roomAlias + ")"
                            color: model.index == popup.currentIndex ? timelineRoot.palette.highlightedText : timelineRoot.palette.placeholderText
                            textFormat: Text.RichText
                        }

                    }

                }

            }

        }

    }


    background: Rectangle {
        color: timelineRoot.palette.base
        border.color: timelineRoot.palette.mid
    }

}
