using Xkb;
using GLib;

namespace XkbPlugin
{
    private const string XKB_NAMES_ATOM = "_XKB_RULES_NAMES";
    private const string ACTIVE_WINDOW_ATOM = "_NET_ACTIVE_WINDOW";

    private enum KeyboardStateNotifyIgnore
    {
        NO,
        YES_SET,
        YES_ALL
    }
    public class XkbBackend : Object
    {
        private int32 core_keyboard;
        private unowned Xcb.xkb.Connection conn;
        private Xkb.Context ctx;
        private Xkb.State state;
        private Xcb.Atom active_window_atom;
        private Xcb.Atom xkb_names_atom;
        private KeyboardStateNotifyIgnore ignore_state;
        private HashTable<Xcb.Window, Xkb.LayoutIndex?> layout_per_window;
        private uint8 first_event;
        private Xkb.RuleNames keymap_rule_names;
        public bool use_system_layouts {get; set;}
        public bool layout_group_per_window {get; set;}
        public string[] layout_names {get; private set;}
        public string[] layout_short_names {get; private set;}
        public string layout_name {
            get {
                return layout_names[layout_number];
            }
        }
        public string layout_short_name {
            get {
                return layout_short_names[layout_number];
            }
        }
        public uint32 layout_number {
            get {
                return (uint32)state.serialize_layout(StateComponent.LAYOUT_EFFECTIVE);
            }
        }
        public uint32 layouts_count {
            get {
                return state.keymap.num_layouts();
            }
        }
        public string rules
        {
            get {return keymap_rule_names.rules;}
            set {keymap_rule_names.rules = value;}
        }
        public string model
        {
            get {return keymap_rule_names.model;}
            set {keymap_rule_names.model = value;}
        }
        public string layout
        {
            get {return keymap_rule_names.layout;}
            set {keymap_rule_names.layout = value;}
        }
        public string variant
        {
            get {return keymap_rule_names.variant;}
            set {keymap_rule_names.variant = value;}
        }
        public string options
        {
            get {return keymap_rule_names.options;}
            set {keymap_rule_names.options = value;}
        }
        public signal void layout_changed();
        public signal void keymap_changed();
        construct
        {
            use_system_layouts = true;
            layout_names = new string[4];
            layout_short_names = new string[4];
            keymap_rule_names = Xkb.RuleNames();
            ctx = new Xkb.Context();
            var disp = Gdk.Display.get_default() as Gdk.X11.Display;
            conn = (Xcb.xkb.Connection)((X.xcb.Display)disp.get_xdisplay()).connection;
            bool started = Xkb.X11.setup_xkb_extension(conn,Xkb.X11.MIN_MAJOR_XKB_VERSION,
                                                            Xkb.X11.MIN_MINOR_XKB_VERSION,
                                                            Xkb.X11.ExtensionFlags.NO_FLAGS,
                                                            null,null, out first_event);
            core_keyboard = Xkb.X11.get_core_keyboard_device_id(conn);
            var keymap = Xkb.X11.keymap_new_from_device(ctx,conn,(int32)core_keyboard);
            state = Xkb.X11.state_new_from_device(keymap,conn,(int32)core_keyboard);
            if (!started || ctx == null || conn == null || state == null)
            {
                stderr.printf("%s\n",_("XKB extension error. Keyboard layout plugin will not work"));
            }
            layout_per_window = new HashTable <Xcb.Window, Xkb.LayoutIndex?>(direct_hash,direct_equal);
            var xkb_cookie = conn.intern_atom(false,(char[])XKB_NAMES_ATOM.data);
            var active_cookie = conn.intern_atom(false,(char[])ACTIVE_WINDOW_ATOM.data);
            find_root_window().change_attributes(conn,Xcb.Cw.EVENT_MASK,{Xcb.EventMask.PROPERTY_CHANGE});
            var xkb_reply = xkb_cookie.reply(conn);
            if (xkb_reply != null)
                xkb_names_atom = xkb_reply.atom;
            var active_reply = active_cookie.reply(conn);
            if (active_reply != null)
                active_window_atom = active_reply.atom;
            (null as Gdk.Window).add_filter(xlib_event_filter);
            update_state();
        }
        public XkbBackend()
        {
            Object();
        }
        public void next_layout_group()
        {
            set_layout_group((layout_number + 1) % state.keymap.num_layouts());
        }
        public void prev_layout_group()
        {
            set_layout_group((layout_number - 1) % state.keymap.num_layouts());
        }
        public void set_layout_group(LayoutIndex new_layout_number)
        {
            conn.latch_lock_state (Xcb.xkb.Id.USE_CORE_KBD, 0, 0, true, (Xcb.xkb.Group)new_layout_number, 0, false, 0);
            update_state();
        }
        private void update_state()
        {
            var old_keymap = state.keymap.get_as_string();
            var old_layout_index = layout_number;
            var keymap = Xkb.X11.keymap_new_from_device(ctx,conn,(int32)core_keyboard);
            state = Xkb.X11.state_new_from_device(keymap,conn,(int32)core_keyboard);
            for (LayoutIndex i = 0; i < state.keymap.num_layouts(); i++)
                layout_names[i] = state.keymap.layout_get_name(i);
            find_short_names_from_keymap();
            enter_locale_by_process();
            if (old_keymap != state.keymap.get_as_string())
                keymap_changed();
            if (old_layout_index != layout_number)
                layout_changed();
        }
        private void enter_locale_by_process()
        {
            if (layout_per_window != null)
            {
                Xcb.Window win = find_active_window();
                if (win != 0)
                    layout_per_window.insert(win, layout_number);
            }
        }
        /* React to change of focus by switching to the application's layout or the default layout. */
        private void active_window_changed(Xcb.Window window)
        {
            if (!layout_per_window.contains(window))
                layout_per_window.insert(window,0);
            var new_layout_index = layout_per_window.lookup(window);
            if (new_layout_index < state.keymap.num_layouts())
                set_layout_group(new_layout_index);
        }
        private Gdk.FilterReturn xlib_event_filter(Gdk.XEvent xevent, Gdk.Event event)
        {
            X.Event* xev = (X.Event*)xevent;
            if (xev->xany.type == first_event + X.Xkb.EventCode)
            {
                X.Xkb.Event* xkbev = (X.Xkb.Event*)xevent;
                if (xkbev->any.xkb_type == X.Xkb.NewKeyboardNotify)
                {
                    if (this.ignore_state == KeyboardStateNotifyIgnore.NO)
                    {
                        this.ignore_state = KeyboardStateNotifyIgnore.YES_SET;
                        Timeout.add(1000/*msec*/, ()=>{
                            this.ignore_state = KeyboardStateNotifyIgnore.NO;
                            return false;
                        });
                        this.set_keymap();
                    }
                    else if (this.ignore_state == KeyboardStateNotifyIgnore.YES_SET)
                    {
                        this.ignore_state = KeyboardStateNotifyIgnore.YES_ALL;
                        this.update_state();
                    }
                }
                else if (xkbev->any.xkb_type == X.Xkb.StateNotify)
                {
                    if (xkbev.state.group != layout_number)
                    {
                        update_state();
                    }
                }
            }
            else if (layout_group_per_window && xev->xany.type == X.PropertyNotify)
            {
                unowned X.PropertyEvent* pev = (X.PropertyEvent*)xevent;
                if (pev->window == find_root_window() && pev->atom == active_window_atom)
                {
                    this.active_window_changed(find_active_window());
                    update_state();
                }
            }
            return Gdk.FilterReturn.CONTINUE;
        }
        public void set_keymap()
        {
            if (use_system_layouts)
                return;
            int len = 0;
            len += keymap_rule_names.rules.length;
            len += keymap_rule_names.model.length;
            len += keymap_rule_names.layout.length;
            len += keymap_rule_names.variant.length;
            len += keymap_rule_names.options.length;
            if (len < 1)
                return;
            len += 5;
            Array<uint8> rules_char = new Array<uint8>.sized(false,true,1,len);
            rules_char.append_vals((keymap_rule_names.rules + "\0").data,keymap_rule_names.rules.length + 1);
            rules_char.append_vals((keymap_rule_names.model + "\0").data,keymap_rule_names.model.length + 1);
            rules_char.append_vals((keymap_rule_names.layout + "\0").data,keymap_rule_names.layout.length + 1);
            rules_char.append_vals((keymap_rule_names.variant + "\0").data,keymap_rule_names.variant.length + 1);
            rules_char.append_vals((keymap_rule_names.options + "\0").data,keymap_rule_names.options.length + 1);
            find_root_window().change_property(conn, Xcb.PropMode.REPLACE, xkb_names_atom, Xcb.AtomType.STRING, 8, (void[])rules_char.data);
            update_state();
        }
        private Xcb.Window find_root_window()
        {
            var gwin = Gdk.Screen.get_default().get_root_window() as Gdk.X11.Window;
            return (Xcb.Window)gwin.get_xid();
        }
        private Xcb.Window find_active_window()
        {
            var gwin = Gdk.Screen.get_default().get_active_window() as Gdk.X11.Window;
            return (Xcb.Window)gwin.get_xid();
        }
        private void find_short_names_from_keymap()
        {
            try {
                var symbols_regex = new Regex("(xkb_symbols)(\\s+)(\".*?\")");
                MatchInfo info;
                symbols_regex.match(state.keymap.get_as_string(),0,out info);
                var symbols_str = info.fetch(3);
                var first_name_regex = new Regex("(_)([a-z][a-z]+)(_)");
                first_name_regex.match(symbols_str,0,out info);
                layout_short_names[0] = info.fetch(2);
                var next_names_regex = new Regex("(_)([a-z][a-z]+)(_)([0-9])");
                next_names_regex.match(symbols_str,0,out info);
                for (var i = 1; info.matches(); info.next(), i++)
                    layout_short_names[i] = info.fetch(2);
            } catch (Error e) {
                stderr.printf("Layouts cannot be parsed: %s\n",e.message);
            }
        }
    }
}
