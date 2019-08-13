package io.agora.pk.model;

import android.util.Log;

import java.util.Iterator;
import java.util.concurrent.ConcurrentHashMap;

import io.agora.rtc.IRtcEngineEventHandler;

public class MyEngineEventHandler {

    private ConcurrentHashMap<Integer, AGEventHandler> handlers = new ConcurrentHashMap<>();

    public void addEventHandler(AGEventHandler handler) {
        handlers.put(0, handler);
    }

    public void removeEventHandler(AGEventHandler handler) {
        handlers.remove(0);
    }

    private static final String LOG_TAG = "AG_EVT";

    final IRtcEngineEventHandler mEventHandlerList = new IRtcEngineEventHandler() {
        @Override
        public void onJoinChannelSuccess(String channel, int uid, int elapsed) {
            Log.e(LOG_TAG, "success");
            super.onJoinChannelSuccess(channel, uid, elapsed);

            if (handlers.isEmpty()) {
                return;
            }

            Iterator<AGEventHandler> it = handlers.values().iterator();
            while (it.hasNext()) {
                it.next().onJoinChannelSuccess(channel, uid, elapsed);
            }
        }

        @Override
        public void onRejoinChannelSuccess(String channel, int uid, int elapsed) {
            super.onRejoinChannelSuccess(channel, uid, elapsed);

            if (handlers.isEmpty()) {
                return;
            }

            Iterator<AGEventHandler> it = handlers.values().iterator();
            while (it.hasNext()) {
                it.next().onJoinChannelSuccess(channel, uid, elapsed);
            }
        }

        @Override
        public void onUserJoined(int uid, int elapsed) {
            Log.e(LOG_TAG, "joined");
            super.onUserJoined(uid, elapsed);

            if (handlers.isEmpty()) {
                return;
            }

            Iterator<AGEventHandler> it = handlers.values().iterator();
            while (it.hasNext()) {
                it.next().onUserJoined(uid, elapsed);
            }
        }

        @Override
        public void onStreamPublished(String url, int error) {
            Log.e(LOG_TAG, "onStreamUnpublished: " + url);
            super.onStreamPublished(url, error);

            if (handlers.isEmpty()) {
                return;
            }

            Iterator<AGEventHandler> it = handlers.values().iterator();
            while (it.hasNext()) {
                it.next().onStreamPublished(url, error);
            }
        }

        @Override
        public void onStreamUnpublished(String url) {
            Log.e(LOG_TAG, "onStreamUnpublished: " + url);
            super.onStreamUnpublished(url);

            if (handlers.isEmpty()) {
                return;
            }

            Iterator<AGEventHandler> it = handlers.values().iterator();
            while (it.hasNext()) {
                it.next().onStreamUnpublished(url);
            }
        }

        @Override
        public void onError(int err) {
            super.onError(err);
            Log.e(LOG_TAG, "error: " + err);

            if (handlers.isEmpty()) {
                return;
            }

            Iterator<AGEventHandler> it = handlers.values().iterator();
            while (it.hasNext()) {
                it.next().onError(err);
            }
        }

        @Override
        public void onUserOffline(int uid, int reason) {
            Log.d(LOG_TAG, "joined");
            super.onUserOffline(uid, reason);

            if (handlers.isEmpty()) {
                return;
            }

            Iterator<AGEventHandler> it = handlers.values().iterator();
            while (it.hasNext()) {
                it.next().onUserOffline(uid, reason);
            }
        }

        @Override
        public void onLeaveChannel(RtcStats stats) {
            super.onLeaveChannel(stats);

            if (handlers.isEmpty()) {
                return;
            }

            Iterator<AGEventHandler> it = handlers.values().iterator();
            while (it.hasNext()) {
                it.next().onLeaveChannel(stats);
            }
        }
    };
}
