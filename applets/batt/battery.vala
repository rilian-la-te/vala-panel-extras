using StatusNotifier;
using GLib;
using DBusMenu;

public static int main(string[] args)
{
    Gtk.init(ref args);
    var icon = new BatteryIconExporter();
    var app = new App("battery",icon);
    icon.app = app;
    return app.run(args);
}

[Compact]
private class DeviceData
{
    internal ServerItem item;
    internal UPower.DeviceState prev_state;
    internal UPower.DeviceWarningLevel prev_level;
    public DeviceData(ServerItem item)
    {
        this.item = item;
    }
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
    private static const string PATH = "display-device-path";
    public bool use_notifications {get; internal set;}
    public bool show_percentage {get; internal set;}
    public bool show_time_remaining {get; internal set;}
    public string pm_command {get; internal set;}
    public ObjectPath display_device_path {get; internal set;}
    private void create_status_notification(UPower.Device dev)
    {
        var not = new Notifier.Notification.with_app_id("battery-applet",app.application_id);
        not.app_icon = dev.icon_name[0:dev.icon_name.last_index_of("-symbolic")];
        var hours_empty = dev.time_to_empty/3600;
        var minutes_empty = dev.time_to_empty/60 - hours_empty * 60;
        var hours_full = dev.time_to_full/3600;
        var minutes_full = dev.time_to_full/60 - hours_full * 60;
        switch (dev.state)
        {
            case UPower.DeviceState.DISCHARGING:
                not.title = _("Battery is discharging. %3.0lf%% remaining.").printf(dev.percentage);
                not.body = _("%02lli:%02lli remaining to empty.").printf(hours_empty,minutes_empty);
                break;
            case UPower.DeviceState.CHARGING:
                not.title = _("Battery is charging. %3.0lf%% charged.").printf(dev.percentage);
                not.body = _("%02lli:%02lli remaining to full.").printf(hours_full,minutes_full);
                break;
            case UPower.DeviceState.CHARGED:
                not.title = _("Battery is charged.");
                not.body = _("Battery percentage: %3.0lf%%.").printf(dev.percentage);
                break;
            default:
                not.title = _("Battery percentage: %3.0lf%%.").printf(dev.percentage);
                not.body = "";
                break;
        }
        not.send();
    }
    private void create_warning_notification(UPower.Device dev)
    {
        var not = new Notifier.Notification.with_app_id("battery-applet",app.application_id);
        not.app_icon = dev.icon_name[0:dev.icon_name.last_index_of("-symbolic")];
        switch (dev.warning_level)
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
    private void update_display()
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
                new_status(StatusNotifier.Status.ACTIVE);
                tooltip.title = _("Battery is discharging. %3.0lf%% remaining.").printf(display_device.percentage);
                tooltip.description = _("%02lli:%02lli remaining to empty.").printf(hours_empty,minutes_empty);
                if (show_time_remaining)
                    label += " %02lli:%02lli".printf(hours_empty,minutes_empty);
                break;
            case UPower.DeviceState.CHARGING:
                new_status(StatusNotifier.Status.ACTIVE);
                tooltip.title = _("Battery is charging. %3.0lf%% charged.").printf(display_device.percentage);
                tooltip.description = _("%02lli:%02lli remaining to full.").printf(hours_full,minutes_full);
                if (show_time_remaining)
                    label += " %02lli:%02lli".printf(hours_full,minutes_full);
                break;
            case UPower.DeviceState.CHARGED:
                tooltip.title = _("Battery is charged.");
                tooltip.description = _("Battery percentage: %3.0lf%%.").printf(display_device.percentage);
                new_status(StatusNotifier.Status.PASSIVE);
                break;
            default:
                new_status(StatusNotifier.Status.ACTIVE);
                tooltip.title = _("Battery percentage: %3.0lf%%.").printf(display_device.percentage);
                tooltip.description = "";
                break;
        }
        this.tool_tip = tooltip;
        new_tool_tip();
        new_icon();
        if (show_percentage || show_time_remaining)
            x_ayatana_new_label(label,label);
        else
            x_ayatana_new_label("","");
    }
    private ServerItem? create_device_item(ObjectPath devs)
    {
        UPower.Device? dev = null;
        try {
            dev = Bus.get_proxy_sync(BusType.SYSTEM,UPOWER_NAME,devs);
        } catch (Error e){return null;}
        if (dev.device_type == UPower.DeviceType.LINE_POWER)
            return null;
        var item = new ServerItem();
        item.set_variant_property("label",new Variant.string("%s%s (%s) - %0.0lf%%".printf(dev.vendor,dev.model,dev.device_type.to_string(),dev.percentage)));
        item.set_variant_property("icon-name",new Variant.string(dev.icon_name));
        item.set_variant_property("toggle-type",new Variant.string("radio"));
        if (devs == display_device_path)
            item.set_variant_property("toogle-state",new Variant.int32(1));
        item.activated.connect(()=>{
            settings.set(PATH,"o",devs);
        });
        return item;
    }
    private void create_menu(ObjectPath[] devices)
    {
        var sep = new ServerItem();
        sep.set_variant_property("type",new Variant.string("separator"));
        dbusmenu.prepend_item(sep);
        foreach (var devs in devices)
        {
            var item = create_device_item(devs);
            if (item == null)
                continue;
            var data = new DeviceData(item);
            devices_table.insert(devs,(owned)data);
            dbusmenu.prepend_item(item);
        }
        dbusmenu.layout_updated(layout_revision++,0);
    }
    private void device_removed_cb(ObjectPath device)
    {
        unowned DeviceData data = devices_table.lookup(device);
        if (data.item == null)
            return;
        dbusmenu.remove_item(data.item.id);
        dbusmenu.layout_updated(layout_revision++,0);
        devices_table.remove(device);
    }
    private void device_added_cb(ObjectPath devs)
    {
        var item = create_device_item(devs);
        var data = new DeviceData(item);
        devices_table.insert(devs,(owned)data);
        dbusmenu.prepend_item(item);
        dbusmenu.layout_updated(layout_revision++,0);
    }
    private void on_path_cb()
    {
        try {
            if (!(display_device_path in devices_table))
            {
                ObjectPath dev_path;
                bas.get_display_device(out dev_path);
                display_device_path = dev_path;
            }
            display_device = Bus.get_proxy_sync(BusType.SYSTEM,UPOWER_NAME,display_device_path);
            update_display();
        } catch (Error e) {stderr.printf("%s\n",e.message);}
    }
    private void update_menu_properties()
    {
        HashTableIter<ObjectPath,DeviceData?> iter = HashTableIter<ObjectPath,DeviceData?>(devices_table);
        unowned ObjectPath path;
        unowned DeviceData data;
        Variant[] items = {};
        while(iter.next(out path, out data))
        {
            try {
                unowned ServerItem item = data.item;
                UPower.Device dev = Bus.get_proxy_sync(BusType.SYSTEM,UPOWER_NAME,path);
                item.set_variant_property("label",new Variant.string("%s%s (%s) - %0.0lf%%".printf(dev.vendor,dev.model,dev.device_type.to_string(),dev.percentage)));
                item.set_variant_property("icon-name",new Variant.string(dev.icon_name));
                item.set_variant_property("toggle-type",new Variant.string("radio"));
                if (path == display_device_path)
                    item.set_variant_property("toogle-state",new Variant.int32(1));
                if (data.prev_state != dev.state)
                {
                    data.prev_state = dev.state;
                    if (use_notifications && app.is_registered)
                        create_status_notification(dev);
                }
                if (data.prev_level != dev.warning_level)
                {
                    data.prev_level = dev.warning_level;
                    if (use_notifications && app.is_registered)
                        create_warning_notification(dev);
                }
                var builder = new VariantBuilder(new VariantType("(ia{sv})"));
                builder.add("i",item.id);
                builder.add_value(item.serialize_properties());
                items += builder.end();
            } catch (GLib.Error e){continue;}
        }
        var properties = new Variant.array(new VariantType("(ia{sv})"),items);
        items = {};
        var removed = new Variant.array(new VariantType("(ias)"),items);
        dbusmenu.items_properties_updated(properties,removed);
    }
    private bool update_function()
    {
        try {
            display_device.refresh();
        }
        catch (Error e) {
            stderr.printf("%s\n",e.message);
        }
        update_display();
        update_menu_properties();
        return true;
    }
    private Gtk.Dialog create_preferences_dialog()
    {
        var dlg = Configurator.generic_config_dlg(_("Vala Panel Battery Applet"),
                                                    this.settings,
                                                    _("Use notifications"), NOTIFY, GenericConfigType.BOOL,
                                                    _("Show percentage"), PERCENT, GenericConfigType.BOOL,
                                                    _("Show time remaining"), TIME, GenericConfigType.BOOL,
                                                    _("Power manager command"), COMMAND, GenericConfigType.STR,
                                                    _("Display device path"), PATH, GenericConfigType.STR);
        dlg.icon_name = "battery";
        return dlg;
    }
    public BatteryIconExporter()
    {
        this.id = "vala-panel-extras-battery";
        this.title = _("Battery Applet");
        this.category = Category.HARDWARE;
        this.notify["app"].connect(()=>{
            app.about.logo_icon_name = "battery";
            app.about.icon_name = "battery";
            app.about.program_name = _("Vala Panel Battery Applet");
            app.about.comments = _("Simple UPower based battery indicator.");
            this.settings = new GLib.Settings(app.application_id);
            this.settings.bind(NOTIFY, this, NOTIFY, SettingsBindFlags.GET);
            this.settings.bind(PERCENT, this, PERCENT, SettingsBindFlags.GET);
            this.settings.bind(TIME, this, TIME, SettingsBindFlags.GET);
            this.settings.bind(COMMAND, this, COMMAND, SettingsBindFlags.GET);
            this.settings.bind(PATH, this, PATH, SettingsBindFlags.GET);
            app.preferences = create_preferences_dialog;
            devices_table = new HashTable<ObjectPath,DeviceData?> (str_hash,str_equal);
            try {
                bas = Bus.get_proxy_sync(BusType.SYSTEM,UPOWER_NAME,UPOWER_PATH);
                ObjectPath[] devices;
                bas.enumerate_devices(out devices);
                on_path_cb();
                create_menu(devices);
                update_display();
                settings.changed[PATH].connect(on_path_cb);
                bas.device_added.connect(device_added_cb);
                bas.device_removed.connect(device_removed_cb);
                Timeout.add(500,update_function);
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
    private UPower.Device display_device;
    private UPower.DeviceWarningLevel prev_level;
    private UPower.DeviceState prev_state;
    private UPower.Base bas;
    private HashTable<ObjectPath,DeviceData?> devices_table;
}
