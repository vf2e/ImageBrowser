# ImageBrowser 测试用例明细

本文档逐条记录每个自动化测试的**目的**、**前置条件**、**操作步骤**、**断言**与**关联源码**。运行方式见 [testing.md](testing.md)。

---

## C++ 后端测试（`tst_imagebrowserbackend`）

被测类：`src/backend/ImageBrowserBackend.{h,cpp}`  
测试文件：`tests/tst_imagebrowserbackend.cpp`

---

### 1. 初始状态

#### `initialState_isEmpty`

| 项 | 内容 |
|----|------|
| **目的** | 验证新构造的后端处于空状态 |
| **前置** | 默认 `TestFixture` |
| **步骤** | 无额外操作 |
| **断言** | `totalCount==0`，`currentIndex==-1`，`favoriteCount==0`，`!isCurrentFavorite()`，`imagePaths` 为空 |
| **关联** | 构造函数、`loadRecentFoldersFromSettings()` |

#### `currentImagePath_returnsEmptyWhenNoImages`

| 项 | 内容 |
|----|------|
| **目的** | 无图片时 `currentImagePath()` 返回空字符串 |
| **前置** | 默认 `TestFixture` |
| **步骤** | 无 |
| **断言** | `currentImagePath().isEmpty()` |
| **关联** | `currentImagePath()` L112–117 |

---

### 2. 文件夹加载

#### `loadFolder_emptyFolder_hasZeroImages`

| 项 | 内容 |
|----|------|
| **目的** | 空文件夹加载后图片列表为空 |
| **前置** | 创建无文件的 `empty/` 目录 |
| **步骤** | `loadFolder(folder)` |
| **断言** | `totalCount==0`，`currentIndex==-1` |
| **关联** | `loadImagesFromFolder()` L82–110 |

#### `loadFolder_readsSupportedImageExtensions`

| 项 | 内容 |
|----|------|
| **目的** | 支持 jpg/jpeg/png/bmp/gif/webp 六种扩展名 |
| **前置** | 目录内各创建一个对应文件 |
| **步骤** | `loadFolder(folder)` |
| **断言** | `totalCount==6` |
| **关联** | `IMAGE_SUFFIXES` 常量 L11 |

#### `loadFolder_ignoresUnsupportedFiles`

| 项 | 内容 |
|----|------|
| **目的** | 非图片文件不被计入列表 |
| **前置** | 1 张 jpg + txt/mp4/zip |
| **步骤** | `loadFolder(folder)` |
| **断言** | `totalCount==1`，路径以 `photo.jpg` 结尾 |
| **关联** | `dir.setNameFilters(IMAGE_SUFFIXES)` L82 |

#### `loadFolder_nonexistentFolder_emitsMessageAndRemovesFromRecent`

| 项 | 内容 |
|----|------|
| **目的** | 不存在目录时提示用户并从最近列表移除 |
| **前置** | 路径指向不存在的 `missing-folder` |
| **步骤** | `loadFolder(missing)`，监听 `showMessage` |
| **断言** | `showMessage` 触发 1 次；`totalCount==0`；`recentFolders` 不含该路径 |
| **关联** | `loadImagesFromFolder()` L66–71 |

#### `loadFolder_emptyFolder_currentIndexIsMinusOne`

| 项 | 内容 |
|----|------|
| **目的** | 空目录时索引保持 -1 |
| **前置** | 空目录 |
| **步骤** | `loadFolder` |
| **断言** | `currentIndex==-1` |
| **关联** | L102 `m_currentIndex = ... -1 : 0` |

#### `loadFolder_withImages_currentIndexStartsAtZero`

| 项 | 内容 |
|----|------|
| **目的** | 有图时默认从第一张开始（无历史进度） |
| **前置** | 2 张 jpg |
| **步骤** | `loadFolder` |
| **断言** | `currentIndex==0`，路径为 `1.jpg` 或 `2.jpg` 之一 |
| **关联** | `loadProgress()` 返回 -1 时的默认行为 |

---

### 3. 索引与导航

#### `setCurrentIndex_updatesCurrentImagePath`

| 项 | 内容 |
|----|------|
| **目的** | 切换索引同步更新当前路径 |
| **前置** | `first.jpg`、`second.jpg` |
| **步骤** | `loadFolder` → `setCurrentIndex(1)` |
| **断言** | 索引 0 时路径为 `first`；索引 1 时为 `second` |
| **关联** | `setCurrentIndex()` L131–138 |

#### `setCurrentIndex_ignoresInvalidIndices`

| 项 | 内容 |
|----|------|
| **目的** | 越界索引被忽略 |
| **前置** | 单张图片 |
| **步骤** | `setCurrentIndex(99)` 然后 `setCurrentIndex(-1)` |
| **断言** | 两次后 `currentIndex` 仍为 0 |
| **关联** | `setCurrentIndex` 边界检查 L133 |

#### `setCurrentIndex_sameIndex_doesNotChangeState`

| 项 | 内容 |
|----|------|
| **目的** | 设置相同索引不重复发信号 |
| **前置** | 2 张图片，spy `currentIndexChanged` |
| **步骤** | `setCurrentIndex(0)`（当前已是 0） |
| **断言** | `currentIndexChanged` 计数为 0 |
| **关联** | `index != m_currentIndex` 条件 L133 |

#### `nextImage_wrapsAroundAtEnd`

| 项 | 内容 |
|----|------|
| **目的** | 末张下一张回到首张 |
| **前置** | 2 张图，当前索引 1 |
| **步骤** | `nextImage()` |
| **断言** | `currentIndex==0` |
| **关联** | `nextImage()` L140–144 |

#### `previousImage_wrapsAroundAtStart`

| 项 | 内容 |
|----|------|
| **目的** | 首张上一张跳到末张 |
| **前置** | 2 张图，当前索引 0 |
| **步骤** | `previousImage()` |
| **断言** | `currentIndex==1` |
| **关联** | `previousImage()` L146–150 |

#### `nextImage_onEmptyFolder_doesNothing`

| 项 | 内容 |
|----|------|
| **目的** | 空目录时 next 不改变状态 |
| **前置** | 空目录 |
| **步骤** | `nextImage()` |
| **断言** | `currentIndex==-1` |
| **关联** | `m_imagePaths.isEmpty()` 早退 L142 |

#### `previousImage_onEmptyFolder_doesNothing`

| 项 | 内容 |
|----|------|
| **目的** | 空目录时 previous 不改变状态 |
| **前置** | 空目录 |
| **步骤** | `previousImage()` |
| **断言** | `currentIndex==-1` |
| **关联** | 同 `nextImage` 空列表早退 |

---

### 4. 收藏

#### `toggleFavorite_addsCurrentImage`

| 项 | 内容 |
|----|------|
| **目的** | 收藏当前图片 |
| **前置** | 单张 `star.jpg` |
| **步骤** | `loadFolder` → `toggleFavoriteForCurrent()` |
| **断言** | `favoriteCount==1`，`isCurrentFavorite()==true`，路径匹配 |
| **关联** | `toggleFavoriteForCurrent()` L152–169 |

#### `toggleFavorite_removesCurrentImage`

| 项 | 内容 |
|----|------|
| **目的** | 再次切换取消收藏 |
| **前置** | 单张图片 |
| **步骤** | toggle 两次 |
| **断言** | `favoriteCount==0`，`!isCurrentFavorite()` |
| **关联** | `m_favorites.remove(path)` L158–160 |

#### `toggleFavorite_emitsFavMessageType`

| 项 | 内容 |
|----|------|
| **目的** | 收藏时消息类型为 `fav` |
| **前置** | 单张图片，spy `showMessage` |
| **步骤** | `loadFolder` 后 toggle |
| **断言** | 1 条消息，第二参数 `"fav"` |
| **关联** | L163 `QStringLiteral("fav")` |

#### `toggleFavorite_emitsUnfavMessageType`

| 项 | 内容 |
|----|------|
| **目的** | 取消收藏时消息类型为 `unfav` |
| **前置** | 先收藏再 spy |
| **步骤** | 第二次 toggle |
| **断言** | 1 条消息，类型 `"unfav"` |
| **关联** | L160 `QStringLiteral("unfav")` |

#### `toggleFavorite_onEmptyFolder_doesNothing`

| 项 | 内容 |
|----|------|
| **目的** | 无当前图片时不收藏 |
| **前置** | 空目录 |
| **步骤** | `toggleFavoriteForCurrent()` |
| **断言** | 无 `showMessage`，`favoriteCount==0` |
| **关联** | `path.isEmpty()` 早退 L155 |

#### `isCurrentFavorite_reflectsFavoriteState`

| 项 | 内容 |
|----|------|
| **目的** | 收藏状态随当前图片变化 |
| **前置** | 2 张图 |
| **步骤** | 收藏第 0 张 → 切到第 1 张 |
| **断言** | 第 0 张时 true；第 1 张时 false |
| **关联** | `isCurrentFavorite()` L119–122 |

---

### 5. 收藏持久化

#### `favorites_persistToUtf8File`

| 项 | 内容 |
|----|------|
| **目的** | 收藏写入 UTF-8 的 `favorites.txt` |
| **前置** | 中文文件名 `收藏.jpg` |
| **步骤** | 收藏后读文件 |
| **断言** | 文件存在，内容为 `收藏.jpg` |
| **关联** | `saveFavoritesLog()` L199–210 |

#### `favorites_reloadAfterFolderReopen`

| 项 | 内容 |
|----|------|
| **目的** | 新后端实例重开文件夹能恢复收藏 |
| **前置** | 固定 `settingsKey`，收藏 `keep.png` |
| **步骤** | 新建 `TestFixture`（同 key）再 `loadFolder` |
| **断言** | `favoriteCount==1`，路径正确，仍收藏 |
| **关联** | `loadFavoritesLog()` L212–228 |

#### `favorites_ignoreMissingFilesInLog`

| 项 | 内容 |
|----|------|
| **目的** | 日志中不存在的文件不计入收藏 |
| **前置** | 预写 `favorites.txt` 含 `exists.jpg` 与 `ghost.jpg` |
| **步骤** | `loadFolder` |
| **断言** | `favoriteCount==1` |
| **关联** | `QFile::exists(fullPath)` L224 |

#### `favorites_supportChineseFileNames`

| 项 | 内容 |
|----|------|
| **目的** | 中文目录与文件名全流程可用 |
| **前置** | 目录 `中文目录`，文件 `风景照片.jpg` |
| **步骤** | fixture1 收藏 → fixture2 重开同路径 |
| **断言** | `favoriteCount==1`，路径含中文 |
| **关联** | `in.setCodec("UTF-8")` L218 |

---

### 6. 浏览进度持久化

#### `progress_savedOnIndexChange`

| 项 | 内容 |
|----|------|
| **目的** | 切换索引写入 `browser_config.ini` |
| **前置** | 2 张图 |
| **步骤** | `setCurrentIndex(1)` 后读 ini |
| **断言** | `LastIndex==1`，`LastFileName=="b.jpg"` |
| **关联** | `saveProgress()` L171–178 |

#### `progress_restoredByFileNameWhenIndexShifted`

| 项 | 内容 |
|----|------|
| **目的** | 新增文件导致索引偏移时，按文件名恢复位置 |
| **前置** | 收藏 `a.jpg`、`target.jpg`，浏览到 `target` |
| **步骤** | 新增 `new-first.jpg` 后重新 `loadFolder` |
| **断言** | 当前路径仍以 `target.jpg` 结尾 |
| **关联** | `loadProgress()` 按 `LastFileName` 匹配 L189–195 |

#### `progress_restoredBySavedIndexWhenFileNameMissing`

| 项 | 内容 |
|----|------|
| **目的** | 原文件删除时回退到保存的索引（裁剪后） |
| **前置** | `a.jpg`、`b.jpg`，浏览到 `b` |
| **步骤** | 删除 `b.jpg` 后 `loadFolder` |
| **断言** | `currentIndex==0` |
| **关联** | `loadProgress()` 返回 `savedIndex` L196 |

---

### 7. 最近文件夹

#### `recentFolders_prependsLoadedFolder`

| 项 | 内容 |
|----|------|
| **目的** | 加载后目录出现在最近列表首位 |
| **前置** | 单目录 `album-a` |
| **步骤** | `loadFolder` |
| **断言** | `recentFolders().first()==folder` |
| **关联** | `prepend` L75 |

#### `recentFolders_deduplicatesExistingEntry`

| 项 | 内容 |
|----|------|
| **目的** | 重复加载同一目录不重复条目，且置顶 |
| **前置** | `album-a`、`album-b`，初始 recent 为空 |
| **步骤** | 加载 A → B → A |
| **断言** | 列表长度 2，首位为 A |
| **关联** | `removeAll` + `prepend` L74–75 |

#### `recentFolders_keepsAtMostFiveEntries`

| 项 | 内容 |
|----|------|
| **目的** | 最近目录最多保留 5 条 |
| **前置** | 连续创建 6 个目录并依次加载 |
| **步骤** | 全部 `loadFolder` |
| **断言** | 长度 5，首位为最后加载，不含第一个 |
| **关联** | `while size > 5 removeLast` L76–78 |

#### `recentFolders_persistAcrossInstances`

| 项 | 内容 |
|----|------|
| **目的** | QSettings 跨后端实例持久化最近目录 |
| **前置** | 共享 UUID `settingsKey` |
| **步骤** | fixture1 加载 `persisted`；fixture2（`clearSettings=false`）再加载另一目录 |
| **断言** | fixture2 的 recent 仍含 `persisted` |
| **关联** | `saveRecentFoldersToSettings()` L57–61 |
| **注意** | fixture2 必须 `clearSettings=false` |

---

### 8. 导出

#### `exportFavorites_withNoFavorites_emitsInfoMessage`

| 项 | 内容 |
|----|------|
| **目的** | 无收藏时提示信息 |
| **前置** | 有图但未收藏 |
| **步骤** | `exportFavorites()` |
| **断言** | 1 条 `showMessage`，类型 `info` |
| **关联** | L232–234 |

#### `exportFavorites_copiesFilesToDestination`

| 项 | 内容 |
|----|------|
| **目的** | 收藏文件复制到 `{exportRoot}/{文件夹名}/` |
| **前置** | 收藏 2 个文件 |
| **步骤** | `exportFavorites()`，等待异步完成（5s） |
| **断言** | 目标目录两文件存在；消息含 `"2"` |
| **关联** | `QtConcurrent::run` L250–265 |

#### `exportFavorites_skipsExistingDestinationFiles`

| 项 | 内容 |
|----|------|
| **目的** | 目标已存在同名文件时不覆盖 |
| **前置** | 目标目录预置 `fav.jpg`（内容 `existing`） |
| **步骤** | 导出并等待 |
| **断言** | 目标内容仍为 `existing`；成功数为 0 |
| **关联** | `!QFile::exists(destPath)` L256 |

#### `exportFavorites_completesAsynchronously`

| 项 | 内容 |
|----|------|
| **目的** | 导出在后台线程完成，非同步返回 |
| **前置** | 单张收藏 |
| **步骤** | 调用后立即检查 spy |
| **断言** | 调用瞬间 spy 为空；5s 内收到 1 条消息 |
| **关联** | `QMetaObject::invokeMethod` 回调 L262–264 |

---

### 9. 信号（扩展）

#### `loadFolder_emitsRecentFoldersChanged`

| 项 | 内容 |
|----|------|
| **目的** | 加载时更新最近目录并发射信号 |
| **断言** | `recentFoldersChanged` 计数 1；列表含当前目录 |

#### `toggleFavorite_emitsIsCurrentFavoriteChanged`

| 项 | 内容 |
|----|------|
| **目的** | 收藏切换发射 `isCurrentFavoriteChanged` |
| **断言** | spy 计数 1；`isCurrentFavorite()==true` |

#### `loadFolder_emitsCurrentIndexChanged`

| 项 | 内容 |
|----|------|
| **目的** | 有图加载时发射 `currentIndexChanged` |
| **断言** | spy 计数 1；`currentIndex==0` |

### 10. selectFolder（注入式）

#### `selectFolder_usesInjectedPicker`

| 项 | 内容 |
|----|------|
| **目的** | `setFolderPicker` 替代 `QFileDialog` |
| **步骤** | 注入目录 → `selectFolder()` |
| **断言** | 图片加载成功 |

#### `selectFolder_emptyPickerResult_doesNothing`

| 项 | 内容 |
|----|------|
| **目的** | 空结果不加载 |
| **断言** | `totalCount==0`，无消息 |

### 11. 多收藏与文件夹隔离

#### `favorites_multipleImages_trackedIndependently`

| 项 | 内容 |
|----|------|
| **目的** | 多图独立收藏 |
| **断言** | `favoriteCount==2`；各索引状态正确 |

#### `favorites_isolatedPerFolder`

| 项 | 内容 |
|----|------|
| **目的** | 相册间收藏隔离 |
| **断言** | 切换相册后收藏集合独立恢复 |

### 12. 导出异常

#### `exportFavorites_mkpathFailure_emitsMessage`

| 项 | 内容 |
|----|------|
| **目的** | `mkpath` 失败时提示 |
| **前置** | 导出路径被文件阻塞 |
| **断言** | 消息含「无法创建目录」 |

### 13. 集成工作流

#### `workflow_loadNavigateFavoriteAndExport`

| 项 | 内容 |
|----|------|
| **目的** | 端到端：加载→翻页→收藏→导出→切换→重载 |
| **断言** | 导出 2 张；重载后收藏与进度恢复 |

---

### 14. 信号（原有）

#### `loadFolder_emitsStateChangeSignals`

| 项 | 内容 |
|----|------|
| **目的** | 加载文件夹触发核心属性变更信号 |
| **前置** | 单张图片，spy 四个信号 |
| **步骤** | `loadFolder` |
| **断言** | `imagePathsChanged`、`totalCountChanged`、`favoriteCountChanged`、`currentImagePathChanged` 各 1 次 |
| **关联** | `loadImagesFromFolder` emit 段 L105–109 |

#### `setCurrentIndex_emitsCurrentIndexChanged`

| 项 | 内容 |
|----|------|
| **目的** | 有效索引变更发射信号 |
| **前置** | 2 张图 |
| **步骤** | `setCurrentIndex(1)` |
| **断言** | `currentIndexChanged` 计数 1 |
| **关联** | `updateCurrentImagePath()` L124–129 |

---

## QML 组件测试（`tst_qml`）

测试数据目录：`tests/qml/`（通过 `QUICK_TEST_SOURCE_DIR` 编译进测试可执行文件）  
Mock 对象：`tests/qml/MockBackend.qml`  
运行环境：`QT_QPA_PLATFORM=offscreen`，`QT_PLUGIN_PATH` 指向 Qt `plugins` 目录

### 测试手法

1. 使用 `Qt.createComponent(Qt.resolvedUrl(...))` 加载组件
2. 使用 `createTemporaryObject(component, root, { controller: mock })` 创建实例
3. 使用 `MockBackend` 模拟 `ImageBrowserBackend` 的 QML 属性
4. 可见性相关用例断言**绑定表达式**而非 `visible`（offscreen + DropShadow 下 `visible` 不可靠）

```qml
// EmptyPlaceholder: visible: imageCount === 0
compare(placeholder.imageCount === 0, true)

// TopToolbar / BottomToolbar: visible: imageCount > 0
compare(toolbar.imageCount > 0, true)
```

---

### `tst_emptyplaceholder.qml`

| 用例 | 目的 | Mock 状态 | 断言 |
|------|------|-----------|------|
| `test_visible_when_no_images` | 无图时应显示占位符 | `totalCount=0` | `imageCount==0`，`imageCount===0` 为 true |
| `test_hidden_when_images_loaded` | 有图时不显示占位符 | `totalCount=3` | `imageCount===0` 为 false |
| `test_reads_recent_folders_from_controller` | 绑定 recent 列表 | `recentFolders` 含 2 项 | `recentList.length==2` |

**被测组件**：`qml/components/EmptyPlaceholder.qml`  
**关键属性**：`imageCount`、`recentList`、`visible: imageCount === 0`

---

### `tst_toptoolbar.qml`

| 用例 | 目的 | Mock 状态 | 断言 |
|------|------|-----------|------|
| `test_hidden_when_no_images` | 无图时顶栏逻辑隐藏 | 默认 | `imageCount==0`，`imageCount>0` 为 false |
| `test_visible_when_has_images` | 有图时显示路径与收藏数 | `totalCount=2`，`currentImagePath`，`favoriteCount=1` | `imageCount>0` 为 true，路径与收藏数正确 |

**被测组件**：`qml/components/TopToolbar.qml`  
**关键属性**：`visible: imageCount > 0`，`imagePath`，`favorites`

---

### `tst_bottomtoolbar.qml`

| 用例 | 目的 | Mock 状态 | 断言 |
|------|------|-----------|------|
| `test_hidden_when_no_images` | 无图时底栏逻辑隐藏 | 默认 | `imageCount>0` 为 false |
| `test_shows_index_counter` | 索引与总数绑定 | `totalCount=5`，`currentIndex=2` | `imageCount>0` 为 true，`imageIndex==2`，`imageCount==5` |

**被测组件**：`qml/components/BottomToolbar.qml`  
**关键属性**：`imageIndex`、`imageCount`、`visible: imageCount > 0`

---

### 键盘集成（`tst_keyboard_integration`）

| 用例 | 目的 | 断言 |
|------|------|------|
| `rightArrow_advancesIndex` | → 键翻页 | 索引 0→1→2 |
| `leftArrow_goesToPreviousIndex` | ← 键后退 | 索引 1→0 |
| `space_togglesFavorite` | 空格收藏/取消 | `isCurrentFavorite` 切换 |
| `unboundKey_doesNotChangeIndex` | Tab 无效 | 索引不变 |

**Harness**：`tests/qml/KeyboardHarness.qml`（与 `main.qml` 快捷键逻辑一致）

### `tst_imageviewer.qml`

| 用例 | 目的 | 断言 |
|------|------|------|
| `test_binds_image_path_and_count` | 路径与数量绑定 | `imageCount==2`，`imagePath` 正确 |
| `test_favorite_badge_follows_controller` | 收藏角标跟随 mock | `currentFavorite` 随 mock 变化 |
| `test_zero_images_hides_content` | 无图状态 | `imageCount==0` |

**被测组件**：`qml/components/ImageViewer.qml`

### `tst_recentfolderpopup.qml`

| 用例 | 目的 | 断言 |
|------|------|------|
| `test_reads_recent_list_from_controller` | 最近列表绑定 | `recentList.length==3` |
| `test_empty_recent_list` | 空列表 | `recentList.length==0` |

**被测组件**：`qml/components/RecentFolderPopup.qml`

### `tst_backgroundgradient.qml`

| 用例 | 目的 | 断言 |
|------|------|------|
| `test_component_loads` | 组件可解析 | `Component.Ready` |
| `test_gradient_has_two_stops` | 渐变配置 | 2 个 `GradientStop` |

### `tst_toastmessage.qml`

| 用例 | 目的 | 操作 | 断言 |
|------|------|------|------|
| `test_show_sets_message_and_type` | show 设置内容与类型 | `show("测试消息","info")` | message/type 正确，`opacity→1` |
| `test_fav_type_updates_styling` | 收藏样式分支 | `show("已收藏","fav")` | `type=="fav"` |
| `test_unfav_type_updates_styling` | 取消收藏样式分支 | `show("已取消","unfav")` | `type=="unfav"` |

**被测组件**：`qml/components/ToastMessage.qml`  
**关键 API**：`show(msg, type)`，渐变/边框按 `type` 分支

---

## 用例统计

| 套件 | 文件数 | 用例数 |
|------|--------|--------|
| C++ 后端 | 1 | 48 |
| 键盘集成 | 1 | 4 |
| QML 组件 | 7 | 17 |
| **合计** | **9** | **69** |

---

## 修订记录

| 日期 | 变更 |
|------|------|
| 2026-06-06 | 初版：38 个 C++ 用例明细 |
| 2026-06-06 | 新增 10 个 QML 用例与 MockBackend 说明 |
| 2026-06-06 | C++ 增至 48 用例；QML 增至 15；新增 `setFolderPicker` |
