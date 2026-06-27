find_package(Qt5 5.15 REQUIRED COMPONENTS Test Concurrent Quick QuickTest)

# --- C++ 后端单元测试 ---
add_executable(tst_imagebrowserbackend
    tst_imagebrowserbackend.cpp
    ../src/backend/ImageBrowserBackend.cpp
    ../src/backend/ImageBrowserBackend.h
    ../src/backend/AestheticEvaluator.cpp
    ../src/backend/AestheticEvaluator.h
    ../src/backend/CritiqueEvaluator.cpp
    ../src/backend/CritiqueEvaluator.h
)

target_include_directories(tst_imagebrowserbackend PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/backend
)

target_compile_definitions(tst_imagebrowserbackend PRIVATE
    QT_DEPRECATED_WARNINGS
)

if(MSVC)
    target_compile_options(tst_imagebrowserbackend PRIVATE /utf-8)
elseif(MINGW)
    target_compile_options(tst_imagebrowserbackend PRIVATE
        -finput-charset=UTF-8
        -fexec-charset=UTF-8
    )
endif()

target_link_libraries(tst_imagebrowserbackend PRIVATE
    Qt5::Test
    Qt5::Concurrent
    Qt5::Widgets
)

add_test(NAME imagebrowserbackend COMMAND tst_imagebrowserbackend)

# --- QML 组件测试 ---
get_target_property(_qt_qmake_executable Qt5::qmake IMPORTED_LOCATION)
execute_process(
    COMMAND "${_qt_qmake_executable}" -query QT_INSTALL_QML
    OUTPUT_VARIABLE _qt_install_qml
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
    COMMAND "${_qt_qmake_executable}" -query QT_INSTALL_PLUGINS
    OUTPUT_VARIABLE _qt_install_plugins
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

# 使用正斜杠，避免 MSVC 宏字符串中 \t \q 等被当作转义序列
set(_qml_import_root "${CMAKE_SOURCE_DIR}/qml")
set(_qml_test_dir "${CMAKE_CURRENT_SOURCE_DIR}/qml")
string(REPLACE "\\" "/" _qml_import_root "${_qml_import_root}")
string(REPLACE "\\" "/" _qml_test_dir "${_qml_test_dir}")
string(REPLACE "\\" "/" _qt_install_qml "${_qt_install_qml}")
string(REPLACE "\\" "/" _qt_install_plugins "${_qt_install_plugins}")

add_executable(tst_qml tst_qml.cpp)

target_compile_definitions(tst_qml PRIVATE
    QML_IMPORT_ROOT="${_qml_import_root}"
    QT_QML_IMPORT_PATH="${_qt_install_qml}"
    QT_PLUGIN_PATH="${_qt_install_plugins}"
    QUICK_TEST_SOURCE_DIR="${_qml_test_dir}"
)

if(MSVC)
    target_compile_options(tst_qml PRIVATE /utf-8)
elseif(MINGW)
    target_compile_options(tst_qml PRIVATE
        -finput-charset=UTF-8
        -fexec-charset=UTF-8
    )
endif()

target_link_libraries(tst_qml PRIVATE
    Qt5::QuickTest
    Qt5::Quick
    Qt5::Gui
)

add_test(NAME qml COMMAND tst_qml)

# --- 键盘快捷键 C++ 集成测试 ---
add_executable(tst_keyboard_integration
    tst_keyboard_integration.cpp
    ../src/backend/ImageBrowserBackend.cpp
    ../src/backend/ImageBrowserBackend.h
    ../src/backend/AestheticEvaluator.cpp
    ../src/backend/AestheticEvaluator.h
    ../src/backend/CritiqueEvaluator.cpp
    ../src/backend/CritiqueEvaluator.h
)

target_include_directories(tst_keyboard_integration PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/backend
)

target_compile_definitions(tst_keyboard_integration PRIVATE
    QT_DEPRECATED_WARNINGS
    TEST_QML_DIR="${_qml_test_dir}"
)

if(MSVC)
    target_compile_options(tst_keyboard_integration PRIVATE /utf-8)
elseif(MINGW)
    target_compile_options(tst_keyboard_integration PRIVATE
        -finput-charset=UTF-8
        -fexec-charset=UTF-8
    )
endif()

target_link_libraries(tst_keyboard_integration PRIVATE
    Qt5::Test
    Qt5::Quick
    Qt5::Gui
    Qt5::Qml
    Qt5::Concurrent
    Qt5::Widgets
)

add_test(NAME keyboard_integration COMMAND tst_keyboard_integration)

# --- 覆盖率（可选）---
option(IMAGEBROWSER_ENABLE_COVERAGE "Enable debug info for coverage tools (MSVC /Zi)" OFF)
if(IMAGEBROWSER_ENABLE_COVERAGE)
    if(MSVC)
        target_compile_options(tst_imagebrowserbackend PRIVATE /Zi)
        target_compile_options(tst_keyboard_integration PRIVATE /Zi)
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        target_compile_options(tst_imagebrowserbackend PRIVATE --coverage)
        target_link_options(tst_imagebrowserbackend PRIVATE --coverage)
        target_compile_options(tst_keyboard_integration PRIVATE --coverage)
        target_link_options(tst_keyboard_integration PRIVATE --coverage)
    endif()
endif()
