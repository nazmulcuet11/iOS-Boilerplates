//
//  UploadDownloadServiceSubscription.swift
//  CommChat
//
//  Created by Nazmul's Mac Mini on 22/3/21.
//  Copyright © 2021 TigerIT Foundation. All rights reserved.
//

import Foundation

@objc
class CancellableSubscription: NSObject {
    typealias OnCancelCallback = () -> Void
    private let onCancel: OnCancelCallback

    init(onCancel: @escaping OnCancelCallback) {
        self.onCancel = onCancel
    }

    deinit {
        cancel()
    }

    func cancel() {
        onCancel()
    }
}
