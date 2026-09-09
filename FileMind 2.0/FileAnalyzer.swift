//
//  FileAnalyzer.swift
//  FileMind
//
//  Created by WessoBesso on 2025-05-15.
//

import Foundation
import PDFKit
import Vision
import AppKit

class FileAnalyzer {

    /// Analyze an array of files and return a map of URL to extracted content summary
    static func analyzeFiles(urls: [URL], completion: @escaping ([URL: String]) -> Void) {
        var results: [URL: String] = [:]
        let dispatchGroup = DispatchGroup()

        for url in urls {
            dispatchGroup.enter()

            DispatchQueue.global(qos: .userInitiated).async {
                let fileType = url.pathExtension.lowercased()
                var content = ""

                switch fileType {
                case "pdf":
                    content = extractTextFromPDF(url: url)

                case "txt", "md":
                    content = (try? String(contentsOf: url)) ?? ""

                case "jpg", "jpeg", "png", "heic":
                    extractImageDescription(url: url) { description in
                        results[url] = description
                        dispatchGroup.leave()
                    }
                    return // already handled asynchronously

                default:
                    content = "[Unsupported file type: \(fileType)]"
                }

                results[url] = content
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(results)
        }
    }

    /// Extract text from a PDF using PDFKit
    private static func extractTextFromPDF(url: URL) -> String {
        guard let pdf = PDFDocument(url: url) else { return "" }
        var fullText = ""
        for i in 0..<pdf.pageCount {
            if let page = pdf.page(at: i), let text = page.string {
                fullText += text + "\n"
            }
        }
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Extract a brief image description using Vision OCR (optional: use GPT-4o for better tags)
    private static func extractImageDescription(url: URL, completion: @escaping (String) -> Void) {
        guard let image = NSImage(contentsOf: url),
              let tiffData = image.tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else {
            completion("[Unable to load image]")
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let observations = request.results as? [VNRecognizedTextObservation] {
                let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                completion("[Image OCR Text]: \(text.prefix(200))")
            } else {
                completion("[No text recognized in image]")
            }
        }

        request.recognitionLevel = .fast
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion("[Vision OCR failed]")
        }
    }
}
