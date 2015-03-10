using StatusNotifier;
using GLib;

public static int main(string[] args)
{
    Gtk.init(ref args);
    var icon = new BatteryIconExporter();
    var app = new App("battery",icon);
    icon.app = app;
    return app.run(args);
}

[DBus (name = "org.kde.StatusNotifierItem")]
public class BatteryIconExporter : ItemExporter
{
    private static const string UPOWER_PATH = "/org/freedesktop/UPower";
    private static const string UPOWER_NAME = "org.freedesktop.UPower";
    private static const string NOTIFY = "use-notifications";
    private static const string PERCENT = "show-percentage";
    private static const string TIME = "show-time-remaining";
    private static const string COMMAND = "pm-command";
    public bool use_notifications {get; internal set;}
    public bool show_percentage {get; internal set;}
    public bool show_time_remaining {get; internal set;}
    public string pm_command {get; internal set;}
    void update_display()
    {
        var icon_name = display_device.icon_name[0:display_device.icon_name.last_index_of("-symbolic")];
        var tooltip = ToolTip();
        this.icon_name = icon_name;
        tooltip.icon_name = icon_name;
        var label = "";
        var hours_empty = display_device.time_to_empty/3600;
        var minutes_empty = display_device.time_to_empty/60 - hours_empty * 60;
        var hours_full = display_device.time_to_full/3600;
        var minutes_full = display_device.time_to_full/60 - hours_full * 60;
        if (show_percentage)
            label += " %3.0lf%%".printf(display_device.percentage);
        switch (display_device.state)
        {
            case UPower.DeviceState.DISCHARGING:
                new_status(Status.ACTIVE);
                tooltip.title = _("Battery is discharging. %3.0lf%% remaining.").printf(display_device.percentage);
                tooltip.description = _("%02lli:%02lli remaining to empty.").printf(hours_empty,minutes_empty);
                if (show_time_remaining)
                    label += " %02lli:%02lli".printf(hours_empty,minutes_empty);
                break;
            case UPower.DeviceState.CHARGING:
                new_status(Status.ACTIVE);
                tooltip.title = _("Battery is charging. %3.0lf%% charged.").printf(display_device.percentage);
                tooltip.description = _("%02lli:%02lli remaining to full.").printf(hours_full,minutes_full);
                if (show_time_remaining)
                    label += " %02lli:%02lli".printf(hours_full,minutes_full);
                break;
            case UPower.DeviceState.CHARGED:
                tooltip.title = _("Battery is charged.");
                tooltip.description = _("Battery percentage: %3.0lf%%.").printf(display_device.percentage);
                new_status(Status.PASSIVE);
                break;
            default:
                new_status(Status.ACTIVE);
                tooltip.title = _("Battery percentage: %3.0lf%%.").printf(display_device.percentage);
                tooltip.description = "";
                break;
        }
        if (prev_state != display_device.state)
        {
            prev_state = display_device.state;
            if (use_notifications && app.is_registered)
            {
                not.app_icon = icon_name;
                switch (display_device.state)
                {
                    case UPower.DeviceState.DISCHARGING:
                        new_status(Status.ACTIVE);
                        not.title = _("Battery is discharging. %3.0lf%% remaining.").printf(display_device.percentage);
                        not.body = _("%02lli:%02lli remaining to empty.").printf(hours_empty,minutes_empty);
                        break;
                    case UPower.DeviceState.CHARGING:
                        new_status(Status.ACTIVE);
                        not.title = _("Battery is charging. %3.0lf%% charged.").printf(display_device.percentage);
                        not.body = _("%02lli:%02lli remaining to full.").printf(hours_full,minutes_full);
                        break;
                    case UPower.DeviceState.CHARGED:
                        not.title = _("Battery is charged.");
                        not.body = _("Battery percentage: %3.0lf%%.").printf(display_device.percentage);
                        new_status(Status.PASSIVE);
                        break;
                    default:
                        new_status(Status.ACTIVE);
                        not.title = _("Battery percentage: %3.0lf%%.").printf(display_device.percentage);
                        not.body = "";
                        break;
                }
                not.send();
            }
        }
        if (prev_level != display_device.warning_level)
        {
            prev_level = display_device.warning_level;
            if (use_notifications && app.is_registered)
            {
                not.app_icon = icon_name;
                switch (display_device.warning_level)
                {
                    case UPower.DeviceWarningLevel.LOW:
                        not.body = _("Battery is low!");
                        break;
                    case UPower.DeviceWarningLevel.CRITICAL:
                        not.body = _("Battery is very low!");
                        not.priority = Notifier.Priority.HIGH;
                        break;
                    case UPower.DeviceWarningLevel.ACTION:
                        not.body = _("Battery is critical!");
                        not.priority = Notifier.Priority.URGENT;
                        break;
                }
                not.send();
            }
        }
        this.tool_tip = tooltip;
        new_tool_tip();
        new_icon();
        if (show_percentage || show_time_remaining)
            x_ayatana_new_label(label,label);
        else
            x_ayatana_new_label("","");
    }
    private Gtk.Dialog create_preferences_dialog()
    {
        var dlg = Configurator.generic_config_dlg(_("Vala Panel Battery Applet"),
                                                    this.settings,
                                                    _("Use notifications"), NOTIFY, GenericConfigType.BOOL,
                                                    _("Show percentage"), PERCENT, GenericConfigType.BOOL,
                                                    _("Show time remaining"), TIME, GenericConfigType.BOOL,
                                                    _("Power manager command"), COMMAND, GenericConfigType.STR);
        dlg.icon_name = "battery";
        return dlg;
    }
    public BatteryIconExporter()
    {
        this.id = "vala-panel-extras-battery";
        this.title = _("Battery Applet");
        this.category = Category.HARDWARE;
        this.notify["app"].connect(()=>{
            not = new Notifier.Notification.with_app_id("battery-applet",app.application_id);
            app.about.logo_icon_name = "battery";
            app.about.icon_name = "battery";
            app.about.program_name = _("Vala Panel Battery Applet");
            app.about.comments = _("Simple UPower based battery indicator.");
            this.settings = new GLib.Settings(app.application_id);
            this.settings.bind(NOTIFY, this, NOTIFY, SettingsBindFlags.GET);
            this.settings.bind(PERCENT, this, PERCENT, SettingsBindFlags.GET);
            this.settings.bind(TIME, this, TIME, SettingsBindFlags.GET);
            this.settings.bind(COMMAND, this, COMMAND, SettingsBindFlags.GET);
            app.preferences = create_preferences_dialog;
            try {
                UPower.Base bas = Bus.get_proxy_sync(BusType.SYSTEM,UPOWER_NAME,UPOWER_PATH);
                ObjectPath display_device_path;
                bas.get_display_device(out display_device_path);
                display_device = Bus.get_proxy_sync(BusType.SYSTEM,UPOWER_NAME,display_device_path);
                update_display();
                Timeout.add(500,()=>{
                    try {
                        display_device.refresh();
                    }
                    catch (Error e) {
                        stderr.printf("%s\n",e.message);
                    }
                    update_display();
                    return true;
                });
            } catch (Error e) {stderr.printf("%s\n",e.message); app.quit();}
        });
    }
    public override void activate(int x, int y)
    {
        try {
            GLib.AppInfo info = AppInfo.create_from_commandline(pm_command,null,
                                AppInfoCreateFlags.SUPPORTS_STARTUP_NOTIFICATION);
            info.launch(null,Gdk.Display.get_default().get_app_launch_context());
        } catch (GLib.Error e){stderr.printf("%s\n",e.message);}
    }
    private Notifier.Notification not;
    private UPower.Device display_device;
    private UPower.DeviceWarningLevel prev_level;
    private UPower.DeviceState prev_state;
}
