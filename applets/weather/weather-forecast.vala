using GLib;
using Gtk;

namespace Weather
{
    [CCode (cname = "ForecastDialog"), GtkTemplate (ui = "/org/vala-panel/weather/ui/forecast.ui")]
    public class ForecastDialog : Gtk.Window
    {
        [GtkChild (name = "store-forecast")]
        Gtk.ListStore store_forecast;
        [GtkChild (name = "label-attribution")]
        Gtk.Label label_attribution;
        private ulong handler;
        public ForecastDialog(WeatherIconExporter plugin)
        {
            build_forecast(plugin.info);
            handler = plugin.info.updated.connect(()=>{
                build_forecast(plugin.info);
            });
            this.destroy.connect(()=>{
                plugin.info.disconnect(handler);
                plugin.forecast_dlg = null;
            });
        }
        private void build_forecast(GWeather.Info location_info)
        {
            this.title = _("Extended forecast for %s").printf(location_info.get_location_name());
            store_forecast.clear();
            label_attribution.label = location_info.get_attribution();
            foreach(var info in location_info.get_forecast_list())
            {
                TreeIter iter;
                store_forecast.append(out iter);
                int64 timeval;
                info.get_value_update(out timeval);
                var dt = new DateTime.from_unix_local(timeval);
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
                store_forecast.set(iter,0,dt.format("%a,%F,%R"),1,info.get_icon_name(),2,cond_str,3,info.get_temp());
            }
        }
        [GtkCallback]
        private void on_unmap()
        {
            this.destroy();
        }
    }
}
