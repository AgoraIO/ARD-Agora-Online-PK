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
     * This view is uesd to set the account
     *
     * In this app we use the accout to identify
     *      - Agora media channel name
     *      - Agora signal account
     *      - Agora signal channel name
     *      - Agora RTMP Push URL (Constants.pushUrl + account)
     * -----------------------------------------------------------------------------
     */
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var accountTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addKeyboardObserver()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func doLoginButtonPressed(_ sender: UIButton) {
        guard let account = accountTextField.text else {
            return
        }
        if !check(String: account) {
            return
        }
        UserDefaults.standard.set(account, forKey: "myAccount")
        
        performSegue(withIdentifier: "toMain", sender: self)
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

private extension LoginViewController {
    func addKeyboardObserver() {
        // Add Keyboard Observer
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: nil) { [weak self] notify in
            guard let strongSelf = self, let userInfo = (notify as NSNotification).userInfo,
                let keyBoardBoundsValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
                let durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber else {
                    return
            }
            
            let keyBoardBounds = keyBoardBoundsValue.cgRectValue
            let duration = durationValue.doubleValue
            var deltaY = isIPhoneX ? keyBoardBounds.size.height + 34 : keyBoardBounds.size.height
            deltaY -= ScreenHeight - (self?.loginButton.frame.maxY)! - 10
            
            if duration > 0 {
                var optionsInt: UInt = 0
                if let optionsValue = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber {
                    optionsInt = optionsValue.uintValue
                }
                let options = UIViewAnimationOptions(rawValue: optionsInt)
                
                UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                    strongSelf.view.frame = CGRect(x: 0, y: -deltaY, width: ScreenWidth, height: ScreenHeight)
                    strongSelf.view?.layoutIfNeeded()
                }, completion: nil)
                
            } else {
                strongSelf.view.frame = CGRect(x: 0, y: -deltaY, width: ScreenWidth, height: ScreenHeight)
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: nil) { [weak self] notify in
            guard let strongSelf = self else {
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
                    strongSelf.view.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight)
                    strongSelf.view?.layoutIfNeeded()
                }, completion: nil)
                
            } else {
                strongSelf.view.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight)
            }
        }
    }
}
