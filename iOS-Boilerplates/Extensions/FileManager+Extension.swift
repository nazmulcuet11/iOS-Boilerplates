//
//  FileManager+Extension.swift
//  SecureChat
//
//  Created by Nazmul's Mac Mini on 30/11/20.
//  Copyright © 2020 TigerIT Foundation. All rights reserved.
//

import Foundation

extension FileManager {
    func copyAndOverwriteItem(at srcURL: URL, to dstURL: URL) throws {
        if fileExists(atPath: dstURL.path) {
            let suffix = ".deleteCandidate"
            let renamedDstURL = URL(fileURLWithPath: dstURL.path.appending(suffix))
            if fileExists(atPath: renamedDstURL.path) {
                try removeItem(at: renamedDstURL)
            }
            
            try moveItem(at: dstURL, to: renamedDstURL)
            try copyItem(at: srcURL, to: dstURL)
            try removeItem(at: renamedDstURL)
        } else {
            let parentDirectory = dstURL.deletingLastPathComponent()
            try createDirectoryIfNotExists(at: parentDirectory)
            try copyItem(at: srcURL, to: dstURL)
        }
    }
    
    func removeFileIfExists(at url: URL) throws {
        if fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
    }
    
    func removeDirectoryIfExists(at directoryURL: URL) throws {
        try removeFileIfExists(at: directoryURL)
    }
    
    func createDirectoryIfNotExists(at directoryURL: URL) throws {
        if !fileExists(atPath: directoryURL.path) {
            try createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    var documentsDirectory: URL {
        guard let dir = urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Documents Dir Not Found")
        }
        return dir
    }
    
    var applicationSupportDirectory: URL {
        guard let dir = urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("App Support Dir Not Found")
        }
        return dir
    }
}
