# Create an SDK package containing all installed files.

if(NOT TARGET sdk)
    add_custom_target(sdk)
endif()
add_custom_target(sdk-${PROJECT_BASE_NAME} ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target install
    COMMAND ${CMAKE_COMMAND} -E chdir ${CMAKE_INSTALL_PREFIX} ${CMAKE_COMMAND} -E tar "cf" "${CMAKE_BINARY_DIR}/sdk.zip" --format=zip --files-from=${CMAKE_BINARY_DIR}/install_manifest.txt
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Packaging artefacts into ${CMAKE_BINARY_DIR}/sdk.zip ..."
    VERBATIM)
add_dependencies(sdk sdk-${PROJECT_BASE_NAME})


# Create an arbitrary archive.
set(MY_DIR ${CMAKE_CURRENT_LIST_DIR})
macro(add_to_archive NAME FILE)
    if(NOT TARGET ${NAME}-archive)

        # Create a target to create the file list for the archive.
        add_custom_command(OUTPUT dummy-${NAME}.unexisting
            COMMAND ${CMAKE_COMMAND} -E remove_directory archive-staging/${NAME}
            COMMAND ${CMAKE_COMMAND} -E make_directory archive-staging/${NAME}
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
            COMMENT "Gathering files for ${NAME} archive...")
            
        # Create a target to create the archive.
        add_custom_target(${NAME}-archive
            COMMAND ${CMAKE_COMMAND} -E remove -f "${NAME}.zip"
            COMMAND ${CMAKE_COMMAND} -E chdir archive-staging ${CMAKE_COMMAND} -E tar "cf" "${CMAKE_BINARY_DIR}/${NAME}.zip" --format=zip ${NAME}
            COMMAND ${CMAKE_COMMAND} -E remove_directory "archive-staging"
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
            DEPENDS dummy-${NAME}.unexisting
            COMMENT "Creating ${NAME} archive: ${CMAKE_BINARY_DIR}/${NAME}.zip")
    endif()
    
    if(NOT IS_DIRECTORY ${FILE})
        # Copy file
        add_custom_command(OUTPUT dummy-${NAME}.unexisting
                COMMAND ${CMAKE_COMMAND} -E copy_if_different ${FILE} archive-staging/${NAME}
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                APPEND)
    else()
        # Copy directory
        add_custom_command(OUTPUT dummy-${NAME}.unexisting
            COMMAND ${CMAKE_COMMAND} -E copy_directory ${FILE} archive-staging/${NAME}
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
            APPEND)
    endif()
endmacro()