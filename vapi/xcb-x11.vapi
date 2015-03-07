[CCode (cprefix = "X", cheader_filename = "X11/Xlib-xcb.h")]
namespace Xcb.X11
{
    [CCode (cname = "XEventQueueOwner")]
    public enum EventQueueOwner
    {
        [CCode (cname = "XlibOwnsEventQueue")]
        XLIB,
        [CCode (cname = "XCBOwnsEventQueue")]
        XCB
    }
    [CCode (cname = "XGetXCBConnection")]
    Xcb.Connection get_xcb_connection(X11.Display display);
    [CCode (cname = "XSetQueueOwner")]
    void set_event_queue_owner(X11.Display dpy, EventQueueOwner owner);
}
