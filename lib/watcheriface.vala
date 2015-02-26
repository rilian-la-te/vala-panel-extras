namespace StatusNotifier
{
	[DBus (name = "org.kde.StatusNotifierWatcher")]
	public interface WatcherIface: Object
	{
		/* Signals */
		public signal void status_notifier_item_registered(out string item);
		public signal void status_notifier_host_registered();
		public signal void status_notifier_item_unregistered(out string item);
		public signal void status_notifier_host_unregistered();
		/* Public properties */
		public abstract string[] registered_status_notifier_items
		{owned get;protected set;}
		public abstract bool is_status_notifier_host_registered
		{get;}
		public abstract int protocol_version
		{get;}
		/* Public methods */
		public abstract void register_status_notifier_item(string service) throws IOError;
		public abstract void register_status_notifier_host(string service) throws IOError;
	}
}
