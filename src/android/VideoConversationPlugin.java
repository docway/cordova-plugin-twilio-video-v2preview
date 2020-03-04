package com.docway.video;

import android.content.Intent;
import android.os.Bundle;
import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;

public class VideoConversationPlugin extends CordovaPlugin {

    private CallbackContext callbackContext;
    private CordovaInterface cordova;
    private String roomId;
    private String token;
    private String remoteParticipantName;
    private String connectionMessage;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        this.cordova = cordova;
	  }

	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {
	    this.callbackContext = callbackContext;
		if (action.equals("open")) {
            this.openRoom(args);
        }
        return true;
    }

    public void openRoom(final JSONArray args) {
        try {
            this.roomId = args.getString(0);
            this.token = args.getString(1);
            this.remoteParticipantName = args.getString(2);
            this.connectionMessage = args.getString(3);
            final CordovaPlugin that = this;
            final String token = this.token;
            final String roomId = this.roomId;
            final String remoteParticipantName = this.remoteParticipantName;

            LOG.d("TOKEN", token);
            LOG.d("ROOMID", roomId);
            LOG.d("REMOTE PARTICIPANT", remoteParticipantName);

            cordova.getThreadPool().execute(() -> {
                Intent intentTwilioVideo = new Intent(that.cordova.getActivity().getBaseContext(), ConversationActivity.class);
                intentTwilioVideo.putExtra("token", token);
                intentTwilioVideo.putExtra("roomId", roomId);
                intentTwilioVideo.putExtra("remoteName", remoteParticipantName);
                intentTwilioVideo.putExtra("connectionMessage", this.connectionMessage);
                that.cordova.startActivityForResult(that, intentTwilioVideo, 0);
            });
        } catch (JSONException e) {  }
    }

    public Bundle onSaveInstanceState() {
        Bundle state = new Bundle();
        state.putString("token", this.token);
        state.putString("roomId", this.roomId);
        state.putString("remoteName", this.remoteParticipantName);
        return state;
    }

    public void onRestoreStateForActivityResult(Bundle state, CallbackContext callbackContext) {
        this.token = state.getString("token");
        this.roomId = state.getString("roomId");
        this.remoteParticipantName = state.getString("remoteName");
        this.callbackContext = callbackContext;
    }
}
