Vala Panel Extras
---

This is StatusNotifierItems for using in Vala Panel (but can be used any DE in list below). Supported DE is:
 * XFCE (via xfce4-sntray-plugin or xfce4-snw-plugin)
 * ValaPanel (SNTray)
 * KDE (native)
 * Gnome (via gnome-shell-extension-appindicator)
 * Unity (native)

*TODO:*
 * Sound applet (will fully work only in Vala Panel or xfce4-sntray-plugin)
 * Brightness applet (will fully work only in Vala Panel or xfce4-sntray-plugin)
 * XKB
 * Network status
 * Weather
 * CPU temperature
 * CPU frequrency


*Dependencies:*

*All:*
 * GLib (>= 2.40.0)
 * valac
 
*Some:*
 * GTK+ (>= 3.12.0)
 * upower-glib (>= 0.9.20)
 * libwnck (>= 3.4.7)
 * libgweather (>= 3.12.0)
 * gee-0.8 (not gee-1.0!)




Lastly, always set -DCMAKE_INSTALL_PREXIX=/usr when using cmake, otherwise you
won't be able to start the panel on most distros

Author
===
 * Athor <ria.freelander@gmail.com>

Special thanks:
===
 * Ikey Doherty <ikey@evolve-os.com> for sidebar widget and icontasklist

Inspirations
===
 * Budgie Desktop <https://github.com/evolve-os/budgie-desktop/>
 * LXPanel <https://github.com/lxde/lxpanel>
