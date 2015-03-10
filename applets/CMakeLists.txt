option(ENABLE_ALSA "Enable volume applet" ON)

if (ENABLE_ALSA)
    pkg_check_modules(ALSA alsa)
    if (NOT(ALSA_FOUND))
        set(ENABLE_ALSA OFF)
    endif()
endif()

if (ENABLE_ALSA)
    add_subdirectory(volume)
endif()

add_subdirectory(batt)

option(ENABLE_XKB "Enable xkb applet" ON)
if (ENABLE_XKB)
    pkg_check_modules(XKB xkbcommon)
    pkg_check_modules(X11 xcb-xkb xkbcommon-x11 x11-xcb xkbfile gdk-x11-3.0)
    if (NOT(XKB_FOUND) OR NOT(X11_FOUND))
        set(ENABLE_XKB OFF)
    endif()
endif()

if (ENABLE_XKB)
    add_subdirectory(xkb)
endif()
