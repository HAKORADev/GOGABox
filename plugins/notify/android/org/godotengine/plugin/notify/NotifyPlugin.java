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
 * GDScript:
 *   var n = Engine.get_singleton("Notify")
 *   n.requestPermission()
 *   n.permissionGranted()
 *   n.schedule(id, title, body, delay_seconds)   // survives reboot
 *   n.cancel(id) / n.cancelAll()
 *
 * Schedules are persisted to SharedPreferences and re-armed by BootReceiver,
 * so "come back in 3 days" style reveals work across process death.
 */
public class NotifyPlugin extends GodotPlugin {

    private static final String CHANNEL_ID = "gogabox_general";
    private static final String PREFS = "goga_notify";
    private static final String KEY_PENDING = "pending";

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
    public boolean permissionGranted() {
        if (activity == null) {
            return false;
        }
        if (Build.VERSION.SDK_INT < 33) {
            return true;   // pre-13: notifications on by default
        }
        return activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                == PackageManager.PERMISSION_GRANTED;
    }

    @UsedByGodot
    public void requestPermission() {
        if (activity == null || Build.VERSION.SDK_INT < 33 || permissionGranted()) {
            return;
        }
        activity.requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 4711);
    }

    @UsedByGodot
    public void schedule(int id, String title, String body, int delaySec) {
        Context ctx = context();
        long fireAt = System.currentTimeMillis() + Math.max(1, delaySec) * 1000L;
        persist(ctx, id, title, body, fireAt);
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
    public void cancelAll() {
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

    static void persist(Context ctx, int id, String title, String body, long fireAt) {
        JSONObject all = readPending(ctx);
        try {
            JSONObject e = new JSONObject();
            e.put("title", title);
            e.put("body", body);
            e.put("fireAt", fireAt);
            all.put(String.valueOf(id), e);
            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                    .edit().putString(KEY_PENDING, all.toString()).apply();
        } catch (Exception ignored) {
        }
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

    static void post(Context ctx, int id, String title, String body) {
        NotificationManager nm =
                (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm == null) {
            return;
        }
        Notification.Builder b;
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel ch = new NotificationChannel(CHANNEL_ID,
                    "GOGABox", NotificationManager.IMPORTANCE_DEFAULT);
            ch.setDescription("Game reveals and return reminders");
            nm.createNotificationChannel(ch);
            b = new Notification.Builder(ctx, CHANNEL_ID);
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

    /** Fires a due notification (called by AlarmReceiver / BootReceiver). */
    public static void fire(Context ctx, int id) {
        JSONObject all = readPending(ctx);
        JSONObject e = all.optJSONObject(String.valueOf(id));
        if (e == null) {
            return;
        }
        post(ctx, id, e.optString("title", "GOGABox"), e.optString("body", ""));
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
