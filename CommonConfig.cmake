cmake_minimum_required(VERSION 3.5.2 FATAL_ERROR)

#################
# Build options #
#################

if (NOT DEFINED BUILD_SHARED_LIBS)
    option(BUILD_SHARED_LIBS "Build as shared library" ON)
endif()
# When set to OFF, the library will be built as a static library
if (${BUILD_SHARED_LIBS})
    add_definitions(-DBUILD_SHARED_LIBS)
endif()


# Usage of Qt libraries
# ---------------------
# Point CMake search path to Qt intallation directory
# Either supply QTDIR as -DQTDIR=<path> to cmake or set an environment variable QTDIR pointing to the Qt installation
if ((NOT DEFINED QTDIR) AND DEFINED ENV{QTDIR})
  set(QTDIR $ENV{QTDIR})
endif ((NOT DEFINED QTDIR) AND DEFINED ENV{QTDIR})

if (NOT DEFINED QTDIR)
  message(FATAL_ERROR "QTDIR has not been set nor supplied as a define parameter to cmake.")
endif (NOT DEFINED QTDIR)

if (QTDIR)
  list (APPEND CMAKE_PREFIX_PATH ${QTDIR})
endif (QTDIR)

# Instruct CMake to run moc automatically when needed.
set(CMAKE_AUTOMOC ON)
# let CMake decide which classes need to be rcc'ed by qmake (Qt)
set(CMAKE_AUTORCC ON)
# let CMake decide which classes need to be uic'ed by qmake (Qt)
set(CMAKE_AUTOUIC ON)


# Usage of CMake Packages
# -----------------------
include(CMakePackageConfigHelpers)

# Point cmake to the packages of libraries in this tree.
list(APPEND CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR}/local-exports)


# Compiler flags
# --------------
if (NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    # not using Visual Studio C++
    add_definitions(-Wall -fvisibility=hidden)
endif()
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find includes in corresponding build directories
set(CMAKE_INCLUDE_CURRENT_DIR ON)

# Compile with @rpath option on Apple
if (APPLE)
  set(CMAKE_MACOSX_RPATH 1)
endif (APPLE)


# Switch testing on
# -----------------
enable_testing()
add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND})
include(AddQtTest)

# Common compiler flags
include(CompilerFlags)