This repository contains very generic cmake components which can be used across other cmake projects.

# Including in your code.
The common cmake files need to be present when cmake is run.
There are various ways of achieving this.

## Git submodule
You can fetch the files during your git clone using a submodule.
```
git submodule add -b <tag> https://github.com/cmakespark/cmake.git path/to/cmakespark
```

## Cloning during cmake run
Add this snippet to your CMakeLists.txt
```
# Download build system
if(NOT EXISTS "${CMAKE_BINARY_DIR}/cmakespark/v2.0")
    message(STATUS "Downloading buildsystem...")

    find_package(Git REQUIRED)
    execute_process(COMMAND ${GIT_EXECUTABLE} clone --branch v2.0 https://github.com/cmakespark/cmake.git ${CMAKE_BINARY_DIR}/cmakespark/v2.0)
endif()
list(APPEND CMAKE_MODULE_PATH "${CMAKE_BINARY_DIR}/cmakespark/v2.0")
```

# Usage

You can include these files in your CMakeLists.txt
```
# Include common cmake modules
include(CommonConfig)
```

## Create a library

```
createlib(NAME <name> [STATIC|SHARED|<none>]
    NAMESPACE <namespace>
    VERSION <version>
    SOURCES ${SOURCES}
    PUBLIC_HEADERS ${PUBLIC_HEADERS}
    PRIVATE_HEADERS ${PRIVATE_HEADERS}
    PUBLIC_DEPS ${PUBLIC_DEPS}
    PRIVATE_DEPS ${PRIVATE_DEPS}
    GENERATE_PACKAGE)
```
NAME: name of the library  
NAMESPACE: Prefix added to the name of the library. (eg Qt5Core: Qt is the namespace, 5 if the major version and Core is the name of the library)  
LINKING: Can be explicit (static or shared). If omitted, it will depend on the value of the ```BUILD_SHARED_LIBS``` variable.  
VERSION: semver formatted version of the library. (eg. 1.0.0)  
SOURCES: List of source files to be compiled.  
PUBLIC_HEADERS: List of headers which can be included from the library.  
PRIVATE_HEADERS: List of headers which are private to the library and are not exposed.  
PUBLIC_DEPS: Dependencies of this library which are exposed to the users of this library  
PRIVATE_DEPS: Dependencies of this library which are not exposed to the users of this library  
GENERATE_PACKAGE: (optional) If added, a relocatable cmake package is generated to allow the library to be used outside this cmake tree.

## Create an executable

```
createapp(NAME <name>
    VERSION <version>
    [CONSOLE]
    SOURCES ${SOURCES}
    HEADERS ${HEADERS}
    DEPS <dependencies>)
```
NAME: name of the executable  
VERSION: semver formatted version of the executable. (eg. 1.0.0)  
CONSOLE: (optional) If added, the executable is build as a console applicatie. If omitted, it will be a GUI application (windows)  
SOURCES: List of source files to be compiled.  
HEADERS: List of headers to be used  
DEPS: List of dependent libraries of this application.  

## More options
This buildsys also allows to:
- Run unit tests
- Run valgrind on unit tests
- Create archive of installed files
- Create arbitrary archive
- Run cppcheck
- Run code coverage (lcov)
