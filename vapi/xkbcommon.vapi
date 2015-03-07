[CCode (cprefix = "XKB_", lower_case_cprefix = "xkb_", cheader_filename = "xkbcommon/xkbcommon.h")]
namespace Xkb
{
    [Flags]
    [CCode (cname = "xkb_keysym_flags", cprefix = "XKB_KEYSYM_")]
    public enum KeysymFlags
    {
        NO_FLAGS = 0,
        CASE_INSENSITIVE = 1
    }
    [CCode (cname = "xkb_log_level")]
    public enum LogLevel
    {
        CRITICAL,
        ERROR,
        WARNING,
        INFO,
        DEBUG
    }
    [Compact]
    [CCode (cname = "xkb_keysym_t", lower_case_cprefix = "xkb_keysym_")]
    public class Keysym : uint32
    {
        public static Keysym from_name(string name, KeysymFlags flags = KeysymFlags.NO_FLAGS);
        public int get_name(out char[] name, size_t size);
        public int to_utf8(out char[] name, size_t size);
        public uint32 to_utf32();
    }
    [Flags]
    [CCode (cname = "xkb_context_flags", cprefix = "XKB_CONTEXT_")]
    public enum ContextFlags
    {
        NO_FLAGS,
        NO_DEFAULT_INCLUDES,
        NO_ENVIRONMENT_NAMES
    }
    [Compact]
    [CCode (cname = "xkb_context", lower_case_cprefix = "xkb_context_", ref_function = "xkb_context_ref", unref_function = "xkb_context_unref")]
    public class Context
    {
        [CCode (cname = "xkb_context_new")]
        public Context(ContextFlags flags = ContextFlags.NO_FLAGS);
        public Context @ref();
        public void unref();
        public void* user_data
        {
            [CCode (cname = "xkb_context_get_user_data")]
            get;
            [CCode (cname = "xkb_context_set_user_data")]
            set;
        }
        public LogLevel log_level
        {
            [CCode (cname = "xkb_context_get_log_level")]
            get;
            [CCode (cname = "xkb_context_set_log_level")]
            set;
        }
        public int log_verbosity
        {
            [CCode (cname = "xkb_context_get_log_verbosity")]
            get;
            [CCode (cname = "xkb_context_set_log_verbosity")]
            set;
        }
        public bool include_path_append(string path);
        public bool include_path_append_default();
        public bool include_path_reset_defaults();
        public void include_path_clear();
        public uint num_include_paths();
        public unowned string include_path_get(uint index);
        public delegate void LogFn (LogLevel level, string format, ...);
        public void set_log_fn(LogFn func);
    }
    [CCode (cname = "xkb_rule_names")]
    public struct RuleNames
    {
        public string rules;
        public string model;
        public string layout;
        public string variant;
        public string options;
    }
    [Flags]
    [CCode (cname = "xkb_keymap_compile_flags", cprefix = "XKB_KEYMAP_COMPILE_")]
    public enum KeymapCompileFlags
    {
        NO_FLAGS
    }
    [CCode (cname = "xkb_keymap_format")]
    public enum KeymapFormat
    {
        TEXT_V1
        [CCode (cname = "XKB_KEYMAP_USE_ORIGINAL_FORMAT")]
        KeymapFormat use_original_format();
    }
    [Compact]
    [CCode (cname = "xkb_keycode_t", cprefix = "XKB_KEYCODE_", lower_case_cprefix = "xkb_keycode_")]
    public class Keycode : uint32
    {
        public static Keycode MAX;
        public static Keycode INVALID;
        public bool is_legal_ext();
        public bool is_legal_x11();
    }
    [Compact]
    [CCode (cname = "xkb_mod_index_t", cprefix = "XKB_MOD_")]
    public class ModIndex : uint32
    {
        public static ModIndex INVALID;
    }
    [Compact]
    [CCode (cname = "xkb_mod_mask_t")]
    public class ModMask : uint32 {}
    [Compact]
    [CCode (cname = "xkb_layout_index_t", cprefix = "XKB_LAYOUT_")]
    public class LayoutIndex : uint32
    {
        public static LayoutIndex INVALID;
    }
    [Compact]
    [CCode (cname = "xkb_layout_mask_t")]
    public class LayoutMask : uint32 {}
    [Compact]
    [CCode (cname = "xkb_led_index_t", cprefix = "XKB_LED_")]
    public class LEDIndex : uint32
    {
        public static LEDIndex INVALID;
    }
    [Compact]
    [CCode (cname = "xkb_level_index_t", cprefix = "XKB_LEVEL_")]
    public class LevelIndex : uint32
    {
        public static LevelIndex INVALID;
    }
    [Compact]
    [Immutable]
    [CCode (cname = "xkb_keymap", lower_case_cprefix = "xkb_keymap_", ref_function = "xkb_keymap_ref", unref_function = "xkb_keymap_unref")]
    public class Keymap
    {
        [CCode (cname = "xkb_keymap_new_from_names")]
        public Keymap.from_names(Context context, RuleNames names, KeymapCompileFlags flags = KeymapCompileFlags.NO_FLAGS);
        [CCode (cname = "xkb_keymap_new_from_file")]
        public Keymap.from_file(Context context, Posix.FILE file, KeymapFormat format = KeymapFormat.TEXT_V1, KeymapCompileFlags flags = KeymapCompileFlags.NO_FLAGS);
        [CCode (cname = "xkb_keymap_new_from_string")]
        public Keymap.from_string(Context context, string str, KeymapFormat format = KeymapFormat.TEXT_V1, KeymapCompileFlags flags = KeymapCompileFlags.NO_FLAGS);
        [CCode (cname = "xkb_keymap_new_from_buffer", array_length = true, array_length_type = "size_t" array_length_pos = 2.1)]
        public Keymap.from_buffer(Context context, uint8[] buffer, KeymapFormat format = KeymapFormat.TEXT_V1, KeymapCompileFlags flags = KeymapCompileFlags.NO_FLAGS);
        public Keymap @ref();
        public void unref();
        public string get_as_string(KeymapFormat format = KeymapFormat.TEXT_V1);
        public Keycode min_keycode();
        public Keycode max_keycode();
        [CCode (cname = "xkb_keymap_key_iter_t", delegate_target = true, delegate_target_pos = 1.9)]
        public delegate void IterFunc(Keycode key);
        [CCode (cname "xkb_keymap_key_for_each")]
        public void @foreach(IterFunc f);
        public ModIndex num_mods();
        public unowned string mod_get_name(ModIndex idx);
        public ModIndex mod_get_index(string name);
        public LayoutIndex num_layouts();
        public unowned string layout_get_name(LayoutIndex idx);
        public LayoutIndex layout_get_index(string name);
        public LEDIndex num_leds();
        public unowned string led_get_name(LEDIndex idx);
        public LEDIndex led_get_index(string name);
        public LayoutIndex num_layouts_by_key(Keycode key);
        public LevelIndex num_levels_by_key(Keycode key);
        [CCode (array_length = false)]
        public int key_get_syms_by_level(Keycode key, LayoutIndex layout, LevelIndex level, out Keysym[] syms);
        public bool key_repeats(Keycode key);
    }
    [Flags]
    [CCode (cname = "xkb_state_component", cprefix = "XKB_STATE_")]
    public enum StateComponent
    {
        MODS_DEPRESSED,
        MODS_LATCHED,
        MODS_LOCKED,
        MODS_EFFECTIVE,
        LAYOUT_DEPRESSED,
        LAYOUT_LATCHED,
        LAYOUT_LOCKED,
        LAYOUT_EFFECTIVE,
        LEDS
    }
    [CCode (cname = "xkb_key_direction", cprefix = "XKB_KEY_")]
    public enum KeyDirection
    {
        UP,
        DOWN
    }
    [Flags]
    [CCode (cname = "xkb_state_match", cprefix = "XKB_STATE_MATCH_")]
    public enum StateMatch
    {
        ANY,
        ALL,
        NON_EXCLUSIVE
    }
    [Compact]
    [CCode (cname = "xkb_state", lower_case_cprefix = "xkb_state_", ref_function = "xkb_state_ref", unref_function = "xkb_state_unref")]
    public class State
    {
        [CCode (cname = "xkb_state_new")]
        public State(Keymap keymap);
        public State @ref();
        public void unref();
        public Keymap get_keymap();
        public StateComponent update_key(Keycode key, KeyDirection direction);
        public StateComponent update_mask(ModMask depressed_mods, ModMask latched_mods, ModMask locked_mods, LayoutMask depressed_layout, LayoutMask latched_layout, LayoutMask locked_layout);
        [CCode (array_length = false)]
        public int key_get_syms(Keycode key, out Keysym[] syms);
        public int key_get_utf8(Keycode key, uint8[] buffer, size_t size);
        public uint32 key_get_utf32(Keycode key);
        public Keysym key_get_one_sym(Keycode key);
        public LayoutIndex key_get_layout(Keycode key);
        public LevelIndex key_get_level(Keycode key);
        public ModMask serialize_mods (StateComponent component);
        public LayoutMask serialize_layout(StateComponent component);
        public bool mod_name_is_active(string name, StateComponent component);
        public int mod_names_are_active(string name, StateComponent component, StateMatch match, ...);
        public bool mod_index_is_active(ModIndex idx, StateComponent component);
        public int mod_indices_are_active(ModIndex idx, StateComponent component, StateMatch match, ...);
        public bool mod_index_is_consumed(Keycode key, ModIndex idx);
        public ModMask mod_mask_remove_consumed(Keycode key, ModMask mask);
        public ModMask key_get_consumed_mods(Keycode key);
        public bool led_name_is_active(string name);
        public bool led_index_is_active(LEDIndex idx);
    }
}
[CCode (cprefix = "XKB_MOD_NAME_", cheader_filename = "xkbcommon/xkbcommon-names.h")]
namespace Xkb.ModName
{
    public const string CAPS;
    public const string SHIFT;
    public const string CTRL;
    public const string ALT;
    public const string NUM;
    public const string LOGO;
}
[CCode (cprefix = "XKB_LED_NAME_", cheader_filename = "xkbcommon/xkbcommon-names.h")]
namespace Xkb.LEDName
{
    public const string CAPS;
    public const string SCROLL;
    public const string NUM;
}
[CCode (cprefix = "XKB_COMPOSE_", lower_case_cprefix = "xkb_compose_", cheader_filename = "xkbcommon/xkbcommon-compose.h")]
namespace Xkb.Compose
{
    [Flags]
    [CCode (cname = "xkb_compose_compile_flags", cprefix = "XKB_COMPOSE_COMPILE_")]
    public enum CompileFlags
    {
        NO_FLAGS
    }
    [CCode (cname = "xkb_compose_format")]
    public enum Format
    {
        TEXT_V1
    }
    [Flags]
    [CCode (cname = "xkb_compose_state_flags", cprefix = "XKB_COMPOSE_STATE_")]
    public enum StateFlags
    {
        NO_FLAGS
    }
    [CCode (cname = "xkb_compose_feed_result", cprefix = "XKB_COMPOSE_FEED_")]
    public enum FeedResult
    {
        IGNORED,
        ACCEPTED
    }
    [CCode (cname = "xkb_compose_status", cprefix = "XKB_COMPOSE_")]
    public enum Status
    {
        NOTHING,
        COMPOSING,
        COMPOSED,
        CANCELLED
    }
    [Compact]
    [Immutable]
    [CCode (cname = "xkb_compose_table", lower_case_cprefix = "xkb_compose_table_", ref_function = "xkb_compose_table_ref", unref_function = "xkb_compose_table_unref")]
    public class Table
    {
        [CCode (cname = "xkb_compose_table_new_from_locale")]
        public Table.from_locale(Xkb.Context context, string locale, CompileFlags flags);
        [CCode (cname = "xkb_compose_table_new_from_file")]
        public Table.from_file(Xkb.Context context, Posix.FILE file, string locale, Format format, CompileFlags flags);
        [CCode (cname = "xkb_compose_table_new_from_buffer", array_length = true, array_length_type = "size_t" array_length_pos = 2.1)]
        public Table.from_buffer(Xkb.Context context, uint8[] buffer, string locale, Format format, CompileFlags flags);
        public Table @ref();
        public void unref();
    }
    [Compact]
    [CCode (cname = "xkb_compose_state", lower_case_cprefix = "xkb_compose_state_", ref_function = "xkb_compose_state_ref", unref_function = "xkb_compose_state_unref")]
    public class State
    {
        [CCode (cname = "xkb_compose_state_new")]
        public State (Table table, StateFlags flags);
        public State @ref();
        public void unref();
        public Table get_compose_table();
        public FeedResult feed (Xkb.Keysym sym);
        public void reset();
        public Status get_status();
        public int get_utf8(uint8[] buffer, size_t size);
        public Xkb.Keysym get_one_sym();
    }
}
