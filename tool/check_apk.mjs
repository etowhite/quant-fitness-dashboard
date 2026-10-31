import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';

const apk = process.argv[2] ?? 'build/app/outputs/flutter-apk/app-release.apk';
const sdk = process.env.ANDROID_HOME ?? process.env.ANDROID_SDK_ROOT;
if (!sdk || !fs.existsSync(apk)) throw new Error('Android SDK or APK is missing.');
const aapt = path.join(sdk, 'build-tools', '35.0.0', process.platform === 'win32' ? 'aapt.exe' : 'aapt');
function dump(...args) {
  const result = spawnSync(aapt, ['dump', ...args], {encoding: 'utf8'});
  if (result.error || result.status !== 0) throw result.error ?? new Error(result.stderr);
  return result.stdout;
}
const allowed = new Set([
  'android.permission.INTERNET',
  'android.permission.POST_NOTIFICATIONS',
  'android.permission.SCHEDULE_EXACT_ALARM',
  'android.permission.RECEIVE_BOOT_COMPLETED',
  'android.permission.VIBRATE',
  'android.permission.WAKE_LOCK',
  'android.permission.CAMERA',
  'android.permission.ACCESS_NETWORK_STATE',
  'android.permission.ACTIVITY_RECOGNITION',
  'android.permission.health.READ_STEPS',
  'android.permission.health.READ_ACTIVE_CALORIES_BURNED',
  'android.permission.health.READ_WEIGHT',
  'android.permission.health.READ_BODY_FAT',
  'android.permission.health.READ_HEALTH_DATA_HISTORY',
]);
const permissions = [...dump('permissions', apk).matchAll(/uses-permission[^\n]*name='([^']+)'/g)]
  .map((m) => m[1]);
for (const permission of [...allowed].filter((p) => !['android.permission.WAKE_LOCK','android.permission.VIBRATE','android.permission.ACCESS_NETWORK_STATE'].includes(p))) {
  if (!permissions.includes(permission)) throw new Error(`Missing permission: ${permission}`);
}
for (const permission of permissions) {
  if (permission.startsWith('android.permission.') && !allowed.has(permission)) {
    throw new Error(`Unexpected Android permission: ${permission}`);
  }
}
const manifest = dump('xmltree', apk, 'AndroidManifest.xml');
for (const attribute of ['allowBackup', 'fullBackupContent', 'usesCleartextTraffic']) {
  const line = manifest.split('\n').find((s) => s.includes(`android:${attribute}(`));
  if (!line || !line.trim().endsWith('0x0')) throw new Error(`${attribute} is not disabled.`);
}
const debuggable = manifest.split('\n').find((s) => s.includes('android:debuggable('));
if (debuggable && !debuggable.trim().endsWith('0x0')) throw new Error('Release is debuggable.');
const badging = dump('badging', apk);
if (!badging.includes("application-label:'quant'")) throw new Error('Unexpected application label.');
if (!badging.includes("sdkVersion:'26'") || !badging.includes("targetSdkVersion:'35'")) {
  throw new Error('Unexpected minSdk/targetSdk.');
}
console.log('APK verified: expected Android permissions, backups/cleartext/debug disabled, minSdk 26, targetSdk 35.');
