cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)
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
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.24" MINIMUM)
include (ValaPrecompile)

add_definitions(-DVALA_VERSION="${VALA_SHORTVER}")
add_definitions(-w) # Disable gcc warnings

find_package (PkgConfig)

pkg_check_modules (CORE REQUIRED
  gtk+-3.0>=3.12
  glib-2.0>=2.40
  gio-2.0>=2.40
  gio-unix-2.0>=2.40
  gthread-2.0>=2.40
  gmodule-2.0>=2.40)

set(CORE_PACKAGES
  gtk+-3.0
  glib-2.0
  gio-2.0
  gio-unix-2.0
  gmodule-2.0)

set(PACKGAGE_CFLAGS ${CORE_CFLAGS})
set(PACKAGE_LINK_DIRS ${CORE_LIBRARY_DIRS})
set(PACKAGE_LIBRARIES ${CORE_LIBRARIES})

add_definitions (${CORE_CFLAGS})
link_libraries (${CORE_LIBRARIES})
link_directories (${CORE_LIBRARY_DIRS})


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
