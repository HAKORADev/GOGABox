package org.godotengine.plugin.unityads;

import com.unity3d.ads.BannerAd;
import com.unity3d.ads.BannerConfiguration;
import com.unity3d.ads.BannerShowListener;
import com.unity3d.ads.BannerSize;
import com.unity3d.ads.IUnityAdsInitializationListener;
import com.unity3d.ads.IUnityAdsLoadListener;
import com.unity3d.ads.IUnityAdsShowListener;
import com.unity3d.ads.LoadListener;
import com.unity3d.ads.UnityAds;
import com.unity3d.ads.UnityAdsError;
import com.unity3d.ads.UnityAdsShowOptions;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import android.app.Activity;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.LinearLayout;

import java.util.HashSet;
import java.util.Set;

/**
 * Unity Ads bridge plugin for Godot 4.x (plugin system v1), SDK 4.20.0.
 *
 * GDScript usage (after materialize stages this into the gradle source set):
 *   var ads = Engine.get_singleton("UnityAds")
 *   ads.configure(game_id, test_mode, banner_enabled)
 *   ads.load(placement) / ads.show(placement) / ads.banner_show(placement) / ads.banner_hide()
 *
 * Signals (connect from GDScript):
 *   init_complete() , init_failed(String message)
 *   ad_loaded(String placement) , ad_failed(String placement, String message)
 *   ad_shown(String placement)  , ad_closed(String placement, int completion_state)
 *   banner_loaded()             , banner_failed(String message)
 *
 * completion_state mirrors UnityAds.UnityAdsShowCompletionState ordinal:
 * SKIPPED=1 (0? see enum), COMPLETED=2. The GDScript layer treats >= 2 as watched.
 */
public class UnityAdsPlugin extends GodotPlugin {

    private static final int COMPLETION_UNKNOWN = 0;

    private final Activity activity;
    private String gameId = "";
    private boolean testMode = true;
    private boolean bannerEnabled = true;
    private boolean initialized = false;

    private final Set<String> loadedPlacements = new HashSet<>();

    // banner state
    private BannerAd bannerAd = null;
    private LinearLayout bannerHolder = null;
    private boolean bannerVisible = false;
    private boolean bannerWanted = false;
    private final android.os.Handler mainHandler = new android.os.Handler(android.os.Looper.getMainLooper());

    public UnityAdsPlugin(Godot godot) {
        super(godot);
        this.activity = getActivity();
    }

    @Override
    public String getPluginName() {
        return "UnityAds";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("init_complete"));
        signals.add(new SignalInfo("init_failed", String.class));
        signals.add(new SignalInfo("ad_loaded", String.class));
        signals.add(new SignalInfo("ad_failed", String.class, String.class));
        signals.add(new SignalInfo("ad_shown", String.class));
        signals.add(new SignalInfo("ad_closed", String.class, Integer.class));
        signals.add(new SignalInfo("banner_loaded"));
        signals.add(new SignalInfo("banner_failed", String.class));
        return signals;
    }

    // ------------------------------------------------------------------ API

    @UsedByGodot
    public void configure(String gameId, boolean testMode, boolean bannerEnabled) {
        this.gameId = gameId;
        this.testMode = testMode;
        this.bannerEnabled = bannerEnabled;
        if (gameId == null || gameId.isEmpty()) {
            emitSignal("init_failed", "empty game id");
            return;
        }
        UnityAds.setDebugMode(testMode);
        UnityAds.initialize(activity, gameId, testMode, new IUnityAdsInitializationListener() {
            @Override
            public void onInitializationComplete() {
                initialized = true;
                emitSignal("init_complete");
            }

            @Override
            public void onInitializationFailed(UnityAds.UnityAdsInitializationError error, String message) {
                emitSignal("init_failed", String.valueOf(error) + ": " + message);
            }
        });
    }

    @UsedByGodot
    public boolean is_supported() {
        return true;
    }

    @UsedByGodot
    public boolean is_loaded(String placement) {
        return loadedPlacements.contains(placement);
    }

    @UsedByGodot
    public void load(final String placement) {
        if (!initialized) return;
        UnityAds.load(placement, new IUnityAdsLoadListener() {
            @Override
            public void onUnityAdsAdLoaded(String adUnitId) {
                loadedPlacements.add(adUnitId);
                emitSignal("ad_loaded", adUnitId);
            }

            @Override
            public void onUnityAdsFailedToLoad(String adUnitId, UnityAds.UnityAdsLoadError error, String message) {
                loadedPlacements.remove(adUnitId);
                emitSignal("ad_failed", adUnitId, String.valueOf(error) + ": " + message);
            }
        });
    }

    @UsedByGodot
    public void show(final String placement) {
        if (!initialized) return;
        UnityAds.show(activity, placement, new UnityAdsShowOptions(), new IUnityAdsShowListener() {
            @Override
            public void onUnityAdsShowFailure(String adUnitId, UnityAds.UnityAdsShowError error, String message) {
                loadedPlacements.remove(adUnitId);
                emitSignal("ad_failed", adUnitId, String.valueOf(error) + ": " + message);
            }

            @Override
            public void onUnityAdsShowStart(String adUnitId) {
                emitSignal("ad_shown", adUnitId);
            }

            @Override
            public void onUnityAdsShowClick(String adUnitId) { }

            @Override
            public void onUnityAdsShowComplete(String adUnitId, UnityAds.UnityAdsShowCompletionState state) {
                loadedPlacements.remove(adUnitId);
                int s = (state != null) ? state.ordinal() : COMPLETION_UNKNOWN;
                emitSignal("ad_closed", adUnitId, s);
                // pre-load the next one right away
                UnityAdsPlugin.this.load(adUnitId);
            }
        });
    }

    @UsedByGodot
    public void banner_show(final String placement) {
        if (!bannerEnabled || !initialized) return;
        bannerWanted = true;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                ensureBannerHolder();
                if (bannerAd != null && bannerAd.getView() != null) {
                    // fresh banner already loaded -> just reveal it
                    bannerHolder.setVisibility(View.VISIBLE);
                    bannerVisible = true;
                } else {
                    // no banner yet (first show, or stale one destroyed on
                    // hide): load a FRESH one. Banners expire - reusing an old
                    // view is why the banner "worked once and never again".
                    bannerVisible = false;
                    loadBanner(placement);
                }
            }
        });
    }

    @UsedByGodot
    public void banner_hide() {
        bannerWanted = false;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (bannerHolder != null) {
                    bannerHolder.removeAllViews();
                    bannerHolder.setVisibility(View.GONE);
                }
                bannerVisible = false;
                // drop the banner view entirely so the next show loads fresh
                // fill (banners expire - a stale view shows nothing)
                bannerAd = null;
            }
        });
    }

    // -------------------------------------------------------------- banner

    private void ensureBannerHolder() {
        if (bannerHolder != null) return;
        ViewGroup root = activity.findViewById(android.R.id.content);
        bannerHolder = new LinearLayout(activity);
        bannerHolder.setOrientation(LinearLayout.VERTICAL);
        bannerHolder.setGravity(Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
        // transparent + wrap-content: only the 320x50dp standard banner shows,
        // never a big dark slab across the bottom of the game.
        bannerHolder.setBackgroundColor(0x00000000);
        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dpToPx(52));
        lp.gravity = Gravity.BOTTOM;
        root.addView(bannerHolder, lp);
        bannerHolder.setVisibility(View.GONE);
    }

    private void loadBanner(final String placement) {
        try {
            BannerShowListener showListener = new BannerShowListener() {
                @Override
                public void onImpression(BannerAd ad) { emitSignal("banner_loaded"); }

                @Override
                public void onClicked(BannerAd ad) { }

                @Override
                public void onFailedToShow(BannerAd ad, UnityAdsError error) {
                    emitSignal("banner_failed", String.valueOf(error));
                }
            };
            BannerConfiguration config = new BannerConfiguration.Builder(
                    placement, BannerSize.Companion.getStandard(), showListener).build();

            BannerAd.load(config, new LoadListener<BannerAd>() {
                @Override
                public void onAdLoaded(BannerAd ad, UnityAdsError error) {
                    if (ad == null) {
                        emitSignal("banner_failed", String.valueOf(error));
                        retryBannerLater(placement);
                        return;
                    }
                    bannerAd = ad;
                    activity.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            try {
                                View bannerView = bannerAd.getView();
                                bannerHolder.removeAllViews();
                                bannerHolder.addView(bannerView, new FrameLayout.LayoutParams(
                                        FrameLayout.LayoutParams.WRAP_CONTENT,
                                        FrameLayout.LayoutParams.WRAP_CONTENT,
                                        Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL));
                                bannerHolder.setVisibility(bannerWanted ? View.VISIBLE : View.GONE);
                                bannerVisible = bannerWanted;
                            } catch (Exception e) {
                                emitSignal("banner_failed", String.valueOf(e));
                            }
                        }
                    });
                }
                // NOTE: the LoadListener interface reports failures through
                // onAdLoaded(null, error) - covered above.
            });
        } catch (Throwable t) {
            emitSignal("banner_failed", String.valueOf(t));
            retryBannerLater(placement);
        }
    }

    /** One quiet retry after 8s - no fill is common right after init. */
    private void retryBannerLater(final String placement) {
        if (!bannerWanted) return;
        mainHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (bannerWanted && bannerAd == null) {
                    loadBanner(placement);
                }
            }
        }, 8000);
    }

    private int dpToPx(int dp) {
        return Math.round(dp * activity.getResources().getDisplayMetrics().density);
    }
}
