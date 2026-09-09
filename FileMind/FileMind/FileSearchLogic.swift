//
//  FileSearchLogic.swift
//  FileMind
//
//  Created by WessoBesso on 2025-04-30.
//

import Foundation
import Combine
import AppKit

struct FileSearchResult: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let isDirectory: Bool
}

class FileSearchLogic: NSObject, ObservableObject, NSMetadataQueryDelegate {
    @Published var searchResults: [FileSearchResult] = []

    private var metadataQuery: NSMetadataQuery?
    private let userVisibleFolders = ["Documents", "Downloads", "Desktop", "Pictures", "Movies", "Music"]

    func searchFiles(for query: String, in folders: [URL] = [], excluding excludedFolders: Set<URL> = [], deepSearch: Bool = false) {
        print("searchFiles called with query: '\(query)', deepSearch: \(deepSearch)")

        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else {
            print("Empty query")
            stopAndClearQuery()
            DispatchQueue.main.async { self.searchResults = [] }
            return
        }

        stopAndClearQuery()

        let query = NSMetadataQuery()
        self.metadataQuery = query
        query.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(queryDidUpdate(_:)), name: .NSMetadataQueryDidUpdate, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryDidFinish(_:)), name: .NSMetadataQueryDidFinishGathering, object: query)

        var searchScopes: [Any] = []

        if deepSearch {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: "/") {
                let fullDiskFolders = contents.map { URL(fileURLWithPath: "/" + $0) }
                let filtered = fullDiskFolders.filter { !excludedFolders.contains($0) }
                searchScopes = filtered.map { $0.path }
                print("DeepSearch scope: \(searchScopes)")
            } else {
                searchScopes = [NSMetadataQueryLocalComputerScope]
                print("DeepSearch fallback: entire disk")
            }
        } else {
            let userHome = FileManager.default.homeDirectoryForCurrentUser
            searchScopes = userVisibleFolders.map { userHome.appendingPathComponent($0).path }
            print("Prioritized folders scope: \(searchScopes)")
        }

        query.searchScopes = searchScopes

        let typeValues = [
            "public.data", "public.content", "public.image",
            "public.audio", "public.movie", "public.text", "public.folder"
        ]

        let namePredicate = NSPredicate(format: "%K LIKE[cd] %@", NSMetadataItemFSNameKey, "\(trimmedQuery)*")
        let typePredicates = typeValues.map {
            NSPredicate(format: "%K == %@", NSMetadataItemContentTypeTreeKey, $0)
        }
        let typePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: typePredicates)
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [namePredicate, typePredicate])

        query.predicate = combinedPredicate
        query.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemFSNameKey, ascending: true)]

        print("Predicate set: \(combinedPredicate)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let started = query.start()
            print(started ? "Query started" : "Failed to start query")
        }
    }

    func stopAndClearQuery() {
        guard let query = metadataQuery else { return }

        print("Stopping and cleaning up metadata query")

        query.disableUpdates()
        query.stop()

        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidUpdate, object: query)
        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: query)

        query.delegate = nil
        query.searchScopes = []
        query.predicate = nil
        query.sortDescriptors = []

        // Force Spotlight to release internal caches
        query.valueListAttributes = []
        query.groupingAttributes = []
        query.notificationBatchingInterval = 1.0

        metadataQuery = nil

        // Clear results and manually dereference memory-heavy items
        DispatchQueue.main.async {
            self.searchResults.removeAll()
        }

        print("Query cleared and fully deallocated")
    }


    @objc private func queryDidUpdate(_ notification: Notification) {
        print("queryDidUpdate received")
        processResults()
    }

    @objc private func queryDidFinish(_ notification: Notification) {
        print("queryDidFinish received")
        metadataQuery?.disableUpdates()
        processResults()
        metadataQuery?.enableUpdates()
    }

    private func processResults() {
        guard let query = metadataQuery else { return }

        autoreleasepool {
            print("Processing \(query.resultCount) results...")

            let urls: [URL] = query.results.compactMap { item in
                guard let item = item as? NSMetadataItem else { return nil }

                if let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL {
                    return url
                }

                if let path = item.value(forAttribute: NSMetadataItemPathKey) as? String {
                    return URL(fileURLWithPath: path)
                }

                return nil
            }

            let prioritized = urls.sorted { priorityScore(for: $0) > priorityScore(for: $1) }

            DispatchQueue.main.async {
                self.searchResults = prioritized.map { url in
                    var isDirectory: ObjCBool = false
                    FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                    return FileSearchResult(url: url, isDirectory: isDirectory.boolValue)
                }
                print("Top result: \(self.searchResults.first?.url.path ?? "(none)")")
            }
        }
    }

    private func priorityScore(for url: URL) -> Int {
        let userHome = FileManager.default.homeDirectoryForCurrentUser
        let paths = userVisibleFolders.map { userHome.appendingPathComponent($0).path }
        for (index, folderPath) in paths.enumerated() {
            if url.path.hasPrefix(folderPath) {
                return userVisibleFolders.count - index
            }
        }
        return 0
    }
}
