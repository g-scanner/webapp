// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:js_interop';
import 'package:web/web.dart' as web;

web.EventListener? _visibilityListener;

/// Stops all active MediaStream tracks associated with video elements in the DOM.
/// This physically turns off the webcam / camera indicator in the browser.
void stopWebMediaTracks() {
  try {
    final videoElements = web.document.querySelectorAll('video');
    for (var i = 0; i < videoElements.length; i++) {
      final el = videoElements.item(i);
      if (el != null) {
        final video = el as web.HTMLVideoElement;
        final stream = video.srcObject;
        if (stream != null) {
          final mediaStream = stream as web.MediaStream;
          final tracks = mediaStream.getTracks().toDart;
          for (final track in tracks) {
            track.stop();
          }
          video.srcObject = null;
        }
      }
    }
  } catch (_) {}
}

/// Listens for the browser tab visibility change events (minimize, change tab, window blur).
void setupWebVisibilityListener(void Function(bool isVisible) onVisibilityChanged) {
  removeWebVisibilityListener();
  _visibilityListener = (web.Event event) {
    final isHidden = web.document.hidden;
    onVisibilityChanged(!isHidden);
  }.toJS;
  web.document.addEventListener('visibilitychange', _visibilityListener);
}

/// Removes the browser tab visibility change listener.
void removeWebVisibilityListener() {
  if (_visibilityListener != null) {
    web.document.removeEventListener('visibilitychange', _visibilityListener);
    _visibilityListener = null;
  }
}
