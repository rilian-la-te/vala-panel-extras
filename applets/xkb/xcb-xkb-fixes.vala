using Xcb;
using Xcb.xkb;

namespace XcbFixes
{
    [Compact, CCode (cname = "xcb_connection_t", free_function = "xcb_disconnect")]
    public class Connection : Xcb.xkb.Connection
    {
        [CCode (cname = "xcb_connect")]
        public extern Connection (string? displayname = null, out int screen = null);
        [CCode (cname = "xcb_xkb_get_kbd_by_name_fixed")]
        public inline void get_kbd_by_name_fixed(DeviceSpec deviceSpec, Gbndetail need, Gbndetail want, bool load, string? keymap_spec = null, string? keycodes_spec = null, string? types_spec = null, string? compat_map_spec = null, string? symbols_spec = null, string? geometry_spec = null)
        {
            ProtocolRequest req = ProtocolRequest();
            req.count = 2;
            req.ext = id;
            req.opcode = 23;
            req.isvoid = 0;
            Posix.iovector[] xcb_parts =  new Posix.iovector[2];
            GetKbdByNameRequest xcb_out = GetKbdByNameRequest();
            /* in the protocol description, variable size fields are followed by fixed size fields */
            void *xcb_aux = null;

            /* Stubs to silence Vala compiler */
            xcb_out.major_opcode = 0;
            xcb_out.minor_opcode = 0;
            xcb_out.length = 0;
            /* end stubs */
            xcb_out.deviceSpec = deviceSpec;
            xcb_out.need = need;
            xcb_out.want = want;
            xcb_out.load = (uint8)load;
            xcb_out.pad0 = 0;
            xcb_out.keymapsSpec = keymap_spec;
            xcb_out.keycodesSpec = keycodes_spec;
            xcb_out.typesSpec = types_spec;
            xcb_out.compatMapSpec = compat_map_spec;
            xcb_out.symbolsSpec = symbols_spec;
            xcb_out.geometrySpec = geometry_spec;
            xcb_out.keymapsSpecLen = (keymap_spec != null) ? (uint8)keymap_spec.length : 0;
            xcb_out.keycodesSpecLen = (keycodes_spec != null) ? (uint8)keycodes_spec.length : 0;
            xcb_out.typesSpecLen = (types_spec != null) ? (uint8)types_spec.length : 0;
            xcb_out.compatMapSpecLen = (compat_map_spec != null) ? (uint8)compat_map_spec.length : 0;
            xcb_out.symbolsSpecLen = (symbols_spec != null) ? (uint8)symbols_spec.length : 0;
            xcb_out.geometrySpecLen = (geometry_spec != null) ? (uint8)geometry_spec.length : 0;

            xcb_parts[0].iov_base = &xcb_out;
            xcb_parts[0].iov_len = 2*sizeof(uint8) + sizeof(uint16);
            xcb_parts[1].iov_len = (int)xcb_out.serialize (out xcb_aux);
            xcb_parts[1].iov_base = (void*) xcb_aux;
            this.send_request(Xcb.RequestFlags.CHECKED, (void*)xcb_parts, req);
        }
        [Compact, CCode (cname = "xcb_xkb_get_kbd_by_name_request_t_fixed",has_type_id = false)]
        private struct GetKbdByNameRequest
        {
            uint8      major_opcode; /**<  */
            uint8      minor_opcode; /**<  */
            uint16     length; /**<  */
            DeviceSpec deviceSpec; /**<  */
            uint16     need; /**<  */
            uint16     want; /**<  */
            uint8      load; /**<  */
            uint8      pad0; /**<  */
            uint8      keymapsSpecLen; /**<  */
            string     keymapsSpec;
            uint8      keycodesSpecLen; /**<  */
            string     keycodesSpec;
            uint8      typesSpecLen; /**<  */
            string     typesSpec;
            uint8      compatMapSpecLen; /**<  */
            string     compatMapSpec;
            uint8      symbolsSpecLen; /**<  */
            string     symbolsSpec;
            uint8      geometrySpecLen; /**<  */
            string     geometrySpec;
            public inline uint serialize(out void* buff)
            {
                /* insert struct into GArray as temporary fix */
                GLib.Array<uint8> arr = new GLib.Array<uint8>(false,true,1);
                arr.append_vals(&deviceSpec,(uint)sizeof(DeviceSpec));
                arr.append_vals(&need,(uint)sizeof(uint16));
                arr.append_vals(&want,(uint)sizeof(uint16));
                arr.append_vals(&load,(uint)sizeof(uint8));
                arr.append_vals(&pad0,(uint)sizeof(uint8));
                arr.append_vals(&keymapsSpecLen,(uint)sizeof(uint8));
                arr.append_vals((void*)keymapsSpec,(keymapsSpec != null) ? keymapsSpec.length : 0);
                arr.append_vals(&keycodesSpecLen,(uint)sizeof(uint8));
                arr.append_vals((void*)keycodesSpec,(keycodesSpec != null) ? keycodesSpec.length : 0);
                arr.append_vals(&typesSpecLen,(uint)sizeof(uint8));
                arr.append_vals((void*)typesSpec,(typesSpec != null) ? typesSpec.length : 0);
                arr.append_vals(&compatMapSpecLen,(uint)sizeof(uint8));
                arr.append_vals((void*)compatMapSpec,(compatMapSpec != null) ? compatMapSpec.length : 0);
                arr.append_vals(&symbolsSpecLen,(uint)sizeof(uint8));
                arr.append_vals((void*)symbolsSpec,(symbolsSpec != null) ? symbolsSpec.length : 0);
                arr.append_vals(&geometrySpecLen,(uint)sizeof(uint8));
                arr.append_vals((void*)geometrySpec,(geometrySpec != null) ? geometrySpec.length : 0);
                /* insert padding. In vala no offsetof() macro exists, and.. It is magic... */
                arr.set_size((uint)padded_size(arr.length));
                buff = (void*)arr.data;
                return arr.length;
            }
            public inline size_t padded_size (size_t size)
            {
                return (((size+3) >> 2) << 2);
            }
        }
    }
}
