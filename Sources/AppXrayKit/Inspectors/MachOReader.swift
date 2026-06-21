import Foundation

/// A minimal, dependency-free Mach-O reader.
///
/// It parses fat (universal) and thin Mach-O files to extract the CPU
/// architectures and the dynamic libraries the binary links against
/// (`LC_LOAD_DYLIB`, `LC_LOAD_WEAK_DYLIB`, `LC_REEXPORT_DYLIB`), flagging links
/// that resolve under `/System/Library/PrivateFrameworks` as private-API usage.
struct MachOReader {

    struct Result {
        var architectures: [String]
        var libraries: [LinkedLibrary]
    }

    // Magic numbers
    private static let FAT_MAGIC: UInt32 = 0xcafe_babe
    private static let FAT_MAGIC_64: UInt32 = 0xcafe_babf
    private static let MH_MAGIC: UInt32 = 0xfeed_face
    private static let MH_MAGIC_64: UInt32 = 0xfeed_facf
    private static let MH_CIGAM: UInt32 = 0xcefa_edfe
    private static let MH_CIGAM_64: UInt32 = 0xcffa_edfe

    // Load commands
    private static let LC_REQ_DYLD: UInt32 = 0x8000_0000
    private static let LC_LOAD_DYLIB: UInt32 = 0x0000_000c
    private static let LC_LOAD_WEAK_DYLIB: UInt32 = 0x0000_0018 | 0x8000_0000
    private static let LC_REEXPORT_DYLIB: UInt32 = 0x0000_001f | 0x8000_0000

    let url: URL

    /// Parse the Mach-O at `url`. Returns `nil` if it is not a Mach-O file.
    func read() -> Result? {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe), data.count >= 4 else {
            return nil
        }

        var archSet: [String] = []
        var libs: [LinkedLibrary] = []
        var seenLibPaths = Set<String>()

        let magic = data.u32(at: 0, bigEndian: false) ?? 0

        var sliceOffsets: [Int] = []
        if magic == Self.FAT_MAGIC || magic == Self.FAT_MAGIC_64 {
            // Fat headers are big-endian on disk.
            let is64 = (magic == Self.FAT_MAGIC_64)
            guard let nArch = data.u32(at: 4, bigEndian: true) else { return nil }
            var cursor = 8
            for _ in 0..<min(nArch, 64) {
                if is64 {
                    guard let cpu = data.u32(at: cursor, bigEndian: true),
                          let sub = data.u32(at: cursor + 4, bigEndian: true),
                          let off = data.u64(at: cursor + 8, bigEndian: true) else { break }
                    archSet.append(Self.archName(cpuType: cpu, cpuSubtype: sub))
                    sliceOffsets.append(Int(off))
                    cursor += 32
                } else {
                    guard let cpu = data.u32(at: cursor, bigEndian: true),
                          let sub = data.u32(at: cursor + 4, bigEndian: true),
                          let off = data.u32(at: cursor + 8, bigEndian: true) else { break }
                    archSet.append(Self.archName(cpuType: cpu, cpuSubtype: sub))
                    sliceOffsets.append(Int(off))
                    cursor += 20
                }
            }
        } else if [Self.MH_MAGIC, Self.MH_MAGIC_64, Self.MH_CIGAM, Self.MH_CIGAM_64].contains(magic) {
            sliceOffsets = [0]
        } else {
            return nil
        }

        for off in sliceOffsets {
            guard let slice = parseSlice(data, at: off) else { continue }
            if sliceOffsets == [0] {
                archSet.append(slice.arch)
            }
            for lib in slice.libraries where !seenLibPaths.contains(lib.path) {
                seenLibPaths.insert(lib.path)
                libs.append(lib)
            }
        }

        return Result(architectures: dedupePreservingOrder(archSet),
                      libraries: libs.sorted { $0.path < $1.path })
    }

    private struct Slice {
        var arch: String
        var libraries: [LinkedLibrary]
    }

    private func parseSlice(_ data: Data, at sliceOffset: Int) -> Slice? {
        guard let magic = data.u32(at: sliceOffset, bigEndian: false) else { return nil }
        let is64: Bool
        let swap: Bool
        switch magic {
        case Self.MH_MAGIC_64: is64 = true; swap = false
        case Self.MH_CIGAM_64: is64 = true; swap = true
        case Self.MH_MAGIC: is64 = false; swap = false
        case Self.MH_CIGAM: is64 = false; swap = true
        default: return nil
        }

        guard let cpu = data.u32(at: sliceOffset + 4, bigEndian: swap),
              let sub = data.u32(at: sliceOffset + 8, bigEndian: swap),
              let ncmds = data.u32(at: sliceOffset + 16, bigEndian: swap) else { return nil }

        let headerSize = is64 ? 32 : 28
        var cmdOffset = sliceOffset + headerSize
        var libraries: [LinkedLibrary] = []

        for _ in 0..<min(ncmds, 4096) {
            guard let cmd = data.u32(at: cmdOffset, bigEndian: swap),
                  let cmdSize = data.u32(at: cmdOffset + 4, bigEndian: swap),
                  cmdSize >= 8 else { break }

            if cmd == Self.LC_LOAD_DYLIB || cmd == Self.LC_LOAD_WEAK_DYLIB || cmd == Self.LC_REEXPORT_DYLIB {
                if let nameOff = data.u32(at: cmdOffset + 8, bigEndian: swap) {
                    let strStart = cmdOffset + Int(nameOff)
                    let strEnd = cmdOffset + Int(cmdSize)
                    if let path = data.cString(from: strStart, upTo: strEnd) {
                        let isWeak = (cmd == Self.LC_LOAD_WEAK_DYLIB)
                        libraries.append(Self.classify(path: path, isWeak: isWeak))
                    }
                }
            }

            cmdOffset += Int(cmdSize)
        }

        return Slice(arch: Self.archName(cpuType: cpu, cpuSubtype: sub), libraries: libraries)
    }

    static func classify(path: String, isWeak: Bool) -> LinkedLibrary {
        let isPrivate = path.contains("/System/Library/PrivateFrameworks/")
        let isSystem = path.hasPrefix("/System/") || path.hasPrefix("/usr/lib/")
            || path.hasPrefix("/Library/Apple/")
        return LinkedLibrary(path: path, isSystem: isSystem, isPrivateFramework: isPrivate, isWeak: isWeak)
    }

    static func archName(cpuType: UInt32, cpuSubtype: UInt32) -> String {
        switch cpuType {
        case 0x0100_0007: return "x86_64"
        case 7: return "i386"
        case 0x0100_000c: return (cpuSubtype & 0xff) == 2 ? "arm64e" : "arm64"
        case 12: return "arm"
        default: return "cputype(\(cpuType))"
        }
    }
}

// MARK: - Byte reading

private extension Data {
    func u32(at off: Int, bigEndian: Bool) -> UInt32? {
        guard off >= 0, off + 4 <= count else { return nil }
        let base = startIndex + off
        var v: UInt32 = 0
        for i in 0..<4 { v |= UInt32(self[base + i]) << (8 * i) }
        return bigEndian ? v.byteSwapped : v
    }

    func u64(at off: Int, bigEndian: Bool) -> UInt64? {
        guard off >= 0, off + 8 <= count else { return nil }
        let base = startIndex + off
        var v: UInt64 = 0
        for i in 0..<8 { v |= UInt64(self[base + i]) << (8 * i) }
        return bigEndian ? v.byteSwapped : v
    }

    func cString(from start: Int, upTo end: Int) -> String? {
        guard start >= 0, start < end, end <= count else { return nil }
        var bytes: [UInt8] = []
        var i = startIndex + start
        let limit = startIndex + end
        while i < limit {
            let b = self[i]
            if b == 0 { break }
            bytes.append(b)
            i += 1
        }
        return bytes.isEmpty ? nil : String(decoding: bytes, as: UTF8.self)
    }
}

private func dedupePreservingOrder(_ items: [String]) -> [String] {
    var seen = Set<String>()
    return items.filter { seen.insert($0).inserted }
}
