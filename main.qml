import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15

ApplicationWindow {
    id: window
    visible: true
    width: 1200
    height: 800
    title: qsTr("图片浏览器")
    color: "#0F0F13"

    Connections {
        target: backend
        function onShowMessage(msg) { toast.show(msg) }
    }

    // --- 背景装饰 ---
    RadialGradient {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1A1A24" }
            GradientStop { position: 1.0; color: "#0F0F13" }
        }
    }

    // --- 主交互区域 ---
    Item {
        id: mainContainer
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
                            switch(event.key) {
                                case Qt.Key_Left:  backend.previousImage(); break;
                                case Qt.Key_Right: backend.nextImage(); break;
                                case Qt.Key_Up:
                                case Qt.Key_Down:
                                case Qt.Key_Space: backend.toggleFavoriteForCurrent(); break;
                                default: return;
                            }
                            event.accepted = true;
                        }

        onActiveFocusChanged: { if(!activeFocus) forceActiveFocus() }

        // --- 图片显示区域 ---
        Rectangle {
            id: imageContainer
            anchors.fill: parent
            // 动态边距：当有图片时自动收缩，为固定的上下工具栏腾出空间，避免遮挡
            anchors.topMargin: backend.totalCount > 0 ? 88 : 16
            anchors.bottomMargin: backend.totalCount > 0 ? 96 : 16
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            radius: 16
            color: "#1A1A1F"
            border.width: 1
            border.color: "#2A2A35"

            Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on anchors.bottomMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

            // 双缓冲图层包装器
            Item {
                id: imageDisplayWrapper
                anchors.fill: parent
                anchors.margins: 1

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: imageContainer.width
                        height: imageContainer.height
                        radius: imageContainer.radius
                    }
                }

                property string currentSrc: backend.currentImagePath ? "file:///" + backend.currentImagePath : ""

                // 底层：用于定格上一张图片
                Image {
                    id: oldImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    autoTransform: true
                    sourceSize: Qt.size(width, height)
                    visible: backend.totalCount > 0
                }

                // 顶层：用于异步加载新图片并执行渐显动画
                Image {
                    id: newImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    autoTransform: true
                    sourceSize: Qt.size(width, height)
                    visible: backend.totalCount > 0

                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 0;
                            easing.type: Easing.OutCubic
                            onRunningChanged: {
                                if (!running && newImage.opacity === 1.0) {
                                    oldImage.source = newImage.source;
                                }
                            }
                        }
                    }

                    onStatusChanged: {
                        if (status === Image.Ready) opacity = 1.0
                        else if (status === Image.Loading) opacity = 0
                    }
                }

                // 监听后端路径变化
                onCurrentSrcChanged: {
                    if (newImage.status === Image.Ready) {
                        oldImage.source = newImage.source;
                    }
                    newImage.source = currentSrc;
                }

                // 优化后的收藏角标
                Rectangle {
                    id: favoriteBadge
                    anchors { top: parent.top; right: parent.right; margins: 24 }
                    width: 56; height: 56; radius: 28
                    color: "#E61A1A1F" // 毛玻璃质感半透明底色
                    border.color: "#FFD700"
                    border.width: 2
                    visible: backend.isCurrentFavorite
                    scale: visible ? 1.0 : 0.0

                    layer.enabled: true
                    layer.effect: DropShadow {
                        color: "#80FFD700"
                        radius: 20
                        samples: 25
                        spread: 0.15
                    }

                    Behavior on scale {
                        NumberAnimation { duration: 400; easing.type: Easing.OutBack }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "⭐"
                        font { pixelSize: 26; bold: true }
                        color: "#FFD700"

                        // 呼吸发光动画
                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            running: favoriteBadge.visible
                            NumberAnimation { from: 1.0; to: 1.15; duration: 1000; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.15; to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onWheel: (wheel) => {
                                 if (wheel.angleDelta.y > 0) backend.previousImage();
                                 else backend.nextImage();
                             }
                    onClicked: (mouse) => {
                                   mainContainer.forceActiveFocus();
                                   if (mouse.button === Qt.RightButton) backend.toggleFavoriteForCurrent();
                               }
                }
            }
        }

        // 无图片占位
        Rectangle {
            id: placeholderContainer
            anchors.centerIn: parent
            width: 400; height: 200
            radius: 20
            color: "#1A1A1F"
            border.width: 1.5
            border.color: "#2A2A35"
            visible: backend.totalCount === 0

            layer.enabled: true
            layer.effect: DropShadow {
                color: "#40000000"
                radius: 20
                samples: 25
                verticalOffset: 4
            }

            // 扩大点击热区：将 MouseArea 覆盖整个占位框
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: placeholderText.color = "#FFFFFF"
                onExited: placeholderText.color = "#AAAAAA"
                onClicked: {
                    if (backend.recentFolders.length > 0) {
                        recentFolderMenu.open();
                    } else {
                        backend.selectFolder();
                    }
                    mainContainer.forceActiveFocus();
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "📁"
                    font.pixelSize: 48
                    color: "#6666FF"
                }

                Text {
                    id: placeholderText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("请选择一个图片文件夹")
                    font {
                        pixelSize: 18; weight: Font.Medium;
                        family: "Microsoft YaHei, Segoe UI"
                    }
                    color: "#AAAAAA"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            SequentialAnimation on opacity {
                running: placeholderContainer.visible
                loops: Animation.Infinite
                NumberAnimation { from: 0.8; to: 1.0; duration: 2000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.0; to: 0.8; duration: 2000; easing.type: Easing.InOutSine }
            }
        }
    }

    // --- 顶部工具栏 (固定布局) ---
    Rectangle {
        id: topBar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        width: Math.min(parent.width * 0.9, 900)
        height: 52
        radius: 16

        // 仅当有图片时才显示，无图片时隐藏
        visible: backend.totalCount > 0
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#E6181820" }
            GradientStop { position: 1.0; color: "#E610101A" }
        }

        border.color: topBarMouse.containsMouse ? "#4D4D5A" : "#2A2A35"
        border.width: 1.5

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 6
            radius: 20
            samples: 25
            color: "#80000000"
        }

        MouseArea {
            id: topBarMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mainContainer.forceActiveFocus()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 16

            // 选择文件夹按钮
            Rectangle {
                id: btnFolder
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 12
                color: folderMouse.containsMouse ? "#33333A" : "transparent"
                border.width: 1
                border.color: folderMouse.containsMouse ? "#4D4D5A" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "📁"
                    font.pixelSize: 20
                    opacity: folderMouse.containsMouse ? 1.0 : 0.7
                    scale: folderMouse.pressed ? 0.9 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150 } }
                }

                MouseArea {
                    id: folderMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        recentFolderMenu.open();
                        mainContainer.forceActiveFocus()
                    }
                }
            }

            // 分隔线
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 20
                color: "#33333A"
            }

            // 路径显示
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 12
                color: "#1A1A1F"

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: Text.AlignVCenter
                    text: backend.currentImagePath ? backend.currentImagePath : qsTr("未选择路径")
                    font {
                        pixelSize: 13; weight: Font.Normal;
                        family: "Consolas, Microsoft YaHei"
                    }
                    color: "#AAAAAA"
                    elide: Text.ElideMiddle
                }
            }

            // 收藏统计
            Rectangle {
                Layout.preferredWidth: 100
                Layout.preferredHeight: 40
                radius: 12
                color: "#1A1A1F"
                border.width: 1
                border.color: "#33333A"

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "✨"
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: backend.favoriteCount
                        color: "#FFD700"
                        font {
                            pixelSize: 16; weight: Font.Bold;
                            family: "Consolas"
                        }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // 导出按钮
            Rectangle {
                id: btnExport
                Layout.preferredWidth: 100
                Layout.preferredHeight: 40
                radius: 12

                gradient: Gradient {
                    GradientStop { position: 0.0; color: exportMouse.containsMouse ? "#4F46E5" : "#4338CA" }
                    GradientStop { position: 1.0; color: exportMouse.containsMouse ? "#3730A3" : "#312E81" }
                }

                border.width: 1
                border.color: exportMouse.containsMouse ? "#818CF8" : "#4F46E5"

                scale: exportMouse.pressed ? 0.95 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    color: exportMouse.containsMouse ? "#804F46E5" : "#004F46E5"
                    radius: 16
                    samples: 25
                    verticalOffset: 4
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: qsTr("导出")
                        color: "white"
                        font {
                            pixelSize: 14; weight: Font.DemiBold;
                            letterSpacing: 0.5
                        }
                    }
                }

                MouseArea {
                    id: exportMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        backend.exportFavorites();
                        mainContainer.forceActiveFocus()
                    }
                }
            }
        }
    }

    // --- 底部工具栏 (固定布局) ---
    Rectangle {
        id: bottomBar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        width: Math.min(parent.width * 0.9, 900)
        height: 60
        radius: 20

        visible: backend.totalCount > 0
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#E6181820" }
            GradientStop { position: 1.0; color: "#E610101A" }
        }

        border.color: "#2A2A35"
        border.width: 1.5

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: -6
            radius: 20
            samples: 25
            color: "#80000000"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            spacing: 20

            // 计数器
            Rectangle {
                Layout.preferredHeight: 36
                Layout.preferredWidth: 120
                radius: 18
                color: "#1A1A1F"
                border.width: 1
                border.color: "#33333A"

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: backend.totalCount > 0 ? (backend.currentIndex + 1) + " / " + backend.totalCount : "0 / 0"
                    font {
                        pixelSize: 14; weight: Font.Medium;
                        family: "Consolas"
                    }
                    color: "white"
                }
            }

            // 进度条 (使用 Slider 替换 ProgressBar 以支持拖拽)
            Slider {
                id: customProgress
                Layout.fillWidth: true
                from: 0
                to: Math.max(0, backend.totalCount - 1)
                stepSize: 1

                // 初始绑定
                value: backend.currentIndex

                // 核心修复 2：监听后端信号，在外部（如键盘）切换图片时手动更新滑块，防止拖拽破坏静态绑定
                Connections {
                    target: backend
                    function onCurrentIndexChanged() {
                        if (!customProgress.pressed) {
                            customProgress.value = backend.currentIndex;
                        }
                    }
                }

                // 监听拖拽和点击改变事件
                onMoved: {
                    // 核心修复 1：不调用函数，而是直接对属性赋值，自动触发 Q_PROPERTY 的 WRITE 操作
                    backend.currentIndex = Math.round(value);
                }

                // 轨道背景与已阅进度渐变
                background: Rectangle {
                    x: customProgress.leftPadding
                    y: customProgress.topPadding + customProgress.availableHeight / 2 - height / 2
                    implicitHeight: 6
                    width: customProgress.availableWidth
                    height: implicitHeight
                    radius: 3
                    color: "#2A2A35"

                    Rectangle {
                        width: customProgress.visualPosition * parent.width
                        height: parent.height
                        radius: 3

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#6366F1" }
                            GradientStop { position: 0.5; color: "#8B5CF6" }
                            GradientStop { position: 1.0; color: "#10B981" }
                        }
                    }
                }

                // 拖拽滑块 (Handle)
                handle: Rectangle {
                    x: customProgress.leftPadding + customProgress.visualPosition * (customProgress.availableWidth - width)
                    y: customProgress.topPadding + customProgress.availableHeight / 2 - height / 2
                    width: 12
                    height: 12
                    radius: 6
                    color: "#FFFFFF"

                    // 增加交互反馈：拖拽时触点轻微放大
                    scale: customProgress.pressed ? 1.3 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                    layer.enabled: true
                    layer.effect: DropShadow {
                        radius: 8
                        color: "#8B5CF6"
                        samples: 12
                    }
                }
            }

            // 操作提示
            Row {
                spacing: 20
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: ["↑↓ Space 右键 收藏", "← → 滚轮 翻页"]
                    delegate: Text {
                        text: modelData
                        font {
                            pixelSize: 12; weight: Font.Normal;
                            family: "Microsoft YaHei, Segoe UI"
                        }
                        color: "#888888"
                    }
                }
            }
        }
    }

    // --- 最近打开文件夹悬浮菜单 ---
    Popup {
        id: recentFolderMenu
        anchors.centerIn: parent
        width: 480
        height: contentColumn.height + 40
        modal: true
        focus: true

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 350; easing.type: Easing.OutBack }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 200 }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.95; duration: 200 }
        }

        background: Rectangle {
            color: "#E61A1A1F"
            radius: 20
            border.width: 1.5
            border.color: "#2A2A35"

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: 30
                samples: 25
                verticalOffset: 10
                color: "#99000000"
            }
        }

        Column {
            id: contentColumn
            anchors.centerIn: parent
            width: parent.width - 40
            spacing: 12

            Text {
                text: qsTr("最近打开")
                color: "#FFFFFF"
                font { pixelSize: 16; weight: Font.Bold; family: "Microsoft YaHei" }
                leftPadding: 8
                bottomPadding: 8
            }

            Repeater {
                model: backend.recentFolders
                delegate: Rectangle {
                    width: contentColumn.width
                    height: 50
                    radius: 12
                    color: itemMouse.containsMouse ? "#33333A" : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Text {
                            text: "📂"
                            font.pixelSize: 16
                            opacity: itemMouse.containsMouse ? 1.0 : 0.6
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData
                            color: itemMouse.containsMouse ? "#FFFFFF" : "#CCCCCC"
                            elide: Text.ElideLeft
                            font { pixelSize: 13; family: "Consolas, Microsoft YaHei" }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            backend.loadFolder(modelData);
                            recentFolderMenu.close();
                        }
                    }
                }
            }

            Text {
                visible: backend.recentFolders.length === 0
                text: qsTr("暂无历史记录")
                color: "#666666"
                font.pixelSize: 13
                leftPadding: 8
                bottomPadding: 8
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#2A2A35"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                width: contentColumn.width
                height: 50
                radius: 12
                color: browseMouse.containsMouse ? "#1A3B82F6" : "transparent"
                border.width: 1
                border.color: browseMouse.containsMouse ? "#3B82F6" : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "🔍"; font.pixelSize: 16; opacity: 0.8 }
                    Text {
                        text: qsTr("浏览本地文件夹...")
                        color: browseMouse.containsMouse ? "#60A5FA" : "#AAAAAA"
                        font { pixelSize: 14; weight: Font.Medium }
                    }
                }

                MouseArea {
                    id: browseMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        recentFolderMenu.close();
                        backend.selectFolder();
                    }
                }
            }
        }
    }

    // --- 消息提示 ---
    Rectangle {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - height - 100

        property string type: "info"
        property alias message: toastLabel.text

        visible: opacity > 0
        width: Math.min(contentRow.width + 60, 500)
        height: 56
        radius: 28

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: {
                    if (toast.type === "fav") return "#E6F0FDF4";
                    if (toast.type === "unfav") return "#E6FEF2F2";
                    return "#E61A1A1F";
                }
            }
            GradientStop {
                position: 1.0
                color: {
                    if (toast.type === "fav") return "#E6DCFCE7";
                    if (toast.type === "unfav") return "#E6FEE2E2";
                    return "#E6181820";
                }
            }
        }

        border.color: {
            if (toast.type === "fav") return "#6686EFAC";
            if (toast.type === "unfav") return "#66FCA5A5";
            return "#2A2A35";
        }
        border.width: 1.5

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 25
            samples: 25
            verticalOffset: 8
            color: {
                if (toast.type === "fav") return "#4022C55E";
                if (toast.type === "unfav") return "#40EF4444";
                return "#60000000";
            }
        }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 12

            Item {
                width: 24; height: 24
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (toast.type === "fav") return "✨";
                        if (toast.type === "unfav") return "🫧";
                        return "💎";
                    }
                    font.pixelSize: toast.type === "fav" ? 20 : 18

                    scale: toast.opacity > 0.8 ? 1.0 : 0.2
                    Behavior on scale {
                        NumberAnimation { duration: 500; easing.type: Easing.OutBack }
                    }
                }
            }

            Text {
                id: toastLabel
                color: {
                    if (toast.type === "fav") return "#166534";
                    if (toast.type === "unfav") return "#991B1B";
                    return "#F8FAFC";
                }
                font {
                    pixelSize: 14; weight: Font.Medium;
                    family: "Microsoft YaHei, Segoe UI"
                }
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        opacity: 0
        scale: opacity > 0 ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }

        Behavior on scale {
            NumberAnimation { duration: 400; easing.type: Easing.OutBack }
        }

        Behavior on y {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutExpo
            }
        }

        function show(msg) {
            toast.message = msg;
            if (msg.indexOf("已收藏") !== -1) {
                toast.type = "fav";
            } else if (msg.indexOf("取消") !== -1) {
                toast.type = "unfav";
            } else {
                toast.type = "info";
            }

            toast.opacity = 1.0;
            toast.y = window.height - toast.height - 80;
            hideTimer.restart();
        }

        Timer {
            id: hideTimer
            interval: 500
            onTriggered: {
                toast.opacity = 0;
                toast.y = window.height - toast.height - 100;
            }
        }
    }

    Component.onCompleted: mainContainer.forceActiveFocus()
}
