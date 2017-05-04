INCLUDE(GResource)
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

# Build library for plugins and application
set (LIBS ${CORE_LIBRARIES} -lm)
set (LIB_PATHS ${CORE_LIBRARY_DIRS})
link_directories (${LIB_PATHS})

set (LIB_FILES ${VALA_C})

add_library (internal STATIC
    ${LIB_FILES}
    ${GLIB_RESOURCES_LIB}
)
add_custom_target(vala-files-lib SOURCES ${CORE_VALA_FILES})
target_link_libraries (internal ${LIBS})

set_target_properties (internal PROPERTIES
    VERSION 0.0
    SOVERSION 0)
