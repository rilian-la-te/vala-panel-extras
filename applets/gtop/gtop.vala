using StatusNotifier;
using GLib;
using GTop;
using DBusMenu;

public static int main(string[] args)
{
    Gtk.init(ref args);
    var icon = new NetloadIconExporter();
    var app = new App("gtop",icon);
    icon.app = app;
    return app.run(args);
}

[DBus (name = "org.kde.StatusNotifierItem")]
public class NetloadIconExporter : ItemExporter
{
    private static const string IFACE = "network-interface";
    public string network_interface {get; internal set;}
    public bool reload {get; internal set;}
    private uint64 bytes_in_old;
    private uint64 bytes_out_old;
    private bool first_run;
    private string[] interfaces;
    private ServerItem[] ifaces;
    private ServerItem ifaces_parent;
    private ServerItem up_item;
    private ServerItem down_item;
    private ServerItem all_item;
    private int period = 1;
    private void set_invalid_icon()
    {
        this.icon_name = "dialog-error";
        var tooltip = ToolTip();
        tooltip.icon_name = "dialog-error";
        tooltip.title = _("No network connection");
        tooltip.description = _("or no location.");
        this.tool_tip = tooltip;
    }
    void update_display()
    {
        //get sum of up and down net traffic and separate values
        //and refresh labels of current interface
        uint64[] net_traffic = {0, 0};
        get_net(ref net_traffic);
        uint64 net_down = net_traffic[0];
        uint64 net_up = net_traffic[1];
        uint64 net_total = net_down + net_up;
        string indicator_label = format_net_label(net_total, true);
        string label_guide = "10000.00 MiB/s";   //maximum length label text, doesn't really work atm
        x_ayatana_new_label(indicator_label, label_guide);
        string net_down_label = format_net_label(net_down, false);
        down_item.set_variant_property("label",new Variant.string(net_down_label));
        string net_up_label = format_net_label(net_up, false);
        up_item.set_variant_property("label",new Variant.string(net_up_label));
        string icon_name = "network-idle";
        if (net_down != 0 && net_up != 0)
            icon_name = "network-transmit-receive";
        else if (net_down != 0)
            icon_name = "network-receive";
        else if (net_up != 0)
            icon_name = "network-transmit";
        var tooltip = ToolTip();
        this.icon_name = icon_name;
        tooltip.icon_name = icon_name;
        tooltip.title = _("Network Statistics");
        tooltip.description = _("Up: %s\nDown: %s").printf(net_up_label,net_down_label);
        this.tool_tip = tooltip;
        update_main_menu_properties();
    }
    private Gtk.Dialog create_preferences_dialog()
    {
        var dlg = Configurator.generic_config_dlg(_("Vala Panel Netload Applet"),
                                                    this.settings,
                                                    _("Select network interface"), IFACE, GenericConfigType.STR,
                                                    _("Reload network interfaces"), "reload", GenericConfigType.BOOL);
        dlg.icon_name = "network-wired";
        return dlg;
    }
    private string format_net_label(uint64 data, bool padding)
    {
        string str;
        /*if(data < 1000)
        {
            string = g_strdup_printf("%d B/s", data);
        }
        else*/ if(data < 1000000)  //should be < 1 MiB and not 1 MB, but this keeps width smaller
            str = "%.1lf KiB/s".printf(data/1024.0);
        else
            str = "%.2lf MiB/s".printf(data/1048576.0);
    //will someone have 1 gb/s ? maybe...
//~         if(padding)
//~         {
//~             //render string and get its pixel width
//~             int width = 0;
//~             int maxWidth = 12;   //max width for label in pixels
//~             //TODO: should be determined from current panel font type and size
//~             int spaceWidth = 4;  //width of one space char in pixels,
//~             Pango.Context context = this.get_pango_context();
//~             Pango.Layout layout = new Pango.Layout(context);
//~             layout.set_text(str);
//~             layout.get_pixel_size(out width, null);
//~             // frees the layout object, do not use after this point
//~             //push max size up as needed
//~             if (width > maxWidth) maxWidth = width + spaceWidth;
//~             //fill up with spaces
//~             str = "%*s%s".printf((int)((maxWidth-width)/spaceWidth), " ", str);
//~         }
        return str;
    }

    private void get_net(ref uint64[] traffic)
    {
        glibtop_netload netload;
        glibtop_netlist netlist;
        uint64 bytes_in = 0;
        uint64 bytes_out = 0;
        interfaces = glibtop_get_netlist(out netlist);
        for(var i = 0; i < netlist.number; i++)
        {
            if (strcmp("lo", interfaces[i]) == 0)
                continue;
            if("all" == network_interface || network_interface == interfaces[i])
            {
                glibtop_get_netload(out netload, interfaces[i]);
                bytes_in += netload.bytes_in;
                bytes_out += netload.bytes_out;
            }
        }
        if(first_run)
        {
            bytes_in_old = bytes_in;
            bytes_out_old = bytes_out;
            first_run = false;
        }
        traffic[0] = (bytes_in - bytes_in_old) / period;
        traffic[1] = (bytes_out - bytes_out_old) / period;
        bytes_in_old = bytes_in;
        bytes_out_old = bytes_out;
    }
    private void update_main_menu_properties()
    {
        /*Return all properties instead of requested*/
        Variant[] items = {};
        var builder = new VariantBuilder(new VariantType("(ia{sv})"));
        builder.add("i",up_item.id);
        builder.add_value(up_item.serialize_properties());
        items += builder.end();
        builder = new VariantBuilder(new VariantType("(ia{sv})"));
        builder.add("i",down_item.id);
        builder.add_value(down_item.serialize_properties());
        items += builder.end();
        var properties = new Variant.array(new VariantType("(ia{sv})"),items);
        items = {};
        var removed = new Variant.array(new VariantType("(ias)"),items);
        dbusmenu.items_properties_updated(properties,removed);
    }
    private void if_signal_select(string name)
    {
        network_interface = name;
    }
    private void update_ifaces()
    {
        /*Return all properties instead of requested*/
        Variant[] items = {};
        foreach(var item in ifaces)
        {
            var builder = new VariantBuilder(new VariantType("(ia{sv})"));
            builder.add("i",item.id);
            builder.add_value(item.serialize_properties());
            items += builder.end();
        }
        var properties = new Variant.array(new VariantType("(ia{sv})"),items);
        items = {};
        var removed = new Variant.array(new VariantType("(ias)"),items);
        dbusmenu.items_properties_updated(properties,removed);
    }
    private void add_netifs() {
        //populate list of interfaces
        //TODO: make this refresh when interfaces change
        glibtop_netlist netlist;
        interfaces = glibtop_get_netlist(out netlist);
        foreach(var item in ifaces)
            dbusmenu.remove_item(item.id);
        ifaces = new ServerItem[netlist.number];
        for(int i = 0; i < netlist.number; i++)
        {
            if (strcmp("lo", interfaces[i]) == 0)
                continue;
            ifaces[i] = new ServerItem();
            ifaces[i].set_variant_property("label",new Variant.string(interfaces[i]));
            ifaces[i].set_variant_property("toggle-type","radio");
            ifaces[i].set_variant_property("toggle-state",new Variant.int32((int)(interfaces[i] == network_interface)));
            ifaces[i].activated.connect(()=>{
                if_signal_select(interfaces[i]);
            });
            dbusmenu.append_item(ifaces[i],ifaces_parent.id);
        }
        all_item = new ServerItem();
        all_item.set_variant_property("label",new Variant.string(_("All")));
        all_item.set_variant_property("toggle-type","radio");
        all_item.set_variant_property("toggle-state",new Variant.int32((int)("all" == network_interface)));
        dbusmenu.append_item(all_item,ifaces_parent.id);
        all_item.activated.connect(()=>{
            if_signal_select("all");
        });
        dbusmenu.layout_updated(layout_revision++,0);
    }
    public NetloadIconExporter()
    {
        this.id = "vala-panel-extras-gtop";
        this.title = _("Netload Applet");
        this.category = Category.HARDWARE;
        set_invalid_icon();
        var sep = new ServerItem();
        sep.set_variant_property("type",new Variant.string("separator"));
        dbusmenu.prepend_item(sep);
        ifaces_parent = new ServerItem();
        ifaces_parent.set_variant_property("label",new Variant.string(_("Interfaces")));
        ifaces_parent.set_variant_property("children-display",new Variant.string("submenu"));
        dbusmenu.prepend_item(ifaces_parent);
        sep = new ServerItem();
        sep.set_variant_property("type",new Variant.string("separator"));
        dbusmenu.prepend_item(sep);
        down_item = new ServerItem();
        down_item.set_variant_property("label",new Variant.string(_("Down")));
        down_item.set_variant_property("icon-name",new Variant.string("network-receive-symbolic"));
        dbusmenu.prepend_item(down_item);
        up_item = new ServerItem();
        up_item.set_variant_property("label",new Variant.string(_("Up")));
        up_item.set_variant_property("icon-name",new Variant.string("network-transmit-symbolic"));
        dbusmenu.prepend_item(up_item);
        this.notify["app"].connect(()=>{
            app.about.logo_icon_name = "network-wired";
            app.about.icon_name = "network-wired";
            app.about.program_name = _("Vala Panel Netload Applet");
            app.about.comments = _("Simple LibGTop based network indicator.");
            this.settings = new GLib.Settings(app.application_id);
            this.settings.bind(IFACE, this, IFACE, SettingsBindFlags.GET);
            app.preferences = create_preferences_dialog;
            add_netifs();
            update_display();
            this.notify[IFACE].connect(()=>{
                for(var i = 0; i< ifaces.length; i++)
                    ifaces[i].set_variant_property("toggle-state",new Variant.int32((int)(network_interface == interfaces[i])));
                all_item.set_variant_property("toggle-state",new Variant.int32((int)(network_interface == "all")));
                first_run = true;
                update_display();
                update_ifaces();
            });
            this.notify["reload"].connect(()=>{
                if (reload)
                    add_netifs();
                settings.set_boolean("reload",false);
            });
            Timeout.add_seconds(period,()=>{
                update_display();
                return Source.CONTINUE;
            });
        });
    }
}
