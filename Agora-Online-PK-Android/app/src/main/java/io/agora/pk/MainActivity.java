package io.agora.pk;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.os.Bundle;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.text.TextUtils;
import android.view.View;
import android.widget.EditText;
import android.widget.Toast;

import io.agora.pk.utils.PKConstants;
import io.agora.rtc.Constants;

public class MainActivity extends Activity {

    private boolean hasPermission = false;

    private EditText mEtChannel;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mEtChannel = findViewById(R.id.et_channel);

        if (checkSelfPermissions()) {
            hasPermission = true;
        }
    }

    public void onBroadcastClicked(View v) {
        String channel = mEtChannel.getText().toString();
        if (TextUtils.isEmpty(channel)) {
            Toast.makeText(this, R.string.main_channel_hint, Toast.LENGTH_LONG).show();
            return;
        }
        ((PKApplication)getApplication()).getPkConfig().setBroadcasterAccount(channel);

        forwardTo(Constants.CLIENT_ROLE_BROADCASTER);
    }

    private void forwardTo(int clintRole) {
        if (hasPermission) {
            Intent intent = new Intent(MainActivity.this, PKBroadcasterActivity.class);
            intent.putExtra(PKConstants.USER_CLIENT_ROLE, clintRole);
            startActivity(intent);
        } else {
            Toast.makeText(this, "Permission limited", Toast.LENGTH_SHORT).show();
        }
    }

    private boolean checkSelfPermissions() {
        return checkSelfPermission(Manifest.permission.RECORD_AUDIO, 200) &&
                checkSelfPermission(Manifest.permission.CAMERA, 201) &&
                checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE, 202);
    }

    public boolean checkSelfPermission(String permission, int requestCode) {
        if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,
                    new String[]{permission},
                    requestCode);
            return false;
        }

        return true;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        switch (requestCode) {
            case 200: {
                if (grantResults.length > 0
                        && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    checkSelfPermission(Manifest.permission.CAMERA, 201);
                } else {
                    finish();
                }
                break;
            }
            case 201: {
                if (grantResults.length > 0
                        && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE, 202);
                    hasPermission = true;
                } else {
                    finish();
                }
                break;
            }
            case 202: {
                if (grantResults.length > 0
                        && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                } else {
                    finish();
                }
                break;
            }
        }
    }
}
