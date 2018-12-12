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

/// PK view width
let pkViewWidth = ScreenWidth / 2.0

/// PK view height
let pkViewHeight = ScreenWidth / 9.0 * 8

let isIPhoneX = ScreenHeight == 812 ? true : false

let userProfileLists = [#imageLiteral(resourceName: "profile_01"),#imageLiteral(resourceName: "profile_02"),#imageLiteral(resourceName: "profile_03"),#imageLiteral(resourceName: "profile_04"),#imageLiteral(resourceName: "profile_05"),#imageLiteral(resourceName: "profile_06"),#imageLiteral(resourceName: "profile_07"),#imageLiteral(resourceName: "profile_08")]

/// RTMP Push URL
let pushUrl = "rtmp://vid-218.push.chinanetcenter.broadcastapp.agora.io/live/"

/// RTMP Pull URL
let pullUrl = "rtmp://vid-218.pull.chinanetcenter.broadcastapp.agora.io/live/"
