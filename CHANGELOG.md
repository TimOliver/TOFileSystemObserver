x.y.z Release Notes (yyyy-MM-dd)
=============================================================

0.1.0 Release Notes (2026-05-04)
=============================================================

### Breaking

* Minimum platform requirements raised to iOS 11.0 and macOS 10.13. The library's
  Files-app integration premise and APFS extended-attribute usage have always
  required these floors in practice; they are now stated explicitly.
* `-[NSURL to_setFileSystemUUID:]` now returns `BOOL` (previously `void`) so
  callers can detect xattr write failures. Existing call sites that ignore
  the return value continue to compile.
* `-[NSURL to_generateFileSystemUUID]` is now annotated `nullable` and returns
  `nil` when the underlying xattr write fails, instead of returning a UUID
  that was never persisted to disk.
* `TOFileSystemPresenter`'s `-performCoordinatedRead:` and
  `-performCoordinatedWrite:` methods have been removed. Their only callers
  were inside the library and have been replaced with direct, simpler logic.
* `TOFileSystemItemMapTable` no longer conforms to `NSFastEnumeration`.
  Iterate the new `-allItems` snapshot accessor instead.

### Added

* `-[NSURL to_setFileSystemUUIDIfAbsent:]` — atomic set-if-absent UUID write
  using `XATTR_CREATE`. Replaces the previous read-then-write coordination
  for the initial UUID assignment path.
* `TOFileSystemItemMapTable -allItems` — point-in-time snapshot accessor
  that's safe to iterate while the table is being mutated.
* `TOFileSystemObserver.directoryItem` is now actually implemented (the
  property was previously declared but auto-synthesized to always return
  `nil`).
* Threading contract for `-addNotificationBlock:` is now documented in the
  public header. Notification blocks fire on a background queue.

### Fixed

* `getxattr` / `setxattr` return values are now checked. UUID reads no
  longer interpret uninitialised stack memory as a UUID on filesystems
  that don't support extended attributes; UUID writes no longer silently
  fail.
* `-[NSURL to_setFileSystemUUID:]` no longer crashes when passed `nil` or
  an empty string (`strlen(NULL)`).
* `-[NSURL to_isCopying]` now returns `NO` when the file's modification
  date is unreadable. Previously it returned `YES` and consumers would
  treat the file as "still copying" indefinitely.
* `-[NSURL to_numberOfSubItems]` now falls back to `lstat` when the
  filesystem reports `DT_UNKNOWN` (NFS, FAT and similar). Previously the
  count was silently wrong on those filesystems.
* Notification-token dispatch now iterates a snapshot of the underlying
  hash table, so a block that invalidates another token mid-dispatch can
  no longer crash or skip in-flight notifications.
* `TOFileSystemItemList -synchronizeWithDisk` removes deleted items in
  reverse index order. Previously, removing two non-contiguous deletions
  could mis-target items because indices shifted between removals.
* The full-scan `WillBegin` / `DidComplete` notifications now fire on
  empty directories. Previously the scan returned early without sending
  either, leaving consumers hung waiting for "scan complete".
* Cross-instance scan stalls eliminated. UUID writes from one
  `TOFileSystemObserver` instance no longer serialise behind another
  observer's queue. Tests that previously took ~8 seconds now complete
  in under a second.
* `TOFileSystemPresenter -stop` now drains any buffered file events and
  resets internal timer state, so a subsequent `-start` does not replay
  events from before the stop.
* Symlinked directories are no longer recursed into during scans. A
  circular directory symlink would previously loop the scan indefinitely.
* Removed the dead/broken `-[TOFileSystemItem regenerateUUID]` private
  method.

0.0.4 Release Notes (2022-01-23)
=============================================================

### Enhancements

* Replaced dispatch barriers in `TOFileSystemItem` with threading locks to minimize GCD queue creation.
* General internal code/commenting cleanup and refinement.

### Fixed

* An incorrect casting breaking the visible number of items inside of a directory.
* A crash that can occur if querying for the number of files in a deleted folder.
* A linking issue when importing the library via SPM on macOS.

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
