set(CORE_VALA_FILES
    watcheriface.vala
    snitemproxy.vala
    menuserializer.vala
    application.vala
    configurator.vala
    notifications.vala
    ${CMAKE_BINARY_DIR}/vapi/config.vala
    )
vala_precompile(VALA_C internal
    ${CORE_VALA_FILES}
PACKAGES
    ${CORE_PACKAGES}
    gio-addons-2.0
OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --vapidir=${CMAKE_BINARY_DIR}/vapi
    --target-glib=2.40
    --gresources=${CMAKE_CURRENT_SOURCE_DIR}/internal.gresource.xml
    --thread
GENERATE_VAPI
    internal
)

add_definitions(-DG_SETTINGS_ENABLE_BACKEND)

#####
# Core Library
#####

set (LIB_FILES ${VALA_C})

add_library (internal STATIC
    ${LIB_FILES}
    ${GLIB_RESOURCES_LIB}
)
add_custom_target(vala-files-lib SOURCES ${CORE_VALA_FILES})
set_target_properties (internal PROPERTIES
    VERSION 0.0
    SOVERSION 0)
