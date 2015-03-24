using Gtk;
using GLib;

namespace XkbPlugin
{
    [CCode(cname = "ConfigDialog"),GtkTemplate (ui = "/org/vala-panel/xkb/config.ui")]
    public class ConfigDialog : Gtk.Dialog
    {
        [GtkChild (name = "model-menu")]
        private MenuButton model_menu;
        [GtkChild (name = "options-menu")]
        private MenuButton options_menu;
        [GtkChild (name = "button-add")]
        private MenuButton layouts_menu;
        [GtkChild (name = "layout-per-window")]
        private CheckButton layout_per_window;
        [GtkChild (name = "indicator-only")]
        private CheckButton keep_system;
        [GtkChild (name = "all-grid")]
        private Grid layout_config;
        [GtkChild (name = "show-flag")]
        private CheckButton show_flag;
        [GtkChild (name = "show-text")]
        private CheckButton show_text;
        [GtkChild (name = "button-remove")]
        private Button remove_button;
        [GtkChild (name = "list-current")]
        private Gtk.ListStore list_current;
        [GtkChild (name = "selection-current")]
        private TreeSelection selection_current;
        [GtkChild (name = "scroll-options")]
        private ScrolledWindow options_scroll;
        [GtkChild (name = "scroll-layouts")]
        private ScrolledWindow layouts_scroll;
        [GtkChild (name = "scroll-model")]
        private ScrolledWindow model_scroll;
        [GtkChild (name = "store-layouts")]
        internal Gtk.TreeStore layouts_store;
        [GtkChild (name = "store-options")]
        internal Gtk.TreeStore options_store;
        [GtkChild (name = "store-model")]
        internal Gtk.ListStore model_store;
        private XKeyboardConfigParser parser;
        internal XkbIconExporter plugin;
        public ConfigDialog (XkbIconExporter icon)
        {
            var config_desc = File.new_for_path("/usr/share/X11/xkb/rules/evdev.xml");
            uint8[] xml_data;
            bool checker;
            try {
                checker = config_desc.load_contents(null, out xml_data, null);
            } catch (Error e) {
                checker = false;
            }
            if (!checker)
            {
                var dlg = new Gtk.MessageDialog (null, 0, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, _("Cannot initialize xkeyboard-config!")) as Gtk.Dialog;
                this.hide();
                dlg.present();
                return;
            }
            IconTheme.get_default().append_search_path(Config.INSTALL_PREFIX + "/share/vala-panel-extras/xkb/icons");
            unowned string xml = (string)xml_data;
            this.plugin = icon;
            icon.settings.bind(PER_WINDOW,layout_per_window,"active",SettingsBindFlags.DEFAULT);
            icon.settings.bind(SHOW_FLAG,show_flag,"active",SettingsBindFlags.DEFAULT);
            icon.settings.bind(SHOW_TEXT,show_text,"active",SettingsBindFlags.DEFAULT);
            icon.settings.bind(KEEP_SYSTEM,keep_system,"active",SettingsBindFlags.DEFAULT);
            icon.settings.bind(KEEP_SYSTEM,layout_config,"sensitive",SettingsBindFlags.DEFAULT | SettingsBindFlags.INVERT_BOOLEAN);
            icon.settings.bind(OPTIONS,icon.backend,OPTIONS,SettingsBindFlags.DEFAULT);
            icon.backend.bind_property(OPTIONS,options_menu,"label",BindingFlags.SYNC_CREATE);
            icon.backend.bind_property(MODEL,model_menu,"label",BindingFlags.SYNC_CREATE);
            var lbl = model_menu.get_child() as Label;
            lbl.ellipsize = Pango.EllipsizeMode.MIDDLE;
            icon.backend.bind_property("layouts-count",remove_button,"sensitive",BindingFlags.SYNC_CREATE,(b,s,ref t)=>{
                if (s.get_uint() > 1)
                    t.set_boolean(true);
                else
                    t.set_boolean(false);
                return true;
            });
            var popover = new Popover(options_menu);
            popover.add(options_scroll);
            popover.set_size_request(-1,200);
            options_menu.popover = popover;
            popover = new Popover(layouts_menu);
            popover.add(layouts_scroll);
            popover.set_size_request(-1,200);
            layouts_menu.popover = popover;
            popover = new Popover(model_menu);
            popover.add(model_scroll);
            popover.set_size_request(-1,200);
            model_menu.popover = popover;
            parser = new XKeyboardConfigParser(this);
            parser.try_parse(xml);
            update_current_layout();
            icon.backend.keymap_changed.connect(()=>{
                update_current_layout();
            });
            this.set_default_size(800,480);
        }
        private void update_current_layout()
        {
            list_current.clear();
            TreeIter iter;
            for (var i = 0; i < plugin.backend.layouts_count; i++)
            {
                list_current.append(out iter);
                list_current.set(iter,0,"flag-"+plugin.backend.layout_short_names[i],
                                      1,dgettext("xkeyboard-config",plugin.backend.layout_names[i]),
                                      2,plugin.backend.layout_short_names[i],
                                      3,plugin.backend.layout_variants[i]);
            }
        }
        [GtkCallback]
        private void layout_added(TreePath path, TreeViewColumn column)
        {
            string layout_flag, layout_desc,layout_name,layout_variant;
            TreeIter iter;
            layouts_store.get_iter(out iter, path);
            layouts_store.get(iter, 0, out layout_flag,
                                    1, out layout_desc,
                                    2, out layout_variant,
                                    3, out layout_name);
            list_current.insert(out iter,(int)plugin.backend.layouts_count);
            list_current.set(iter, 0, layout_flag,
                                   1, layout_desc,
                                   3, layout_variant,
                                   2, layout_name);
            update_layouts_from_widget();
        }
        [GtkCallback]
        private void option_toggled(string path_str)
        {
            TreeIter iter;
            StringBuilder options_b = new StringBuilder(plugin.backend.options);
            TreePath path = new TreePath.from_string(path_str);
            bool radio, active;
            string option_id;
            options_store.get_iter(out iter, path);
            options_store.get(iter, 0, out active, 1, out radio,4,out option_id);
            active = !active;
            if (!active)
            {
                var ind = options_b.str.index_of(option_id);
                options_b.erase(ind-1,option_id.length+1);
            }
            else if (!radio)
            {
                if (options_b.len > 0)
                    options_b.append(",");
                options_b.append(option_id);
            }
            else
            {
                TreeIter parent;
                TreeIter child;
                options_store.iter_parent(out parent, iter);
                for (options_store.iter_children(out child, parent); options_store.iter_next(ref child);)
                {
                    bool active_ch;
                    string option_id_ch;
                    options_store.get(child, 0, out active_ch, 4,out option_id_ch);
                    if (active_ch)
                    {
                        var ind = options_b.str.index_of(option_id_ch);
                        options_b.erase(ind-1,option_id_ch.length+1);
                        options_store.set(child,0,!active_ch);
                    }
                }
                if (options_b.len > 0)
                    options_b.append(",");
                options_b.append(option_id);
            }
            options_store.set(iter,0,active);
            plugin.backend.options = options_b.str;
        }
        [GtkCallback]
        private void model_toggled(string path_str)
        {
            TreeIter iter;
            TreePath path = new TreePath.from_string(path_str);
            bool active;
            string id;
            model_store.get_iter(out iter, path);
            model_store.get(iter, 0, out active,2,out id);
            active = !active;
            if (active)
            {
                TreeIter parent;
                for (model_store.get_iter_first(out parent); model_store.iter_next(ref parent);)
                {
                    bool active_ch;
                    model_store.get(parent, 0, out active_ch);
                    if (active_ch)
                        model_store.set(parent,0,!active_ch);
                }
                plugin.backend.model = id;
            }
        }
        [GtkCallback]
        private void model_selected(TreePath path, TreeViewColumn column)
        {
            model_toggled(path.to_string());
        }
        [GtkCallback]
        private void option_selected(TreePath path, TreeViewColumn column)
        {
            option_toggled(path.to_string());
        }
        [GtkCallback]
        private void layout_remove()
        {
            TreeIter  tree_iter_sel;
            if(selection_current.get_selected(null,out tree_iter_sel))
            {
                list_current.remove(tree_iter_sel);
                update_layouts_from_widget();
            }
        }
        [GtkCallback]
        private void layout_move_up()
        {
            TreeIter sel_iter;
            TreeIter? prev_iter = null;
            if(selection_current.get_selected(null, out sel_iter))
            {
                TreePath path = list_current.get_path(sel_iter);
                if(path.prev() && list_current.get_iter(out prev_iter,path))
                {
                    list_current.swap(sel_iter, prev_iter);
                    update_layouts_from_widget();
                }
            }
        }
        [GtkCallback]
        private void layout_move_down()
        {
            TreeIter sel_iter;
            TreeIter? prev_iter = null;
            if(selection_current.get_selected(null, out sel_iter))
            {
                prev_iter = sel_iter;
                if(list_current.iter_next(ref prev_iter))
                {
                    list_current.swap(sel_iter, prev_iter);
                    update_layouts_from_widget();
                }
            }
        }
        private void update_layouts_from_widget()
        {
            StringBuilder layouts_str = new StringBuilder();
            StringBuilder variants_str = new StringBuilder();
            list_current.foreach((model,path,iter)=>{
                string layout,variant;
                model.get(iter,2,out layout,3,out variant);
                if (layouts_str.len > 0)
                {
                    layouts_str.append_c(',');
                    variants_str.append_c(',');
                }
                layouts_str.append(layout);
                variants_str.append(variant ?? "");
                return false;
            });
            plugin.backend.layout = layouts_str.str;
            plugin.backend.variant = variants_str.str;
        }
    }
    private enum ConfigType
    {
        NONE,
        MODEL,
        LAYOUT,
        VARIANT,
        OPTION_GROUP,
        OPTION
    }
    private enum KeyName
    {
        NONE = 0,
        NAME = 1,
        DESCRIPTION = 2,
    }
    private class XKeyboardConfigParser : Object
    {
        private const MarkupParser parser = {
            visit_start,
            visit_end,
            visit_text,
            null,
            null
        };
        private ConfigType type;
        private string[] element;
        private string[] radio_group;
        private KeyName key_name;
        private ConfigDialog dialog;
        private MarkupParseContext context;
        private bool options_radio;
        private TreeIter parent_iter;
        private TreeIter child_iter;
        public XKeyboardConfigParser (ConfigDialog dialog)
        {
            this.dialog = dialog;
            context = new MarkupParseContext (parser, 0, this, null);
            element = new string[2];
            radio_group = new string[2];
        }
        private void visit_start (MarkupParseContext context, string name, string[] attr_names, string[] attr_values) throws MarkupError
        {
            if (name == "model")
            {
                dialog.model_store.append(out parent_iter);
                type = ConfigType.MODEL;
            }
            else if (name == "layout")
            {
                dialog.layouts_store.append(out parent_iter,null);
                type = ConfigType.LAYOUT;
            }
            else if (name == "variant")
            {
                dialog.layouts_store.append(out child_iter, parent_iter);
                type = ConfigType.VARIANT;
            }
            else if (name == "option")
            {
                dialog.options_store.append(out child_iter, parent_iter);
                type = ConfigType.OPTION;
            }
            else if (name == "name")
                key_name = KeyName.NAME;
            else if (name == "description")
                key_name = KeyName.DESCRIPTION;
            else if (name == "group")
            {
                dialog.options_store.append(out parent_iter, null);
                options_radio = attr_values[0] == "false";
                type = ConfigType.OPTION_GROUP;
            }
        }
        private void visit_end (MarkupParseContext context, string name) throws MarkupError
        {
            if (name == "group")
            {
                dialog.options_store.set(parent_iter,
                                         0,false,
                                         1,options_radio,
                                         2,radio_group[0],
                                         3,dgettext("xkeyboard-config",radio_group[1]),
                                         4,radio_group[0],
                                         5,false);
                options_radio = false;
            }
            else if (name == "variant")
            {
                type = ConfigType.LAYOUT;
                dialog.layouts_store.set(child_iter,
                                         0,"flag-"+radio_group[0],
                                         1,dgettext("xkeyboard-config",element[1]),
                                         2,element[0],
                                         3,radio_group[0]);
            }
            else if (name == "model")
            {
                type = ConfigType.NONE;
                dialog.model_store.set(parent_iter,
                                       0,element[0] == dialog.plugin.backend.model,
                                       1,dgettext("xkeyboard-config",element[1]),
                                       2,element[0]);
            }
            else if(name == "layout")
            {
                type = ConfigType.NONE;
                dialog.layouts_store.set(parent_iter,
                                         0,"flag-"+radio_group[0],
                                         1,dgettext("xkeyboard-config",radio_group[1]),
                                         2,"",
                                         3,radio_group[0]);
            }
            else if (name == "option")
            {
                type = ConfigType.OPTION_GROUP;
                dialog.options_store.set(child_iter,
                                         0,(element[0] in dialog.plugin.backend.options),
                                         1,options_radio,
                                         2,radio_group[0],
                                         3,dgettext("xkeyboard-config",element[1]),
                                         4,element[0],
                                         5,true);
            }
            else if (name == "name" || name == "description")
                key_name = KeyName.NONE;
        }
        private void visit_text (MarkupParseContext context, string text, size_t text_len) throws MarkupError
        {
            if (key_name > KeyName.NONE)
            {
                element[key_name - 1] = text;
                if (type == ConfigType.OPTION_GROUP || type == ConfigType.LAYOUT)
                    radio_group[key_name - 1] = text;
            }
        }
        public bool parse (string markup) throws MarkupError {
            return context.parse (markup, -1);
        }
        public bool try_parse (string markup)
        {
            try {
                parse (markup);
            } catch (Error e) {
                stderr.printf("%s\n",e.message);
            }
            return false;
        }
    }
}
