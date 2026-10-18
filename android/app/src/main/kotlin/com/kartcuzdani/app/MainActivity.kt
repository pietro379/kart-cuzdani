package com.kartcuzdani.app

import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Yalnızca debug yapıda (geliştirme sırasında ekran görüntüsü alabilmek için)
        // koruma atlanır; release sürümü her zaman korumalıdır.
        val isDebuggable = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        if (isDebuggable) return

        // Ekran görüntüsü / ekran kaydını ve "son uygulamalar" önizlemesini engeller,
        // böylece kart bilgileri ekran dışına sızmaz.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }
}
