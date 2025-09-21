![](./icon_s.png)

## Contacts Search

This is an Alfred Workflow that searches and opens Contacts by directly querying the SQLite3 databases on the system.

It allows binding Contact searches to a keyword trigger or hotkey, rather than cluttering general Alfred searches with Contact results.

It also works around a limitation imposed by macOS 26 ("Tahoe") where Spotlight metadata for contacts is no longer searchable, rendering previous file filter-based workflows inoperable.

### Usage Tips

- It's suggested to enable the "Open Contacts in Alfred" option in Features > Contacts, so you can quickly view contact details right from within Alfred. When used in this way, you can press <kbd>ESC</kbd> to return to the search results.
- QuickLook works! Press and release the <kbd>⇧SHIFT</kbd> key from Alfred's result list to preview a contact card.
- Hold the <kbd>⌘COMMAND</kbd> key while actioning a contact to reveal that contact's .abcdp file in Finder.
- Hold the <kbd>⌥OPTION</kbd> key while actioning a contact to open the contact in the native Contacts.app.

### Narrowing Scope

You can limit the search results to a specific AddressBook in the Workflow Configuration area. Leave blank to include all addressbooks found in the default location (`~/Library/Application Support/AddressBook/Sources`)

Additionally, you can choose specific GUIDs to exclude, by adding them to the **Exclusions** field in the config. The GUID is the string of HEX digits in the AddressBook path, e.g. `0414758E-7607-4C67-8EA1-CFDDCB4FDE5C`.

These features can be combined so Alfred returns only the results you desire.

### Credits

Thanks to [FireFingers21](https://www.alfredforum.com/topic/16269-contacts-search-only-with-keyword/page/2/#findComment-122641) for inspiration and the excellent SQL query that was adapted for use here.

### Requirements

The workflow depends on [jq](http://jqlang.org/) for JSON processing. If you're using macOS 15 or later, `jq` is already preinstalled. Otherwise, please install it using your preferred method (probably `brew install jq`).

The workflow also requires Alfred to have Full Disk Access so it can access your AddressBook data.

### Further Discussion

https://www.alfredforum.com/topic/16269-contacts-search-only-with-keyword
