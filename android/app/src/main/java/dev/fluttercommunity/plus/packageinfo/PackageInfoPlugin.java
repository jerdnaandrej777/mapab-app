package dev.fluttercommunity.plus.packageinfo;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import java.util.Map;

/**
 * Fallback implementation for package_info_plus on builds where the plugin module
 * is not linked correctly. Keeps MethodChannel contract compatible.
 */
public class PackageInfoPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
  private static final String CHANNEL_NAME = "dev.fluttercommunity.plus/package_info";

  private Context applicationContext;
  private MethodChannel channel;

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    applicationContext = binding.getApplicationContext();
    channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
      channel = null;
    }
    applicationContext = null;
  }

  @Override
  public void onMethodCall(MethodCall call, MethodChannel.Result result) {
    if (!"getAll".equals(call.method)) {
      result.notImplemented();
      return;
    }

    if (applicationContext == null) {
      result.error("no_context", "Application context unavailable", null);
      return;
    }

    try {
      PackageManager pm = applicationContext.getPackageManager();
      PackageInfo info = pm.getPackageInfo(applicationContext.getPackageName(), 0);

      Map<String, String> map = new HashMap<>();
      map.put(
          "appName",
          info.applicationInfo != null
              ? String.valueOf(info.applicationInfo.loadLabel(pm))
              : "");
      map.put("packageName", applicationContext.getPackageName());
      map.put("version", info.versionName != null ? info.versionName : "");
      map.put("buildNumber", String.valueOf(getLongVersionCode(info)));
      map.put("installTime", String.valueOf(info.firstInstallTime));
      map.put("updateTime", String.valueOf(info.lastUpdateTime));
      result.success(map);
    } catch (Exception e) {
      result.error("package_info_error", e.getMessage(), null);
    }
  }

  private long getLongVersionCode(PackageInfo info) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      return info.getLongVersionCode();
    }
    return info.versionCode;
  }
}
