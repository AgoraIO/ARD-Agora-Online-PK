package io.agora.pk.engine;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;
import android.view.SurfaceView;

import java.lang.ref.WeakReference;

import io.agora.pk.utils.PKConstants;
import io.agora.pk.utils.StringUtils;
import io.agora.rtc.Constants;
import io.agora.rtc.RtcEngine;
import io.agora.rtc.video.VideoCanvas;

public class WorkThread extends Thread {
    private final static String TAG = WorkThread.class.getName();

    private Context mContext;

    private RtcEngine mRtcEngine;
    private WorkHandler mWorkHandler;
    private MediaEngineHandler mMediaEngineHandler;

    private boolean isThreadReady = false;

    private static class WorkHandler extends Handler {
        private WorkThread workThread;

        public WorkHandler(WorkThread wt) {
            this.workThread = wt;
        }

        public void release() {
            workThread = null;
        }

        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);

            switch (msg.what) {
                case PKConstants.HANDLER_MESSAGE_JOIN_CHANNEL:
                    workThread.joinChannel((String) msg.obj, msg.arg1);
                    break;
                case PKConstants.HANDLER_MESSAGE_PREVIEW:
                    Object[] previewData = (Object[]) msg.obj;
                    workThread.preview((boolean) previewData[0], (SurfaceView) previewData[1], (int) previewData[2]);
                    break;
                case PKConstants.HANDLER_MESSAGE_EXIT:
                    workThread.exit();
                    break;
                case PKConstants.HANDLER_MESSAGE_LEAVE_CHANNEL:
                    workThread.leaveChannel();
                    break;
                case PKConstants.HANDLER_MESSAGE_CONIFG_ENGINE:
                    workThread.configEngine((Integer) msg.obj, msg.arg1);
                    break;
                case PKConstants.HANDLER_MESSAGE_REMOTE_VIEW:
                    Object[] remoteData = (Object[]) msg.obj;
                    workThread.setmRemoteView((SurfaceView) remoteData[0], (int) remoteData[1]);
                    break;
                default:
                    throw new RuntimeException("unknown handler event");
            }
        }
    }

    public WorkThread(WeakReference<Context> ctx) {
        this.mContext = ctx.get();
        this.mMediaEngineHandler = new MediaEngineHandler();
    }

    @Override
    public void run() {
        super.run();
        Looper.prepare();
        mWorkHandler = new WorkHandler(this);
        ensureEnineCreated();
        isThreadReady = true;
        Looper.loop();
    }

    public void waitForReady() {
        while (!isThreadReady) {
            try {
                Thread.sleep(20);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    private void ensureEnineCreated() {
        if (mRtcEngine != null)
            return;

        if (!StringUtils.validate(PKConstants.MEDIA_APP_ID))
            throw new RuntimeException("media app id is null");

        try {
            mRtcEngine = RtcEngine.create(mContext, PKConstants.MEDIA_APP_ID, mMediaEngineHandler.engineEventHandler);
        } catch (Exception e) {
            e.printStackTrace();
        }

        mRtcEngine.setChannelProfile(Constants.CHANNEL_PROFILE_LIVE_BROADCASTING);
    }

    public RtcEngine rtcEngine() {
        return mRtcEngine;
    }

    public MediaEngineHandler handler() {
        return mMediaEngineHandler;
    }

    public void exit() {
        if (Thread.currentThread() != this) {
            mWorkHandler.release();
            return;
        }
        Looper.myLooper().quit();
        isThreadReady = false;
    }

    public final void joinChannel(final String channel, int uid) {
        if (Thread.currentThread() != this) {
            Message envelop = new Message();
            envelop.what = PKConstants.HANDLER_MESSAGE_JOIN_CHANNEL;
            envelop.obj = channel;
            envelop.arg1 = uid;
            mWorkHandler.sendMessage(envelop);
            return;
        }

        ensureEnineCreated();

        int ret = mRtcEngine.joinChannel(null, channel, "", uid);
        Log.e(TAG, "joinChannel:" + ret);
    }

    public final void configEngine(int channelProfile, int videoProfile) {
        if (Thread.currentThread() != this) {
            Message msg = Message.obtain();
            msg.what = PKConstants.HANDLER_MESSAGE_CONIFG_ENGINE;
            msg.obj = channelProfile;
            msg.arg1 = videoProfile;
            mWorkHandler.sendMessage(msg);

            return;
        }

        ensureEnineCreated();

        mRtcEngine.setClientRole(channelProfile);
        mRtcEngine.setVideoProfile(videoProfile, true);
        mRtcEngine.enableVideo();
        mRtcEngine.enableDualStreamMode(true);
    }

    public final void preview(boolean start, SurfaceView view, int uid) {
        if (Thread.currentThread() != this) {
            Message envelop = new Message();
            envelop.what = PKConstants.HANDLER_MESSAGE_PREVIEW;
            envelop.obj = new Object[]{start, view, uid};
            mWorkHandler.sendMessage(envelop);
            return;
        }

        ensureEnineCreated();

        if (start) {
            mRtcEngine.setupLocalVideo(new VideoCanvas(view, VideoCanvas.RENDER_MODE_HIDDEN, uid));
            mRtcEngine.startPreview();
        } else {
            mRtcEngine.stopPreview();
        }
    }

    public final void setmRemoteView(SurfaceView view, int uid) {
        if (Thread.currentThread() != this) {
            Message envelop = new Message();
            envelop.what = PKConstants.HANDLER_MESSAGE_REMOTE_VIEW;
            envelop.obj = new Object[]{view, uid};
            mWorkHandler.sendMessage(envelop);
            return;
        }

        ensureEnineCreated();

        mRtcEngine.setupRemoteVideo(new VideoCanvas(view, VideoCanvas.RENDER_MODE_HIDDEN, uid));
    }


    public final void leaveChannel() {
        if (Thread.currentThread() != this) {
            Message envelop = new Message();
            envelop.what = PKConstants.HANDLER_MESSAGE_LEAVE_CHANNEL;
            mWorkHandler.sendMessage(envelop);
            return;
        }
        if (mRtcEngine != null) {
            mRtcEngine.leaveChannel();
        }
    }

}
