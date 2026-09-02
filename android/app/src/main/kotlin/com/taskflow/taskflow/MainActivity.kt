package com.taskflow.taskflow

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * FlutterFragmentActivity rather than FlutterActivity: local_auth needs a
 * FragmentActivity host to show the biometric prompt.
 */
class MainActivity : FlutterFragmentActivity()
