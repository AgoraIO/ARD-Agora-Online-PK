# PK 连麦

*Other Languages： [English](README.md)*

声网 PK 连麦方案场景针对 CDN 推流拉流场景设计，包含以下内容:

* 场景描述
* 架构设计
* 实现细节
* 集成指南

## 场景描述

声网 PK 连麦场景针对 CDN 推流拉流场景设计，主要涉及两种模式的切换：

* 双主播普通模式
* 双主播 PK 模式

### 双主播普通模式

 主播可以采用第三方工具（比如 ijkplayer）推流到 CDN。两个主播的 CDN 推流地址彼此独立，各自的观众不会看到对方主播。

### 双主播 PK 模式

 两个主播退出 CDN 推流并同时加入同一个声网频道，各自在声网服务端设置双主播的合图（setLiveTranscoding），并通过声网提供的推流接口（addPublishStreamUrl）将合图后的流推送到原先的 CDN 地址。各自的 CDN 观众看到两个主播开始 PK。由于两个 PK 主播各自的 CDN 推流地址未发生改变，CDN 观  众端不需要切换 CDN 地址。只要任意一个主播离开声网频道，另一主播也退出 PK 模式返回普通模式。

## 架构设计

下图为一起 PK 连麦场景的声网实现架构图：

.. image:: competing_hosts.png
   :scale: 60%

声网已在 GitHub 提供了 Android 平台的 [实现代码](https://github.com/AgoraIO/ARD-Agora-Online-PK/tree/master/Agora-Online-PK-Android)。你也可以下载实现的 [apk 文件](https://pan.baidu.com/s/1T7Psw5KxNkSsYRPiTTB7Dg) 下载密码请联系声网客服 sales@agora.io 。

## 实现细节

* 声网 PK 连麦方案采用直播模式的 Agora Video SDK。
* 从普通模式进入 PK 模式时，每个主播都需要退出原来的旁路推流。
* 从普通模式进入 PK 模式时，各位主播需要同时加入同一声网频道，可由 APP 控制实现。
* PK 模式下，每个主播都需要设置合图（setLiveTranscoding）
* PK 模式下，设置合图（setLiveTranscoding）和添加 CDN 推流地址（addPublishStreamUrl）需要在声网频道内进行。
* PK 模式下，双方主播的 CDN 推流地址应与普通模式时选用的 URL 地址一致确保 CDN 观众无需切换 CDN 地址。
* PK 模式下，只要有一位主播退出声网频道，其余主播也同时退出声网频道进入普通模式，可由 APP 控制实现。
* 从 PK 模式进入普通模式前，每个主播都需要移除原先的 CDN 推流地址（removePublishStreamUrl）。
* 从 PK 模式进入普通模式时，每个主播需要重新向原来的 CDN 地址推流确保 CDN 观众无需切换地址。


## 集成指南

### 集成 SDK

详见 [设置开发环境](https://docs.agora.io/cn/2.3.1/product/Interactive%20Broadcast/Quickstart%20Guide/broadcast_audio_android?platform=Android)


### 实现双主播普通模式和 PK 模式的切换

1. [实现视频直播](https://docs.agora.io/cn/2.3.1/product/Interactive%20Broadcast/Quickstart%20Guide/broadcast_video_android?platform=Android)

2. [推流到 CDN ](https://docs.agora.io/cn/2.3.1/product/Interactive%20Broadcast/Quickstart%20Guide/push_stream_android2.0?platform=Android)

3. 调用 :ref:`removePublishStreamUrl_android`

### ijkplayer 实现 (可选)

详见 [Android 开发 ijkplayer 框架的集成](https://github.com/Bilibili/ijkplayer) 。
