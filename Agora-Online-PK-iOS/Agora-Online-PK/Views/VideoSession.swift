//
//  VideoSession.swift
//  Agora-Online-PK
//
//  Created by ZhangJi on 2018/6/4.
//  Copyright © 2018 CavanSu. All rights reserved.
//

import UIKit
import AgoraRtcEngineKit

class VideoSession: NSObject {
    // this is a custom object for agora video view
    var uid: UInt = 0
    var hostingView: UIView!
    var canvas: AgoraRtcVideoCanvas!
    
    init(uid: UInt) {
        self.uid = uid
        
        hostingView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        canvas = AgoraRtcVideoCanvas()
        canvas.uid = UInt(uid)
        canvas.view = hostingView
        canvas.renderMode = .hidden
    }
}

extension VideoSession {
    static func localSession() -> VideoSession {
        return VideoSession(uid: 0)
    }
}
