import Foundation

enum SDKManagerImageCatalog {
    static func parse(_ output: String, includeDownloads: Bool) throws -> [EmulatorSystemImage] {
        var section: String?
        var sawPackageSection = false
        var images: [String: EmulatorSystemImage] = [:]
        for line in output.split(whereSeparator: \.isNewline) {
            let text = line.trimmingCharacters(in: .whitespaces)
            let heading = text.lowercased()
            if ["installed packages:", "available packages:", "available updates:"].contains(heading) {
                section = heading
                sawPackageSection = true
                continue
            }
            let installed = section == "installed packages:"
            guard installed || (includeDownloads && section == "available packages:"),
                  text.hasPrefix("system-images;") || text.hasPrefix("system-images/") else { continue }
            let columns = text.split(separator: "|", omittingEmptySubsequences: false)
            let id = columns[0].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "/", with: ";")
            let parts = id.components(separatedBy: ";")
            guard columns.count >= 3, parts.count == 4, parts[1].hasPrefix("android-"),
                  !parts[2].isEmpty, !parts[3].isEmpty else {
                throw EmulatorCreationError("Couldn’t read the Android system image entry \(text)")
            }
            guard installed || images[id] == nil else { continue }
            let platform = parts[1]
            let apiLevel = Int(String(platform.dropFirst("android-".count).prefix(while: \.isNumber)))
            images[id] = EmulatorSystemImage(
                id: id, platform: platform, apiLevel: apiLevel, tag: parts[2], abi: parts[3],
                description: columns[2].trimmingCharacters(in: .whitespaces), installed: installed
            )
        }
        guard sawPackageSection else {
            throw EmulatorCreationError("Couldn’t find a package list in sdkmanager’s output. Check the Android SDK Command-line Tools in SDK Manager.")
        }
        return images.values.sorted { $0.id < $1.id }
    }
}
