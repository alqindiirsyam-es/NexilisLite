//
//  sqlite3.h (shim)
//  NexilisLite / FMDB (SwiftPM only)
//
//  SQLCipher is distributed as an XCFramework, so its headers live under
//  <SQLCipher/sqlite3.h>. FMDB's implementation files import the unqualified
//  <sqlite3.h>, which would otherwise resolve to the SDK's stock sqlite3 —
//  the one WITHOUT sqlite3_key/sqlite3_rekey.
//
//  This directory is put on the FMDB target's header search path (see
//  Package.swift), so the unqualified import lands here and is forwarded to
//  SQLCipher. That keeps the vendored FMDB sources identical to the ones
//  CocoaPods installs for the `FMDB/SQLCipher` subspec.
//
//  Private to the FMDB target; not exported.
//

#import <SQLCipher/sqlite3.h>
