add_subdirectory(valgrind)

add_custom_target(runtests
    COMMAND ${CMAKE_COMMAND} -DBASEDIR=${CMAKE_BINARY_DIR} -P ${CMAKE_CURRENT_LIST_DIR}/runtests.cmake
    SOURCES runtests.cmake)
