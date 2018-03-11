set(PLUGIN_NAME weather)
set(VALA_FILES
    ${PLUGIN_NAME}.vala
    ${PLUGIN_NAME}-config.vala
    ${PLUGIN_NAME}-forecast.vala
    )
vala_precompile(VALA_C vala-panel-extras-${PLUGIN_NAME}
    ${VALA_FILES}
PACKAGES
    ${CORE_PACKAGES}
    internal
    gweather-3.0
OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --vapidir=${CMAKE_BINARY_DIR}/lib
    --vapidir=${CMAKE_BINARY_DIR}/vapi
    --target-glib=2.50
    --gresources=${CMAKE_CURRENT_SOURCE_DIR}/${PLUGIN_NAME}.gresource.xml
    --thread
)
#####
# Plugin Library
#####
glib_compile_resources(RESOURCES
    source
        ${PLUGIN_NAME}.gresource.xml
)
# Build library for plugin

add_executable (vala-panel-extras-${PLUGIN_NAME}
    ${VALA_C}
    ${RESOURCES}
)

target_link_libraries (vala-panel-extras-${PLUGIN_NAME} PkgConfig::GWEATHER internal m)
target_compile_definitions(vala-panel-extras-${PLUGIN_NAME} PRIVATE -DGWEATHER_I_KNOW_THIS_IS_UNSTABLE)
add_custom_target(vala-files-${PLUGIN_NAME} SOURCES ${VALA_FILES})
# Install plugin stuffs
install(TARGETS vala-panel-extras-${PLUGIN_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/org.valapanel.${PLUGIN_NAME}.desktop DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications)
