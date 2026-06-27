import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import "components"

ApplicationWindow {
    id: window
    visible: true
    width: 1200
    height: 800
    title: qsTr("图片浏览器")
    color: "#0F0F13"

    Connections {
        target: typeof backend !== "undefined" ? backend : null
        enabled: target !== null
        function onShowMessage(msg, type) { toast.show(msg, type) }
    }

    BackgroundGradient {
        anchors.fill: parent
    }

    Item {
        id: mainContainer
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (!backend) return
            if (backend.assistantPanelOpen) return
            switch (event.key) {
                case Qt.Key_Left: backend.previousImage(); break
                case Qt.Key_Right: backend.nextImage(); break
                case Qt.Key_Up:
                case Qt.Key_Down:
                case Qt.Key_Space: backend.toggleFavoriteForCurrent(); break
                default: return
            }
            event.accepted = true
        }

        onActiveFocusChanged: {
            if (activeFocus) return
            if (backend && backend.assistantPanelOpen) return
            if (backend && backend.critiquePanelOpen) return
            forceActiveFocus()
        }

        ImageViewer {
            controller: backend
            anchors.fill: parent
            onRequestFocus: mainContainer.forceActiveFocus()
        }

        EmptyPlaceholder {
            controller: backend
            onRequestFocus: mainContainer.forceActiveFocus()
            onOpenRecentMenu: recentFolderMenu.open()
            onSelectFolder: backend.selectFolder()
        }
    }

    TopToolbar {
        controller: backend
        onRequestFocus: mainContainer.forceActiveFocus()
        onOpenRecentMenu: recentFolderMenu.open()
    }

    BottomToolbar {
        controller: backend
    }

    RecentFolderPopup {
        id: recentFolderMenu
        controller: backend
        onSelectFolder: backend.selectFolder()
    }

    CritiquePanel {
        z: 500
        controller: backend
    }

    AssistantPanel {
        controller: backend
    }

    AssistantFab {
        controller: backend
    }

    ToastMessage {
        id: toast
    }

    Component.onCompleted: mainContainer.forceActiveFocus()
}
