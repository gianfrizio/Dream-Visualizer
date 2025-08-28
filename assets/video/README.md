Place your background video file(s) here and reference them in code via their asset path.

Recommendations:
- Use MP4 (H.264) for best cross-platform support.
- Keep resolution and bitrate reasonable for mobile (1080p or lower, ~3-6Mbps).
- Prefer a short looping clip to reduce package size.

Example usage in code:
  StarryBackground(videoAsset: 'assets/video/bg_loop.mp4')

Note: After adding a video file, run `flutter pub get` and rebuild the app.
