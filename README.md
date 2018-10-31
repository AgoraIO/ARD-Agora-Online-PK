# ARD-Agora-Online-PK

# **Agora PK Hosting**

The Agora PK Hosting solution is designed for CDN Live push-and-pull stream scenarios that involve switching between the following scenarios:

- Co-hosting in Standard mode
- Co-hosting in PK mode

# Co-hosting in Standard Mode

The hosts can use third-party applications such as ijkplayer to push streams to CDN Live. The push stream address for the hosts are independent and the audience can only see the corresponding host.

# Co-hosting in PK Mode

The hosts need to quit the CDN Live push stream process, join the same Agora channel, and set the co-hosting composite mode on the Agora server using the _setLiveTranscoding_ API method; then push the composite stream to the original CDN address using the push stream _addPublishStreamUrl_ API method.

The CDN Live audience can then participate in the PK between the hosts. The CDN Live audience does not need to change the CDN Live URL address as the hosts will still use the previous CDN Live push stream URL address. When either one of the hosts quit the Agora channel, the other host will switch to the Standard mode.

# **Architectural Design**
![ArchitectureDesign.png](Image/ArchitectureDesign.png)

You can find the Agora [implementation code](https://github.com/AgoraIO/ARD-Agora-Online-PK/tree/master/Agora-Online-PK-Android) for Android on Github. You can also download the [APK file](https://pan.baidu.com/share/init?surl=T7Psw5KxNkSsYRPiTTB7Dg) and request for a password by contacting [sales@Agora.io](mailto:sales@agora.io).

# **Implementation**

- The Agora PK Hosting solution uses the Agora Video SDK in the communication mode.

- When switching to the PK mode from the Standard mode, each host needs to quit the original CDN Live stream and join the same Agora channel through the application logic.

- Under the PK mode:
1. Each host needs to set the composite configuration using the _setLiveTranscoding API method a_nd add the CDN Live push stream URL address, using the _addPublishStreamUrl API method,_ in the Agora channel.
2. The hosts need to ensure that the CDN Live push stream URL address will not change after switching from the Standard mode.
3. When either one of the hosts quit the Agora channel, the other host will quit the channel and switch to the Standard mode through the application.

- Before switching to the Standard mode from the PK mode:
1. Each host needs to remove the previous CDN Live push stream URL address using the _removePublishStreamUrl API_ method.
2. Each host needs to push the stream to the original CDN URL address.


# **Integration Guide**

# Integration SDK

- For Android, see [Configuring the DEV runtime](https://docs.agora.io/en/Interactive%20Broadcast/android_video?platform=Android).
- For IOS, see [Configuring the DEV runtime.](https://docs.agora.io/en/Interactive%20Broadcast/ios_video?platform=iOS)

# Switching Between the Co-hosting Standard Mode and Co-hosting PK Mode

_Android_:

1. [Video broadcasting realization](https://docs.agora.io/en/2.3.1/product/Interactive%20Broadcast/Quickstart%20Guide/broadcast_video_android?platform=Android)
2. [Stream pushing to CDN Live](https://docs.agora.io/en/2.3.1/product/Interactive%20Broadcast/Quickstart%20Guide/push_stream_android2.0?platform=Android)
3. Call the [_removePublishStreamUrl_](https://docs.agora.io/en/2.4/product/Interactive%20Broadcast/API%20Reference/live_video_android?platform=Android) API method to remove the stream URL address.

_IOS_:

1. [Video broadcasting realization](https://docs.agora.io/en/2.3.1/product/Interactive%20Broadcast/Quickstart%20Guide/broadcast_video_ios?platform=iOS)

1. [Stream pushing to CDN Live](https://docs.agora.io/en/2.3.1/product/Interactive%20Broadcast/Quickstart%20Guide/push_stream_ios2.0?platform=iOS)
2. Call the [_removePublishStreamUrl_](https://docs.agora.io/en/2.4/product/Interactive%20Broadcast/API%20Reference/live_video_ios?platform=iOS) API method to remove the stream URL address.

Ijkplayer Realization (Optional)

Android: See [&#39;Integration of ijkplayer framework for Android development&#39;](https://github.com/Bilibili/ijkplayer).
