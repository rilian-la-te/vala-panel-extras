using StatusNotifier;
using DBusMenu;
using GLib;
using Alsa;
using Canberra;

public static int main(string[] args)
{
    Gtk.init(ref args);
    var icon = new VolumeIconExporter();
    var app = new App("volume",icon);
    icon.app = app;
    return app.run(args);
}

[DBus (name = "org.kde.StatusNotifierItem")]
public class VolumeIconExporter : ItemExporter
{
    private const string KEY_CHANNEL = "channel-id";
    private const string KEY_CARD_ID = "card-id";
    private const string KEY_MIXER = "mixer";
    bool asound_find_element(string ename)
    {
        for (
          master_element = mixer.first_elem();
          master_element != null;
          master_element = master_element.next())
        {
            master_element.get_id(sid);
            if (master_element.is_active() && ename == sid.get_name())
                    return true;
        }
        return false;
    }
    bool asound_reset_mixer_evt_idle()
    {
        if (!MainContext.current_source().is_destroyed())
            mixer_evt_idle = 0;
        return false;
    }
    /* Handler for I/O event on ALSA channel. */
    bool asound_mixer_event(IOChannel channel, IOCondition cond)
    {
        int res = 0;
        if (MainContext.current_source().is_destroyed())
            return false;
        if (mixer_evt_idle == 0)
        {
            mixer_evt_idle = Idle.add_full(Priority.DEFAULT,asound_reset_mixer_evt_idle);
            res = mixer.handle_events();
        }
        if ((cond & IOCondition.IN) > 0)
        {
            /* the status of mixer is changed. update of display is needed. */
            update_display();
        }
        if (((cond & IOCondition.HUP) > 0) || (res < 0))
        {
            /* This means there're some problems with alsa. */
            warning("""volumealsa: ALSA (or pulseaudio) had a problem:
                    volumealsa: snd_mixer_handle_events() = %d,
                    cond 0x%x (IN: 0x%x, HUP: 0x%x).""", res, cond,
                    IOCondition.IN, IOCondition.HUP);
            var tooltip = ToolTip();
            tooltip.title = _("ALSA (or pulseaudio) had a problem.");
            tooltip.description = _(" Please check the volume-applet logs.");
            tooltip.icon_name = "dialog-error";
            this.tool_tip = tooltip;
            new_tool_tip();
            new_status(StatusNotifier.Status.PASSIVE);
            if (restart_idle == 0)
                restart_idle = Timeout.add_seconds(1, asound_restart);
            return false;
        }
        return true;
    }
    bool asound_restart()
    {
        if (MainContext.current_source().is_destroyed())
            return false;
        asound_deinitialize();
        if (!asound_initialize()) {
            warning("volumealsa: Re-initialization failed.");
            return true; // try again in a second
        }
        warning("volumealsa: Restarted ALSA interface...");
        restart_idle = 0;
        return false;
    }
    /* Initialize the ALSA interface. */
    bool asound_initialize()
    {
        /* Access the "default" device. */
        SimpleElementId.alloc(out sid);
        Mixer.open(out mixer, 0);
        mixer.attach(card_id);
        mixer.register();
        mixer.load();

        /* Find Master element, or Front element, or PCM element, or LineOut element.
         * If one of these succeeds, master_element is valid. */
        if (!asound_find_element(channel))
            return false;

        /* Set the playback volume range as we wish it. */
        master_element.set_playback_volume_range(0, 100);

        /* Listen to events from ALSA. */
        int n_fds = mixer.get_poll_descriptors_count();
        Posix.pollfd[] fds = new Posix.pollfd[n_fds];

        channels = new IOChannel[n_fds];
        watches = new uint[n_fds];
        num_channels = n_fds;

        mixer.set_poll_descriptors(fds);
        for (var i = 0; i < n_fds; ++i)
        {
            var channel = new IOChannel.unix_new(fds[i].fd);
            watches[i] = channel.add_watch(IOCondition.IN | IOCondition.HUP, asound_mixer_event);
            channels[i] = channel;
        }
        return true;
    }

    void asound_deinitialize()
    {
        if (mixer_evt_idle != 0) {
            Source.remove(mixer_evt_idle);
            mixer_evt_idle = 0;
        }

        for (var i = 0; i < num_channels; i++) {
            Source.remove(watches[i]);
            try
            {
                channels[i].shutdown(false);
            } catch (GLib.Error e){}
        }
        channels = {};
        watches = {};
        num_channels = 0;
        mixer = null;
        master_element = null;
        sid = null;
    }
    /* Get the presence of the mute control from the sound system. */
    bool asound_has_mute()
    {
        return ((master_element != null) ? master_element.has_playback_switch() : false);
    }

    /* Get the condition of the mute control from the sound system. */
    bool asound_is_muted()
    {
        /* The switch is on if sound is not muted, and off if the sound is muted.
         * Initialize so that the sound appears unmuted if the control does not exist. */
        int val = 1;
        if (master_element != null)
            master_element.get_playback_switch(0, out val);
        var volume = asound_get_volume();
        return (val == 0 || volume == 0);
    }

    /* Get the volume from the sound system.
     * This implementation returns the average of the Front Left and Front Right channels. */
    long asound_get_volume()
    {
        long aleft = 0;
        long aright = 0;
        if (master_element != null)
        {
            master_element.get_playback_volume(SimpleChannelId.FRONT_LEFT, out aleft);
            master_element.get_playback_volume(SimpleChannelId.FRONT_RIGHT, out aright);
        }
        return (aleft + aright) >> 1;
    }

    /* Set the volume to the sound system.
     * This implementation sets the Front Left and Front Right channels to the specified value. */
    void asound_set_volume(long volume)
    {
        if (master_element != null)
        {
            master_element.set_playback_volume(SimpleChannelId.FRONT_LEFT, volume);
            master_element.set_playback_volume(SimpleChannelId.FRONT_RIGHT, volume);

#if CANBERRA
            if (sound_change == null)
                Context.create(out sound_change);
            else {
                sound_change.play (0, PROP_EVENT_ID, "audio-volume-change",
                    PROP_EVENT_DESCRIPTION, "audio-volume-change");
            }
#endif
        }
    }
    string lookup_current_icon(long level)
    {
        mute = asound_is_muted();
        if (asound_is_muted() || level == 0)
            return "audio-volume-muted";
        else if (level >= 66)
            return "audio-volume-high";
        else if (level >= 33)
            return "audio-volume-medium";
        else if (level > 0)
            return "audio-volume-low";
        return "dialog-warning";
    }
    /*
     * Here we just update volume's vertical scale and mute check button.
     * The rest will be updated by signal handelrs.
     */
    void update_display()
    {
        /* Volume. */
        if (volume_scale != null)
        {
            volume_scale.set_value(asound_get_volume());
            var level = volume_scale.get_value();
            update_current_icon((long)level);
            if (update_menu)
                update_current_menu((long)level);
            notification.val = (int) level;
            notification.app_icon = lookup_current_icon((long) level);
            notification.title = tool_tip.title;
            notification.sound_name = "audio-volume-change";
            notification.send();
        }
    }
    void set_invalid_icon()
    {
        this.icon_name = "dialog-error";
        new_status(StatusNotifier.Status.PASSIVE);
        var tooltip = ToolTip();
        tooltip.icon_name = "dialog-error";
        tooltip.title = _("ALSA is not connected");
        tooltip.description = "";
        this.tool_tip = tooltip;
    }
    /* Do a full redraw of the display. */
    void update_current_icon(long level)
    {
        this.icon_name = lookup_current_icon(level);
        var tooltip = ToolTip();
        tooltip.icon_name = this.icon_name;
        tooltip.title = "%s: %li".printf(channel,level);
        tooltip.description = "";
        this.tool_tip = tooltip;
    }
    void update_current_menu(long level)
    {
        if (alsa_is_init)
        {
            mute_item.set_variant_property("visible",new Variant.boolean(true));
            scale_item.set_variant_property("visible",new Variant.boolean(true));
            mute_item.set_variant_property("toggle-state",new Variant.int32((int)asound_is_muted()));
            scale_item.set_variant_property("x-valapanel-current-value",new Variant.double(volume_scale.adjustment.value));
        }
        else
        {
            mute_item.set_variant_property("visible",new Variant.boolean(false));
            scale_item.set_variant_property("visible",new Variant.boolean(false));
        }
        menu_properties_changed();
    }
    void menu_properties_changed()
    {
        /*Return all properties instead of requested*/
        Variant[] items = {};
        var builder = new VariantBuilder(new VariantType("(ia{sv})"));
        builder.add("i",mute_item.id);
        builder.add_value(mute_item.serialize_properties());
        items += builder.end();
        builder = new VariantBuilder(new VariantType("(ia{sv})"));
        builder.add("i",scale_item.id);
        builder.add_value(scale_item.serialize_properties());
        items += builder.end();
        var properties = new Variant.array(new VariantType("(ia{sv})"),items);
        items = {};
        var removed = new Variant.array(new VariantType("(ias)"),items);
        dbusmenu.items_properties_updated(properties,removed);
    }
    void alsa_init()
    {
        if (asound_initialize())
        {
            alsa_is_init = true;
            build_activate_window();
            /* Update the display, show the widget, and return. */
            update_display();
            new_status(StatusNotifier.Status.ACTIVE);
        }
        else
        {
            set_invalid_icon();
            alsa_is_init = false;
        }
    }
    void alsa_reset()
    {
        if (alsa_is_init)
        {
            asound_deinitialize();
            alsa_is_init = false;
        }
        alsa_init();
    }
    /* Build the window that appears when the top level widget is clicked. */
    void build_activate_window()
    {
        /* Create a new window. */
        activate_window = new Gtk.Window(Gtk.WindowType.TOPLEVEL);
        activate_window.decorated = false;
        activate_window.border_width = 0;
        activate_window.skip_taskbar_hint = true;
        activate_window.skip_pager_hint = true;
        activate_window.set_default_size(-1,145);
        activate_window.type_hint = Gdk.WindowTypeHint.POPUP_MENU;
        activate_window.add_events(Gdk.EventMask.FOCUS_CHANGE_MASK);
        activate_window.focus_out_event.connect(()=>{
            activate_window.hide();
            return false;
        });

        /* Create a vertical box as the child of the frame. */
        var box =  new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        activate_window.add(box);

        /* Create a vertical scale as the child of the vertical box. */
        volume_scale = new Gtk.Scale(Gtk.Orientation.VERTICAL,new Gtk.Adjustment(100, 0, 100, 1, 5, 0));
        volume_scale.draw_value = false;
        volume_scale.inverted = true;
        volume_scale.vexpand = true;
        box.add(volume_scale);
        /* Value-changed and scroll-event signals. */
        volume_scale.value_changed.connect(()=>{
            var level = volume_scale.get_value();
            asound_set_volume((long)level);
            update_current_icon((long)level);
            if (update_menu)
                update_current_menu((long)level);
        });
        volume_scale.scroll_event.connect((evt)=>{
            /* Get the state of the vertical scale. */
            var val = volume_scale.get_value();
            /* Dispatch on scroll direction to update the value. */
            if (evt.direction == Gdk.ScrollDirection.UP)
                val += 2;
            else if (evt.direction == Gdk.ScrollDirection.DOWN)
                val -= 2;
            else if (evt.direction == Gdk.ScrollDirection.SMOOTH)
            {
              val -= evt.delta_y * 2;
              val = val.clamp(0,100);
            }
            /* Reset the state of the vertical scale.  This provokes a "value_changed" event. */
            volume_scale.set_value(val.clamp(0, 100));
            return false;
        });
        box.show_all();
    }
    void launch_mixer_command()
    {
        try{
        GLib.AppInfo info = AppInfo.create_from_commandline(mixer_command,null,
                    AppInfoCreateFlags.SUPPORTS_STARTUP_NOTIFICATION);
        info.launch(null,Gdk.Display.get_default().get_app_launch_context());
        } catch (GLib.Error e){stderr.printf("%s\n",e.message);}
    }
    Gtk.Dialog create_preferences_dialog()
    {
        var dlg = Configurator.generic_config_dlg(_("Vala Panel Volume Applet"),
                                                    this.settings,
                                                    _("ALSA Card"), KEY_CARD_ID, GenericConfigType.STR,
                                                    _("ALSA Channel"), KEY_CHANNEL, GenericConfigType.STR,
                                                    _("Mixer launch command"), KEY_MIXER, GenericConfigType.STR);
        dlg.icon_name = "multimedia-volume-control";
        return dlg;
    }
    public VolumeIconExporter()
    {
        this.id = "vala-panel-extras-volume";
        this.title = _("Volume Applet");
        this.category = Category.HARDWARE;
        set_invalid_icon();
        var sep = new ServerItem();
        sep.set_variant_property("type",new Variant.string("separator"));
        dbusmenu.prepend_item(sep);
        mixer_item = new ServerItem();
        mixer_item.set_variant_property("label",new Variant.string(_("Volume _Control...")));
        mixer_item.set_variant_property("icon-name",new Variant.string("multimedia-volume-control"));
        mixer_item.activated.connect(()=>{
            launch_mixer_command();
        });
        sep = new ServerItem();
        sep.set_variant_property("type",new Variant.string("separator"));
        dbusmenu.prepend_item(mixer_item);
        dbusmenu.prepend_item(sep);
        mute_item = new ServerItem();
        mute_item.set_variant_property("label",new Variant.string(_("_Mute")));
        mute_item.set_variant_property("toggle-type",new Variant.string("checkmark"));
        mute_item.set_variant_property("toggle-state",new Variant.int32(0));
        mute_item.activated.connect(()=>{
            x_ayatana_secondary_activate(Gtk.get_current_event_time());
            mute_item.set_variant_property("toggle-state",new Variant.int32((int)asound_is_muted()));
            menu_properties_changed();
        });
        dbusmenu.prepend_item(mute_item);
        scale_item = new ServerItem();
        scale_item.set_variant_property("label",new Variant.string(_("Volume Scale")));
        scale_item.set_variant_property("type",new Variant.string("scale"));
        scale_item.set_variant_property("icon-name",new Variant.string("audio-volume-high-symbolic"));
        scale_item.set_variant_property("x-valapanel-min-value",new Variant.double(0));
        scale_item.set_variant_property("x-valapanel-max-value",new Variant.double(100));
        scale_item.set_variant_property("x-valapanel-step-increment",new Variant.double(1));
        scale_item.set_variant_property("x-valapanel-page-increment",new Variant.double(5));
        scale_item.set_variant_property("x-valapanel-draw-value",new Variant.boolean(true));
        scale_item.set_variant_property("x-valapanel-format-value",new Variant.string("%3.0lf%%"));
        scale_item.value_changed.connect((val)=>{
            update_menu = false;
            volume_scale.set_value(val);
            update_menu = true;
        });
        dbusmenu.prepend_item(scale_item);
        dbusmenu.layout_updated(layout_revision++,0);
        this.notify["app"].connect(()=>{
            notification = new Notifier.Notification.with_app_id("vol",app.application_id);
            app.about.logo_icon_name = "multimedia-volume-control";
            app.about.icon_name = "multimedia-volume-control";
            app.about.program_name = _("Vala Panel Volume Applet");
            app.about.comments = _("Simple ALSA playback volume indicator.");
            this.settings = new GLib.Settings(app.application_id);
            app.preferences = create_preferences_dialog;
            settings.changed.connect((k)=>{
                channel = settings.get_string(KEY_CHANNEL);
                card_id = settings.get_string(KEY_CARD_ID);
                mixer_command = settings.get_string(KEY_MIXER);
                if (k != KEY_MIXER && alsa_is_init)
                    alsa_reset();
                if (!alsa_is_init)
                    alsa_init();
            });
            channel = settings.get_string(KEY_CHANNEL);
            card_id = settings.get_string(KEY_CARD_ID);
            mixer_command = settings.get_string(KEY_MIXER);
            alsa_init();
        });
    }
    public override void scroll(int delta, string orientation)
    {
        if (volume_scale != null)
        {
            /* Get the state of the vertical scale. */
            double val = volume_scale.get_value();
            /* Dispatch on scroll direction to update the value. */
            if (orientation == "vertical")
            {
                if (delta < 0)
                    val -= 2;
                else if (delta > 0)
                    val += 2;
            }
            val.clamp(0,100);
            /* Reset the state of the vertical scale.  This provokes a "value_changed" event. */
            volume_scale.set_value(val);
        }
    }
    public override void activate(int x, int y)
    {
        if (activate_window.visible)
        {
            activate_window.hide();
            return;
        }
        activate_window.realize();
        Gtk.Requisition requisition = {0,0};
        requisition.width = activate_window.get_allocated_width ();
        requisition.height = activate_window.get_allocated_height ();
        var monitor_object = activate_window.get_display().get_monitor_at_point (x, y);
        var monitor = monitor_object.get_workarea ();
        if (y + requisition.height > monitor.y + monitor.height)
            y = (monitor.y + monitor.height) - requisition.height;
        if (y < monitor.y)
            y = monitor.y;
        x = x.clamp(monitor.x, int.max(monitor.x, monitor.x + monitor.width - requisition.width));
        activate_window.move(x,y);
        activate_window.present();
    }
    public override void secondary_activate(int x, int y)
    {
        mute = !mute;
        if (volume_scale != null)
        {
            var level = volume_scale.get_value();
            if (master_element != null)
                for (var chn = 0; chn <= SimpleChannelId.LAST; chn++)
                    if(asound_has_mute())
                        master_element.set_playback_switch(chn, (mute) ? 0 : 1);
            update_current_icon((long) level);
            update_current_menu((long) level);
        }
    }
    public override void context_menu (int x, int y)
    {
        activate(x,y);
    }
    uint num_channels;
    uint[] watches;
    IOChannel[] channels;
    MixerElement master_element;
    Mixer mixer;
    SimpleElementId sid;
    uint mixer_evt_idle;
    uint restart_idle;
    string card_id;
    string channel;
    string mixer_command;
    bool alsa_is_init;
    bool mute;
    bool update_menu = true;
    Gtk.Scale volume_scale;
    Gtk.Window activate_window;
    ServerItem mute_item;
    ServerItem scale_item;
    ServerItem mixer_item;
    Notifier.Notification notification;
#if CANBERRA
    Context sound_change;
#endif
}
