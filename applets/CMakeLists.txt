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
