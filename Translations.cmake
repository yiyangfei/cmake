
# 2. Find the dependency
find_package(Qt5LinguistTools QUIET)
if(Qt5LinguistTools_FOUND)
    set(TRANSLATIONS_OUTPUT_DIR "${CMAKE_BINARY_DIR}/translations" CACHE STRING "Output directory to place translation files.")
    set(TRANSLATION_LOCALES "en_EN;en_US;nl_BE;fr_FR" CACHE STRING "Locales to generate translation files for")
    
    message(STATUS "Qt5Linguist tools found: 'translate' build target will be created. Use this build target to generate the .TS and .QM files.")
    
    set(TRANSLATION_OUTPUT_FILES "")
    foreach(LOCALE ${TRANSLATION_LOCALES})
        list(APPEND TRANSLATION_OUTPUT_FILES "${TRANSLATIONS_OUTPUT_DIR}/${LOCALE}.ts")
    endforeach()
    message(STATUS "TRANSLATION_OUTPUT_FILES: ${TRANSLATION_OUTPUT_FILES}")
    
    # Generate TS and QM files
    qt5_create_translation(QM_FILES ${CMAKE_SOURCE_DIR} ${TRANSLATION_OUTPUT_FILES})
    set(QM_FILES ${QM_FILES} PARENT_SCOPE)

    # Create build target
    add_custom_target(translate ALL DEPENDS ${QM_FILES})
endif(Qt5LinguistTools_FOUND)
