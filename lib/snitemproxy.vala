using GLib;

namespace StatusNotifier
{
    [DBus (use_string_marshalling = true)]
    public enum Category
    {
        [DBus (value = "ApplicationStatus")]
        APPLICATION,
        [DBus (value = "Communications")]
        COMMUNICATIONS,
        [DBus (value = "SystemServices")]
        SYSTEM,
        [DBus (value = "Hardware")]
        HARDWARE
    }

    [DBus (use_string_marshalling = true)]
    public enum Status
    {
        [DBus (value = "Passive")]
        PASSIVE,
        [DBus (value = "Active")]
        ACTIVE,
        [DBus (value = "NeedsAttention")]
        NEEDS_ATTENTION
    }
    public struct IconPixmap
    {
        int width;
        int height;
        uint8[] bytes;
    }

    public struct ToolTip
    {
        string icon_name;
        IconPixmap[] pixmap;
        string title;
        string description;
    }
    [DBus (name = "org.kde.StatusNotifierItem")]
    public abstract class ItemExporter : Object
    {
        [DBus (visible = false)]
        public DBusMenu.Serializer dbusmenu
        {get; private set;}
        [DBus (visible = false)]
        public App app
        {get; set;}
        [DBus (visible = false)]
        public Settings settings
        {get; set;}
        /* Base properties */
        public Category category {get; protected set;}
        public string id {get; protected set;}
        public Status status {get; protected set;}
        public string title {get; protected set;}
        public int window_id {get; protected set;}
        /* Menu properties */
        public ObjectPath menu {get; protected set;}
        public bool items_in_menu {get; protected set;}
        /* Icon properties */
        public string icon_name {get; protected set; default = "";}
        public string icon_accessible_desc {get; protected set; default = "";}
        public string overlay_icon_name {get; protected set; default = "";}
        public string attention_icon_name {get; protected set; default = "";}
        public string attention_accessible_desc {get; protected set; default = "";}
        /* Tooltip */
        public ToolTip tool_tip {get; protected set;}
        /* Methods */
        public virtual void context_menu(int x, int y) {}
        public virtual void activate(int x, int y) {}
        public virtual void secondary_activate(int x, int y) {}
        public virtual void scroll(int delta, string orientation) {}
        public void x_ayatana_secondary_activate(uint32 timestamp)
        {
            secondary_activate(0,0);
        }
        /* Signals */
        public signal void new_title();
        public signal void new_icon();
        public signal void new_icon_theme_path(string icon_theme_path);
        public signal void new_attention_icon();
        public signal void new_overlay_icon();
        public signal void new_tool_tip();
        public virtual signal void new_status(Status status)
        {
            this.status = status;
        }
        /* Ayatana */
        public string x_ayatana_label {get; protected set; default = "";}
        public string x_ayatana_label_guide {get; protected set; default = "";}
        public uint x_ayatana_ordering_index {get; protected set;}
        public virtual signal void x_ayatana_new_label(string label, string guide)
        {
            this.x_ayatana_label = label;
            this.x_ayatana_label_guide = guide;
        }
        protected ItemExporter()
        {
            menu = new ObjectPath("/MenuBar");
            dbusmenu = new DBusMenu.Serializer();
            this.notify.connect((pspec)=>{
                if (pspec.name == "tool-tip")
                    new_tool_tip();
                if (pspec.name == "title")
                    new_title();
                if (pspec.name == "icon-name")
                    new_icon();
                if (pspec.name == "attention-icon-name")
                    new_attention_icon();
                if (pspec.name == "overlay-icon-name")
                    new_overlay_icon();
                if (pspec.name == "x-ayatana-label" || pspec.name == "x-ayatana-label-guide")
                    x_ayatana_new_label(this.x_ayatana_label,this.x_ayatana_label_guide);
            });
            preferences = new DBusMenu.ServerItem();
            preferences.set_variant_property("label",new Variant.string("_Preferences..."));
            preferences.set_variant_property("icon-name","preferences-system");
            preferences.activated.connect(()=>{app.activate_action("preferences",null);});
            about = new DBusMenu.ServerItem();
            about.set_variant_property("label",new Variant.string("_About..."));
            about.set_variant_property("icon-name","help-about");
            about.activated.connect(()=>{app.activate_action("about",null);});
            quit = new DBusMenu.ServerItem();
            quit.set_variant_property("label",new Variant.string("_Quit"));
            quit.set_variant_property("icon-name","application-exit");
            quit.activated.connect(()=>{app.activate_action("quit",null);});
            dbusmenu.append_item(preferences);
            dbusmenu.append_item(about);
            dbusmenu.append_item(quit);
            dbusmenu.layout_updated(layout_revision++,0);
        }
        protected uint layout_revision;
        protected DBusMenu.ServerItem preferences;
        protected DBusMenu.ServerItem about;
        protected DBusMenu.ServerItem quit;
    }
}
