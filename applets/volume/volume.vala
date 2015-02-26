using StatusNotifier;
using DBusMenu;
using GLib;

public class VolumeApplication: Application
{
    public static int main(string[] args)
    {
        var app = new VolumeApplication();
        return app.run(args);
    }
}
public class VolumeIconExporter : ItemExporter
{
    public VolumeIconExporter()
    {
        Object();
    }
}
