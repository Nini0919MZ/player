# Reglas ProGuard / R8 para audiotags y Flutter FFI

# Evitar que R8 elimine o renombre referencias a librerías nativas (.so)
-keepclasseswithmembernames class * {
    native <methods>;
}

# Mantener clases de FFI / audiotags
-keep class com.erikas.audiotags.** { *; }
-dontwarn com.erikas.audiotags.**
