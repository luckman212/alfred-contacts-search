![](./icon_s.png)

## Contacts Search

This is an Alfred Workflow that searches and opens Contacts by directly querying the SQLite3 databases on the system.

It allows binding Contact searches to a keyword trigger or hotkey, rather than cluttering general Alfred searches with Contact results.

It also works around a limitation imposed by macOS 26 ("Tahoe") where Spotlight metadata for contacts is no longer searchable, rendering previous file filter-based workflows inoperable.

##### Usage Tips

- It's suggested to enable the "Open Contacts in Alfred" option in Features > Contacts, so you can quickly view contact details right from within Alfred. When used in this way, you can press <kbd>ESC</kbd> to return to the search results.
- QuickLook works! Press and release the <kbd>⇧SHIFT</kbd> key from Alfred's result list to preview a contact card.
- Hold the <kbd>⌘COMMAND</kbd> key while actioning a contact to reveal that contact's .abcdp file in Finder.
- Hold the <kbd>⌥OPTION</kbd> key while actioning a contact to open the contact in the native Contacts.app.

##### Credits

Thanks to [FireFingers21](https://www.alfredforum.com/topic/16269-contacts-search-only-with-keyword/page/2/#findComment-122641) for inspiration and the excellent SQL query that was adapted for use here.

##### Requirements

The workflow depends on [`jq`](http://jqlang.org/) for JSON processing. If needed, please install this using your preferred method (probably `brew install jq`). It also almost certainly requires Alfred to have Full Disk Access.

##### Further Discussion

https://www.alfredforum.com/topic/16269-contacts-search-only-with-keyword
