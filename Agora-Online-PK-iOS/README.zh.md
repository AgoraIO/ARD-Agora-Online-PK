# Agora Online PK

*Read this in other languages: [English](README.md)*

“PK场”景是直播娱乐中一种典型的应用场景，主播可以在直播过程中与其他主播进行直播PK，以达到更好的互动性。

这个示例程序根据主播和观众的不同身份，实现了以下功能：

- 主播：直播功能和发起PK功能
- 观众：观看直播功能


## 功能列表
这个开源示例项目演示了如果快速集成 [Agora](www.agora.io) 视频 SDK 和信令SDK，并利用 [ijkplayer](https://github.com/Bilibili/ijkplayer) 实现视频直播PK场景。

主播端：

- 登录：在首页输入用户名，并点击“登录”按钮；
- 开始直播：点击“开始直播”按钮，进入直播房间，开始直播和CDN推流；
- 发起PK：在房间内点击“发起PK”按钮，并输入“PK房间名”进入PK（需要两个主播同时输入相同的“PK房间名”以进入同一房间）；
- 退出PK：点击“退出PK”按钮，退出PK模式，返回单主播模式；
- 退出房间：点击右上角“离开”按钮，离开直播房间；
- 聊天：房间内可以进行群聊天；

观众端：

- 登录：在首页输入用户名，并点击“登录”按钮；
- 观看直播：点击“观看直播”按钮，并输入观看的主播用户名，进入直播房间观看（直播观看使用的是ijkplayer进行的CDN拉流）；
- 退出房间：点击右上角“离开”按钮，离开直播房间； 
- 聊天：房间内可以进行群聊天。



## 运行示例程序
首先在 [Agora.io 注册](https://dashboard.agora.io/cn/signup/) 注册账号，并创建自己的测试项目，获取到 AppID。将 AppID 填写进 KeyCenter.m

```
static let AppId: String = "Your App ID"
```
然后在 [Agora.io SDK](https://www.agora.io/cn/download/) 下载 视频通话 + 直播 SDK，解压后将其中的 libs/AgoraRtcEngineKit.framework 复制到项目文件夹下。

获取 AgoraMessageTubeKit.framework 文件，放入项目文件夹下。AgoraMessageTubeKit.framework是为本项目封装的信令库，你可以去以下地址下载 [AgoraMessageTubeKit.framework](https://github.com/AgoraIO/ARD-Agora-Online-PK/files/2370417/AgoraMessageTubeKit.zip)

获取 [ijkplayer](https://github.com/Bilibili/ijkplayer)， 根据文档生成 IJKMediaFramework.framework，放入项目文件夹下。你也可以去以下地址下载我们编译好的版本 [IJKMediaFramework.framework]() （该版本只用于项目调试）

最后使用 XCode 打开 Agora-Online-PK.xcodeproj，连接 iPhone／iPad 测试设备，设置有效的开发者签名后即可运行。

## 运行环境
* XCode 8.0 +
* iOS 真机设备
* 不支持模拟器

## FAQ
- 关于 ijkplayer 的相关使用可参看一下文章：

  [iOS开发ijkplayer框架的集成](https://www.jianshu.com/p/d26ebb77d856)
  
  [iOS视频播放之ijkplayer使用](https://www.jianshu.com/p/683ccc09d4ad)
  

## 联系我们

- 如果发现了示例程序的 bug，欢迎提交 [issue](https://github.com/AgoraIO/ARD-Agora-Online-PK/issues)
- 声网 SDK 完整 API 文档见 [文档中心](https://docs.agora.io/cn/)
- 如果在集成中遇到问题，你可以到 [开发者社区](https://dev.agora.io/cn/) 提问
- 如果有售前咨询问题，可以拨打 400 632 6626，或加入官方Q群 12742516 提问
- 如果需要售后技术支持，你可以在 [Agora Dashboard](https://dashboard.agora.io) 提交工单

## 代码许可

The MIT License (MIT).


