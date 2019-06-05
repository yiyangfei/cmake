set(METHODS_LOCATION ${CMAKE_CURRENT_LIST_DIR})

macro(createlib)
    cmake_parse_arguments(
        CREATELIB # prefix of output variables
        "STATIC;SHARED;GENERATE_PACKAGE" # list of names of the boolean arguments (only defined ones will be true)
        "NAME;NAMESPACE;VERSION" # list of names of mono-valued arguments
        "SOURCES;PUBLIC_HEADERS;PRIVATE_HEADERS;PUBLIC_DEPS;PRIVATE_DEPS" # list of names of multi-valued arguments (output variables are lists)
        ${ARGN} # arguments of the function to parse, here we take the all original ones
    )
    # note: if it remains unparsed arguments, here, they can be found in variable PARSED_ARGS_UNPARSED_ARGUMENTS
    if(NOT CREATELIB_NAME)
        message(FATAL_ERROR "You must provide a name")
    endif(NOT CREATELIB_NAME)
    if(NOT CREATELIB_NAMESPACE)
        message(FATAL_ERROR "You must provide a namespace")
    endif(NOT CREATELIB_NAMESPACE)
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

    set(INSTALL_DIRECTORY_NAME ${CREATELIB_NAMESPACE}${VERSION_MAJOR}${CREATELIB_NAME}/${CREATELIB_NAMESPACE}${VERSION_MAJOR})
    set(CMAKE_DIRECTORY_NAME ${CREATELIB_NAMESPACE}${VERSION_MAJOR}${CREATELIB_NAME})
    #base name used for cmake config files:
    #<CMAKE_CONFIG_FILE_BASE_NAME>Config.cmake
    #<CMAKE_CONFIG_FILE_BASE_NAME>ConfigVersion.cmake
    #<CMAKE_CONFIG_FILE_BASE_NAME>Targets.cmake
    #<CMAKE_CONFIG_FILE_BASE_NAME>Targets_noconfig.cmake
    set(CMAKE_CONFIG_FILE_BASE_NAME ${CREATELIB_NAMESPACE}${VERSION_MAJOR}${CREATELIB_NAME})

    set(LIB_INSTALL_DIR lib/${INSTALL_DIRECTORY_NAME})
    set(INCLUDE_INSTALL_DIR include/${INSTALL_DIRECTORY_NAME}/${CREATELIB_NAMESPACE}${VERSION_MAJOR}${CREATELIB_NAME})
    set(GLOBAL_INCLUDE_INSTALL_DIR include/${INSTALL_DIRECTORY_NAME})
    set(BIN_INSTALL_DIR bin)
    set(CMAKE_INSTALL_DIR lib/cmake/${CMAKE_DIRECTORY_NAME})

    # Linking
    if(${CREATELIB_STATIC})
        set(LINKING "STATIC")
    endif(${CREATELIB_STATIC})
    if(${CREATELIB_SHARED})
        set(LINKING "SHARED")
    endif(${CREATELIB_SHARED})

    # Create target
    add_library(${CREATELIB_NAME} ${LINKING}
                ${CREATELIB_SOURCES}
                ${CREATELIB_PUBLIC_HEADERS}
                ${CREATELIB_PRIVATE_HEADERS})
    add_library(${CREATELIB_NAMESPACE}${VERSION_MAJOR}::${CREATELIB_NAME} ALIAS ${CREATELIB_NAME})

    message(STATUS "Creating ${LINKING} library ${CREATELIB_NAME} (${CREATELIB_NAMESPACE}${VERSION_MAJOR}::${CREATELIB_NAME}) ${CREATELIB_VERSION}")

    set_target_properties(${CREATELIB_NAME} PROPERTIES
        VERSION ${CREATELIB_VERSION}
        SOVERSION ${VERSION_MAJOR}
        PUBLIC_HEADER "${CREATELIB_PUBLIC_HEADERS}"
        PRIVATE_HEADER "${CREATELIB_PRIVATE_HEADERS}"
    )

    # Make list of paths where includes can be found.
    foreach(header ${CREATELIB_PUBLIC_HEADERS})
        get_filename_component(dir ${header} REALPATH)
        get_filename_component(dir ${dir} DIRECTORY)
        list(APPEND directories ${dir})
    endforeach(header)
    list(REMOVE_DUPLICATES directories)
    foreach(include ${directories})
        target_include_directories(${CREATELIB_NAME} PUBLIC $<BUILD_INTERFACE:${include}>)
    endforeach(include)

    # Link dependencies
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
        set(ISSHAREDLIBRARY FALSE)
        if (DEFINED BUILD_SHARED_LIBS AND NOT DEFINED LINKING)
            set(ISSHAREDLIBRARY ${BUILD_SHARED_LIBS})
        endif()

        if(${CREATELIB_SHARED} OR ${ISSHAREDLIBRARY})
            install(FILES $<TARGET_PDB_FILE:${CREATELIB_NAME}> DESTINATION bin OPTIONAL)
        endif()
    endif()

    if(DEFINED CREATELIB_GENERATE_PACKAGE)
        message(STATUS "${CREATELIB_NAME} is available as package. Add find_package(${CREATELIB_NAMESPACE}${VERSION_MAJOR}${CREATELIB_NAME} REQUIRED) to your project to provide the ${CREATELIB_NAME} target.")

        set(CMAKE_DIRECTORY_NAME ${CREATELIB_NAMESPACE}${VERSION_MAJOR}${CREATELIB_NAME})
        set(CMAKE_INSTALL_DIR lib/cmake/${CREATELIB_NAMESPACE}${VERSION_MAJOR}${CREATELIB_NAME})

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
          NAMESPACE ${CREATELIB_NAMESPACE}${VERSION_MAJOR}::
          DESTINATION ${CMAKE_INSTALL_DIR}
        )

        # Now install the 3 config files
        install(FILES ${CMAKE_BINARY_DIR}/${CMAKE_CONFIG_FILE_BASE_NAME}Config.cmake
                      ${CMAKE_BINARY_DIR}/${CMAKE_CONFIG_FILE_BASE_NAME}ConfigVersion.cmake
                DESTINATION ${CMAKE_INSTALL_DIR}
        )

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

    # Create target
    add_executable(${CREATEAPP_NAME}
                   ${CREATEAPP_SOURCES}
                   ${CREATEAPP_HEADERS})

    # Link dependencies
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

    # Output Path for the non-config build (i.e. mingw)
    set_target_properties(${CREATEAPP_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY bin)
    set_target_properties(${CREATEAPP_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY bin)
    set_target_properties(${CREATEAPP_NAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY bin)

    install(TARGETS ${CREATEAPP_NAME} DESTINATION bin)

endmacro(createapp)
