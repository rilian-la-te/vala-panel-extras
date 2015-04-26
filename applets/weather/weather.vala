using StatusNotifier;
using DBusMenu;
using GLib;

namespace Weather
{
    public static int main(string[] args)
    {
        Gtk.init(ref args);
        var icon = new WeatherIconExporter();
        var app = new App("weather",icon);
        icon.app = app;
        return app.run(args);
    }

    [DBus (name = "org.kde.StatusNotifierItem")]
    public class WeatherIconExporter : ItemExporter
    {
        internal static const string LOCATIONS = "locations";
        internal static const string CURRENT_LOC = "current-location";
        internal static const string UPDATE = "update-interval";
        internal static const string SHOW_LABEL = "show-temperature";
        private uint update_source;
        internal GWeather.Location[] locations {get; set;}
        internal bool show_temperature {get; set;}
        internal uint current_location {get; set;}
        internal GWeather.Info info {get; private set;}
        internal ForecastDialog forecast_dlg {get; set;}
        private ServerItem[] location_items;
        private ServerItem temp_item;
        private ServerItem sunrise_item;
        private ServerItem sunset_item;
        private ServerItem humidity_item;
        private ServerItem conditions_item;
        private ServerItem wind_item;
        private ServerItem refresh_item;
        private ServerItem forecast_item;
        private ServerItem location_header;
        public WeatherIconExporter()
        {
            this.id = "vala-panel-extras-weather";
            this.title = _("Weather Applet");
            this.category = Category.APPLICATION;
            set_invalid_icon();
            locations = {};
            location_items = {};
            this.notify["app"].connect(()=>{
                app.about.logo_icon_name = "weather-clear";
                app.about.icon_name = "weather-clear";
                app.about.program_name = _("Vala Panel Weather Applet");
                app.about.comments = _("Simple weather indicator.");
                this.settings = new GLib.Settings(app.application_id);
                settings.changed.connect(on_settings_changed);
                settings.bind(SHOW_LABEL,this,SHOW_LABEL,SettingsBindFlags.GET);
                app.preferences = create_preferences_dialog;
                info = new GWeather.Info(null,GWeather.ForecastType.LIST);
                info.enabled_providers = GWeather.Provider.ALL;
                info.updated.connect(info_updated);
                var gnome_settings = new GLib.Settings("org.gnome.GWeather");
                gnome_settings.changed.connect((k)=>{info.update();});
                var sep = new ServerItem();
                sep.set_variant_property("type",new Variant.string("separator"));
                dbusmenu.prepend_item(sep);
                refresh_item = new ServerItem();
                refresh_item.set_variant_property("label",new Variant.string(_("Refresh")));
                refresh_item.set_variant_property("icon-name",new Variant.string("view-refresh-symbolic"));
                refresh_item.activated.connect(()=>{info.update();});
                dbusmenu.prepend_item(refresh_item);
                forecast_item = new ServerItem();
                forecast_item.set_variant_property("label",new Variant.string(_("Forecast...")));
                forecast_item.activated.connect(()=>{this.activate(0,0);});
                dbusmenu.prepend_item(forecast_item);
                sep = new ServerItem();
                sep.set_variant_property("type",new Variant.string("separator"));
                dbusmenu.prepend_item(sep);
                sunset_item = new ServerItem();
                dbusmenu.prepend_item(sunset_item);
                sunrise_item = new ServerItem();
                dbusmenu.prepend_item(sunrise_item);
                wind_item = new ServerItem();
                dbusmenu.prepend_item(wind_item);
                humidity_item = new ServerItem();
                dbusmenu.prepend_item(humidity_item);
                temp_item = new ServerItem();
                dbusmenu.prepend_item(temp_item);
                conditions_item = new ServerItem();
                dbusmenu.prepend_item(conditions_item);
                location_header = new ServerItem();
                location_header.set_variant_property("enabled",new Variant.boolean(false));
                dbusmenu.prepend_item(location_header);
                sep = new ServerItem();
                sep.set_variant_property("type",new Variant.string("separator"));
                dbusmenu.prepend_item(sep);
                dbusmenu.layout_updated(layout_revision++,0);
                on_settings_changed(LOCATIONS);
                on_settings_changed(UPDATE);
                this.notify[SHOW_LABEL].connect(()=>{
                    if (show_temperature)
                        x_ayatana_new_label(info.get_temp_summary(),"100 °C");
                    else
                        x_ayatana_new_label("","");
                });
            });
        }
        private void set_invalid_icon()
        {
            this.icon_name = "dialog-error";
            var tooltip = ToolTip();
            tooltip.icon_name = "dialog-error";
            tooltip.title = _("No network connection");
            tooltip.description = _("or no location.");
            this.tool_tip = tooltip;
        }
        private void on_settings_changed(string key)
        {
            if (key == LOCATIONS)
            {
                var loc = settings.get_value(LOCATIONS);
                current_location = settings.get_uint(CURRENT_LOC);
                if (loc.n_children() < 1)
                    return;
                locations = new GWeather.Location[(int)loc.n_children()];
                foreach(var item in location_items)
                    dbusmenu.remove_item(item.id);
                location_items = new ServerItem[(int)loc.n_children()];
                if (current_location >= location_items.length)
                    current_location %= location_items.length;
                for(var i = 0; i < loc.n_children(); i++)
                {
                    var index = i;
                    locations[i] = GWeather.Location.get_world();
                    locations[i] = locations[i].deserialize(loc.get_child_value(i).get_variant());
                    location_items[i] = new ServerItem();
                    location_items[i].set_variant_property("label", new Variant.string(locations[i].get_city_name()));
                    location_items[i].set_variant_property("toggle-type","radio");
                    location_items[i].set_variant_property("toggle-state",new Variant.int32((int)(i == current_location)));
                    location_items[i].activated.connect(()=>{
                        settings.set_uint(CURRENT_LOC,index);
                    });
                    dbusmenu.prepend_item(location_items[i]);
                }
                info.location = locations[current_location];
                info.abort();
                info.update();
                dbusmenu.layout_updated(layout_revision++,0);
            }
            else if (key == CURRENT_LOC)
            {
                current_location = settings.get_uint(CURRENT_LOC);
                for(var i = 0; i < location_items.length; i++)
                    location_items[i].set_variant_property("toggle-state",new Variant.int32((int)(i == current_location)));
                if (current_location >= location_items.length)
                    current_location %= location_items.length;
                info.set_location(locations[current_location]);
                info.abort();
                info.update();
                dbusmenu_attributes_location_updated();
            }
            else if (key == UPDATE)
            {
                if (update_source > 0)
                    Source.remove(update_source);
                var interval = settings.get_uint(UPDATE)*60;
                update_source = Timeout.add_seconds(interval,()=>{
                    info.abort();
                    info.update();
                    return Source.CONTINUE;
                });
            }
        }
        private void info_updated()
        {
            GWeather.ConditionQualifier q;
            GWeather.ConditionPhenomenon f;
            GWeather.Sky s;
            string cond_str;
            if (info.get_value_conditions(out f, out q))
                cond_str = info.get_conditions();
            else if (info.get_value_sky(out s))
                cond_str = info.get_sky();
            else
                cond_str = info.get_weather_summary();
            location_header.set_variant_property("label",new Variant.string(info.get_location_name()));
            conditions_item.set_variant_property("icon-name",new Variant.string(info.get_symbolic_icon_name()));
            conditions_item.set_variant_property("label", new Variant.string(_("Conditions: %s").printf(cond_str)));
            temp_item.set_variant_property("label",new Variant.string(_("Temperature: %s").printf(info.get_temp())));
            humidity_item.set_variant_property("label",new Variant.string(_("Humidity: %s").printf(info.get_humidity())));
            wind_item.set_variant_property("label",new Variant.string(_("Wind: %s").printf(info.get_wind())));
            sunrise_item.set_variant_property("label",new Variant.string(_("Sunrise: %s").printf(info.get_sunrise())));
            sunset_item.set_variant_property("label",new Variant.string(_("Sunset: %s").printf(info.get_sunset())));
            refresh_item.set_variant_property("label",new Variant.string(_("Refresh... (%s)").printf(info.get_update())));
            this.icon_name = info.get_icon_name();
            var tooltip = ToolTip();
            tooltip.icon_name = info.get_icon_name();
            tooltip.title = info.get_weather_summary()+" "+info.get_temp_summary();
            var desc = new StringBuilder();
            desc.append_printf("%s %s\n",_("Pressure:"),info.get_pressure());
            desc.append_printf("%s %s\n",_("Wind:"),info.get_wind());
            tooltip.description = desc.str;
            this.tool_tip = tooltip;
            if (show_temperature)
               x_ayatana_new_label(info.get_temp_summary(),"100 °C");
            else
                x_ayatana_new_label("","");
            dbusmenu_attributes_updated();
        }
        private void dbusmenu_attributes_updated()
        {
            /*Return all properties instead of requested*/
            Variant[] items = {};
            var builder = new VariantBuilder(new VariantType("(ia{sv})"));
            builder.add("i",location_header.id);
            builder.add_value(location_header.serialize_properties());
            items += builder.end();
            builder = new VariantBuilder(new VariantType("(ia{sv})"));
            builder.add("i",conditions_item.id);
            builder.add_value(conditions_item.serialize_properties());
            items += builder.end();
            builder = new VariantBuilder(new VariantType("(ia{sv})"));
            builder.add("i",temp_item.id);
            builder.add_value(temp_item.serialize_properties());
            items += builder.end();
            builder = new VariantBuilder(new VariantType("(ia{sv})"));
            builder.add("i",humidity_item.id);
            builder.add_value(humidity_item.serialize_properties());
            items += builder.end();
            builder = new VariantBuilder(new VariantType("(ia{sv})"));
            builder.add("i",wind_item.id);
            builder.add_value(wind_item.serialize_properties());
            items += builder.end();
            builder = new VariantBuilder(new VariantType("(ia{sv})"));
            builder.add("i",sunrise_item.id);
            builder.add_value(sunrise_item.serialize_properties());
            items += builder.end();
            builder = new VariantBuilder(new VariantType("(ia{sv})"));
            builder.add("i",sunset_item.id);
            builder.add_value(sunset_item.serialize_properties());
            items += builder.end();
            builder = new VariantBuilder(new VariantType("(ia{sv})"));
            builder.add("i",refresh_item.id);
            builder.add_value(refresh_item.serialize_properties());
            items += builder.end();
            var properties = new Variant.array(new VariantType("(ia{sv})"),items);
            items = {};
            var removed = new Variant.array(new VariantType("(ias)"),items);
            dbusmenu.items_properties_updated(properties,removed);
        }
        public void dbusmenu_attributes_location_updated()
        {
            /*Return all properties instead of requested*/
            Variant[] items = {};
            foreach(var item in location_items)
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
        private Gtk.Dialog create_preferences_dialog()
        {
            var dlg = new Weather.ConfigDialog(this);
            dlg.icon_name = "weather-clear";
            return dlg;
        }
        public override void scroll(int delta, string orientation)
        {
            if (orientation == "vertical")
            {
                if (delta > 0)
                    settings.set_uint(CURRENT_LOC,++current_location%locations.length);
                else
                    settings.set_uint(CURRENT_LOC,--current_location%locations.length);
            }
        }
        public override void activate(int x, int y)
        {
            if (forecast_dlg == null)
                forecast_dlg = new ForecastDialog(this);
            forecast_dlg.present();
        }
        public override void secondary_activate(int x, int y)
        {
            info.abort();
            info.update();
        }
        public override void context_menu (int x, int y)
        {

        }
    }
}
