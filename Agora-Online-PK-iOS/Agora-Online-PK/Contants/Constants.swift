//
//  Constants.swift
//  Agora-Online-PK
//
//  Created by ZhangJi on 2018/6/4.
//  Copyright © 2018 CavanSu. All rights reserved.
//

import UIKit

/// Screen Width
let ScreenWidth = UIScreen.main.bounds.size.width
/// Screen Height
let ScreenHeight = UIScreen.main.bounds.size.height

/// iphone4s
let isIPhone4 = ScreenHeight == 480 ? true : false
/// iPhone 5
let isIPhone5 = ScreenHeight == 568 ? true : false
/// iPhone 6
let isIPhone6 = ScreenHeight == 667 ? true : false
/// iPhone 6P
let isIPhone6P = ScreenHeight == 736 ? true : false

let isIPhoneX = ScreenHeight == 812 ? true : false

let userProfileLists = [#imageLiteral(resourceName: "profile_01"),#imageLiteral(resourceName: "profile_02"),#imageLiteral(resourceName: "profile_03"),#imageLiteral(resourceName: "profile_04"),#imageLiteral(resourceName: "profile_05"),#imageLiteral(resourceName: "profile_06"),#imageLiteral(resourceName: "profile_07"),#imageLiteral(resourceName: "profile_08")]

let backgroundLists = [#imageLiteral(resourceName: "background_01"),#imageLiteral(resourceName: "background_02"),#imageLiteral(resourceName: "background_03"),#imageLiteral(resourceName: "background_04"),#imageLiteral(resourceName: "background_05"),#imageLiteral(resourceName: "background_06"),#imageLiteral(resourceName: "background_07"),#imageLiteral(resourceName: "background_08")]

let userNameList = ["安迪爱包子", "Eren Jäger", "Mikasa Ackerman", "Armin Arlert", "Erwin Smith", "Rival Ackerman", "包子", "安迪"]

/// RTMP Push URL
let pushUrl = "rtmp://vid-218.push.chinanetcenter.broadcastapp.agora.io/live/"

/// RTMP Pull URL
let pullUrl = "rtmp://vid-218.pull.chinanetcenter.broadcastapp.agora.io/live/"
