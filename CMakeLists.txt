cmake_minimum_required(VERSION 3.16)

project(ImageBrowser VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt5 5.15 REQUIRED COMPONENTS Core Quick Widgets Concurrent)

set(IMAGEBROWSER_SOURCES
    src/main.cpp
    src/backend/ImageBrowserBackend.cpp
    src/backend/AestheticEvaluator.cpp
    src/backend/CritiqueEvaluator.cpp
)

set(IMAGEBROWSER_HEADERS
    src/backend/ImageBrowserBackend.h
    src/backend/AestheticEvaluator.h
    src/backend/CritiqueEvaluator.h
)

set(IMAGEBROWSER_RESOURCES
    qml.qrc
)

add_executable(ImageBrowser WIN32
    ${IMAGEBROWSER_SOURCES}
    ${IMAGEBROWSER_HEADERS}
    ${IMAGEBROWSER_RESOURCES}
)

target_include_directories(ImageBrowser PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/backend
)

target_compile_definitions(ImageBrowser PRIVATE
    QT_DEPRECATED_WARNINGS
)

if(MSVC)
    target_compile_options(ImageBrowser PRIVATE /utf-8)
elseif(MINGW)
    target_compile_options(ImageBrowser PRIVATE
        -finput-charset=UTF-8
        -fexec-charset=UTF-8
    )
endif()

if(WIN32)
    set(IMAGEBROWSER_RC_FILE ${CMAKE_CURRENT_BINARY_DIR}/ImageBrowser.rc)
    file(WRITE ${IMAGEBROWSER_RC_FILE}
        "IDI_ICON1 ICON \"${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/logo.ico\"\n"
    )
    target_sources(ImageBrowser PRIVATE ${IMAGEBROWSER_RC_FILE})
endif()

target_link_libraries(ImageBrowser PRIVATE
    Qt5::Core
    Qt5::Quick
    Qt5::Widgets
    Qt5::Concurrent
)

option(IMAGEBROWSER_BUILD_TESTS "Build unit tests" ON)
if(IMAGEBROWSER_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
