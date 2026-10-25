package dev.harmony.quest;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.webkit.*;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.Toast;
import java.io.ByteArrayInputStream;
import java.util.Collections;

/** Bundled web app at a secure, app-owned origin. No remote JS bridge. */
public final class MainActivity extends Activity {
    private static final String HOST = "appassets.androidplatform.net";
    private WebView web;
    private PermissionRequest pending;
    private View fullscreen;
    private WebChromeClient.CustomViewCallback fullscreenCallback;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        android.view.WindowManager.LayoutParams windowOptions = getWindow().getAttributes();
        windowOptions.preferredRefreshRate = 60f;
        android.view.Display display = getWindowManager().getDefaultDisplay();
        android.view.Display.Mode currentMode = display.getMode();
        for (android.view.Display.Mode mode : display.getSupportedModes()) {
            if (Math.abs(mode.getRefreshRate() - 60f) < 1f
                && mode.getPhysicalWidth() == currentMode.getPhysicalWidth()
                && mode.getPhysicalHeight() == currentMode.getPhysicalHeight()) {
                windowOptions.preferredDisplayModeId = mode.getModeId();
                break;
            }
        }
        getWindow().setAttributes(windowOptions);
        web = new WebView(this);
        WebSettings settings = web.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(false);
        settings.setAllowContentAccess(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        settings.setMediaPlaybackRequiresUserGesture(true);
        if (android.os.Build.VERSION.SDK_INT >= 35) {
            web.setOnApplyWindowInsetsListener(new View.OnApplyWindowInsetsListener() {
                @Override public android.view.WindowInsets onApplyWindowInsets(View view, android.view.WindowInsets insets) {
                    android.graphics.Insets bars = insets.getInsets(android.view.WindowInsets.Type.systemBars());
                    view.setPadding(bars.left, bars.top, bars.right, bars.bottom);
                    return insets;
                }
            });
        }
        web.setWebViewClient(new WebViewClient() {
            @Override public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
                if (!HOST.equals(request.getUrl().getHost())) return null;
                if (!"https".equals(request.getUrl().getScheme()) || !"/index.html".equals(request.getUrl().getPath()))
                    return new WebResourceResponse("text/plain", "UTF-8", 404, "Not Found", Collections.emptyMap(), new ByteArrayInputStream(new byte[0]));
                try {
                    return new WebResourceResponse("text/html", "UTF-8", 200, "OK",
                        Collections.singletonMap("Permissions-Policy", "camera=(self)"), getAssets().open("index.html"));
                } catch (java.io.IOException error) {
                    return new WebResourceResponse("text/plain", "UTF-8", new ByteArrayInputStream("App asset missing".getBytes(java.nio.charset.StandardCharsets.UTF_8)));
                }
            }
            @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                Uri uri = request.getUrl();
                if ("https".equals(uri.getScheme()) && HOST.equals(uri.getHost())) return false;
                if (request.isForMainFrame() && ("https".equals(uri.getScheme()) || "http".equals(uri.getScheme()))) {
                    try { startActivity(new Intent(Intent.ACTION_VIEW, uri)); } catch (android.content.ActivityNotFoundException ignored) { }
                }
                return true;
            }
        });
        web.setWebChromeClient(new WebChromeClient() {
            @Override public void onPermissionRequest(PermissionRequest request) {
                runOnUiThread(new Runnable() { @Override public void run() {
                    if (!"https".equals(request.getOrigin().getScheme()) || !HOST.equals(request.getOrigin().getHost())) { request.deny(); return; }
                    boolean camera = java.util.Arrays.asList(request.getResources()).contains(PermissionRequest.RESOURCE_VIDEO_CAPTURE);
                    if (!camera) { request.deny(); return; }
                    if (checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                        request.grant(new String[]{PermissionRequest.RESOURCE_VIDEO_CAPTURE});
                    } else {
                        if (pending != null) pending.deny();
                        pending = request;
                        requestPermissions(new String[]{Manifest.permission.CAMERA}, 7);
                    }
                }});
            }
            @Override public void onPermissionRequestCanceled(PermissionRequest request) { if (pending == request) pending = null; }
            @Override public void onShowCustomView(View view, CustomViewCallback callback) {
                if (fullscreen != null) { callback.onCustomViewHidden(); return; }
                fullscreen = view; fullscreenCallback = callback;
                addContentView(view, new FrameLayout.LayoutParams(-1, -1));
                getWindow().getDecorView().setSystemUiVisibility(5894);
            }
            @Override public void onHideCustomView() { exitFullscreen(); }
        });
        setContentView(web);
        web.loadUrl("https://" + HOST + "/index.html");
    }
    private void exitFullscreen() {
        if (fullscreen == null) return;
        ((ViewGroup) fullscreen.getParent()).removeView(fullscreen);
        fullscreen = null;
        if (fullscreenCallback != null) fullscreenCallback.onCustomViewHidden();
        fullscreenCallback = null;
        getWindow().getDecorView().setSystemUiVisibility(0);
    }
    @Override public void onRequestPermissionsResult(int code, String[] permissions, int[] results) {
        super.onRequestPermissionsResult(code, permissions, results);
        if (code != 7 || pending == null) return;
        if (results.length > 0 && results[0] == PackageManager.PERMISSION_GRANTED)
            pending.grant(new String[]{PermissionRequest.RESOURCE_VIDEO_CAPTURE});
        else { pending.deny(); Toast.makeText(this, "Permita a câmera nas configurações do aplicativo para usar o rastreamento.", Toast.LENGTH_LONG).show(); }
        pending = null;
    }
    @Override protected void onPause() { super.onPause(); web.onPause(); web.pauseTimers(); }
    @Override protected void onResume() { super.onResume(); if (web != null) { web.onResume(); web.resumeTimers(); } }
    @Override protected void onDestroy() { if (pending != null) pending.deny(); web.destroy(); super.onDestroy(); }
    @Override public void onBackPressed() {
        if (fullscreen != null) exitFullscreen(); else if (web.canGoBack()) web.goBack(); else super.onBackPressed();
    }
}
