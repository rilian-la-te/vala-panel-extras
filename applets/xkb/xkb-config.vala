using Gtk;
using GLib;

namespace XkbPlugin
{
    [CCode(cname = "ConfigDialog"),GtkTemplate (ui = "/org/vala-panel/xkb/config.ui")]
    public class ConfigDialog : Gtk.Dialog
    {
        [GtkChild (name = "model-menu")]
        private MenuButton model_menu;
        [GtkChild (name = "options-menu")]
        private MenuButton switch_options_menu;
        [GtkChild (name = "layout-per-window")]
        private CheckButton layout_per_window;
        [GtkChild (name = "indicator-only")]
        private CheckButton keep_system;
        [GtkChild (name = "all-grid")]
        private Grid layout_config;
        [GtkChild (name = "show-flag")]
        private CheckButton show_flag;
        [GtkChild (name = "show-text")]
        private CheckButton show_text;
        [GtkChild (name = "list-layouts")]
        private ListBox list_layouts;
        [GtkChild (name = "advanced-options-entry")]
        private Entry advanced_options_entry;
        private GLib.Action model_action;
        private GLib.Action switch_action;
        internal string switch_options {get; set;}
        internal string options {
            owned get {
                return switch_options + advanced_options_entry.text;
            }
            set {
                parse_options(value);
            }}
        public ConfigDialog (XkbIconExporter icon)
        {
            icon.settings.bind(PER_WINDOW,layout_per_window,"active",SettingsBindFlags.DEFAULT);
            icon.settings.bind(SHOW_FLAG,show_flag,"active",SettingsBindFlags.DEFAULT);
            icon.settings.bind(SHOW_TEXT,show_text,"active",SettingsBindFlags.DEFAULT);
            icon.settings.bind(KEEP_SYSTEM,keep_system,"active",SettingsBindFlags.DEFAULT);
            icon.settings.bind(KEEP_SYSTEM,layout_config,"sensitive",SettingsBindFlags.DEFAULT | SettingsBindFlags.INVERT_BOOLEAN);
            icon.settings.bind(OPTIONS,this,OPTIONS,SettingsBindFlags.DEFAULT);
            model_action = icon.settings.create_action(MODEL);
            switch_action = new PropertyAction("switch",this,"switch-options");
        }
        private void parse_options(string options)
        {

        }
    }
}
