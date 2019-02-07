execute_process(
    COMMAND ${CMAKE_COMMAND} --build . --target test
    WORKING_DIRECTORY ${BASEDIR}
    RESULT_VARIABLE RESULT
    OUTPUT_VARIABLE OUTPUT
    ERROR_VARIABLE ERROR)

if(NOT ${RESULT} EQUAL 1)
    message(FATAL_ERROR "Valgrind should find an memory leak")
endif()
