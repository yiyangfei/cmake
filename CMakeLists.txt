cmake_minimum_required(VERSION 3.4.3 FATAL_ERROR)
project(cmakespark)

add_subdirectory(src)

add_subdirectory(tests)

# Examples
include(ExternalProject)

ExternalProject_Add(simplelib
                    PREFIX examples
                    GIT_REPOSITORY "https://github.com/cmakespark/simplelib.git"
                    GIT_TAG master
                    CONFIGURE_COMMAND ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DCMAKESPARK=${CMAKE_CURRENT_LIST_DIR}/src ../simplelib
                    BUILD_COMMAND ${CMAKE_COMMAND} --build . --target install)

ExternalProject_Add(simpleapp
                    PREFIX examples
                    GIT_REPOSITORY "https://github.com/cmakespark/simpleapp.git"
                    GIT_TAG master
                    CONFIGURE_COMMAND ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DCMAKESPARK=${CMAKE_CURRENT_LIST_DIR}/src -DCC2SimpleLib=${CMAKE_INSTALL_PREFIX}/lib/cmake/CC2SimpleLib ../simplelib
                    BUILD_COMMAND ${CMAKE_COMMAND} --build . --target install)
