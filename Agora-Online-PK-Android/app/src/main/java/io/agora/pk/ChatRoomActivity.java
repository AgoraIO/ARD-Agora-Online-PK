package io.agora.pk;

import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.support.v7.app.AlertDialog;
import android.view.LayoutInflater;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

import io.agora.live.LiveTranscoding;
import io.agora.pk.engine.IMediaEngineHandler;
import io.agora.pk.engine.ISignalEngineHandler;
import io.agora.pk.utils.MessageUtils;
import io.agora.pk.utils.PKConstants;
import io.agora.pk.utils.StringUtils;
import io.agora.pk.utils.video.IjkVideoView;
import io.agora.rtc.Constants;
import io.agora.rtc.IRtcEngineEventHandler;
import io.agora.rtc.RtcEngine;
import io.agora.rtc.video.VideoCanvas;
import tv.danmaku.ijk.media.player.IMediaPlayer;
import tv.danmaku.ijk.media.player.IjkMediaPlayer;

public class ChatRoomActivity extends BaseActivity implements IMediaEngineHandler, ISignalEngineHandler,
        IMediaPlayer.OnPreparedListener, IMediaPlayer.OnCompletionListener{
    private int mClientRole;

    private FrameLayout mFLSingleView;

    private FrameLayout mFLPKViewLeft;
    private FrameLayout mFLPKViewRight;

    private FrameLayout mFLPKMidBoard;
    private FrameLayout mFLPKViewClient;

    private Button mBtnExitPk;

    private boolean isPKnow = false;
    private boolean isBroadcaster = false;

    private int localUid = 0;
    private List<Integer> mUserList = new ArrayList<>();
    private LiveTranscoding liveTranscoding;

    private IjkVideoView mClientVideoView;
    private SurfaceView localView;
    private SurfaceView remoteView;

    private TextView mTvStartPk;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_chat_room_main);

        mClientRole = getIntent().getIntExtra(PKConstants.USER_CLIENT_ROLE, Constants.CLIENT_ROLE_AUDIENCE);
    }

    @Override
    protected void initUIandEvent() {
        mFLSingleView = findViewById(R.id.fl_chat_room_main_video_view);
        mFLPKViewLeft = findViewById(R.id.fl_chat_room_main_pk_board_left);
        mFLPKViewRight = findViewById(R.id.fl_chat_room_main_pk_board_right);
        mFLPKViewClient = findViewById(R.id.fl_chat_room_main_pk_client_video);
        mFLPKMidBoard = findViewById(R.id.fl_chat_room_main_pk_board);
        mTvStartPk = findViewById(R.id.et_chat_room_main_start_pk);
        mBtnExitPk = findViewById(R.id.btn_main_pk_exit_pk);

       initEngine();
    }

    public void initEngine(){
        workThread().handler().addEventHandler(this);
        workThread().signalHandler().addSignalCallback(this);
        workThread().configEngine(mClientRole, PKConstants.VIDEO_PROFILE);
        if (mClientRole == Constants.CLIENT_ROLE_BROADCASTER) {
            isBroadcaster = true;
            workThread().joinChannel(((PKApplication) getApplication()).getPkConfig().getBroadcasterAccount(), 0);
            workThread().joinSignalChannel(((PKApplication) getApplication()).getPkConfig().getBroadcasterAccount(), ((PKApplication) getApplication()).getPkConfig().getBroadcasterAccount());
        } else if (mClientRole == Constants.CLIENT_ROLE_AUDIENCE) {
            isBroadcaster = false;
            mClientVideoView = new IjkVideoView(this);
            mClientVideoView.setOnCompletionListener(this);
            mClientVideoView.setOnPreparedListener(this);

            workThread().joinSignalChannel(((PKApplication) getApplication()).getPkConfig().getBroadcasterAccount(), ((PKApplication) getApplication()).getPkConfig().getAudienceSignalAccount());
        }
        changeViewToSingle();
        localView = RtcEngine.CreateRendererView(this);
        remoteView = RtcEngine.CreateRendererView(this);
    }

    @Override
    protected void deInitUIandEvent() {

    }

    // finish btn
    public void onBackClicked(View v) {

        stopPlay();

        if (isBroadcaster) {
            removePublishUrl();
            workThread().leaveChannel();
        }

        mUserList.clear();
        workThread().leaveSignalChannel();
        finish();
    }

    @Override
    public void onBackPressed() {
        super.onBackPressed();
        onBackClicked(null);
    }

    // exit pk
    public void onExitPKClicked(View v) {
        isPKnow = false;

        if (remoteView.getParent() != null)
            ((ViewGroup)(remoteView.getParent())).removeAllViews();

        ((PKApplication) getApplication()).getPkConfig().setPkMediaAccount("");

        mUserList.clear();
        workThread().leaveChannel();
        workThread().joinChannel(((PKApplication) getApplication()).getPkConfig().getBroadcasterAccount(), 0);
        changeViewToSingle();
    }

    public void onStartPKClicked(View v) {
        final AlertDialog.Builder alertDialog = new AlertDialog.Builder(this);
        View rootView = LayoutInflater.from(this).inflate(R.layout.pop_view_pk, null);
        alertDialog.setView(rootView);
        final AlertDialog dialog = alertDialog.create();
        if (null != dialog.getWindow())
            dialog.getWindow().setBackgroundDrawable(new ColorDrawable(android.graphics.Color.TRANSPARENT));
        dialog.show();

        Button btn = rootView.findViewById(R.id.btn_start_pk);
        final EditText et = rootView.findViewById(R.id.et_pk_channel);
        btn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!StringUtils.validate(et.getText().toString())) {
                    Toast.makeText(ChatRoomActivity.this, "please input a channel account", Toast.LENGTH_SHORT).show();
                    return;
                }

                isPKnow = true;
                ((PKApplication) getApplication()).getPkConfig().setPkMediaAccount(et.getText().toString());
                workThread().leaveChannel();
                mUserList.clear();
                workThread().joinChannel(((PKApplication) getApplication()).getPkConfig().getPkMediaAccount(), 0);
                dialog.dismiss();
            }
        });
    }

    public void changeViewToSingle() {
        mFLPKMidBoard.setVisibility(View.INVISIBLE);
        mFLSingleView.setVisibility(View.VISIBLE);

        mFLSingleView.setBackgroundColor(Color.BLACK);
        if (isBroadcaster)
            mTvStartPk.setVisibility(View.VISIBLE);
        else {
            mTvStartPk.setVisibility(View.INVISIBLE);
        }
    }

    public void changeViewToPkBroadcaster() {
        mFLSingleView.setVisibility(View.INVISIBLE);
        mFLPKMidBoard.setVisibility(View.VISIBLE);
        mTvStartPk.setVisibility(View.VISIBLE);

        mFLPKViewClient.setVisibility(View.INVISIBLE);
        mFLPKViewRight.setVisibility(View.VISIBLE);
        mFLPKViewLeft.setVisibility(View.VISIBLE);
        mBtnExitPk.setVisibility(View.VISIBLE);
    }

    public void changeViewToPkAudience() {
        mFLSingleView.setVisibility(View.INVISIBLE);
        mFLPKMidBoard.setVisibility(View.VISIBLE);
        mTvStartPk.setVisibility(View.INVISIBLE);

        mFLPKViewClient.setVisibility(View.VISIBLE);
        mFLPKViewRight.setVisibility(View.INVISIBLE);
        mFLPKViewLeft.setVisibility(View.INVISIBLE);
        mBtnExitPk.setVisibility(View.INVISIBLE);
    }

    public void setLocalPreviewView(int uid) {
        workThread().preview(true, localView, uid);

        if (mFLSingleView.getChildCount() > 0) {
            mFLSingleView.removeAllViews();
        }

        if (localView.getParent() != null)
            ((ViewGroup)(localView.getParent())).removeAllViews();

        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        localView.setZOrderOnTop(false);
        localView.setZOrderMediaOverlay(false);
        localView.setLayoutParams(lp);
        mFLSingleView.addView(localView);
    }

    public void setClientSingleView() {
        mClientVideoView.setLayoutParams(new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        if (mFLSingleView.getChildCount() > 0)
            mFLSingleView.removeAllViews();

        if (mClientVideoView.getParent() != null)
            ((ViewGroup)(mClientVideoView.getParent())).removeAllViews();

        mFLSingleView.addView(mClientVideoView);
    }

    public void setLocalPkLeftView(int uid) {
        workThread().preview(true, localView, uid);

        if (mFLPKViewLeft.getChildCount() > 0)
            mFLPKViewLeft.removeAllViews();

        if (localView.getParent() != null)
            ((ViewGroup) (localView.getParent())).removeAllViews();

        mFLPKViewLeft.addView(localView);
    }

    public void setRemotePkRightView(int uid) {
        if (mFLPKViewRight.getChildCount() > 0)
            mFLPKViewRight.removeAllViews();

        if (remoteView.getParent() != null)
            ((ViewGroup) (remoteView.getParent())).removeAllViews();

        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        remoteView.setZOrderOnTop(false);
        remoteView.setZOrderMediaOverlay(false);
        remoteView.setLayoutParams(lp);

        rtcEngine().setupRemoteVideo(new VideoCanvas(remoteView, Constants.RENDER_MODE_HIDDEN, uid));
        mFLPKViewRight.addView(remoteView);
    }

    public void setClientPKView() {
        mClientVideoView.setLayoutParams(new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        if (mFLPKViewClient.getChildCount() > 0)
            mFLPKViewClient.removeAllViews();

        if (mClientVideoView.getParent() != null)
            ((ViewGroup)(mClientVideoView.getParent())).removeAllViews();

        mFLPKViewClient.addView(mClientVideoView);
    }

    @Override
    public void onJoinChannelSuccess(final String channel, final int uid, int elapsed) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                localUid = uid;
                mUserList.add(localUid);
                if (isPKnow) {
                    changeViewToPkBroadcaster();
                    setLocalPkLeftView(uid);
                    workThread().sendChannelMessage(MessageUtils.switchToCtrlMsg(true));
                } else {
                    changeViewToSingle();
                    setLocalPreviewView(uid);
                    workThread().sendChannelMessage(MessageUtils.switchToCtrlMsg(false));
                }
                setLiveTranscoding();
                publishUrl();
            }
        });
    }

    @Override
    public void onUserJoined(final int uid, int elapsed) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (mUserList.size() < 2) {
                    mUserList.add(uid);
                    setLiveTranscoding();
                    setRemotePkRightView(uid);
                }
            }
        });

    }

    @Override
    public void onStreamPublished(String url, int error) {
    }

    @Override
    public void onStreamUnpublished(String url) {
    }

    @Override
    public void onError(int err) {
    }

    @Override
    public void onUserOffline(final int uid, int reason) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (mUserList.contains(uid)) {
                    mUserList.remove(new Integer(uid));
                    onExitPKClicked(null);
                    setLiveTranscoding();
                }
            }
        });

    }

    @Override
    public void onLeaveChannel(IRtcEngineEventHandler.RtcStats stats) {
        liveTranscoding = null;
    }

    //------------------------------------------------------------------------------
    public void publishUrl() {
        rtcEngine().addPublishStreamUrl(PKConstants.PUBLISH_URL + ((PKApplication) getApplication()).getPkConfig().getBroadcasterAccount(), true);
    }

    public void removePublishUrl() {
        rtcEngine().removePublishStreamUrl(PKConstants.PUBLISH_URL + ((PKApplication) getApplication()).getPkConfig().getBroadcasterAccount());
    }

    public void setLiveTranscoding() {
        if (liveTranscoding == null) {
            liveTranscoding = liveTranscoding(isPKnow);
        }

        if (liveTranscoding != null) {
            liveTranscoding.setUsers(getTransCodingUser(localUid, mUserList, isPKnow));
            liveTranscoding.userCount = mUserList.size();
            rtcEngine().setLiveTranscoding(liveTranscoding);
        }
    }

    //--------------------------------------------------
    @Override
    public void onChannelJoined(final String channelID) {
    }

    @Override
    public void onChannelJoinFailed(String channelID, int ecode) {
    }

    @Override
    public void onChannelUserJoined(final String account, int uid) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                workThread().sendP2pMessage(MessageUtils.switchToCtrlMsg(isPKnow), account);
            }
        });
    }

    @Override
    public void onMessageInstantReceive(String account, int uid, final String msg) {
        handleMessage(msg);
    }

    @Override
    public void onMessageChannelReceive(String channelID, String account, int uid, final String msg) {
        handleMessage(msg);
    }

    @Override
    public void onError(String name, int ecode, String desc) {
    }

    @Override
    public void onLogout(final int ecode) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (ecode == 103) {
                    onBackPressed();
                    Toast.makeText(ChatRoomActivity.this, "重复登陆", Toast.LENGTH_SHORT).show();
                }
            }
        });
    }


    // --------------------------------ijk Player--------------------
    private void startPlay(String url) {
        IjkMediaPlayer.loadLibrariesOnce(null);
        IjkMediaPlayer.native_profileBegin("libijkplayer.so");
        IjkMediaPlayer ijkMediaPlayer = new IjkMediaPlayer();
        ijkMediaPlayer.setOption(1, "analyzemaxduration", 100L);
        ijkMediaPlayer.setOption(1, "probesize", 10240L);
        ijkMediaPlayer.setOption(1, "flush_packets", 1L);
        ijkMediaPlayer.setOption(4, "packet-buffering", 0L);
        ijkMediaPlayer.setOption(4, "framedrop", 1L);
        mClientVideoView.setVideoURI(Uri.parse(url));
        mClientVideoView.requestFocus();
        mClientVideoView.start();
    }

    private void stopPlay() {
        if (mClientVideoView != null && !isBroadcaster)
            mClientVideoView.stopPlayback();
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (mClientVideoView != null && !isBroadcaster) {
            mClientVideoView.enterBackground();
        }
    }

    //---------------------------
    public void handleMessage(final String msg) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    new JSONObject(msg);
                } catch (JSONException e) {
                    return;
                }

                Object msgs = MessageUtils.getMessage(msg);
                if (msgs instanceof Boolean) {
                    if (!isBroadcaster) {
                        if (mClientVideoView != null){
                            stopPlay();

                            new Handler().postDelayed(new Runnable() {
                                @Override
                                public void run() {
                                    startPlay(PKConstants.PUBLISH_PULL_URL + (((PKApplication) getApplication()).getPkConfig().getAudienceSignalAccount()));
                                }
                            }, 3000);
                        }

                        if ((boolean) msgs) {
                            changeViewToPkAudience();
                            setClientPKView();
                        } else {
                            changeViewToSingle();
                            setClientSingleView();
                        }
                    }
                }
            }
        });
    }

    @Override
    public void onPrepared(IMediaPlayer mp) {

    }

    @Override
    public void onCompletion(IMediaPlayer mp) {
        onBackClicked(null);
    }
}
