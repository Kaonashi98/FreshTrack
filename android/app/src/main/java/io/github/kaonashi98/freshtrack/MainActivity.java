package io.github.kaonashi98.freshtrack;

import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.time.ZoneId;

public final class MainActivity extends FlutterActivity {
    private static final String TIME_ZONE_CHANNEL = "freshtrack/timezone";
    private static final String SETTINGS_CHANNEL = "freshtrack/system_settings";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                TIME_ZONE_CHANNEL
        ).setMethodCallHandler((call, result) -> {
            if (call.method.equals("getLocalTimezone")) {
                result.success(ZoneId.systemDefault().getId());
            } else {
                result.notImplemented();
            }
        });
        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                SETTINGS_CHANNEL
        ).setMethodCallHandler((call, result) -> {
            if (call.method.equals("openNotificationSettings")) {
                final Intent intent = new Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
                intent.putExtra(Settings.EXTRA_APP_PACKAGE, getPackageName());
                startActivity(intent);
                result.success(null);
            } else if (call.method.equals("openExactAlarmSettings")) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    final Intent intent = new Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM);
                    intent.setData(Uri.parse("package:" + getPackageName()));
                    startActivity(intent);
                }
                result.success(null);
            } else {
                result.notImplemented();
            }
        });
    }
}
