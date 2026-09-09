//
//  ileManager+Extensions.swift
//  FileMind
//
//  Created by WessoBesso on 2025-05-15.
//

import Foundation

extension FileManager {
    func recursivelyListAllFiles() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let folders = ["Documents", "Downloads", "Desktop", "Pictures", "Movies", "Music"]
        var urls: [URL] = []

        for folder in folders {
            let dirURL = home.appendingPathComponent(folder)
            guard let enumerator = enumerator(at: dirURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else { continue }

            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                    if resourceValues.isRegularFile == true {
                        urls.append(fileURL)
                    }
                } catch {
                    continue
                }
            }
        }
        return urls
    }
}
