INCLUDE(GResource)
vala_precompile(VALA_C internal
    watcheriface.vala
    snitemproxy.vala
    menuserializer.vala
    ${CMAKE_BINARY_DIR}/vapi/config.vala
PACKAGES
    ${CORE_PACKAGES}
OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --vapidir=${CMAKE_BINARY_DIR}/vapi
    --target-glib=2.40
    --gresources=${CMAKE_CURRENT_SOURCE_DIR}/libvalapanel.gresource.xml
    --thread
)

#add_definitions(-DG_SETTINGS_ENABLE_BACKEND)
#glib_compile_resources(GLIB_RESOURCES_LIB
#	source
#    	libvalapanel.gresource.xml
#)

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

target_link_libraries (internal ${LIBS})

set_target_properties (internal PROPERTIES
    VERSION 0.0
    SOVERSION 0)
