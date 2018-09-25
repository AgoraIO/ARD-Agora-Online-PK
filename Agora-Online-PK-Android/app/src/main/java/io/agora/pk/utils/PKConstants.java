package io.agora.pk.utils;

import io.agora.rtc.Constants;

public class PKConstants {
    public final static int HANDLER_MESSAGE_JOIN_CHANNEL = 0x100001;
    public final static int HANDLER_MESSAGE_PREVIEW = 0x100002;
    public final static int HANDLER_MESSAGE_EXIT = 0x100003;
    public final static int HANDLER_MESSAGE_LEAVE_CHANNEL = 0x100004;
    public final static int HANDLER_MESSAGE_CONIFG_ENGINE = 0x100005;
    public final static int HANDLER_MESSAGE_REMOTE_VIEW = 0x100006;

    public final static String MEDIA_APP_ID = "0279f083791444fc835764dfedd614ce";

    public final static String BUNDLE_ACCOUNT_NAME = "ACCOUNT_NAME";
    public final static String USER_CLIENT_ROLE = "USER_CLIENT_ROLE";
    public final static int VIDEO_PROFILE = Constants.VIDEO_PROFILE_480P_8;

    public final static int LIVE_TRANSCODING_HEIGHT = 848;
    public final static int LIVE_TRANSCODING_WIDTH = 480;
    public final static int LIVE_TRANSCODING_BITRATE = 1200;

    public final static String PUBLISH_URL = "rtmp://vid-218.push.chinanetcenter.broadcastapp.agora.io/live/";
    public final static String PUBLISH_PULL_URL = "rtmp://vid-218.pull.chinanetcenter.broadcastapp.agora.io/live/";
}
