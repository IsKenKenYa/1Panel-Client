# Keep constructors for reflection-instantiated AndroidX Room/WorkManager/Parcelable classes under AGP 9 R8 strict full mode.
-keep class * extends androidx.room.RoomDatabase {
    <init>(...);
}
-keep class androidx.work.impl.WorkDatabase_Impl {
    <init>(...);
}
-keep class * extends androidx.work.Worker {
    <init>(...);
}
-keep class * extends androidx.work.InputMerger {
    <init>(...);
}
-keep class * implements androidx.versionedparcelable.VersionedParcelable {
    <init>(...);
}
-keep public class androidx.versionedparcelable.ParcelImpl {
    <init>(...);
}
