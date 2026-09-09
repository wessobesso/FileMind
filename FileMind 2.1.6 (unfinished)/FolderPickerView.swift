//
//  FolderPickerView.swift
//  FileMind
//
//  Created by WessoBesso on 2025-05-02.
//

import SwiftUI

struct FolderPickerView: View {
    let folders: [URL]
    @Binding var excludedFolders: Set<URL>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(folders, id: \.self) { folder in
                    Button(action: {
                        if excludedFolders.contains(folder) {
                            excludedFolders.remove(folder)
                        } else {
                            excludedFolders.insert(folder)
                        }
                    }) {
                        HStack {
                            Image(systemName: excludedFolders.contains(folder) ? "square" : "checkmark.square.fill")
                                .foregroundColor(.orange)
                            Text(folder.path)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Exclude Folders from DeepSearch")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}
