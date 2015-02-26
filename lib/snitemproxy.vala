using GLib;
using Gtk;

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
        public string icon_name {get; protected set;}
        public string icon_accessible_desc {get; protected set;}
        public string overlay_icon_name {get; protected set;}
        public string attention_icon_name {get; protected set;}
        public string attention_accessible_desc {get; protected set;}
        /* Tooltip */
        public ToolTip tool_tip {get; protected set;}
        /* Methods */
        public virtual void context_menu(int x, int y) {}
        public virtual void activate(int x, int y) {}
        public virtual void secondary_activate(int x, int y) {}
        public virtual void scroll(int delta, string orientation) {}
        public void x_ayatana_secondary_activate(uint32 timestamp)
        {
            activate(0,0);
        }
        /* Signals */
        public signal void new_title();
        public signal void new_icon();
        public signal void new_icon_theme_path(string icon_theme_path);
        public signal void new_attention_icon();
        public signal void new_overlay_icon();
        public signal void new_tool_tip();
        public signal void new_status(Status status);
        /* Ayatana */
        public string x_ayatana_label {get; protected set;}
        public string x_ayatana_label_guide {get; protected set;}
        public uint x_ayatana_ordering_index {get; protected set;}
        public signal void x_ayatana_new_label(string label, string guide);
        protected ItemExporter() {}
    }
}
