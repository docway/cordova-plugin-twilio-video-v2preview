package com.docway.video;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.SystemClock;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.design.widget.FloatingActionButton;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;
import com.twilio.video.*;
import com.twilio.video.CameraCapturer.CameraSource;
import io.ionic.starter.R;
import org.webrtc.MediaCodecVideoDecoder;
import org.webrtc.MediaCodecVideoEncoder;

import java.util.Arrays;
import java.util.Collections;

public class ConversationActivity extends AppCompatActivity {
    private static final int CAMERA_MIC_PERMISSION_REQUEST_CODE = 1;
    private static final String TAG = "VideoActivity";

    private String accessToken;
    private String roomId;
    private String remoteName;
    private Room room;
    private LocalParticipant localParticipant;
    private VideoView remoteVideo;
    private VideoView localVideo;

    private TextView remoteIdentity;
    private TextView stopwatch;
    private CameraCapturer cameraCapturer;
    @Nullable
    private LocalAudioTrack localAudioTrack;
    @Nullable
    private LocalVideoTrack localVideoTrack;
    private FloatingActionButton endCall;
    private FloatingActionButton switchCamera;
    private FloatingActionButton closeCamera;
    private FloatingActionButton muteMicrophone;
    private AudioManager audioManager;

    private int previousAudioMode;
    private boolean previousMicrophoneMute;
    private VideoRenderer localVideoRenderer;
    private boolean disconnectedFromOnDestroy;
    private Long startTime = 0L;

    private VideoCallReceiver receiver = new VideoCallReceiver();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_video);

        remoteVideo = findViewById(R.id.remote_video);
        localVideo = findViewById(R.id.local_video);
        remoteIdentity = findViewById(R.id.remote_identity);
        stopwatch = findViewById(R.id.stopwatch);

        endCall = findViewById(R.id.end_call);
        switchCamera = findViewById(R.id.switch_camera);
        closeCamera = findViewById(R.id.close_camera);
        muteMicrophone = findViewById(R.id.mute_microphone);

        setVolumeControlStream(AudioManager.STREAM_VOICE_CALL);
        audioManager = (AudioManager)getSystemService(Context.AUDIO_SERVICE);

        Intent intent = getIntent();

        this.roomId =   intent.getStringExtra("roomId");
        this.accessToken = intent.getStringExtra("token");
        this.remoteName =   intent.getStringExtra("remoteName");

        if (!checkPermissionForCameraAndMicrophone()) {
            requestPermissionForCameraAndMicrophone();
        } else {
            createAudioAndVideoTracks();
            connectToRoom(roomId);
        }

        intializeUI();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if (requestCode == CAMERA_MIC_PERMISSION_REQUEST_CODE) {
            boolean cameraAndMicPermissionGranted = true;

            for (int grantResult : grantResults) {
                cameraAndMicPermissionGranted &= grantResult == PackageManager.PERMISSION_GRANTED;
            }

            if (cameraAndMicPermissionGranted) {
                createAudioAndVideoTracks();
                connectToRoom(roomId);
            } else {
                Toast.makeText(this,
                        R.string.permissions_needed,
                        Toast.LENGTH_LONG).show();
            }
        }
    }

    @Override
    protected  void onResume() {
        super.onResume();

        registerReceiver(receiver, new IntentFilter(Intent.ACTION_HEADSET_PLUG));

        if (localVideoTrack == null && checkPermissionForCameraAndMicrophone() && cameraCapturer != null) {
            localVideoTrack = LocalVideoTrack.create(this, true, cameraCapturer);
            if (localVideoTrack != null) {
              localVideoTrack.addRenderer(localVideoRenderer);
              if (localParticipant != null) localParticipant.publishTrack(localVideoTrack);
            }
        }
    }

    @Override
    protected void onPause() {
        unregisterReceiver(receiver);

        if (localVideoTrack != null) {
            if (localParticipant != null) {
                localParticipant.unpublishTrack(localVideoTrack);
            }

            localVideoTrack.release();
            localVideoTrack = null;
        }
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        if (room != null && room.getState() != Room.State.DISCONNECTED) {
            room.disconnect();
            disconnectedFromOnDestroy = true;
        }

        if (localAudioTrack != null) {
            localAudioTrack.release();
            localAudioTrack = null;
        }

        if (localVideoTrack != null) {
            localVideoTrack.release();
            localVideoTrack = null;
        }

        super.onDestroy();
    }

    private boolean checkPermissionForCameraAndMicrophone(){
        int resultCamera = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA);
        int resultMic = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO);
        return resultCamera == PackageManager.PERMISSION_GRANTED && resultMic == PackageManager.PERMISSION_GRANTED;
    }

    private void requestPermissionForCameraAndMicrophone(){
        if (ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.CAMERA) ||
                ActivityCompat.shouldShowRequestPermissionRationale(this,
                        Manifest.permission.RECORD_AUDIO)) {
            Toast.makeText(this,
                    R.string.permissions_needed,
                    Toast.LENGTH_LONG).show();
        } else {
            ActivityCompat.requestPermissions(
                    this,
                    new String[]{Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO},
                    CAMERA_MIC_PERMISSION_REQUEST_CODE);
        }
    }

    private void createAudioAndVideoTracks() {
        localAudioTrack = LocalAudioTrack.create(this, true);
        cameraCapturer = new CameraCapturer(this, CameraSource.FRONT_CAMERA);
        localVideoTrack = LocalVideoTrack.create(this, true, cameraCapturer);
        if (localVideoTrack != null) localVideoTrack.addRenderer(localVideo);
        remoteVideo.setMirror(true);
        localVideoRenderer = localVideo;
        localVideo.setMirror(cameraCapturer.getCameraSource() == CameraSource.FRONT_CAMERA);
    }

    private void connectToRoom(String roomName) {
        MediaCodecVideoEncoder.disableVp8HwCodec();
        MediaCodecVideoEncoder.disableVp9HwCodec();
        MediaCodecVideoDecoder.disableVp8HwCodec();
        MediaCodecVideoDecoder.disableVp9HwCodec();
        configureAudio(true);
        ConnectOptions.Builder connectOptionsBuilder = new ConnectOptions.Builder(accessToken)
                .roomName(roomName);

        if (localAudioTrack != null) {
            connectOptionsBuilder
                    .preferAudioCodecs(Arrays.asList(new OpusCodec(), new IsacCodec()))
                    .audioTracks(Collections.singletonList(localAudioTrack));
        }

        if (localVideoTrack != null) connectOptionsBuilder.videoTracks(Collections.singletonList(localVideoTrack));

        room = Video.connect(this, connectOptionsBuilder.build(), roomListener());
        setDisconnectAction();
    }

    private void intializeUI() {
        switchCamera.show();
        switchCamera.setOnClickListener(switchCameraClickListener());

        closeCamera.show();
        closeCamera.setOnClickListener(localVideoClickListener());

        muteMicrophone.show();
        muteMicrophone.setOnClickListener(muteClickListener());
    }

    private void setDisconnectAction() {
        endCall.show();
        endCall.setOnClickListener(disconnectClickListener());
    }

    private void addParticipant(RemoteParticipant participant) {
        remoteIdentity.setText(participant.getIdentity());
        participant.setListener(participantListener());
        startStopWatch();
    }

    private void addParticipantVideo(RemoteVideoTrack videoTrack) {
        remoteVideo.setMirror(false);
        videoTrack.addRenderer(remoteVideo);
    }

    private void removeParticipant() {
        remoteIdentity.setText("");
    }

    private void removeParticipantVideo(RemoteVideoTrack videoTrack) {
        videoTrack.removeRenderer(remoteVideo);
    }

    private Room.Listener roomListener() {
        return new Room.Listener() {
            @Override
            public void onConnected(Room room) {
                localParticipant = room.getLocalParticipant();
                setTitle(room.getName());
                for (RemoteParticipant participanty : room.getRemoteParticipants()) {
                  addParticipant(participanty);
                  break;
                }
                Log.i(TAG, "Connected to " + room.getName());
            }

            @Override
            public void onConnectFailure(Room room, TwilioException e) {
                configureAudio(false);
                Log.e(TAG,"Failed to connect to " + room.getName(), e);
            }

            @Override
            public void onDisconnected(Room room, TwilioException e) {
                localParticipant = null;
                ConversationActivity.this.room = null;
                configureAudio(false);

                if (!disconnectedFromOnDestroy) {
                    intializeUI();
                }
            }

            @Override
            public void onParticipantConnected(Room room, RemoteParticipant remoteParticipant) {
                addParticipant(remoteParticipant);
            }

            @Override
            public void onParticipantDisconnected(Room room, RemoteParticipant remoteParticipant) {
                removeParticipant();
            }

            @Override
            public void onRecordingStarted(Room room) {
                Log.d(TAG, "onRecordingStarted");
            }

            @Override
            public void onRecordingStopped(Room room) {
                Log.d(TAG, "onRecordingStopped");
            }
        };
    }

    private RemoteParticipant.Listener participantListener() {
        return new RemoteParticipant.Listener() {
            @Override
            public void onAudioTrackPublished(RemoteParticipant remoteParticipant, RemoteAudioTrackPublication remoteAudioTrackPublication) {  }

            @Override
            public void onAudioTrackUnpublished(RemoteParticipant remoteParticipant, RemoteAudioTrackPublication remoteAudioTrackPublication) {  }

            @Override
            public void onAudioTrackSubscribed(RemoteParticipant remoteParticipant, RemoteAudioTrackPublication remoteAudioTrackPublication, RemoteAudioTrack remoteAudioTrack) {  }

            @Override
            public void onAudioTrackSubscriptionFailed(RemoteParticipant remoteParticipant, RemoteAudioTrackPublication remoteAudioTrackPublication, TwilioException twilioException) {  }

            @Override
            public void onAudioTrackUnsubscribed(RemoteParticipant remoteParticipant, RemoteAudioTrackPublication remoteAudioTrackPublication, RemoteAudioTrack remoteAudioTrack) {  }

            @Override
            public void onVideoTrackPublished(RemoteParticipant remoteParticipant, RemoteVideoTrackPublication remoteVideoTrackPublication) {  }

            @Override
            public void onVideoTrackUnpublished(RemoteParticipant remoteParticipant, RemoteVideoTrackPublication remoteVideoTrackPublication) {  }

            @Override
            public void onVideoTrackSubscribed(RemoteParticipant remoteParticipant, RemoteVideoTrackPublication remoteVideoTrackPublication, RemoteVideoTrack remoteVideoTrack) {
                addParticipantVideo(remoteVideoTrack);
            }

            @Override
            public void onVideoTrackSubscriptionFailed(RemoteParticipant remoteParticipant, RemoteVideoTrackPublication remoteVideoTrackPublication, TwilioException twilioException) {  }

            @Override
            public void onVideoTrackUnsubscribed(RemoteParticipant remoteParticipant, RemoteVideoTrackPublication remoteVideoTrackPublication, RemoteVideoTrack remoteVideoTrack) {
                removeParticipantVideo(remoteVideoTrack);

                if (room != null) {
                    room.disconnect();
                    disconnectedFromOnDestroy = true;
                }
                finish();
            }

            @Override
            public void onDataTrackPublished(RemoteParticipant remoteParticipant, RemoteDataTrackPublication remoteDataTrackPublication) {  }

            @Override
            public void onDataTrackUnpublished(RemoteParticipant remoteParticipant, RemoteDataTrackPublication remoteDataTrackPublication) {  }

            @Override
            public void onDataTrackSubscribed(RemoteParticipant remoteParticipant, RemoteDataTrackPublication remoteDataTrackPublication, RemoteDataTrack remoteDataTrack) {  }

            @Override
            public void onDataTrackSubscriptionFailed(RemoteParticipant remoteParticipant, RemoteDataTrackPublication remoteDataTrackPublication, TwilioException twilioException) {  }

            @Override
            public void onDataTrackUnsubscribed(RemoteParticipant remoteParticipant, RemoteDataTrackPublication remoteDataTrackPublication, RemoteDataTrack remoteDataTrack) {  }

            @Override
            public void onAudioTrackEnabled(RemoteParticipant remoteParticipant, RemoteAudioTrackPublication remoteAudioTrackPublication) {  }

            @Override
            public void onAudioTrackDisabled(RemoteParticipant remoteParticipant, RemoteAudioTrackPublication remoteAudioTrackPublication) {  }

            @Override
            public void onVideoTrackEnabled(RemoteParticipant remoteParticipant, RemoteVideoTrackPublication remoteVideoTrackPublication) {  }

            @Override
            public void onVideoTrackDisabled(RemoteParticipant remoteParticipant, RemoteVideoTrackPublication remoteVideoTrackPublication) {  }
        };
    }

    private View.OnClickListener disconnectClickListener() {
        return v -> {
            EndCallDialog dialog = new EndCallDialog(this);
            dialog.setPositiveListener(clickListener -> {
              if (room != null) {
                room.disconnect();
                disconnectedFromOnDestroy = true;
              }
              finish();
            });
            dialog.show();
        };
    }

    private View.OnClickListener switchCameraClickListener() {
        return v -> {
            if (cameraCapturer != null) {
                CameraSource cameraSource = cameraCapturer.getCameraSource();
                cameraCapturer.switchCamera();
                if (localVideo.getVisibility() == View.VISIBLE) {
                    localVideo.setMirror(cameraSource == CameraSource.BACK_CAMERA);
                } else {
                    remoteVideo.setMirror(cameraSource == CameraSource.BACK_CAMERA);
                }
            }
        };
    }

    private View.OnClickListener localVideoClickListener() {
        return v -> {
            if (localVideoTrack != null) {
                boolean enable = !localVideoTrack.isEnabled();
                localVideoTrack.enable(enable);
                int icon;
                if (enable) {
                    icon = R.drawable.ic_cam_on;
                    switchCamera.setEnabled(true);
                } else {
                    icon = R.drawable.ic_cam_off;
                    switchCamera.setEnabled(false);
                }
                closeCamera.setImageDrawable(
                        ContextCompat.getDrawable(ConversationActivity.this, icon));
            }
        };
    }

    private View.OnClickListener muteClickListener() {
        return v -> {
            if (localAudioTrack != null) {
                boolean enable = !localAudioTrack.isEnabled();
                localAudioTrack.enable(enable);
                int icon = enable ?
                        R.drawable.ic_microphone_on : R.drawable.ic_microphone_off;
                muteMicrophone.setImageDrawable(ContextCompat.getDrawable(
                        ConversationActivity.this, icon));
            }
        };
    }

    private void configureAudio(boolean enable) {
        if (localAudioTrack != null) localAudioTrack.enable(enable);

        if (audioManager != null) {
            if (enable) {
                previousAudioMode = audioManager.getMode();
                previousMicrophoneMute = audioManager.isMicrophoneMute();

                audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
                audioManager.setMicrophoneMute(false);
                audioManager.setSpeakerphoneOn(!isHeadphoneConnected());
            } else {
                audioManager.setMode(previousAudioMode);
                audioManager.setMicrophoneMute(previousMicrophoneMute);
            }
        }
    }

  private boolean isHeadphoneConnected() {
    if (audioManager != null) {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        for (AudioDeviceInfo device : audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)) {
          if (device.getType() == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
            device.getType() == AudioDeviceInfo.TYPE_WIRED_HEADSET) {
            return true;
          }
        }
      } else {
        return audioManager.isWiredHeadsetOn();
      }
    }

    return false;
  }

  private void startStopWatch() {
      startTime = SystemClock.uptimeMillis();

      Handler handler = new Handler();
      Runnable runnable = new Runnable() {
        @Override
        public void run() {
          Long currentTime = SystemClock.uptimeMillis() - startTime;
          int seconds = (int) (currentTime / 1000);
          int minutes = seconds / 60;
          seconds = seconds % 60;
          stopwatch.setText(getString(R.string.stopwatch, String.format("%02d", minutes), String.format("%02d", seconds)));
          handler.postDelayed(this, 1000);
        }
      };
      new Handler().postDelayed(runnable, 1000);
    }
}
