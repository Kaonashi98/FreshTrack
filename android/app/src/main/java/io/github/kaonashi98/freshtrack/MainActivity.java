package io.github.kaonashi98.freshtrack;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.time.ZoneId;

public final class MainActivity extends FlutterActivity {
    private static final String TIME_ZONE_CHANNEL = "freshtrack/timezone";

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
    }
}
