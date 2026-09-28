package org.godotengine.plugin.gogabrowser;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

import android.app.Activity;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

/**
 * GogaBrowser - the in-app WebView seat for GOGABox web games (v043 pass 3,
 * WEB_GAMES.md realized). The system WebView hosted INSIDE the app: no
 * browser chrome, no tab, no redirection - the tech the owner named
 * ("there is a tech like this where it runs in-app browser without having
 * the full browser in app").
 *
 * GDScript (names MUST match the @UsedByGodot methods EXACTLY - Godot does
 * no snake_case/camelCase conversion, the notify plugin's law):
 *   var b = Engine.get_singleton("GogaBrowser")
 *   b.load_url("http://127.0.0.1:31450/index.html")
 *   b.show_surface()
 *   b.hide_surface()
 *   b.is_visible()
 *
 * The page's SDK bridge is sdk/web/goga_bridge.js over the box's WebSocket
 * door (127.0.0.1:31443) - the WebView reaches the box's loopback, so the
 * bridge needs NO JavascriptInterface plumbing; the same JS file serves
 * the Android seat and the PC app-mode window. The surface sits ABOVE the
 * Godot view in the activity's content view (FrameLayout overlay).
 */
public class GogaBrowserPlugin extends GodotPlugin {

    private final Activity activity;
    private WebView web;
    private FrameLayout overlay;

    public GogaBrowserPlugin(Godot godot) {
        super(godot);
        this.activity = getActivity();
    }

    @Override
    public String getPluginName() {
        return "GogaBrowser";
    }

    // ------------------------------------------------------------ GDScript API

    @UsedByGodot
    public boolean load_url(String url) {
        if (activity == null || url == null || url.isEmpty()) {
            return false;
        }
        activity.runOnUiThread(() -> {
            ensureBuilt();
            web.loadUrl(url);
        });
        return true;
    }

    @UsedByGodot
    public boolean show_surface() {
        if (activity == null) {
            return false;
        }
        activity.runOnUiThread(() -> {
            ensureBuilt();
            overlay.setVisibility(View.VISIBLE);
            web.requestFocus();
        });
        return true;
    }

    @UsedByGodot
    public boolean hide_surface() {
        if (activity == null) {
            return false;
        }
        activity.runOnUiThread(() -> {
            if (overlay != null) {
                overlay.setVisibility(View.GONE);
                web.loadUrl("about:blank");
            }
        });
        return true;
    }

    @UsedByGodot
    public boolean is_visible() {
        if (activity == null || overlay == null) {
            return false;
        }
        final boolean[] out = {false};
        final Object latch = new Object();
        activity.runOnUiThread(() -> {
            out[0] = overlay.getVisibility() == View.VISIBLE;
            synchronized (latch) { latch.notifyAll(); }
        });
        synchronized (latch) {
            try { latch.wait(200); } catch (InterruptedException ignored) {}
        }
        return out[0];
    }

    // ------------------------------------------------------------ internals

    private void ensureBuilt() {
        if (overlay != null) {
            return;
        }
        ViewGroup root = (ViewGroup) activity.findViewById(android.R.id.content);
        overlay = new FrameLayout(activity);
        overlay.setVisibility(View.GONE);
        root.addView(overlay, new ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT));
        web = new WebView(activity);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setAllowFileAccess(false);
        s.setAllowContentAccess(false);
        web.setWebViewClient(new WebViewClient());
        overlay.addView(web, new FrameLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        Gravity.TOP));
    }
}
