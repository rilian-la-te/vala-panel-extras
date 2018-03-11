cmake_minimum_required (VERSION 3.6 FATAL_ERROR)
cmake_policy (VERSION 3.6)
project (vala-panel-extras C)
enable_testing ()
include(GNUInstallDirs)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share/vala-panel")
set (PKGDATADIR "${DATADIR}")
include(GitVersion)
determine_fallback_version(${CMAKE_SOURCE_DIR}/cmake)
include(FallbackVersion)
set (GETTEXT_PACKAGE "vala-panel-extras")
set (RELEASE_NAME "Vala Panel extra items")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$")

# Add 'make dist' command for creating release tarball
set (CPACK_PACKAGE_VERSION ${VERSION})
set (CPACK_PACKAGE_VERSION_MAJOR "${VERSION_MAJOR}")
set (CPACK_PACKAGE_VERSION_MINOR "${VERSION_MINOR}")
set (CPACK_PACKAGE_VERSION_PATCH "${VERSION_PATCH}")
set (CPACK_PACKAGE_RELEASE "1")
set (CPACK_SOURCE_GENERATOR "TGZ")
set (CPACK_SOURCE_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${CPACK_PACKAGE_VERSION}")
set (CPACK_SOURCE_IGNORE_FILES "/build/;/.git;/.gitignore;/.gitmodules;~$;${CPACK_SOURCE_IGNORE_FILES}")

include (CPack)
add_custom_target (dist COMMAND ${CMAKE_MAKE_PROGRAM} package_source)

#Add RPM build support
include (UseRPMTools)
if (RPMTools_FOUND)
   RPMTools_ADD_RPM_TARGETS(package ${CMAKE_SOURCE_DIR}/rpm/vala-panel-extras.spec.in)
endif(RPMTools_FOUND)

# Configuration
configure_file (${CMAKE_SOURCE_DIR}/vapi/config.vala.in ${CMAKE_BINARY_DIR}/vapi/config.vala)

# Some definitions
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# Vala
find_package (Vala 0.24 REQUIRED)
include (ValaPrecompile)

add_definitions(-DVALA_VERSION="${VALA_SHORTVER}")
add_definitions(-w) # Disable gcc warnings

find_package (PkgConfig)
find_package(GLIB2 2.50 REQUIRED COMPONENTS GOBJECT GIO GIO_UNIX GMODULE GTHREAD CODEGEN MKENUMS GENMARSHAL COMPILE_SCHEMAS COMPILE_RESOURCES)
include(GLibProgramHandlers)
find_package(GTK 3.22 REQUIRED COMPONENTS GDK X11 WAYLAND)

set(CORE_PACKAGES
  gtk+-3.0
  glib-2.0
  gio-2.0
  gio-unix-2.0
  gmodule-2.0)

#Link libraries for all targets
link_libraries (GLIB2::GLIB GLIB2::GIO_UNIX GTK3::GDK GTK3::GTK m)


# Some include paths
include_directories(${CMAKE_BINARY_DIR}/lib)

#set requred variables
set(TARGET_GLIB ${GLIB_VERSION_MAJOR}.${GLIB_VERSION_MINOR})

ADD_SUBDIRECTORY(po)
ADD_SUBDIRECTORY(lib)
ADD_SUBDIRECTORY(applets)
ADD_SUBDIRECTORY(data)

#Additional install
#install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/vala-panel.desktop DESTINATION share/applications)
