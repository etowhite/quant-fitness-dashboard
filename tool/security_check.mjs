import fs from 'node:fs';
import path from 'node:path';

const failures = [];
const assert = (condition, message) => { if (!condition) failures.push(message); };
const manifest = fs.readFileSync('android/app/src/main/AndroidManifest.xml', 'utf8');
const healthPermissions = [...manifest.matchAll(/android\.permission\.health\.([A-Z_]+)/g)]
  .map((match) => match[1]).sort();
assert(JSON.stringify(healthPermissions) === JSON.stringify([
  'READ_ACTIVE_CALORIES_BURNED', 'READ_BODY_FAT', 'READ_HEALTH_DATA_HISTORY', 'READ_STEPS', 'READ_TOTAL_CALORIES_BURNED', 'READ_WEIGHT',
]), 'Manifest must request only the five data READ permissions and history.');
for (const attribute of ['allowBackup="false"', 'fullBackupContent="false"',
  'usesCleartextTraffic="false"', 'dataExtractionRules="@xml/data_extraction_rules"']) {
  assert(manifest.includes(attribute), `Missing manifest protection: ${attribute}`);
}
assert(manifest.includes('android.permission.INTERNET'), 'Open Food Facts requires INTERNET.');
assert(!manifest.includes('android.permission.USE_EXACT_ALARM'), 'Use user-controlled SCHEDULE_EXACT_ALARM only.');
assert(manifest.includes('android.permission.POST_NOTIFICATIONS'), 'Missing notification permission.');
assert(manifest.includes('android.permission.CAMERA'), 'Barcode scanner requires CAMERA.');
assert(manifest.includes('android.permission.START_VIEW_PERMISSION_USAGE'), 'Missing protected Android 14 alias.');
const kotlin = 'android/app/src/main/kotlin/com/example/smart_fitness_dashboard';
assert(fs.readFileSync(`${kotlin}/MainActivity.kt`, 'utf8').includes('FlutterFragmentActivity'),
  'MainActivity must inherit FlutterFragmentActivity.');
assert(!/startActivity|parseUri|getParcelableExtra|Intent\.parse/.test(
  fs.readFileSync(`${kotlin}/HealthPermissionsActivity.kt`, 'utf8')), 'Rationale must not redirect incoming intents.');
function files(directory) {
  return fs.readdirSync(directory, {withFileTypes: true}).flatMap((entry) => {
    const name = path.join(directory, entry.name);
    return entry.isDirectory() ? files(name) : [name];
  });
}
for (const file of files('lib').filter((file) => file.endsWith('.dart'))) {
  const source = fs.readFileSync(file, 'utf8');
  assert(!/\b(?:print|debugPrint)\s*\(/.test(source), `Diagnostic logging in ${file}`);
  assert(!/allowRuntimeFetching\s*=\s*true|GoogleFonts\.\w+TextTheme/.test(source), `Runtime font networking in ${file}`);
}
const ignored = fs.readFileSync('.gitignore', 'utf8');
for (const entry of ['**/*.jks', '**/*.keystore', 'android/key.properties']) {
  assert(ignored.includes(entry), `Missing secret ignore: ${entry}`);
}
const gradle = fs.readFileSync('android/app/build.gradle.kts', 'utf8');
assert(/minSdk\s*=\s*26/.test(gradle), 'minSdk must be 26.');
assert(/compileSdk\s*=\s*35/.test(gradle) && /targetSdk\s*=\s*35/.test(gradle), 'SDK levels must be 35.');
assert(gradle.includes('releaseKeyFile.isFile') && gradle.includes('"release" else "debug"'),
  'Release signing must have an explicit missing-file fallback.');

if (process.argv.includes('--advisories')) {
  const dependencyFile = '.dart_tool/dependency-tree.json';
  const tree = JSON.parse(fs.readFileSync(dependencyFile, 'utf8').replace(/^\uFEFF/, ''));
  const packages = tree.packages.filter((pkg) => pkg.source === 'hosted');
  const response = await fetch('https://api.osv.dev/v1/querybatch', {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({queries: packages.map((pkg) => ({
      package: {name: pkg.name, ecosystem: 'Pub'}, version: pkg.version,
    }))}), signal: AbortSignal.timeout(60000),
  });
  if (!response.ok) throw new Error(`OSV HTTP ${response.status}`);
  const data = await response.json();
  assert(data.results?.length === packages.length, 'OSV returned an incomplete result set.');
  const matches = (data.results ?? []).flatMap((result, index) => (result.vulns ?? [])
    .map((vuln) => ({package: packages[index].name, version: packages[index].version, id: vuln.id})));
  const report = {checkedAt: new Date().toISOString(), ecosystem: 'Pub',
    packageCount: packages.length, matches,
    limitations: 'Pub advisories only; not an audit of native Maven/NDK dependencies or undisclosed vulnerabilities.'};
  fs.writeFileSync('.dart_tool/security-dependencies.json', JSON.stringify(report, null, 2));
  assert(matches.length === 0, `Known advisories: ${JSON.stringify(matches)}`);
  console.log(`OSV: ${packages.length} exact Pub versions checked, ${matches.length} advisory matches.`);
}
if (failures.length) {
  for (const failure of failures) console.error(failure);
  process.exitCode = 1;
} else {
  console.log('Source security regression checks passed. This is not a full security audit.');
}
