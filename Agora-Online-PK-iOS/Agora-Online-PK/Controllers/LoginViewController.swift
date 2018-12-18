//
//  LoginViewController.swift
//  Agora-Online-PK
//
//  Created by ZhangJi on 2018/6/4.
//  Copyright © 2018 CavanSu. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    /**-----------------------------------------------------------------------------
     * This view is uesd to set the channel
     *
     * In this app we use the channel to identify
     *      - Agora media channel name
     *      - Agora RTMP Push URL (Constants.pushUrl + account)
     * -----------------------------------------------------------------------------
     */
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var channelTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let channelName = sender as? String else {
            return
        }
        
        let roomVC = segue.destination as! RoomViewController
        roomVC.mediaRoomName = channelName
    }
    
    @IBAction func doJoinButtonPressed(_ sender: UIButton) {
        guard let channelName = channelTextField.text else {
            return
        }
        if !check(String: channelName) {
            return
        }
        performSegue(withIdentifier: "toRoom", sender: channelName)
    }
    
    func check(String: String) -> Bool {
        if String.isEmpty {
            AlertUtil.showAlert(message: "The account is empty !")
            return false
        }

        return true
    }
}
