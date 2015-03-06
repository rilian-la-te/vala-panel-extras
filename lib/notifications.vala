using GLib;

namespace Notifier
{
    public const string OBJECT_PATH = "/org/freedesktop/Notifications";
    public const string BUS_NAME = "org.freedesktop.Notifications";
    [CCode (type_signature = "u")]
    public enum CloseReason
    {
        EXPIRED = 1,
        DISMISSED = 2,
        METHOD = 3,
        UNDEFINED = 4
    }
    [DBus (name = "org.freedesktop.Notifications")]
    public interface Daemon : Object
    {
        public abstract string[] get_capabilites() throws Error;
        public abstract void get_server_information(out string name, out string vendor,
                                                    out string version, out string specv) throws Error;
        public abstract Quark notify(string app_name,
                                    Quark id,
                                    string app_icon,
                                    string title,
                                    string body,
                                    string[] actions,
                                    HashTable<string, Variant?> hints,
                                    int expire_timeout) throws Error;
        public abstract Quark close_notification(Quark id) throws Error;
        public abstract signal void action_invoked(Quark id, string action_name);
        public abstract signal void notification_closed(Quark id, CloseReason reason);
    }
    public Daemon? get_daemon()
    {
        try
        {
            return Bus.get_proxy_sync(BusType.SESSION, BUS_NAME, OBJECT_PATH);
        } catch (Error e) {stderr.printf("%s\n",e.message);}
        return null;
    }
    public enum Priority
    {
        NORMAL = 0,
        HIGH = 1,
        URGENT = 2
    }
    public class Notification : Object
    {
        private Daemon daemon;
        private HashTable<string,Variant?> hints;
        private Quark dbus_id;
        private string[] actions;
        public signal void action_invoked(string action_name);
        public string id {
            set {dbus_id = Quark.from_string(value);}
        }
        public string app_name {get; private set; default = "";}
        public string app_icon {get; set; default = "";}
        public string title {get; set; default = "";}
        public string body {get; set; default = "";}
        public int expire_timeout {get; set; default = -1;}
        public string desktop_entry {
            get {return hints.lookup("desktop-entry").get_string();}
            set {hints.insert("desktop-entry",new Variant.string(value));}
        }
        public string image_path {
            get {return hints.lookup("image-path").get_string();}
            set {hints.insert("image-path",new Variant.string(value));
                hints.insert("image_path",new Variant.string(value));}
        }
        public bool transient {
            get {return hints.lookup("transient").get_boolean();}
            set {hints.insert("transient",new Variant.boolean(value));}
        }
        public bool icon_only {
            get {return hints.lookup("x-canonical-private-icon-only").get_boolean();}
            set {hints.insert("x-canonical-private-icon-only",new Variant.boolean(value));}
        }
        public int val {
            get {return hints.lookup("value").get_int32();}
            set {hints.insert("value",new Variant.int32(value));}
        }
        public bool action_icons {
            get {return hints.lookup("action-icons").get_boolean();}
            set {hints.insert("action-icons",new Variant.boolean(value));}
        }
        public bool resident {
            get {return hints.lookup("resident").get_boolean();}
            set {hints.insert("resident",new Variant.boolean(value));}
        }
        public string category  {
            get {return hints.lookup("category").get_string();}
            set {hints.insert("category",new Variant.string(value));}
        }
        public string sound_name  {
            get {return hints.lookup("sound-name").get_string();}
            set {hints.insert("sound-name",new Variant.string(value));}
        }
        public Priority priority  {
            get {return (Priority)hints.lookup("urgency").get_byte();}
            set {hints.insert("urgency",new Variant.byte((uint8)value));}
        }
        construct
        {
            hints = new HashTable<string, Variant?> (str_hash, str_equal);
            this.transient = true;
            this.actions = {};
            daemon = get_daemon();
            daemon.action_invoked.connect((id,name)=>{
                if (id == dbus_id)
                    action_invoked(name);
            });
        }
        public Notification.with_app_id (string id, string application_id)
        {
            this(id);
            this.app_name = application_id;
        }
        public Notification (string id)
        {
            this.id = id;
        }
        public Notification.temporary()
        {
            this.dbus_id = 0;
        }
        public void send()
        {
            try
            {
                dbus_id = daemon.notify(app_name,dbus_id,app_icon,title,body,actions,hints,expire_timeout);
            } catch (Error e) {stderr.printf("%s\n",e.message);}
        }
        public void close ()
        {
            try
            {
                dbus_id = daemon.close_notification(dbus_id);
            } catch (Error e) {stderr.printf("%s\n",e.message);}
        }
        public void add_action(string id, string description)
        {
            actions += id;
            actions += description;
        }
        public void clear_all_hints()
        {
            hints.remove_all();
        }
        public void add_hint (string name, Variant val)
        {
            hints.insert(name,val);
        }
        public void remove_hint(string name)
        {
            hints.remove(name);
        }
        public void clear_actions()
        {
            actions = {};
        }
    }
}
