import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';

const apk = process.argv[2] ?? 'build/app/outputs/flutter-apk/app-release.apk';
const sdk = process.env.ANDROID_HOME ?? process.env.ANDROID_SDK_ROOT;
if (!sdk || !fs.existsSync(apk)) throw new Error('Android SDK or APK is missing');
const expected = fs.readFileSync('tool/signing-certificate.sha256', 'utf8').trim().toLowerCase();
if (!/^[a-f0-9]{64}$/.test(expected)) throw new Error('Invalid pinned certificate fingerprint');
const java = process.env.JAVA_HOME
  ? path.join(process.env.JAVA_HOME, 'bin', process.platform === 'win32' ? 'java.exe' : 'java')
  : 'java';
const result = spawnSync(java, ['-jar', path.join(sdk, 'build-tools', '35.0.0', 'lib', 'apksigner.jar'),
  'verify', '--verbose', '--print-certs', apk], {encoding: 'utf8'});
if (result.error || result.status !== 0) throw result.error ?? new Error(result.stderr);
const fingerprints = [...result.stdout.matchAll(/Signer #\d+ certificate SHA-256 digest: ([a-f0-9]+)/gi)]
  .map((m) => m[1].toLowerCase());
if (fingerprints.length !== 1 || fingerprints[0] !== expected) {
  throw new Error('APK certificate does not match the persistent quant signing certificate');
}
console.log(`Verified persistent quant certificate: ${expected}`);
