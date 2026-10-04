package com.arunika

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    /**
     * Push notifications only pop up over other apps ("heads-up") when their
     * channel is IMPORTANCE_HIGH; FCM's fallback channel is not. Ids must match
     * the backend (campaigns send `android.notification.channel_id`) and the
     * default channel meta-data in AndroidManifest.xml.
     *
     * A channel's importance can't be changed after creation — use a new id to
     * change it. Creating an existing channel again is a no-op.
     */
    private fun createNotificationChannels() {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannels(
            listOf(
                NotificationChannel(
                    CHANNEL_UPDATES,
                    "Info akun & pembayaran",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply { description = "Status pembayaran dan informasi akun" },
                NotificationChannel(
                    CHANNEL_PROMO,
                    "Promo & konten baru",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply { description = "Kartu AR dan dongeng baru, serta promo" },
            ),
        )
    }

    companion object {
        const val CHANNEL_UPDATES = "arunika_updates"
        const val CHANNEL_PROMO = "arunika_promo"
    }
}
