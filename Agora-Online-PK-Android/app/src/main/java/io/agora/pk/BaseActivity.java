package io.agora.pk;

import android.os.Bundle;
import android.os.Handler;
import android.support.annotation.Nullable;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;

import io.agora.rtc.live.LiveTranscoding;
import io.agora.pk.engine.WorkThread;
import io.agora.pk.utils.PKConstants;
import io.agora.rtc.RtcEngine;

public abstract class BaseActivity extends AppCompatActivity {
    protected LiveTranscoding liveTranscoding;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.e("BaseActivity-->", "onCreate-----");
        ((PKApplication)getApplication()).initWorkThread();
    }

    @Override
    protected void onPostCreate(@Nullable Bundle savedInstanceState) {
        super.onPostCreate(savedInstanceState);
        Log.e("BaseActivity-->", "onPostCreate-----");
        initUIandEvent();
    }

    protected abstract void initUIandEvent();

    protected abstract void deInitUIandEvent();

    protected RtcEngine rtcEngine() {
        return ((PKApplication) getApplication()).getWorkThread().rtcEngine();
    }

    protected WorkThread workThread() {
        return ((PKApplication) getApplication()).getWorkThread();
    }

    // init LiveTranscoding structure, set width, height and other properties
    protected LiveTranscoding liveTranscoding(boolean isPkNow) {
        liveTranscoding = new LiveTranscoding();
        if (isPkNow) {
            liveTranscoding.width = getWindow().getWindowManager().getDefaultDisplay().getWidth();
            liveTranscoding.height = (int)(getWindow().getWindowManager().getDefaultDisplay().getWidth() / 1.5);
        }else {
            liveTranscoding.width = getWindow().getWindowManager().getDefaultDisplay().getWidth();
            liveTranscoding.height = getWindow().getWindowManager().getDefaultDisplay().getHeight();
        }
        liveTranscoding.videoBitrate = PKConstants.LIVE_TRANSCODING_BITRATE;
        liveTranscoding.lowLatency = true;
        liveTranscoding.videoFramerate = 15;

        return liveTranscoding;
    }

    // set LieTrancoding property for each user
    protected ArrayList<LiveTranscoding.TranscodingUser> getTransCodingUser(int localUid, List<Integer> publishers, boolean isPkNow) {

        ArrayList<LiveTranscoding.TranscodingUser> users;
        int index = 0;
        int viewWidth;
        int viewHEdge;

        if (!isPkNow) {
            viewHEdge = getWindow().getWindowManager().getDefaultDisplay().getHeight();
            viewWidth = getWindow().getWindowManager().getDefaultDisplay().getWidth();
        } else {
            viewHEdge = (int)(getWindow().getWindowManager().getDefaultDisplay().getWidth() / 1.5);
            viewWidth = getWindow().getWindowManager().getDefaultDisplay().getWidth() / 2;
        }

        users = new ArrayList<>(publishers.size());

        LiveTranscoding.TranscodingUser user0 = new LiveTranscoding.TranscodingUser();
        user0.uid = localUid;
        user0.alpha = 1;
        user0.zOrder = 0;
        user0.audioChannel = 0;

        user0.x = 0;
        user0.y = 0;
        user0.width = viewWidth;
        user0.height = viewHEdge;
        users.add(user0);

        index++;
        for (int entry : publishers) {
            if (entry == localUid)
                continue;

            LiveTranscoding.TranscodingUser tmpUser = new LiveTranscoding.TranscodingUser();
            tmpUser.uid = entry;
            tmpUser.x = viewWidth;
            tmpUser.y = 0;
            tmpUser.width = viewWidth;
            tmpUser.height = viewHEdge;
            tmpUser.zOrder = index + 1;
            tmpUser.audioChannel = 0;
            tmpUser.alpha = 1f;

            users.add(tmpUser);
            index++;
        }

        return users;
    }
}
