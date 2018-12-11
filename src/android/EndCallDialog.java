package com.docway.video;

import android.app.Activity;
import android.app.AlertDialog;
import android.view.View;
import android.widget.Button;
import io.ionic.starter.R;

public class EndCallDialog {

  private AlertDialog alert;
  private Button positive;
  private Button negative;

  private View.OnClickListener positiveListener;

  EndCallDialog(Activity activity) {
    View view = activity.getLayoutInflater().inflate(R.layout.dialog_end_call, null);
    AlertDialog.Builder builder = new AlertDialog.Builder(activity);
    builder.setView(view);

    alert = builder.create();
    if (alert.getWindow() != null) alert.getWindow().setBackgroundDrawableResource(android.R.color.transparent);

    positive = view.findViewById(R.id.positive);
    negative = view.findViewById(R.id.negative);

    positive.setOnClickListener(v -> {
      if (positiveListener != null) {
        positiveListener.onClick(v);
      }
      alert.dismiss();
    });

    negative.setOnClickListener(v -> {
      alert.dismiss();
    });
  }

  public void setPositiveListener(View.OnClickListener listener) {
    positiveListener = listener;
  }

  public void show() {
    alert.show();
  }
}
