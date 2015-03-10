using StatusNotifier;
using DBusMenu;
using GLib;

namespace XkbPlugin
{
    public static int main(string[] args)
    {
        Gtk.init(ref args);
        var icon = new XkbIconExporter();
        var app = new App("xkb",icon);
        icon.app = app;
        return app.run(args);
    }

    private const string SHOW_FLAG = "show-flag";
    private const string SHOW_TEXT = "show-text";
    private const string MODEL = "model";
    private const string LAYOUT = "layout";
    private const string VARIANT = "variant";
    private const string OPTIONS = "options";
    private const string RULES = "rules";
    private const string KEEP_SYSTEM = "use-system-layouts";
    private const string PER_WINDOW = "layout-group-per-window";
    [DBus (name = "org.kde.StatusNotifierItem")]
    public class XkbIconExporter : ItemExporter
    {
        public bool show_flag { get; set;}
        public bool show_text { get; set;}
        internal XkbBackend backend {get; private set;}
        public XkbIconExporter()
        {
            backend = new XkbBackend();
            layout_items = new SList<ServerItem>();
            backend.layout_changed.connect(()=>{
                update_menu();
                update_display();
            });
            backend.keymap_changed.connect(()=>{
                rebuild_menu();
                update_display();
            });
            this.id = "vala-panel-extras-keyboard";
            this.title = _("Keyboard Layout Applet");
            this.category = Category.HARDWARE;
            this.status = StatusNotifier.Status.ACTIVE;
            this.icon_theme_path = Config.INSTALL_PREFIX + "/share/vala-panel-extras-xkb/icons";
            dbusmenu.icon_theme_path = {this.icon_theme_path};
            var sep = new ServerItem();
            sep.set_variant_property("type",new Variant.string("separator"));
            dbusmenu.prepend_item(sep);
            this.notify["app"].connect(()=>{
                app.about.logo_icon_name = "preferences-desktop-locale";
                app.about.icon_name = "preferences-desktop-locale";
                app.about.program_name = _("Vala Panel Keyboard Layout Applet");
                app.about.comments = _("Simple keyboard layout indicator.");
                this.settings = new GLib.Settings(app.application_id);
                settings.bind(SHOW_FLAG, this, SHOW_FLAG, SettingsBindFlags.GET);
                settings.bind(SHOW_TEXT, this, SHOW_TEXT, SettingsBindFlags.GET);
                settings.bind(MODEL, backend, MODEL, SettingsBindFlags.GET);
                settings.bind(LAYOUT, backend, LAYOUT, SettingsBindFlags.GET);
                settings.bind(VARIANT, backend, VARIANT, SettingsBindFlags.GET);
                settings.bind(OPTIONS, backend, OPTIONS, SettingsBindFlags.GET);
                settings.bind(RULES, backend, RULES, SettingsBindFlags.GET);
                settings.bind(KEEP_SYSTEM, backend, KEEP_SYSTEM, SettingsBindFlags.GET);
                settings.bind(PER_WINDOW, backend, PER_WINDOW, SettingsBindFlags.GET);
                app.preferences = create_preferences_dialog();
                settings.changed.connect((key)=>{
                    backend.set_keymap();
                    update_display();
                    rebuild_menu();
                });
                backend.set_keymap();
                rebuild_menu();
                update_display();
            });
        }
        private void update_display()
        {
            var tooltip = ToolTip();
            tooltip.icon_name = "flag-"+backend.layout_short_name;
            tooltip.title = backend.layout_name;
            tooltip.description = "";
            this.tool_tip = tooltip;
            if (show_flag)
                this.icon_name = tooltip.icon_name;
            else
                this.icon_name = " ";
            if (show_text)
                x_ayatana_new_label(backend.layout_short_name,backend.layout_short_name);
            else
                x_ayatana_new_label("","");
        }
        private void rebuild_menu()
        {
            foreach (var item in layout_items)
                dbusmenu.remove_item(item.id);
            layout_items = new SList<ServerItem>();
            for (var i = 0; i < backend.layouts_count; i++)
            {
                var num = backend.layouts_count - i - 1;
                var item = new ServerItem();
                item.set_variant_property("icon-name",new Variant.string("flag-"+backend.layout_short_names[num]));
                item.set_variant_property("label", new Variant.string(backend.layout_names[num]));
                item.set_variant_property("toggle-type",new Variant.string("radio"));
                if (num == backend.layout_number)
                    item.set_variant_property("toggle-state", new Variant.int32(1));
                else
                    item.set_variant_property("toggle-state", new Variant.int32(0));
                item.activated.connect(()=>{
                    backend.set_layout_group(num);
                });
                dbusmenu.prepend_item(item);
                layout_items.prepend(item);
            }
            dbusmenu.layout_updated(layout_revision++);
        }
        private void update_menu()
        {
            Variant[] items = {};
            var i = 0;
            for(unowned SList<ServerItem> list = layout_items; list != null; list = list.next)
            {
                var item = list.data;
                if (i == backend.layout_number)
                    item.set_variant_property("toggle-state", new Variant.int32(1));
                else
                    item.set_variant_property("toggle-state", new Variant.int32(0));
                var builder = new VariantBuilder(new VariantType("(ia{sv})"));
                builder.add("i",item.id);
                builder.add_value(item.serialize_properties());
                items += builder.end();
                i++;
            }
            var properties = new Variant.array(new VariantType("(ia{sv})"),items);
            items = {};
            var removed = new Variant.array(new VariantType("(ias)"),items);
            dbusmenu.items_properties_updated(properties,removed);
        }
        private Gtk.Dialog create_preferences_dialog()
        {
            var dlg = new XkbPlugin.ConfigDialog(this);
            dlg.icon_name = "preferences-desktop-locale";
            return dlg;
        }
        public override void activate(int x, int y)
        {
            backend.next_layout_group();
        }
        public override void scroll(int delta, string direction)
        {
            if (direction == "vertical")
                if (delta > 0)
                    backend.next_layout_group();
                else
                    backend.prev_layout_group();
        }
        private SList<ServerItem> layout_items;
    }
}
