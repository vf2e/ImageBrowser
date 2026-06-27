import QtQuick 2.15

// 轻量 mock，用于 QML 组件绑定测试（不依赖 C++ 后端）
QtObject {
    property int totalCount: 0
    property int currentIndex: -1
    property int favoriteCount: 0
    property string currentImagePath: ""
    property var recentFolders: []
    property bool isCurrentFavorite: false
    property double aestheticScore: 0
    property bool aestheticScoreValid: false
    property bool aestheticEvaluating: false
    property string critiqueText: ""
    property bool critiqueValid: false
    property bool critiqueEvaluating: false
    property bool critiquePanelOpen: false

    function requestCritique() {}
    function openCritiquePanel() { critiquePanelOpen = true }

    function loadFolder(path) {
        recentFolders = [path].concat(recentFolders.filter(function(item) { return item !== path }))
        totalCount = 1
        currentIndex = 0
        currentImagePath = path
    }
}
