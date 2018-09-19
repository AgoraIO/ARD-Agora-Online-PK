//
//  MainViewController.swift
//  Agora-Online-PK
//
//  Created by ZhangJi on 2018/6/4.
//  Copyright © 2018 CavanSu. All rights reserved.
//

import UIKit
import AgoraRtcEngineKit

class MainViewController: UIViewController {
    /**-----------------------------------------------------------------------------
     * In this view you can chose the mode to join the room
     *
     * There are two button in the view, staet broadcast / watch broadcast
     *
     * Start broadcast:
     *      when start broadcast button pressed, you will join the room directly as a broadcast
     *
     * Watch broadcast:
     *      When watch broadcast button pressed, a view will pop out, then you need to enter the account which
     *      you want to watch, then you can join the broadcast's room as an audience, the account you entered
     *      will be used to identify the signal channel name and the RTMP Pull URL
     * -----------------------------------------------------------------------------
     */
    var subscribeAccount: String?     // accout you want to subscribe

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let roomVC = segue.destination as! RoomViewController
        if let value = sender as? NSNumber, let role = AgoraClientRole(rawValue: value.intValue) {
            roomVC.clientRole = role
            switch role {
            case .audience: roomVC.signalRoomName = subscribeAccount
            case .broadcaster: roomVC.signalRoomName = UserDefaults.standard.object(forKey: "myAccount") as? String
            }
        }
    }

    @IBAction func doPublishButtonPressed(_ sender: UIButton) {
        self.joinRoom(withRole: .broadcaster)
    }
    
    @IBAction func doSubscribeButtonPressed(_ sender: UIButton) {
        let popView = PopView.newPopViewWith(buttonTitle: "观看直播", placeholder: "请输入用户名")
        popView?.frame = CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: ScreenHeight)
        popView?.delegate = self
        self.view.addSubview(popView!)
        UIView.animate(withDuration: 0.2) {
            popView?.frame = self.view.frame
        }
    }
    
    @IBAction func doBackButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

private extension MainViewController {
    func joinRoom(withRole role: AgoraClientRole) {
        self.performSegue(withIdentifier: "toRoom", sender: NSNumber(value: role.rawValue as Int))
    }
}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserCell
        cell.fakeTheUesrWith(indexPath.row)
        return cell;
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ScreenWidth
    }
}

extension MainViewController: PopViewDelegate {
    func popViewButtonDidPressed(_ popView: PopView) {
        guard let account = popView.inputTextField.text else {
            return
        }
        if !check(String: account) {
            return
        }
        self.subscribeAccount = account
        
        self.joinRoom(withRole: .audience)
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
