//
//  Logic.swift
//  FileMind
//
//  Created by WessoBesso on 2025-04-29.
//


//import Foundation
//import Combine
//
//class FileSearchLogic: ObservableObject {
//    @Published var indexedFiles: [URL] = []
//
//    init() {
//        DispatchQueue.global(qos: .userInitiated).async {
//            self.indexAllFiles()
//        }
//    }
//
//    private func indexAllFiles() {
//        let fileManager = FileManager.default
//        let homeURL = fileManager.homeDirectoryForCurrentUser
//
//        guard let enumerator = fileManager.enumerator(at: homeURL, includingPropertiesForKeys: nil) else { return }
//
//        var results: [URL] = []
//
//        for case let fileURL as URL in enumerator {
//            results.append(fileURL)
//        }
//
//        DispatchQueue.main.async {
//            self.indexedFiles = results
//            print("✅ Indexed \(results.count) files")
//        }
//    }
//
//    func searchFiles(for query: String) -> [URL] {
//        let lowerQuery = query.lowercased()
//        return indexedFiles.filter {
//            $0.lastPathComponent.lowercased().contains(lowerQuery)
//        }
//    }
//}
