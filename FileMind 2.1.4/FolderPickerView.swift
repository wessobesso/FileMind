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
                    Toggle(isOn: Binding(
                        get: { !excludedFolders.contains(folder) },
                        set: { include in
                            if include {
                                excludedFolders.remove(folder)
                            } else {
                                excludedFolders.insert(folder)
                            }
                        }
                    )) {
                        Text(folder.path)
                            .font(.system(.body, design: .monospaced))
                    }
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
