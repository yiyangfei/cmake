set(METHODS_LOCATION ${CMAKE_CURRENT_LIST_DIR})

macro(createlib)
    cmake_parse_arguments(
        CREATELIB # prefix of output variables
        "STATIC;SHARED;GENERATE_PACKAGE" # list of names of the boolean arguments (only defined ones will be true)
        "NAME;PREFIX;VERSION" # list of names of mono-valued arguments
        "SOURCES;PUBLIC_HEADERS;PRIVATE_HEADERS;PUBLIC_DEPS;PRIVATE_DEPS" # list of names of multi-valued arguments (output variables are lists)
        ${ARGN} # arguments of the function to parse, here we take the all original ones
    )
    # note: if it remains unparsed arguments, here, they can be found in variable PARSED_ARGS_UNPARSED_ARGUMENTS
    if(NOT CREATELIB_NAME)
        message(FATAL_ERROR "You must provide a name")
    endif(NOT CREATELIB_NAME)
    if(NOT CREATELIB_VERSION)
        message(FATAL_ERROR "You must provide a version")
    endif(NOT CREATELIB_VERSION)

    # Version field
    set(VERSION_MAJOR 0)
    set(VERSION_MINOR 0)
    set(VERSION_PATCH 0)
    string(REPLACE "." ";" VERSION_PARTS ${CREATELIB_VERSION})
    list(LENGTH VERSION_PARTS VERSION_PARTS_COUNT)
    if(${VERSION_PARTS_COUNT} GREATER 0)
        list (GET VERSION_PARTS 0 VERSION_MAJOR)
    endif()
    if(${VERSION_PARTS_COUNT} GREATER 1)
        list (GET VERSION_PARTS 0 VERSION_MAJOR)
        list (GET VERSION_PARTS 1 VERSION_MINOR)
    endif()
    if(${VERSION_PARTS_COUNT} GREATER 2)
        list (GET VERSION_PARTS 0 VERSION_MAJOR)
        list (GET VERSION_PARTS 1 VERSION_MINOR)
        list (GET VERSION_PARTS 2 VERSION_PATCH)
    endif()
    message("Version: ${CREATELIB_VERSION} ${VERSION_PARTS} ${VERSION_MAJOR} ${VERSION_MINOR} ${VERSION_PATCH}")

    set(PROJECT_NAME ${PROJECT_NAME_PREFIX}${PROJECT_BASE_NAME})
    set(TARGET_NAME ${PROJECT_BASE_NAME})
    set(PROJECT_NAMESPACE ${PROJECT_NAME_PREFIX}${VERSION_MAJOR})
    set(INSTALL_DIRECTORY_NAME ${PROJECT_NAME}/${PROJECT_NAME_PREFIX}${SO_VERSION})
    set(CMAKE_DIRECTORY_NAME ${PROJECT_NAME_PREFIX}${SO_VERSION}${PROJECT_BASE_NAME})
    set(PACKAGE_NAME ${PROJECT_NAME_PREFIX}${SO_VERSION}${PROJECT_BASE_NAME})
    set(MODULE_NAME ${PROJECT_NAME})
    #base name used for cmake config files:
    #<CMAKE_CONFIG_FILE_BASE_NAME>Config.cmake
    #<CMAKE_CONFIG_FILE_BASE_NAME>ConfigVersion.cmake
    #<CMAKE_CONFIG_FILE_BASE_NAME>Targets.cmake
    #<CMAKE_CONFIG_FILE_BASE_NAME>Targets_noconfig.cmake
    set(CMAKE_CONFIG_FILE_BASE_NAME ${CREATELIB_PREFIX}${VERSION_MAJOR}${CREATELIB_NAME})

    set(LIB_INSTALL_DIR lib/${INSTALL_DIRECTORY_NAME})
    set(INCLUDE_INSTALL_DIR include/${INSTALL_DIRECTORY_NAME}/${PROJECT_NAME})
    set(GLOBAL_INCLUDE_INSTALL_DIR include/${INSTALL_DIRECTORY_NAME})
    set(BIN_INSTALL_DIR bin)
    set(CMAKE_INSTALL_DIR lib/cmake/${CMAKE_DIRECTORY_NAME})

#    message("Provided sources are:")
#    foreach(src ${CREATELIB_SOURCES})
#        message("- ${src}")
#    endforeach(src)

    # Linking
    if(${CREATELIB_STATIC})
        set(LINKING "STATIC")
    endif(${CREATELIB_STATIC})
    if(${CREATELIB_SHARED})
        set(LINKING "SHARED")
    endif(${CREATELIB_SHARED})
    message("Linking: ${LINKING}")

    # Create target
    add_library(${CREATELIB_NAME} ${LINKING}
                ${CREATELIB_SOURCES}
                ${CREATELIB_PUBLIC_HEADERS}
                ${CREATELIB_PRIVATE_HEADERS})
    if(DEFINED CREATELIB_PREFIX)
        message("Creating target alias ${CREATELIB_PREFIX}${VERSION_MAJOR}::${CREATELIB_NAME} for ${CREATELIB_NAME}")
        add_library(${CREATELIB_PREFIX}${VERSION_MAJOR}::${CREATELIB_NAME} ALIAS ${CREATELIB_NAME})
    endif()

    set_target_properties(${CREATELIB_NAME} PROPERTIES
        VERSION ${CREATELIB_VERSION}
        SOVERSION ${VERSION_MAJOR}
        PUBLIC_HEADER "${CREATELIB_PUBLIC_HEADERS}"
        PRIVATE_HEADER "${CREATELIB_PRIVATE_HEADERS}"
    )

    # Make list of paths where includes can be found.
    foreach(header ${CREATELIB_PUBLIC_HEADERS})
        get_filename_component(dir ${header} DIRECTORY)
        list(APPEND directories ${dir})
    endforeach(header)
    list(REMOVE_DUPLICATES directories)
    message("includes: ${directories}")
    foreach(include ${directories})
        target_include_directories(${CREATELIB_NAME} PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/${include}>)
    endforeach(include)

    # Link dependencies
    message("public deps: ${CREATELIB_PUBLIC_DEPS}")
    foreach(dep ${CREATELIB_PUBLIC_DEPS})
        target_link_libraries(${CREATELIB_NAME} PUBLIC ${dep})
    endforeach(dep)

    # Output Path for the non-config build (i.e. mingw)
    set_target_properties(${CREATELIB_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY bin)
    set_target_properties(${CREATELIB_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY bin)
    set_target_properties(${CREATELIB_NAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY bin)

    # Second, for multi-config builds (e.g. msvc)
    foreach( CONFIG ${CMAKE_CONFIGURATION_TYPES} )
        string( TOUPPER ${CONFIG} CONFIG )
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CONFIG} bin )
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CONFIG} bin )
        set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CONFIG} bin )
        set_target_properties(${CREATELIB_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_${CONFIG} bin )
        set_target_properties(${CREATELIB_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_${CONFIG} bin )
        set_target_properties(${CREATELIB_NAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_${CONFIG} bin )
    endforeach( CONFIG CMAKE_CONFIGURATION_TYPES )

    if(MSVC)
        install(FILES $<TARGET_PDB_FILE:${CREATELIB_NAME}> DESTINATION bin OPTIONAL)
    endif()

    if(DEFINED CREATELIB_GENERATE_PACKAGE)

        # Create config file
        configure_package_config_file(
            ${METHODS_LOCATION}/config.cmake.in
            ${CMAKE_BINARY_DIR}/${CMAKE_CONFIG_FILE_BASE_NAME}Config.cmake
            INSTALL_DESTINATION ${CMAKE_INSTALL_DIR}
            PATH_VARS INCLUDE_INSTALL_DIR GLOBAL_INCLUDE_INSTALL_DIR
        )

        # Create a config version file
        write_basic_package_version_file(
          ${CMAKE_BINARY_DIR}/${CMAKE_CONFIG_FILE_BASE_NAME}ConfigVersion.cmake
          VERSION ${CREATELIB_VERSION}
          COMPATIBILITY SameMajorVersion
        )

        # Create import targets
        install(TARGETS ${CREATELIB_NAME} EXPORT ${CREATELIB_NAME}Targets
          RUNTIME DESTINATION ${BIN_INSTALL_DIR}
          LIBRARY DESTINATION ${LIB_INSTALL_DIR}
          ARCHIVE DESTINATION ${LIB_INSTALL_DIR}
          PUBLIC_HEADER DESTINATION ${INCLUDE_INSTALL_DIR}
          PRIVATE_HEADER DESTINATION ${INCLUDE_INSTALL_DIR}/private
        )

        # Export the import targets
        install(EXPORT ${CREATELIB_NAME}Targets
          FILE "${CMAKE_CONFIG_FILE_BASE_NAME}Targets.cmake"
          NAMESPACE ${PROJECT_NAMESPACE}::
          DESTINATION ${CMAKE_INSTALL_DIR}
        )

        # Now install the 3 config files
        install(FILES ${CMAKE_BINARY_DIR}/${CMAKE_CONFIG_FILE_BASE_NAME}Config.cmake
                      ${CMAKE_BINARY_DIR}/${CMAKE_CONFIG_FILE_BASE_NAME}ConfigVersion.cmake
                DESTINATION ${CMAKE_INSTALL_DIR}
        )

        # Create and install a global module include file
        # This makes it possible to include all header files of the module by using
        # #include <${PROJECT_NAME}>
        set(GLOBAL_HEADER_FILE ${CMAKE_BINARY_DIR}/${CREATELIB_PREFIX}${VERSION_MAJOR}${CREATELIB_NAME})
        file(WRITE ${GLOBAL_HEADER_FILE} "//Includes all headers of ${CREATELIB_NAME}\n\n")

        foreach(header ${${TARGET_NAME}_PUBLIC_HEADERS})
          get_filename_component(header_filename ${header} NAME)
          file(APPEND ${GLOBAL_HEADER_FILE} "#include \"${PROJECT_NAME_PREFIX}${PROJECT_BASE_NAME}/${header_filename}\"\n")
        endforeach()

        install(FILES ${GLOBAL_HEADER_FILE} DESTINATION ${GLOBAL_INCLUDE_INSTALL_DIR})

    endif(DEFINED CREATELIB_GENERATE_PACKAGE)

endmacro(createlib)

macro(createapp)
    cmake_parse_arguments(
        CREATEAPP # prefix of output variables
        "CONSOLE" # list of names of the boolean arguments (only defined ones will be true)
        "NAME;VERSION" # list of names of mono-valued arguments
        "SOURCES;HEADERS;DEPS" # list of names of multi-valued arguments (output variables are lists)
        ${ARGN} # arguments of the function to parse, here we take the all original ones
    )
    # note: if it remains unparsed arguments, here, they can be found in variable PARSED_ARGS_UNPARSED_ARGUMENTS
    if(NOT CREATEAPP_NAME)
        message(FATAL_ERROR "You must provide a name")
    endif(NOT CREATEAPP_NAME)
    if(NOT CREATEAPP_VERSION)
        message(FATAL_ERROR "You must provide a version")
    endif(NOT CREATEAPP_VERSION)

    # Version field
    set(VERSION_MAJOR 0)
    set(VERSION_MINOR 0)
    set(VERSION_PATCH 0)
    string(REPLACE "." ";" VERSION_PARTS ${CREATEAPP_VERSION})
    list(LENGTH VERSION_PARTS VERSION_PARTS_COUNT)
    if(${VERSION_PARTS_COUNT} GREATER 0)
        list (GET VERSION_PARTS 0 VERSION_MAJOR)
    endif()
    if(${VERSION_PARTS_COUNT} GREATER 1)
        list (GET VERSION_PARTS 0 VERSION_MAJOR)
        list (GET VERSION_PARTS 1 VERSION_MINOR)
    endif()
    if(${VERSION_PARTS_COUNT} GREATER 2)
        list (GET VERSION_PARTS 0 VERSION_MAJOR)
        list (GET VERSION_PARTS 1 VERSION_MINOR)
        list (GET VERSION_PARTS 2 VERSION_PATCH)
    endif()
    message("Version: ${CREATEAPP_VERSION} ${VERSION_PARTS} ${VERSION_MAJOR} ${VERSION_MINOR} ${VERSION_PATCH}")

    # Create target
    add_executable(${CREATEAPP_NAME}
                   ${CREATEAPP_SOURCES}
                   ${CREATEAPP_HEADERS})

    # Link dependencies
    message("public deps: ${CREATEAPP_DEPS}")
    foreach(dep ${CREATEAPP_DEPS})
        target_link_libraries(${CREATEAPP_NAME} PRIVATE ${dep})
    endforeach(dep)

    add_resource_info(${CREATEAPP_NAME} FALSE ${VERSION_MAJOR} ${VERSION_MINOR} ${VERSION_PATCH}
                      ${CREATEAPP_NAME}
                      ${CREATEAPP_NAME}
                      ${CREATEAPP_SOURCES})
    add_manifest(${CREATEAPP_NAME} BIN)

    if(${CREATEAPP_CONSOLE})
        if(WIN32 AND NOT UNIX)
            set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /subsystem:windows /entry:mainCRTStartup")
            set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} /subsystem:windows /entry:mainCRTStartup")
            set(CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO} /subsystem:windows /entry:mainCRTStartup")
        endif()
    endif(${CREATEAPP_CONSOLE})

endmacro(createapp)

macro(createpack)
    cmake_parse_arguments(
        CREATEPACK # prefix of output variables
        "CONSOLE" # list of names of the boolean arguments (only defined ones will be true)
        "NAME;VERSION" # list of names of mono-valued arguments
        "TARGETS" # list of names of multi-valued arguments (output variables are lists)
        ${ARGN} # arguments of the function to parse, here we take the all original ones
    )
    # note: if it remains unparsed arguments, here, they can be found in variable PARSED_ARGS_UNPARSED_ARGUMENTS
    if(NOT CREATEPACK_NAME)
        message(FATAL_ERROR "You must provide a name")
    endif(NOT CREATEPACK_NAME)
    if(NOT CREATEPACK_VERSION)
        message(FATAL_ERROR "You must provide a version")
    endif(NOT CREATEPACK_VERSION)

    # Version field
    set(VERSION_MAJOR 0)
    set(VERSION_MINOR 0)
    set(VERSION_PATCH 0)
    string(REPLACE "." ";" VERSION_PARTS ${CREATEPACK_VERSION})
    list(LENGTH VERSION_PARTS VERSION_PARTS_COUNT)
    if(${VERSION_PARTS_COUNT} GREATER 0)
        list (GET VERSION_PARTS 0 VERSION_MAJOR)
    endif()
    if(${VERSION_PARTS_COUNT} GREATER 1)
        list (GET VERSION_PARTS 0 VERSION_MAJOR)
        list (GET VERSION_PARTS 1 VERSION_MINOR)
    endif()
    if(${VERSION_PARTS_COUNT} GREATER 2)
        list (GET VERSION_PARTS 0 VERSION_MAJOR)
        list (GET VERSION_PARTS 1 VERSION_MINOR)
        list (GET VERSION_PARTS 2 VERSION_PATCH)
    endif()
    message("Version: ${CREATEPACK_VERSION} ${VERSION_PARTS} ${VERSION_MAJOR} ${VERSION_MINOR} ${VERSION_PATCH}")

    # Create config file
    configure_package_config_file(
        ${METHODS_LOCATION}/config.cmake.in
        ${CMAKE_BINARY_DIR}/${CMAKE_CONFIG_FILE_BASE_NAME}Config.cmake
        INSTALL_DESTINATION ${CMAKE_INSTALL_DIR}
        PATH_VARS INCLUDE_INSTALL_DIR GLOBAL_INCLUDE_INSTALL_DIR
    )

    # Create a config version file
    write_basic_package_version_file(
      ${CMAKE_BINARY_DIR}/${CMAKE_CONFIG_FILE_BASE_NAME}ConfigVersion.cmake
      VERSION ${FULL_VERSION}
      COMPATIBILITY SameMajorVersion
    )

    # Create import targets
    install(TARGETS ${CREATEPACK_TARGETS} EXPORT ${CREATEPACK_NAME}Targets
      RUNTIME DESTINATION ${BIN_INSTALL_DIR}
      LIBRARY DESTINATION ${LIB_INSTALL_DIR}
      ARCHIVE DESTINATION ${LIB_INSTALL_DIR}
      PUBLIC_HEADER DESTINATION ${INCLUDE_INSTALL_DIR}
      PRIVATE_HEADER DESTINATION ${INCLUDE_INSTALL_DIR}/private
    )

    # Export the import targets
    install(EXPORT ${CREATEPACK_NAME}Targets
      FILE "${CMAKE_CONFIG_FILE_BASE_NAME}Targets.cmake"
      NAMESPACE ${PROJECT_NAMESPACE}::
      DESTINATION ${CMAKE_INSTALL_DIR}
    )

    # Now install the 3 config files
    install(FILES ${CMAKE_BINARY_DIR}/${CMAKE_CONFIG_FILE_BASE_NAME}Config.cmake
                  ${CMAKE_BINARY_DIR}/${CMAKE_CONFIG_FILE_BASE_NAME}ConfigVersion.cmake
            DESTINATION ${CMAKE_INSTALL_DIR}
    )

endmacro(createpack)
