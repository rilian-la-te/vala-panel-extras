using StatusNotifier;
using DBusMenu;
using GLib;

namespace StatusNotifier
{
    public class App: Gtk.Application
    {
        private static const string NAME = "options";
        private static const string PATH = "/org/vala-panel/";
        private static const GLib.ActionEntry[] app_entries =
        {
            {"preferences", activate_preferences, null, null, null},
            {"about", activate_about, null, null, null},
            {"quit", activate_exit, null, null, null},
        };
        public ItemExporter icon
        {get; construct;}
        public Gtk.Dialog? preferences
        {get; set construct;}
        public Gtk.AboutDialog? about
        {get; private set;}
        public string profile
        {get; internal set construct; default = "default";}
        WatcherIface watcher;
        uint watched_name;
        public App.with_preferences(string name, ItemExporter icon, Gtk.Dialog preferences)
        {
            Object(application_id: "org.valapanel."+name,
                    flags: GLib.ApplicationFlags.IS_SERVICE | GLib.ApplicationFlags.HANDLES_COMMAND_LINE,
                    icon: icon,
                    preferences: preferences,
                    resource_base_path: "/org/vala-panel/"+name);
        }
        public App(string name, ItemExporter icon)
        {
            Object(application_id: "org.valapanel."+name,
                    flags: GLib.ApplicationFlags.IS_SERVICE | GLib.ApplicationFlags.HANDLES_COMMAND_LINE,
                    icon: icon,
                    resource_base_path: "/org/vala-panel/"+name);
        }
        construct
        {
            about = create_about_dialog();
        }
        protected override void startup()
        {
            base.startup();
            GLib.Intl.setlocale(LocaleCategory.CTYPE,"");
            GLib.Intl.bindtextdomain(Config.GETTEXT_PACKAGE,Config.LOCALE_DIR);
            GLib.Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE,"UTF-8");
            GLib.Intl.textdomain(Config.GETTEXT_PACKAGE);
            add_action_entries(app_entries,this);
            this.hold();
            try
            {
                watcher = Bus.get_proxy_sync(BusType.SESSION,"org.kde.StatusNotifierWatcher","/StatusNotifierWatcher");
            } catch (Error e){stderr.printf("%s\n",e.message);}
            watched_name = Bus.watch_name(BusType.SESSION,"org.kde.StatusNotifierWatcher",GLib.BusNameWatcherFlags.NONE,
                                                    () => {
                                                            try {
                                                                watcher.register_status_notifier_item(this.application_id);
                                                            } catch (Error e){}
                                                        },
                                                    () => {}
                                                    );
        }
        protected override bool dbus_register (DBusConnection connection, string object_path) throws Error
        {
            // We must chain up to the parent class:
            var base_register = base.dbus_register (connection, object_path);
            // Now we can do our own stuff here. For example, we could export some D-Bus objects
            connection.register_object ("/StatusNotifierItem", icon);
            connection.register_object ("/MenuBar", icon.dbusmenu);
            return base_register;
        }
        protected override void shutdown()
        {
            Bus.unwatch_name(watched_name);
            base.shutdown();
        }
        protected void activate_preferences(SimpleAction action, Variant? param)
        {
            if (preferences != null && !preferences.visible)
            {
                preferences.window_position = Gtk.WindowPosition.CENTER;
                preferences.response.connect((id)=>{preferences.hide();});
                preferences.present();
            }
        }
        protected void activate_about(SimpleAction action, Variant? param)
        {
            if (about != null && !about.visible)
            {
                about.window_position = Gtk.WindowPosition.CENTER;
                about.response.connect((id)=>{about.hide();});
                about.present();
            }
        }
        protected void activate_exit(SimpleAction action, Variant? param)
        {
            this.quit();
        }
        protected override int handle_local_options(VariantDict opts)
        {
            if (opts.contains("version"))
            {
                stdout.printf(_("%s - Version %s\n"),GLib.Environment.get_application_name(),
                                                    Config.VERSION);
                return 0;
            }
            return -1;
        }
        protected override int command_line(ApplicationCommandLine cmdl)
        {
            string? profile_name;
            var options = cmdl.get_options_dict();
            if (options.lookup("profile","s",out profile_name))
                profile = profile_name;
            activate();
            return 0;
        }
        public override void activate()
        {
            if (!started)
            {
                var dirs = GLib.Environment.get_system_config_dirs();
                var loaded = false;
                string? file = null;
                string? user_file = null;
                foreach (var dir in dirs)
                {
                    file = GLib.Path.build_filename(dir,application_id,profile);
                    if (GLib.FileUtils.test(file,FileTest.EXISTS))
                    {
                        loaded = true;
                        break;
                    }
                }
                user_file = GLib.Path.build_filename(GLib.Environment.get_user_config_dir(),application_id,profile);
                if (!GLib.FileUtils.test(user_file,FileTest.EXISTS) && loaded)
                {
                    var src = File.new_for_path(file);
                    var dest = File.new_for_path(user_file);
                    try{src.copy(dest,FileCopyFlags.BACKUP,null,null);}
                    catch(Error e){warning("Cannot init config: %s\n",e.message);}
                }
                var config_backend = GLib.keyfile_settings_backend_new(user_file,PATH,NAME);
                icon.settings = new GLib.Settings.with_backend_and_path(application_id,config_backend,PATH);
                started = true;
            }
        }
        private Gtk.AboutDialog create_about_dialog()
        {
            var about = new Gtk.AboutDialog();
            about.logo_icon_name = "libpeas-plugin";
            about.icon_name = "libpeas-plugin";
            about.program_name = _("Vala Panel Extras");
            about.comments = _("Status Notifier Items for Vala Panel");
            about.website = "https://vala-panel.github.io";
            about.website_label = _("Vala Panel Website");
            about.authors = {"LXDE team http://lxde.org","Konstantin Pugin <ria.freelander@gmail.com>"};
            about.translator_credits = _("Replace this string by your names, one name per line.");
            about.license_type = Gtk.License.LGPL_3_0;
            about.version = Config.VERSION;
            return about;
        }
        private bool started = false;
    }
}
