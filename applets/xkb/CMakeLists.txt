set(PLUGIN_NAME xkb)
set(VALA_FILES
    ${PLUGIN_NAME}.vala
    xkb-backend.vala
    xkb-config.vala
    )
vala_precompile(VALA_C vala-panel-extras-${PLUGIN_NAME}
    ${VALA_FILES}
PACKAGES
    ${CORE_PACKAGES}
    internal
    xkbcommon-x11
    gdk-x11-3.0
    xcb-xkb
    xcb-x11
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

target_link_libraries (vala-panel-extras-${PLUGIN_NAME} PkgConfig::XKB PkgConfig::X11 internal)
add_custom_target(vala-files-${PLUGIN_NAME} SOURCES ${VALA_FILES})
# Install plugin stuffs
install(TARGETS vala-panel-extras-${PLUGIN_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/org.valapanel.${PLUGIN_NAME}.desktop DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/icons DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/vala-panel-extras/${PLUGIN_NAME})
