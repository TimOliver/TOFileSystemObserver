x.y.z Release Notes (yyyy-MM-dd)
=============================================================

0.0.3 Release Notes (2020-02-24)
=============================================================

### Added

* Public, thread-safe API access for accessing the UUID string of an observed item, 
    and/or its parent directory.

### Fixed

* A thread coordinating issue where file UUIDs might not have
    been set yet upon first access.
* An issue where proper UUIDs were not being generated before 
    adding items as children to list objects.
* An issue where deleting an item in Files.app would make the 
    `.Trash` folder become treated like an official item.

0.0.2 Release Notes (2020-02-11)
=============================================================

### Enhancements

* Exposed full system scans as a property on `TOFileSystemChanges` in order to let
    observing objects defer work until the scan is complete.

### Fixed

* A bug where files moved below the sub-directory level limit weren't treated as deleted.
* A bug where specifying a sub-directory limit would result in an infinite loop.
* A bug where renaming/moving a file wouldn't be properly updated in the main graph.
* A bug where items marked as 'skipped' weren't being handled as such.
* A bug where files created during the initial scan would be permanently left in the 'copying' state.
* A bug where files of the incorrect sub-directory level limit were still being accessed.

0.0.1 Release Notes (2020-01-30)
=============================================================

* Initial Release! 🎉
