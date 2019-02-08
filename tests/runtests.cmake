find_program(VALGRIND valgrind)

execute_process(
    COMMAND ${CMAKE_COMMAND} --build . --target test
    WORKING_DIRECTORY ${BASEDIR}
    RESULT_VARIABLE RESULT
    OUTPUT_VARIABLE OUTPUT
    ERROR_VARIABLE ERROR)

message(STATUS ${OUTPUT})

find_program(VALGRIND valgrind)
if(VALGRIND)
    if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
        if(${RESULT} EQUAL 0)
            message(FATAL_ERROR "Valgrind should find an memory leak.")
        endif()
    endif()
else()
    if(NOT ${RESULT} EQUAL 0)
        message(FATAL_ERROR "Unit tests should pass.")
    endif()
endif()
