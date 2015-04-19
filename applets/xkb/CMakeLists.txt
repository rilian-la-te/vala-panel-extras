set(PLUGIN_NAME xkb)
vala_precompile(VALA_C vala-panel-extras-${PLUGIN_NAME}
    ${PLUGIN_NAME}.vala
    xkb-backend.vala
    xkb-config.vala
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
    --target-glib=2.40
    --gresources=${CMAKE_CURRENT_SOURCE_DIR}/${PLUGIN_NAME}.gresource.xml
    --thread
)
#####
# Plugin Library
#####
INCLUDE(GResource)
glib_compile_resources(RESOURCES
    source
        ${PLUGIN_NAME}.gresource.xml
)

# Build library for plugin
set (LIBS ${CORE_LIBRARIES} ${XKB_LIBRARIES} ${X11_LIBRARIES})
set (LIB_PATHS ${CORE_LIBRARY_DIRS} ${XKB_LIBRARY_DIRS} ${X11_LIBRARY_DIRS})
link_directories (${LIB_PATHS})
add_executable (vala-panel-extras-${PLUGIN_NAME}
    ${VALA_C}
    ${RESOURCES}
)

target_link_libraries (vala-panel-extras-${PLUGIN_NAME} ${LIBS} internal)

# Install plugin stuffs
install(TARGETS vala-panel-extras-${PLUGIN_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/org.valapanel.${PLUGIN_NAME}.desktop DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/icons DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/vala-panel-extras/${PLUGIN_NAME})
