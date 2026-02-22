package com.cinematick.cinematick

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onPostResume() {
        super.onPostResume()
        
        // Prevent system gestures from hiding bottom navigation bar
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.setDecorFitsSystemWindows(false)
            // Set the edge-to-edge to avoid gesture areas overlapping bottom nav
            window.attributes = window.attributes.apply {
                // Keep the system bars visible
                this.layoutInDisplayCutoutMode = 
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
        }
    }
}
