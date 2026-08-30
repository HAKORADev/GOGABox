package org.godotengine.plugin.notify;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Build;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.Iterator;

/**
 * Local notifications plugin for GOGABox (v1 GodotPlugin).
 *
 * GDScript (names MUST match the @UsedByGodot Java methods EXACTLY - Godot
 * does no snake_case/camelCase conversion, docs: "There is no coercing
 * snake_case to camelCase". That mismatch is exactly what silently killed
 * the permission ask in v0.0.6..v0.0.9 - every call errored out unseen):
 *   var n = Engine.get_singleton("Notify")
 *   n.permission_granted()
 *   n.request_permission()                       // the real system dialog
 *   n.open_notification_settings()               // manual helper
 *   n.schedule(id, title, body, delay_seconds)   // survives reboot
 *   n.schedule_kind(id, title, body, delay_seconds, channel)
 *   n.cancel(id) / n.cancel_all()
 *
 * Schedules are persisted to SharedPreferences and re-armed by BootReceiver,
 * so "come back in 3 days" style reveals work across process death.
 */
public class NotifyPlugin extends GodotPlugin {

    private static final String PREFS = "goga_notify";
    private static final String KEY_PENDING = "pending";
    private static final int REQ_POST_NOTIFICATIONS = 4711;

    // MODULAR SOUND CHANNELS (v2 ids: channel sound is fixed at creation, so
    // new sounds need new ids on already-installed devices). Each channel has
    // its own raw-resource sound: batteries-full / game-ready / general.
    private static final String CHANNEL_GENERAL = "gogabox_general_v2";
    private static final String CHANNEL_BATTERY = "gogabox_battery_v2";
    private static final String CHANNEL_READY = "gogabox_ready_v2";

    private final android.app.Activity activity;

    public NotifyPlugin(Godot godot) {
        super(godot);
        this.activity = getActivity();
    }

    @Override
    public String getPluginName() {
        return "Notify";
    }

    // ------------------------------------------------------------ GDScript API

    @UsedByGodot
    public boolean permission_granted() {
        if (activity == null) {
            return false;
        }
        if (Build.VERSION.SDK_INT < 33) {
            return true;   // pre-13: notifications on by default
        }
        return activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                == PackageManager.PERMISSION_GRANTED;
    }

    /**
     * Ask Android 13+ for POST_NOTIFICATIONS - the plain, official flow.
     * Shows the system dialog when the OS allows it; the OS alone decides.
     * MUST run on the UI thread (GodotPlugin methods arrive on the GL
     * thread - off-thread requests silently do nothing).
     * No ladders, no watchdogs, no auto-settings: one honest request.
     */
    @UsedByGodot
    public void request_permission() {
        if (activity == null || Build.VERSION.SDK_INT < 33 || permission_granted()) {
            return;
        }
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                activity.requestPermissions(
                        new String[]{Manifest.permission.POST_NOTIFICATIONS}, REQ_POST_NOTIFICATIONS);
            }
        });
    }

    /** Opens this app's system notification settings page (manual helper -
     *  the user lands on the toggle that always counts). */
    @UsedByGodot
    public void open_notification_settings() {
        if (activity == null) {
            return;
        }
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    android.content.Intent i = new android.content.Intent(
                            android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS);
                    i.putExtra(android.provider.Settings.EXTRA_APP_PACKAGE,
                            activity.getPackageName());
                    i.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK);
                    activity.startActivity(i);
                } catch (Exception ignored) {
                }
            }
        });
    }

    @UsedByGodot
    public void schedule(int id, String title, String body, int delaySec) {
        schedule_kind(id, title, body, delaySec, CHANNEL_GENERAL);
    }

    @UsedByGodot
    public void schedule_kind(int id, String title, String body, int delaySec, String channelId) {
        Context ctx = context();
        long fireAt = System.currentTimeMillis() + Math.max(1, delaySec) * 1000L;
        persist(ctx, id, title, body, fireAt, channelId);
        arm(ctx, id, title, body, fireAt);
    }

    @UsedByGodot
    public void cancel(int id) {
        Context ctx = context();
        unpersist(ctx, id);
        AlarmManager am = (AlarmManager) ctx.getSystemService(Context.ALARM_SERVICE);
        if (am != null) {
            am.cancel(pendingBroadcast(ctx, id));
        }
        NotificationManager nm =
                (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm != null) {
            nm.cancel(id);
        }
    }

    @UsedByGodot
    public void cancel_all() {
        Context ctx = context();
        SharedPreferences sp = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        JSONObject all = readPending(ctx);
        Iterator<String> keys = all.keys();
        AlarmManager am = (AlarmManager) ctx.getSystemService(Context.ALARM_SERVICE);
        while (keys.hasNext()) {
            int id = Integer.parseInt(keys.next());
            if (am != null) {
                am.cancel(pendingBroadcast(ctx, id));
            }
        }
        sp.edit().remove(KEY_PENDING).apply();
    }

    // ------------------------------------------------------------ scheduling

    static void arm(Context ctx, int id, String title, String body, long fireAt) {
        AlarmManager am = (AlarmManager) ctx.getSystemService(Context.ALARM_SERVICE);
        if (am == null) {
            return;
        }
        PendingIntent pi = pendingBroadcast(ctx, id);
        am.cancel(pi);
        // inexact is fine for "come back in N hours" and needs no special permission
        am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAt, pi);
    }

    static PendingIntent pendingBroadcast(Context ctx, int id) {
        Intent i = new Intent(ctx, AlarmReceiver.class);
        i.setAction("org.godotengine.plugin.notify.FIRE");
        i.putExtra("id", id);
        return PendingIntent.getBroadcast(ctx, id, i,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    static PendingIntent contentIntent(Context ctx) {
        Intent i = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
        if (i == null) {
            return null;
        }
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= 23) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        return PendingIntent.getActivity(ctx, 9001, i, flags);
    }

    static void persist(Context ctx, int id, String title, String body, long fireAt, String channel) {
        JSONObject all = readPending(ctx);
        try {
            JSONObject e = new JSONObject();
            e.put("title", title);
            e.put("body", body);
            e.put("fireAt", fireAt);
            e.put("channel", channel == null ? CHANNEL_GENERAL : channel);
            all.put(String.valueOf(id), e);
            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                    .edit().putString(KEY_PENDING, all.toString()).apply();
        } catch (Exception ignored) {
        }
    }

    static void persist(Context ctx, int id, String title, String body, long fireAt) {
        persist(ctx, id, title, body, fireAt, CHANNEL_GENERAL);
    }

    static void unpersist(Context ctx, int id) {
        JSONObject all = readPending(ctx);
        all.remove(String.valueOf(id));
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putString(KEY_PENDING, all.toString()).apply();
    }

    static JSONObject readPending(Context ctx) {
        String raw = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_PENDING, "{}");
        try {
            return new JSONObject(raw);
        } catch (Exception e) {
            return new JSONObject();
        }
    }

    static void post(Context ctx, int id, String title, String body, String channelId) {
        NotificationManager nm =
                (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm == null) {
            return;
        }
        Notification.Builder b;
        if (Build.VERSION.SDK_INT >= 26) {
            createChannels(nm, ctx);
            b = new Notification.Builder(ctx, channelId);
        } else {
            b = new Notification.Builder(ctx);
        }
        b.setSmallIcon(ctx.getResources().getIdentifier("ic_notify", "drawable",
                ctx.getPackageName()))
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(new Notification.BigTextStyle().bigText(body))
                .setAutoCancel(true);
        PendingIntent pi = contentIntent(ctx);
        if (pi != null) {
            b.setContentIntent(pi);
        }
        nm.notify(id, b.build());
    }

    static void post(Context ctx, int id, String title, String body) {
        post(ctx, id, title, body, CHANNEL_GENERAL);
    }

    /** Creates the three sound-equipped channels (idempotent). */
    private static void createChannels(NotificationManager nm, Context ctx) {
        makeChannel(nm, ctx, CHANNEL_GENERAL, "GOGABox",
                "General GOGABox news", "notify_general");
        makeChannel(nm, ctx, CHANNEL_BATTERY, "GOGABatteries",
                "Batteries fully charged reminders", "notify_battery");
        makeChannel(nm, ctx, CHANNEL_READY, "Games ready",
                "Revealed and ready-to-play announcements", "notify_ready");
    }

    private static void makeChannel(NotificationManager nm, Context ctx,
            String channelId, String name, String desc, String rawSound) {
        NotificationChannel ch = nm.getNotificationChannel(channelId);
        if (ch == null) {
            ch = new NotificationChannel(channelId, name,
                    NotificationManager.IMPORTANCE_DEFAULT);
            ch.setDescription(desc);
            int resId = ctx.getResources().getIdentifier(rawSound, "raw",
                    ctx.getPackageName());
            if (resId != 0) {
                android.net.Uri soundUri =
                        android.net.Uri.parse("android.resource://" + ctx.getPackageName() + "/" + resId);
                android.media.AudioAttributes attrs =
                        new android.media.AudioAttributes.Builder()
                                .setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION)
                                .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                .build();
                ch.setSound(soundUri, attrs);
            }
            nm.createNotificationChannel(ch);
        }
    }

    /** Fires a due notification (called by AlarmReceiver / BootReceiver). */
    public static void fire(Context ctx, int id) {
        JSONObject all = readPending(ctx);
        JSONObject e = all.optJSONObject(String.valueOf(id));
        if (e == null) {
            return;
        }
        String channel = e.optString("channel", CHANNEL_GENERAL);
        post(ctx, id, e.optString("title", "GOGABox"), e.optString("body", ""), channel);
        unpersist(ctx, id);
    }

    /** App context: the activity when alive, else the engine context. */
    private Context context() {
        Context c = getContext();          // GodotPlugin#getContext (app context)
        if (c != null) {
            return c;
        }
        return activity;
    }

    /** Fires a due notification (called by AlarmReceiver / BootReceiver). */
    public static class AlarmReceiver extends BroadcastReceiver {
        @Override
        public void onReceive(Context context, Intent intent) {
            int id = intent.getIntExtra("id", -1);
            if (id >= 0) {
                NotifyPlugin.fire(context, id);
            }
        }
    }

    /** Re-arms every persisted notification after a reboot. */
    public static class BootReceiver extends BroadcastReceiver {
        @Override
        public void onReceive(Context context, Intent intent) {
            JSONObject all = readPending(context);
            Iterator<String> keys = all.keys();
            while (keys.hasNext()) {
                String k = keys.next();
                JSONObject e = all.optJSONObject(k);
                if (e == null) {
                    continue;
                }
                int id = Integer.parseInt(k);
                long fireAt = e.optLong("fireAt", 0L);
                if (fireAt <= System.currentTimeMillis()) {
                    NotifyPlugin.fire(context, id);
                } else {
                    arm(context, id, e.optString("title", "GOGABox"),
                            e.optString("body", ""), fireAt);
                }
            }
        }
    }
}
