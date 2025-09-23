#!/usr/bin/env swift

import Foundation
import SQLite3
import AppKit

func appURL(for bundleID: String) -> URL? {
    NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
}

let DEBUG = ProcessInfo.processInfo.environment["DEBUG"] == "1"
func dbg(_ msg: String) {
    if DEBUG {
        FileHandle.standardError.write(Data("🪵DEBUG: \(msg)\n".utf8))
    }
}

final class SQLiteStatement {
    private var stmt: OpaquePointer?
    init(_ stmt: OpaquePointer) { self.stmt = stmt }

    func reset() { sqlite3_reset(stmt) }

    func bind(_ index: Int32, _ value: String) {
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(stmt, index, value, -1, SQLITE_TRANSIENT)
    }

    func bind(_ index: Int32, _ value: Int) {
        sqlite3_bind_int(stmt, index, Int32(value))
    }

    func step() throws {
        let rc = sqlite3_step(stmt)
        if rc != SQLITE_DONE {
            let db = sqlite3_db_handle(stmt)
            let err = String(cString: sqlite3_errmsg(db))
            throw NSError(domain: "SQLite", code: Int(rc), userInfo: [NSLocalizedDescriptionKey: err])
        }
    }

    deinit {
        if let s = stmt { sqlite3_finalize(s) }
        stmt = nil
    }
}

let homeURL = FileManager.default.homeDirectoryForCurrentUser
let dbURL = homeURL
    .appendingPathComponent("Library")
    .appendingPathComponent("Application Support")
    .appendingPathComponent("Alfred")
    .appendingPathComponent("Databases")
    .appendingPathComponent("clipboard.alfdb")

guard FileManager.default.fileExists(atPath: dbURL.path) else {
    fputs("could not access Alfred clipboard database\n", stderr)
    exit(1)
}

let contactsAppURL = appURL(for: "com.apple.AddressBook")
let contactsAppPath = contactsAppURL?.path ?? ""

let now = Int(Date().timeIntervalSince1970)
var refTs = now - 978307200 // epoch y2k offset

var db: OpaquePointer?
if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
    fputs("could not open database\n", stderr)
    exit(1)
}
defer { sqlite3_close(db) }

let sql = """
INSERT INTO clipboard ( item, ts, app, apppath, dataType )
VALUES ( ?, ?, 'Contacts', ?, 0 );
"""
var rawStmt: OpaquePointer?
if sqlite3_prepare_v2(db, sql, -1, &rawStmt, nil) != SQLITE_OK || rawStmt == nil {
    fputs("failed to prepare statement\n", stderr)
    exit(1)
}
let statement = SQLiteStatement(rawStmt!)

guard CommandLine.arguments.count > 1 else {
    fputs("usage: \(CommandLine.arguments[0]) \"multiline text\"\n", stderr)
    exit(1)
}

let input = CommandLine.arguments[1]
let lines = input.split(separator: "\n", omittingEmptySubsequences: false).reversed()

for line in lines {
    let str = String(line)
    if str.isEmpty { continue }

    statement.reset()
    statement.bind(1, str)
    statement.bind(2, refTs)
    statement.bind(3, contactsAppPath)

    do {
        try statement.step()
        dbg("added [\(str)] to clipboard history")
    } catch {
        fputs("insert failed: \(error)\n", stderr)
    }

    refTs += 1
}
