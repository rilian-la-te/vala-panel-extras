using GLib;
using Gtk;

namespace Weather
{
    [CCode (cname = "ConfigDialog"), GtkTemplate (ui = "/org/vala-panel/weather/ui/config.ui")]
    public class ConfigDialog : Gtk.Dialog
    {
        [GtkChild (name = "spin-interval")]
        SpinButton spin_interval;
        [GtkChild (name = "location-search-button")]
        MenuButton location_search_button;
        [GtkChild (name = "remove-button")]
        Button remove_button;
        [GtkChild (name = "location-selection")]
        TreeSelection location_selection;
        [GtkChild (name = "location-list")]
        Gtk.ListStore location_list;
        private Gtk.Popover popover;
        private GWeather.LocationEntry entry;
        private WeatherIconExporter plugin;
        public ConfigDialog(WeatherIconExporter icon)
        {
            var settings = new GLib.Settings("org.gnome.GWeather");
            var temp_action = settings.create_action("temperature-unit");
            var wind_action = settings.create_action("speed-unit");
            var label_action = icon.settings.create_action(WeatherIconExporter.SHOW_LABEL);
            var action_group = new SimpleActionGroup();
            action_group.add_action(temp_action);
            action_group.add_action(wind_action);
            action_group.add_action(label_action);
            this.insert_action_group("conf",action_group);
            icon.settings.bind(WeatherIconExporter.UPDATE,spin_interval.adjustment,"value",SettingsBindFlags.DEFAULT);
            popover = new Gtk.Popover(location_search_button);
            var box = new Box(Orientation.HORIZONTAL,10);
            entry = new GWeather.LocationEntry(GWeather.Location.get_world());
            box.add(entry);
            var button = new Gtk.Button();
            button.image = new Image.from_icon_name("list-add-symbolic",IconSize.BUTTON);
            button.clicked.connect(on_add_location);
            box.add(button);
            popover.add(box);
            box.show_all();
            location_search_button.set_popover(popover);
            remove_button.sensitive = icon.locations.length > 1;
            this.plugin = icon;
            foreach(unowned GWeather.Location location in icon.locations)
            {
                TreeIter iter;
                location_list.append(out iter);
                location_list.set(iter,0,location.equal(icon.locations[icon.current_location]),1,location.get_name(),2,location.serialize());
            }
            plugin.notify[WeatherIconExporter.CURRENT_LOC].connect(()=>{
                location_list.foreach((model,path,iter)=>{
                    unowned Gtk.ListStore list = model as Gtk.ListStore;
                    Variant location;
                    list.get(iter,2,out location);
                    list.set(iter,0,plugin.locations[plugin.current_location].serialize().equal(location));
                    return false;
                });
            });
        }
        [GtkCallback]
        private void on_remove_location()
        {
            TreeIter sel_iter;
            if(location_selection.get_selected(null, out sel_iter))
            {
#if VALA_0_36
                location_list.remove(ref sel_iter);
#else
                location_list.remove(sel_iter);
#endif
                location_settings_updated();
            }
        }
        [GtkCallback]
        private void on_current_location_toggled(string path_str)
        {
            TreeIter iter;
            TreePath path = new TreePath.from_string(path_str);
            location_list.get_iter(out iter, path);
            bool active;
            location_list.get(iter,0,out active);
            if (active)
                return;
            location_list.foreach((model,path,iter)=>{
                unowned Gtk.ListStore list = model as Gtk.ListStore;
                list.set(iter,0,false);
                return false;
            });
            Variant location;
            location_list.set(iter,0,true);
            location_list.get(iter,2,out location);
            for(var i = 0; i < plugin.locations.length; i++)
            {
                if (location.equal(plugin.locations[i].serialize()) && i != plugin.current_location)
                    plugin.settings.set_uint(WeatherIconExporter.CURRENT_LOC,i);
            }
        }
        private void on_add_location()
        {
            if (entry.get_location() == null)
                return;
            foreach(var loc in plugin.locations)
                if (loc.equal(entry.get_location()))
                    return;
            TreeIter iter;
            location_list.append(out iter);
            location_list.set(iter,0,false,2,entry.get_location().serialize(),1,entry.get_location().get_name());
            location_settings_updated();
        }
        private void location_settings_updated()
        {
            Variant[] locations = {};
            location_list.foreach((model,path,iter)=>{
                Variant location;
                model.get(iter,2,out location);
                locations += new Variant.variant(location);
                return false;
            });
            var locations_v = new Variant.array(VariantType.VARIANT,locations);
            remove_button.sensitive = locations_v.n_children() > 1;
            plugin.settings.set_value(WeatherIconExporter.LOCATIONS, locations_v);
        }
    }
}
