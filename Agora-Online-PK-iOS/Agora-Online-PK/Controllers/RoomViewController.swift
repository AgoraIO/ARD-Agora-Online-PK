//
//  RoomViewController.swift
//  Agora-Online-PK
//
//  Created by ZhangJi on 2018/6/5.
//  Copyright © 2018 CavanSu. All rights reserved.
//

import UIKit
import MediaPlayer
import AgoraRtcEngineKit

let pkViewWidth = ScreenWidth / 2.0
let pkViewHeight = ScreenWidth / 9.0 * 8

struct Message {
    // struct for message
    let name: String!
    let content: NSMutableAttributedString!
}

class RoomViewController: UIViewController {
    /**-----------------------------------------------------------------------------
     * This view has two mode: Live broadcast && audience
     *
     * Live broadcast mode:
     *      You will upload the stream to Agora and CDN you chose
     *      You can presse PK button to start PK with another broadcast
     *
     * Audience mode:
     *      In this mode you will subscribe a RTMP stream use rjkplayer
     *
     * -----------------------------------------------------------------------------
     */
    @IBOutlet weak var leaveButton: UIButton!
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var pkButton: UIButton!
    @IBOutlet weak var endPkButton: UIButton!
    @IBOutlet weak var watcherCountLabel: UILabel!
    @IBOutlet weak var userProfileImageView: UIImageView!
    
    @IBOutlet weak var chatInputTextField: UITextField!
    @IBOutlet weak var chatContainViewConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var hostContainView: UIView!
    
    @IBOutlet weak var pkBarContainView: UIView!
    @IBOutlet weak var myPkBar: UIView!
    @IBOutlet weak var remotePkBar: UIView!
    
    
    var agoraKit: AgoraRtcEngineKit!
    var myPushUrl: String?   // url to push rtmp stream
    var myPullUrl: String?   // url to pull rtmp stream
    
    var clientRole = AgoraClientRole.audience
    
    lazy var mediaRoomName: String = {
        // channel name to join Agora media room
        return UserDefaults.standard.object(forKey: "myAccount") as! String
    }()
    
    fileprivate var isBroadcaster: Bool {
        return clientRole == .broadcaster
    }
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
    
    var isBroadcasting = false {
        // the status for the audience mode to identify if there is a broadcast stream
        didSet {
            if isBroadcasting == oldValue {
                return
            } else {
                isBroadcasting ? loadIjkPlayer() : releaseIjkPlyer()
            }
        }
    }
    
    var popViewIsShow = false {
        // status to identify if there is a pop view be showed
        didSet {
            if popViewIsShow {
                UIView.animate(withDuration: 0.2) {
                    self.chatContainViewConstraint.constant = 0
                    self.view?.layoutIfNeeded()
                }
            }
        }
    }
    
    lazy var agoraSignal: AgoraMessageTubeKit = {
        // agora signal instance
        let signalKit = AgoraMessageTubeKit.sharedMessageTubeKit(withAppId: KeyCenter.AppId, workMode: .joinChannelOnly)
        signalKit?.delegate = self
        return signalKit!
    }()
    
    var signalRoomName: String?    // channel name to join agora signal channel
    
    lazy var signalAccount: String = {
        // account for agora aignal system
        return UserDefaults.standard.object(forKey: "myAccount") as! String
    }()
    
    var messageList = [Message]()  // channel chat message list
    
    var ijkPlayer: IJKFFMoviePlayerController?  // ijkplayer
    
    var streamSize: CGSize? {
        // size for RTMP stream, we use this size to observe the stream status in audience mode
        didSet {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2) {
                    if self.isPk {
                        self.ijkPlayer?.view.frame = CGRect(x: 0, y: ScreenHeight / 7, width: ScreenWidth, height: pkViewHeight)
                        self.pkBarAnimate(withStatus: self.isPk)
                    } else {
                        self.ijkPlayer?.view.frame = self.view.frame
                        self.pkBarAnimate(withStatus: self.isPk)
                    }
                }
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addKeyboardObserver()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setView()
        
        if isBroadcaster {
            loadAgoraKit(withIsPk: false)
        }
        
        loadAgoraSignal()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("deinit")
    }
    
    func setView() {
        // init the view
        chatTableView.rowHeight = UITableViewAutomaticDimension
        chatTableView.estimatedRowHeight = 20
        
        pkButton.isHidden = !isBroadcaster
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
        
        
        userProfileImageView.image = userProfileLists[Int(arc4random() % UInt32(userProfileLists.count))]
        watcherCountLabel.text = String(Int(arc4random() % 20000))
        
        let attDic = NSMutableDictionary()
        attDic[NSAttributedStringKey.foregroundColor] = UIColor(hex: 0xC9F7FE)
        let attPlaceholder = NSAttributedString(string: "说点什么...", attributes: attDic as? [NSAttributedStringKey : Any])
        chatInputTextField.attributedPlaceholder = attPlaceholder
        
        let maskPath = UIBezierPath(roundedRect: myPkBar.bounds, byRoundingCorners: [.topLeft,.bottomLeft], cornerRadii: CGSize(width: 5, height: 5))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = myPkBar.bounds
        maskLayer.path = maskPath.cgPath
        myPkBar.layer.mask = maskLayer
        myPkBar.transform = CGAffineTransform(translationX: -ScreenWidth / 2, y: 0)
        
        let remotMaskPath = UIBezierPath(roundedRect: remotePkBar.bounds, byRoundingCorners: [.bottomRight,.topRight], cornerRadii: CGSize(width: 5, height: 5))
        let remoteMaskLayer = CAShapeLayer()
        remoteMaskLayer.frame = remotePkBar.bounds
        remoteMaskLayer.path = remotMaskPath.cgPath
        remotePkBar.layer.mask = remoteMaskLayer
        remotePkBar.transform = CGAffineTransform(translationX: ScreenWidth / 2, y: 0)
    }
    
    func updateViewWithStatus(isPk: Bool) {
        // update view with status
        if isBroadcaster {
            self.pkButton.isHidden = isPk
            self.endPkButton.isHidden = !isPk
            self.pkBarAnimate(withStatus: isPk)
            
            var messageJson = Dictionary<String, Any>()
            messageJson["type"] = "pkStatus"
            messageJson["data"] = isPk
            
            agoraSignal.sendChannelJsonMessage(messageJson, messageId: "")
        }
    }
    
    func pkBarAnimate(withStatus isPk: Bool) {
        if isPk {
            UIView.animate(withDuration: 0.2) {
                self.myPkBar.transform = CGAffineTransform.identity
                self.remotePkBar.transform = CGAffineTransform.identity
                self.pkBarContainView.isHidden = false
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.pkBarContainView.isHidden = true
                self.myPkBar.transform = CGAffineTransform(translationX: -ScreenWidth / 2, y: 0)
                self.remotePkBar.transform = CGAffineTransform(translationX: ScreenWidth / 2, y: 0)
            }
        }
    }
    
    @IBAction func doLeaveButtonPressed(_ sender: UIButton) {
        if isBroadcaster {
            self.isPk = false
            self.pkRoomeName = nil
            self.leaveAgoraChannel()
        } else {
            isBroadcasting = false
        }

        leaveAgoraSignalChannel()
        setIdleTimerActive(true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doPkButtonPressed(_ sender: UIButton) {
        self.chatInputTextField.resignFirstResponder()
        self.popViewIsShow = true
        let popView = PopView.newPopViewWith(buttonTitle: "开始PK", placeholder: "请输入PK房间名")
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
        agoraKit.setClientRole(self.clientRole)
        agoraKit.enableVideo()
        agoraKit.setVideoEncoderConfiguration(AgoraVideoEncoderConfiguration(size: AgoraVideoDimension640x360,
                                                                              frameRate: .fps15,
                                                                              bitrate: AgoraVideoBitrateStandard,
                                                                              orientationMode: .adaptative))
        
        if isBroadcaster {
            agoraKit.startPreview()
            self.addLocalSession()
            UIView.animate(withDuration: 0.2) {
                self.localSession?.hostingView.frame = status ? CGRect(x: 0, y: ScreenHeight / 7, width: pkViewWidth, height: pkViewHeight) : self.hostContainView.frame
            }
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
        if let myPushUrl = self.myPushUrl, isBroadcaster {
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

// MARK: IJKPlayer
// about ijkplayer please refer to the ijkplayer document
private extension RoomViewController {
    func loadIjkPlayer() {
        // load ijkplayer in audience mode to pull a RTMP stream
        setIdleTimerActive(true)
        
        self.myPullUrl = pullUrl + self.signalRoomName!
        let url = URL(string: self.myPullUrl!)
        ijkPlayer = IJKFFMoviePlayerController(contentURL: url!, with: IJKFFOptions.byDefault())

        IJKFFMoviePlayerController.setLogLevel(k_IJK_LOG_ERROR)
        ijkPlayer?.view.frame = CGRect(x: ScreenWidth / 2, y: ScreenHeight / 2, width: 0, height: 0)
        ijkPlayer?.scalingMode = .aspectFill
        self.hostContainView.addSubview((ijkPlayer?.view)!)

        ijkPlayer?.prepareToPlay()
        
        // the notification to observe the RTMP stream
        NotificationCenter.default.addObserver(self, selector: #selector(mediaPlayerPlaybackStateChange), name: NSNotification.Name.IJKMPMoviePlayerLoadStateDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(mediaNaturalSizeAvailable), name: NSNotification.Name.IJKMPMovieNaturalSizeAvailable, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(mediaPlayerPlaybackFinished), name: NSNotification.Name.IJKMPMoviePlayerPlaybackDidFinish, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(mediaPlayerIsPreparedToPlayDidChange), name: NSNotification.Name.IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: nil)
    }
    
    @objc func mediaPlayerIsPreparedToPlayDidChange(notify: NSNotification) {
        if (ijkPlayer?.isPreparedToPlay)! {
            ijkPlayer?.play()
        }
    }
    
    @objc func mediaPlayerPlaybackStateChange(notify: NSNotification) {
    }
    
    @objc func mediaNaturalSizeAvailable(notify: NSNotification) {
        // use the stream size to check if the broadcaster is in PK mode or not
        guard let player = (notify as NSNotification).object as? IJKFFMoviePlayerController else {
            return
        }
        if player.naturalSize != self.streamSize {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: {
                    player.view.frame = CGRect(x: ScreenWidth / 2, y: ScreenHeight / 2, width: 0, height: 0)
                })
                if !self.isPk {
                    self.pkBarAnimate(withStatus: self.isPk)
                }
                self.streamSize = player.naturalSize
            }
        }
    }
    
    @objc func mediaPlayerPlaybackFinished(notify: NSNotification) {
        print("mediaPlayerPlaybackFinished")
        isBroadcasting = false
    }
    
    
    func releaseIjkPlyer() {
        // release the ijlplayer
        self.streamSize = nil
        self.ijkPlayer?.view.removeFromSuperview()
        self.ijkPlayer?.shutdown()
        self.ijkPlayer = nil
    }
}

// MARK: - AgoraSignal
// In this app signal system just used to achieve channel chat, we did use signal system to achieve PK logic
// so if you are just interested in the achieve of PK, you can ignore the following about signal
private extension RoomViewController {
    func loadAgoraSignal() {
        // load and join agora signal channel
        agoraSignal.joinChannel(withChannelId: signalRoomName!, account: signalAccount)
    }
    
    func leaveAgoraSignalChannel() {
        // leave agora channel
        agoraSignal.leaveChannel()
    }
}

extension RoomViewController: AgoraMessageTubeKitDelegate {
    func messageTube(_ msgTube: AgoraMessageTubeKit, didJoinedChannelSuccessWithChannelId channelId: String) {
        print("join signal channel success \(channelId)")
        if isBroadcaster {
            self.isPk = false
        }
    }

    func messageTube(_ msgTube: AgoraMessageTubeKit, didJoinedChannelFailedWithChannelId channelId: String, error: SignalEcode) {
        print("join signal channel failed: \(error.rawValue)")
    }
    
    func messageTube(_ msgTube: AgoraMessageTubeKit, didUserJoinedChannelWithChannelId channelId: String, userAccount: String) {
        if isBroadcaster {
            var messageJson = Dictionary<String, Any>()
            messageJson["type"] = "pkStatus"
            messageJson["data"] = isPk
            
            agoraSignal.sendMessage(toPeer: userAccount, jsonMsgDic: messageJson, messageId: "")
        }
    }
    
    func messageTube(_ msgTube: AgoraMessageTubeKit, didReceivedPeerJsonMessage msgDic: [AnyHashable : Any], remoteAccount account: String) {
        if !isBroadcaster, account == signalRoomName! {
            guard let type = msgDic["type"] as? String else {
                return
            }
            if type == "pkStatus" {
                guard let pkStatus =  msgDic["data"] as? Bool else {
                    return
                }
                if !isBroadcaster {
                    isPk = pkStatus
                    if !isBroadcasting { isBroadcasting = true }
                }
            }
        }
    }
    
    func messageTube(_ msgTube: AgoraMessageTubeKit, didReceivedPeerMessage message: String, remoteAccount account: String) {
        if !isBroadcaster, account == signalRoomName! {
            let data = message.data(using: String.Encoding.utf8)
            do {
                let msgDic: NSDictionary = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! NSDictionary
                guard let type = msgDic["type"] as? String else {
                    return
                }
                if type == "pkStatus" {
                    guard let pkStatus =  msgDic["data"] as? Bool else {
                        return
                    }
                    if !isBroadcaster {
                        isPk = pkStatus
                        if !isBroadcasting { isBroadcasting = true }
                    }
                }
                
            } catch  {
                AlertUtil.showAlert(message: "Receive message error: \(error)")
                print("Error: \(error)")
            }
        }
    }
    
    func messageTube(_ msgTube: AgoraMessageTubeKit, didReceivedChannelMessage message: String, channelId: String, remoteAccount account: String) {
        let data = message.data(using: String.Encoding.utf8)
        do {
            let msgDic: NSDictionary = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! NSDictionary
            guard let type = msgDic["type"] as? String else {
                return
            }
            switch type {
            case "chat":
                guard let message = msgDic["data"] as? String else {
                    return
                }
                let chatMsg = account + ": " + message
                let msgContent = NSMutableAttributedString(string: chatMsg)
                let originalNSString = chatMsg as NSString
                let messageRange = originalNSString.range(of: message)
                
                msgContent.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(hex: 0xC9F7FE), range: messageRange)
                let msg = Message(name: signalAccount, content: msgContent)
                self.messageList.append(msg)
                self.updateChatView()
            case "pkStatus":
                guard let pkStatus =  msgDic["data"] as? Bool else {
                    return
                }
                if !isBroadcaster {
                    isPk = pkStatus
                    if !isBroadcasting { isBroadcasting = true }
                }
            default:
                return
            }
        } catch  {
            AlertUtil.showAlert(message: "Receive message error: \(error)")
            print("Error: \(error)")
        }
    }
    
    func messageTube(_ msgTube: AgoraMessageTubeKit, didReceivedChannelJsonMessage msgDic: [AnyHashable : Any], channelId: String, remoteAccount account: String) {
        guard let type = msgDic["type"] as? String else {
            return
        }
        switch type {
        case "chat":
            guard let message = msgDic["data"] as? String else {
                return
            }
            let chatMsg = account + ": " + message
            let msgContent = NSMutableAttributedString(string: chatMsg)
            let originalNSString = chatMsg as NSString
            let messageRange = originalNSString.range(of: message)
            
            msgContent.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(hex: 0xC9F7FE), range: messageRange)
            let msg = Message(name: signalAccount, content: msgContent)
            self.messageList.append(msg)
            self.updateChatView()
        case "pkStatus":
            guard let pkStatus =  msgDic["data"] as? Bool else {
                return
            }
            if !isBroadcaster {
                isPk = pkStatus
                if !isBroadcasting { isBroadcasting = true }
            }
        default:
            return
        }
    }
    
    func messageTube(_ msgTube: AgoraMessageTubeKit, didChannelMessageSendSuccessWithChannelId channelId: String) {
        
    }
    
    func messageTube(_ msgTube: AgoraMessageTubeKit, didUserLeavedChannelWithChannelId channelId: String, userAccount: String) {
        
    }
    
    func messageTube(_ msgTube: AgoraMessageTubeKit, didOccurErrorCode code: SignalEcode, errorName name: String, errorDesc desc: String) {
        if isBroadcaster {
            self.isPk = false
            self.pkRoomeName = nil
            self.leaveAgoraChannel()
        } else {
            isBroadcasting = false
        }

        setIdleTimerActive(true)
        navigationController?.popViewController(animated: true)
        
        AlertUtil.showAlert(message: "Did occur error: \(name), please try again")
    }
}

extension RoomViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let message = chatInputTextField.text else { return false }
        
        var messageJson = Dictionary<String, Any>()
        messageJson["type"] = "chat"
        messageJson["data"] = message
        
        agoraSignal.sendChannelJsonMessage(messageJson, messageId: "")
        
        let chatMsg = signalAccount + ": " + message
        let msgContent = NSMutableAttributedString(string: chatMsg)
        let originalNSString = chatMsg as NSString
        let messageRange = originalNSString.range(of: message)
        
        msgContent.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(hex: 0xC9F7FE), range: messageRange)
        let msg = Message(name: signalAccount, content: msgContent)
        self.messageList.append(msg)
        self.updateChatView()
        self.chatInputTextField.text = ""

        return true
    }
}

extension RoomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatCell
        cell.messageLabel.attributedText = messageList[indexPath.row].content
        return cell
    }
    
    func updateChatView() {
        guard let tableView = chatTableView else {
            return
        }
        
        tableView.beginUpdates()
        if messageList.count > 100 {
            messageList.removeFirst()
            tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        }
        let insertIndexPath = IndexPath(row: messageList.count - 1, section: 0)
        tableView.insertRows(at: [insertIndexPath], with: .none)
        tableView.endUpdates()
        
        tableView.scrollToRow(at: insertIndexPath, at: .bottom, animated: false)
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
        popViewIsShow = false
    }
    
    func popViewDidRemoved(_ popView: PopView) {
        popViewIsShow = false
    }
    
    func check(String: String) -> Bool {
        if String.isEmpty {
            AlertUtil.showAlert(message: "The account is empty !")
            return false
        }
        if String.count > 128 {
            AlertUtil.showAlert(message: "The accout is longer than 128 !")
            return false
        }
        if String.contains(" ") {
            AlertUtil.showAlert(message: "The accout contains space !")
            return false
        }
        return true
    }
}

private extension RoomViewController {
    func addKeyboardObserver() {
        // Add Keyboard Observer
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: nil) { [weak self] notify in
            guard let strongSelf = self, let userInfo = (notify as NSNotification).userInfo,
                let keyBoardBoundsValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
                let durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber else {
                    return
            }
            
            if strongSelf.popViewIsShow {
                return
            }
            
            let keyBoardBounds = keyBoardBoundsValue.cgRectValue
            let duration = durationValue.doubleValue
            let deltaY = isIPhoneX ? keyBoardBounds.size.height - 34 : keyBoardBounds.size.height
            
            if duration > 0 {
                var optionsInt: UInt = 0
                if let optionsValue = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber {
                    optionsInt = optionsValue.uintValue
                }
                let options = UIViewAnimationOptions(rawValue: optionsInt)
                
                UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                    strongSelf.chatContainViewConstraint.constant = deltaY
                    strongSelf.view?.layoutIfNeeded()
                }, completion: nil)
                
            } else {
                strongSelf.chatContainViewConstraint.constant = deltaY
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: nil) { [weak self] notify in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.popViewIsShow {
                return
            }
            
            let duration: Double
            if let userInfo = (notify as NSNotification).userInfo, let durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {
                duration = durationValue.doubleValue
            } else {
                duration = 0
            }
            
            if duration > 0 {
                var optionsInt: UInt = 0
                if let userInfo = (notify as NSNotification).userInfo, let optionsValue = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber {
                    optionsInt = optionsValue.uintValue
                }
                let options = UIViewAnimationOptions(rawValue: optionsInt)
                
                UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                    strongSelf.chatContainViewConstraint.constant = 0
                    strongSelf.view?.layoutIfNeeded()
                }, completion: nil)
                
            } else {
                strongSelf.chatContainViewConstraint.constant = 0
            }
        }
    }
}
