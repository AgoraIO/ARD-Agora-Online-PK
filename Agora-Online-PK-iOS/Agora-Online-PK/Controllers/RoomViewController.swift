//
//  RoomViewController.swift
//  Agora-Online-PK
//
//  Created by ZhangJi on 2018/6/5.
//  Copyright © 2018 CavanSu. All rights reserved.
//

import UIKit
import AgoraRtcEngineKit

struct Message {
    // struct for message
    let name: String!
    let content: NSMutableAttributedString!
}

class RoomViewController: UIViewController {
    /**-----------------------------------------------------------------------------
     * This view load the mode for Live broadcast
     *
     * Live broadcast mode:
     *      You will upload the stream to Agora and CDN you chose
     *      You can presse PK button to start PK with another broadcast
     *
     * -----------------------------------------------------------------------------
     */
    @IBOutlet weak var leaveButton: UIButton!
    @IBOutlet weak var pkButton: UIButton!
    @IBOutlet weak var endPkButton: UIButton!
    
    @IBOutlet weak var hostContainView: UIView!
    
    @IBOutlet weak var urlContainerView: UIView!
    @IBOutlet weak var pullUrlLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    
    var agoraKit: AgoraRtcEngineKit!
    var myPushUrl: String?   // url to push rtmp stream
    
    var mediaRoomName: String!  // channel name to join Agora media room
   
    var localSession: VideoSession?
    var remoteSession: VideoSession?
    
    var pkRoomeName: String?  // channel name for the PK room
    var count: Int = 0
    var isPk = false {
        // the status for PK
        didSet {
            if isPk != oldValue {
                updateViewWithStatus(isPk: isPk)
            }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setView()
        
        loadAgoraKit(withIsPk: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func setView() {
        // init the view
        pkButton.layer.borderWidth = 1
        pkButton.layer.borderColor = UIColor.white.cgColor
        pkButton.layer.cornerRadius = 5
        pkButton.layer.masksToBounds = true
        
        endPkButton.layer.borderWidth = 1
        endPkButton.layer.borderColor = UIColor.white.cgColor
        endPkButton.layer.cornerRadius = 5
        endPkButton.layer.masksToBounds = true
        endPkButton.frame.size = CGSize(width: 110, height: 44)
        endPkButton.center = CGPoint(x: ScreenWidth / 2.0, y: ScreenHeight / 7 + pkViewHeight)
        
        copyButton.layer.cornerRadius = 4
        copyButton.layer.masksToBounds = true
        
        urlContainerView.layer.cornerRadius = 4
        urlContainerView.layer.masksToBounds = true
    }
    
    func updateViewWithStatus(isPk: Bool) {
        // update view with status
        self.pkButton.isHidden = isPk
        self.endPkButton.isHidden = !isPk
    }
    
    @IBAction func doLeaveButtonPressed(_ sender: UIButton) {
        self.isPk = false
        self.pkRoomeName = nil
        self.leaveAgoraChannel()
        
        setIdleTimerActive(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doPkButtonPressed(_ sender: UIButton) {
        let popView = PopView.newPopViewWith(buttonTitle: "PK", placeholder: "Channel name for PK")
        popView?.frame = CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: ScreenHeight)
        popView?.delegate = self
        self.view.addSubview(popView!)
        UIView.animate(withDuration: 0.2) {
            popView?.frame = self.view.frame
        }
    }
    
    @IBAction func doEndPkButtonPressed(_ sender: UIButton) {
        self.leaveAgoraChannel()
    }
    
    @IBAction func doCopyPressed(_ sender: UIButton) {
        // Copy url
        UIPasteboard.general.string = pullUrl + self.mediaRoomName
    }
    
    func setIdleTimerActive(_ active: Bool) {
        UIApplication.shared.isIdleTimerDisabled = !active
    }
}

// MARK: - AgoraMedia
private extension RoomViewController {
    func loadAgoraKit(withIsPk status: Bool) {
        // load agora media kit and join media channel with PK status, only the broadcaster will join agora
        // the agora media channel, the audience just join agora signal channel for channel chat
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: KeyCenter.AppId, delegate: self)
        agoraKit.setChannelProfile(.liveBroadcasting)
        agoraKit.setClientRole(.broadcaster)
        agoraKit.enableVideo()
        agoraKit.setVideoEncoderConfiguration(AgoraVideoEncoderConfiguration(size: AgoraVideoDimension640x360,
                                                                              frameRate: .fps15,
                                                                              bitrate: AgoraVideoBitrateStandard,
                                                                              orientationMode: .adaptative))
        
        agoraKit.startPreview()
        self.addLocalSession()
        UIView.animate(withDuration: 0.2) {
            self.localSession?.hostingView.frame = status ? CGRect(x: 0, y: ScreenHeight / 7, width: pkViewWidth, height: pkViewHeight) : self.hostContainView.frame
        }
        
        let code = agoraKit.joinChannel(byToken: nil, channelId: isPk ? self.pkRoomeName! : self.mediaRoomName, info: nil, uid: 0, joinSuccess: nil)
        if code == 0 {
            setIdleTimerActive(false)
            agoraKit.setEnableSpeakerphone(true)
        }
        
    }
    
    func addLocalSession() {
        if self.localSession == nil {
            self.localSession = VideoSession.localSession()
        }
        agoraKit.setupLocalVideo(localSession?.canvas)
        self.hostContainView.addSubview((localSession?.hostingView)!)
    }
    
/**-----------------------------------------------------------------------------
 *
 *     Key Code for Live transcode
 *
 * -----------------------------------------------------------------------------
 */
    func updateLiveTranscoding(withMenber menber: Int) {
        // LiveTranscoding update, the LiveTranscoding is used to set the CDN stream layout in Agora server
        // more details please refer to the document
        switch menber {
        case 1:
            // the LiveTranscoding for one person
            let localUser = AgoraLiveTranscodingUser()
            localUser.uid = (self.localSession?.uid)!
            localUser.rect = CGRect(x: 0, y: 0, width: 360, height: 640)
            localUser.zOrder = 1
            localUser.audioChannel = 0
            
            let liveTranscoding = AgoraLiveTranscoding()

            liveTranscoding.transcodingUsers = [localUser]
            liveTranscoding.size = CGSize(width: 360, height: 640)
            liveTranscoding.videoBitrate = 1200
            liveTranscoding.videoFramerate = 15
            liveTranscoding.backgroundColor = UIColor.clear
            
            agoraKit.setLiveTranscoding(liveTranscoding)
        case 2:
            // the LiveTranscoding for two persons in PK mode
            var uses = [AgoraLiveTranscodingUser]()
            let localUser = AgoraLiveTranscodingUser()
            localUser.uid = (self.localSession?.uid)!
            localUser.rect = CGRect(x: 0, y: 0, width: 360, height: 640)
            localUser.zOrder = 1
            localUser.audioChannel = 0
            uses.append(localUser)
            
            if self.remoteSession != nil {
                let removeUser = AgoraLiveTranscodingUser()
                removeUser.uid = (self.remoteSession?.uid)!
                removeUser.rect = CGRect(x: 360, y: 0, width: 360, height: 640)
                removeUser.zOrder = 1
                removeUser.audioChannel = 0
                uses.append(removeUser)
            }
            
            let liveTranscoding = AgoraLiveTranscoding()
            liveTranscoding.transcodingUsers = uses
            liveTranscoding.size = CGSize(width: 720, height: 640)
            liveTranscoding.videoBitrate = 1200
            liveTranscoding.videoFramerate = 15
            liveTranscoding.backgroundColor = UIColor.clear
            
            agoraKit.setLiveTranscoding(liveTranscoding)
        default:
            break
        }
    }
    
    func leaveAgoraChannel() {
        // leave agora media channel
        if let myPushUrl = self.myPushUrl {
            agoraKit.removePublishStreamUrl(myPushUrl)
        }
        agoraKit.setupLocalVideo(nil)
        agoraKit.leaveChannel(nil)
    }
}

// MARK: - AgoraMedia Deleagte
extension RoomViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("join media channel: \(channel)")
        self.localSession?.uid = uid
        
        self.updateLiveTranscoding(withMenber: self.isPk ? 2 : 1)
        self.myPushUrl = pushUrl + self.mediaRoomName
        self.pullUrlLabel.text = pullUrl + self.mediaRoomName
        agoraKit.addPublishStreamUrl(self.myPushUrl!, transcodingEnabled: true)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        if isPk && count < 1 {
            remoteSession = VideoSession(uid: uid)
            agoraKit.setupRemoteVideo((remoteSession?.canvas)!)
            remoteSession?.hostingView.frame = CGRect(x: pkViewWidth, y: ScreenHeight / 7, width: pkViewWidth, height: pkViewHeight)
            self.hostContainView.addSubview((remoteSession?.hostingView)!)
            count = 1
            self.updateLiveTranscoding(withMenber: 2)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        if uid == remoteSession?.uid {
            remoteSession?.hostingView.removeFromSuperview()
            remoteSession = nil
            count = 0
            self.leaveAgoraChannel()
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, streamPublishedWithUrl url: String, errorCode: AgoraErrorCode) {
        print("streamPublishedWithUrl: error \(errorCode.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        print("leave channel")
        guard let _ = self.pkRoomeName else {
            return
        }
        if isPk {
            // if in PK mode, the broadcaster will first leave the PK room, then go back his own room
            self.isPk = false
            self.pkRoomeName = nil
            self.remoteSession?.hostingView.removeFromSuperview()
            loadAgoraKit(withIsPk: false)
        } else {
            // if it's not in PK mode, the broadcaster will first leave his owm roonm, then join the PK room
            self.isPk = true
            loadAgoraKit(withIsPk: true)
        }
    }
}

extension RoomViewController: PopViewDelegate {
    func popViewButtonDidPressed(_ popView: PopView) {
        guard let pkRoomName = popView.inputTextField.text else {
            return
        }
        if !check(String: pkRoomName) {
            return
        }
        self.pkRoomeName = pkRoomName
        self.leaveAgoraChannel()
        popView.removeFromSuperview()
    }
    
    func check(String: String) -> Bool {
        if String.isEmpty {
            AlertUtil.showAlert(message: "The account is empty !")
            return false
        }
        return true
    }
}
