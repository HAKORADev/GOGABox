package org.godotengine.plugin.levelplay;

import android.app.Activity;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.LinearLayout;

import com.unity3d.mediation.LevelPlay;
import com.unity3d.mediation.LevelPlayAdError;
import com.unity3d.mediation.LevelPlayAdInfo;
import com.unity3d.mediation.LevelPlayConfiguration;
import com.unity3d.mediation.LevelPlayInitError;
import com.unity3d.mediation.LevelPlayInitListener;
import com.unity3d.mediation.LevelPlayInitRequest;
import com.unity3d.mediation.banner.LevelPlayBannerAdView;
import com.unity3d.mediation.banner.LevelPlayBannerAdViewListener;
import com.unity3d.mediation.interstitial.LevelPlayInterstitialAd;
import com.unity3d.mediation.interstitial.LevelPlayInterstitialAdListener;
import com.unity3d.mediation.rewarded.LevelPlayReward;
import com.unity3d.mediation.rewarded.LevelPlayRewardedAd;
import com.unity3d.mediation.rewarded.LevelPlayRewardedAdListener;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

/**
 * Unity LevelPlay (mediation) bridge plugin for Godot 4.x (plugin system v1),
 * SDK com.unity3d.ads-mediation:mediation-sdk:9.6.0.
 *
 * LevelPlay is a MEDIATION layer: Unity Ads, Meta Audience Network, AdMob,
 * AppLovin, Mintegral, Liftoff, DT Exchange, ... all compete for every
 * impression. Which networks are active is configured on the LevelPlay
 * dashboard (per-app), not in this code. Adding a network in gradle =
 * one adapter line in this plugin's plugin.meta.json (gradle_deps).
 *
 * API verified against the real AAR via javap (see plugins/levelplay/README.md).
 *
 * GDScript usage (after materialize stages this into the gradle source set):
 *   var ads = Engine.get_singleton("LevelPlayAds")
 *   ads.configure(app_key, test_mode, banner_enabled)
 *   # after init_complete:
 *   ads.set_ad_unit("interstitial", ad_unit_id)
 *   ads.set_ad_unit("rewarded", ad_unit_id)
 *   ads.load("interstitial") / ads.load("rewarded")
 *   ads.is_loaded("interstitial") / ads.show("interstitial") / ads.show("rewarded")
 *   ads.banner_show(banner_ad_unit_id) / ads.banner_hide()
 *
 * Signals (connect from GDScript):
 *   init_complete()                          , init_failed(String message)
 *   ad_loaded(String kind)                   , ad_failed(String kind, String message)
 *   ad_shown(String kind)                    , ad_closed(String kind)
 *   reward_received(String reward_name, int reward_amount)
 *   banner_loaded()                          , banner_failed(String message)
 *
 * kind is "interstitial" | "rewarded" (the plugin's own handle, not a LevelPlay id).
 */
public class LevelPlayPlugin extends GodotPlugin {

    private static final String KIND_INTERSTITIAL = "interstitial";
    private static final String KIND_REWARDED = "rewarded";

    private final Activity activity;

    private String appKey = "";
    private boolean testMode = true;
    private boolean bannerEnabled = true;
    private boolean initialized = false;

    private LevelPlayInterstitialAd interstitialAd = null;
    private LevelPlayRewardedAd rewardedAd = null;

    // banner state
    private LevelPlayBannerAdView bannerView = null;
    private String bannerAdUnitId = "";
    private LinearLayout bannerHolder = null;
    private boolean bannerVisible = false;

    public LevelPlayPlugin(Godot godot) {
        super(godot);
        this.activity = getActivity();
    }

    @Override
    public String getPluginName() {
        return "LevelPlayAds";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("init_complete"));
        signals.add(new SignalInfo("init_failed", String.class));
        signals.add(new SignalInfo("ad_loaded", String.class));
        signals.add(new SignalInfo("ad_failed", String.class, String.class));
        signals.add(new SignalInfo("ad_shown", String.class));
        signals.add(new SignalInfo("ad_closed", String.class));
        signals.add(new SignalInfo("reward_received", String.class, Integer.class));
        signals.add(new SignalInfo("banner_loaded"));
        signals.add(new SignalInfo("banner_failed", String.class));
        return signals;
    }

    // ------------------------------------------------------------------ init

    @UsedByGodot
    public void configure(String appKey, boolean testMode, boolean bannerEnabled) {
        this.appKey = appKey == null ? "" : appKey;
        this.testMode = testMode;
        this.bannerEnabled = bannerEnabled;
        if (this.appKey.isEmpty()) {
            emitSignal("init_failed", "empty LevelPlay app key (see docs/ADS.md - Unity Dashboard -> LevelPlay)");
            return;
        }
        try {
            // puts every mediated network into debug/test mode on this device
            LevelPlay.setAdaptersDebug(testMode);
            LevelPlayInitRequest request = new LevelPlayInitRequest.Builder(this.appKey).build();
            LevelPlay.init(activity, request, new LevelPlayInitListener() {
                @Override
                public void onInitSuccess(LevelPlayConfiguration configuration) {
                    initialized = true;
                    emitSignal("init_complete");
                }

                @Override
                public void onInitFailed(LevelPlayInitError error) {
                    initialized = false;
                    emitSignal("init_failed", "code " + error.getErrorCode() + ": " + error.getErrorMessage());
                }
            });
        } catch (Throwable t) {
            emitSignal("init_failed", String.valueOf(t));
        }
    }

    @UsedByGodot
    public boolean is_supported() {
        return true;
    }

    @UsedByGodot
    public String get_sdk_version() {
        try {
            return LevelPlay.getSdkVersion();
        } catch (Throwable t) {
            return "unknown";
        }
    }

    // ------------------------------------------------------------- ad units

    /** kind: "interstitial" | "rewarded". Call AFTER init_complete. */
    @UsedByGodot
    public void set_ad_unit(String kind, String adUnitId) {
        if (adUnitId == null || adUnitId.isEmpty()) return;
        try {
            if (KIND_INTERSTITIAL.equals(kind)) {
                interstitialAd = new LevelPlayInterstitialAd(adUnitId);
                interstitialAd.setListener(new LevelPlayInterstitialAdListener() {
                    @Override
                    public void onAdLoaded(LevelPlayAdInfo info) {
                        emitSignal("ad_loaded", KIND_INTERSTITIAL);
                    }

                    @Override
                    public void onAdLoadFailed(LevelPlayAdError error) {
                        emitSignal("ad_failed", KIND_INTERSTITIAL, describe(error));
                    }

                    @Override
                    public void onAdDisplayed(LevelPlayAdInfo info) {
                        emitSignal("ad_shown", KIND_INTERSTITIAL);
                    }

                    @Override
                    public void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo info) {
                        emitSignal("ad_failed", KIND_INTERSTITIAL, describe(error));
                    }

                    @Override
                    public void onAdClicked(LevelPlayAdInfo info) { }

                    @Override
                    public void onAdClosed(LevelPlayAdInfo info) {
                        emitSignal("ad_closed", KIND_INTERSTITIAL);
                    }
                });
            } else if (KIND_REWARDED.equals(kind)) {
                rewardedAd = new LevelPlayRewardedAd(adUnitId);
                rewardedAd.setListener(new LevelPlayRewardedAdListener() {
                    @Override
                    public void onAdLoaded(LevelPlayAdInfo info) {
                        emitSignal("ad_loaded", KIND_REWARDED);
                    }

                    @Override
                    public void onAdLoadFailed(LevelPlayAdError error) {
                        emitSignal("ad_failed", KIND_REWARDED, describe(error));
                    }

                    @Override
                    public void onAdDisplayed(LevelPlayAdInfo info) {
                        emitSignal("ad_shown", KIND_REWARDED);
                    }

                    @Override
                    public void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo info) {
                        String name = (reward != null) ? reward.getName() : "";
                        int amount = (reward != null) ? reward.getAmount() : 0;
                        emitSignal("reward_received", name, amount);
                    }

                    @Override
                    public void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo info) {
                        emitSignal("ad_failed", KIND_REWARDED, describe(error));
                    }

                    @Override
                    public void onAdClicked(LevelPlayAdInfo info) { }

                    @Override
                    public void onAdClosed(LevelPlayAdInfo info) {
                        emitSignal("ad_closed", KIND_REWARDED);
                    }
                });
            }
        } catch (Throwable t) {
            emitSignal("ad_failed", kind, String.valueOf(t));
        }
    }

    @UsedByGodot
    public boolean is_loaded(String kind) {
        try {
            if (KIND_INTERSTITIAL.equals(kind)) {
                return interstitialAd != null && interstitialAd.isAdReady();
            }
            if (KIND_REWARDED.equals(kind)) {
                return rewardedAd != null && rewardedAd.isAdReady();
            }
        } catch (Throwable ignored) { }
        return false;
    }

    @UsedByGodot
    public void load(String kind) {
        if (!initialized) return;
        try {
            if (KIND_INTERSTITIAL.equals(kind) && interstitialAd != null) {
                interstitialAd.loadAd();
            } else if (KIND_REWARDED.equals(kind) && rewardedAd != null) {
                rewardedAd.loadAd();
            }
        } catch (Throwable t) {
            emitSignal("ad_failed", kind, String.valueOf(t));
        }
    }

    @UsedByGodot
    public void show(String kind) {
        if (!initialized) return;
        try {
            if (KIND_INTERSTITIAL.equals(kind) && interstitialAd != null) {
                interstitialAd.showAd(activity);
            } else if (KIND_REWARDED.equals(kind) && rewardedAd != null) {
                rewardedAd.showAd(activity);
            }
        } catch (Throwable t) {
            emitSignal("ad_failed", kind, String.valueOf(t));
        }
    }

    // ---------------------------------------------------------------- banner

    @UsedByGodot
    public void banner_show(final String adUnitId) {
        if (!bannerEnabled || !initialized) return;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                ensureBannerHolder();
                ensureBannerView(adUnitId);
                if (bannerView != null) {
                    try { bannerView.resumeAutoRefresh(); } catch (Throwable ignored) { }
                    try { bannerView.loadAd(); } catch (Throwable t) {
                        emitSignal("banner_failed", String.valueOf(t));
                    }
                    bannerHolder.setVisibility(View.VISIBLE);
                    bannerVisible = true;
                }
            }
        });
    }

    @UsedByGodot
    public void banner_hide() {
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (bannerHolder != null) {
                    bannerHolder.setVisibility(View.GONE);
                }
                if (bannerView != null) {
                    try { bannerView.pauseAutoRefresh(); } catch (Throwable ignored) { }
                }
                bannerVisible = false;
            }
        });
    }

    private void ensureBannerHolder() {
        if (bannerHolder != null) return;
        ViewGroup root = activity.findViewById(android.R.id.content);
        bannerHolder = new LinearLayout(activity);
        bannerHolder.setOrientation(LinearLayout.VERTICAL);
        bannerHolder.setGravity(Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
        bannerHolder.setBackgroundColor(0xFF101418);
        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dpToPx(90));
        lp.gravity = Gravity.BOTTOM;
        root.addView(bannerHolder, lp);
        bannerHolder.setVisibility(View.GONE);
    }

    private void ensureBannerView(String adUnitId) {
        if (adUnitId == null || adUnitId.isEmpty()) return;
        if (bannerView != null && adUnitId.equals(bannerAdUnitId)) return;
        if (bannerView != null) {
            try { bannerView.destroy(); } catch (Throwable ignored) { }
            bannerView = null;
        }
        try {
            bannerView = new LevelPlayBannerAdView(activity, adUnitId);
            bannerAdUnitId = adUnitId;
            bannerView.setBannerListener(new LevelPlayBannerAdViewListener() {
                @Override
                public void onAdLoaded(LevelPlayAdInfo info) {
                    emitSignal("banner_loaded");
                }

                @Override
                public void onAdLoadFailed(LevelPlayAdError error) {
                    emitSignal("banner_failed", describe(error));
                }

                @Override
                public void onAdClicked(LevelPlayAdInfo info) { }
            });
            bannerHolder.removeAllViews();
            bannerHolder.addView(bannerView, new FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL));
        } catch (Throwable t) {
            bannerView = null;
            emitSignal("banner_failed", String.valueOf(t));
        }
    }

    // ---------------------------------------------------------------- helpers

    private static String describe(LevelPlayAdError error) {
        if (error == null) return "unknown error";
        return "code " + error.getErrorCode() + ": " + error.getErrorMessage();
    }

    private int dpToPx(int dp) {
        return Math.round(dp * activity.getResources().getDisplayMetrics().density);
    }
}
