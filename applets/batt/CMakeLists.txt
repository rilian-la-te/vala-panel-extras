set(PLUGIN_NAME vala-panel-extras-batt)
vala_precompile(VALA_C ${PLUGIN_NAME}
    ${PLUGIN_NAME}.vala
    upower-iface.vala
PACKAGES
    ${CORE_PACKAGES}
    internal
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

# Build library for plugin
set (LIBS ${CORE_LIBRARIES} -lm)
set (LIB_PATHS ${CORE_LIBRARY_DIRS})
link_directories (${LIB_PATHS})

add_executable (${PLUGIN_NAME}
    ${VALA_C}
    ${RESOURCES}
)

target_link_libraries (${PLUGIN_NAME} ${LIBS} internal)

# Install plugin stuffs
install(TARGETS ${PLUGIN_NAME} RUNTIME DESTINATION bin)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PLUGIN_NAME}.desktop DESTINATION share/applications)
