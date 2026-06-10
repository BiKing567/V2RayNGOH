#!/bin/bash
set -euo pipefail

# Build & Install pipeline for V2RayNG OpenHarmony emulator
# Usage: ./build_install.sh [clean]

WORK_DIR="$(cd "$(dirname "$0")" && pwd)"
HVIGOR="/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/bin/hvigor.js"
PATH="/tmp/go/bin:$PATH"

HDC="$HOME/Library/Huawei/Sdk/HarmonyOS-6.1.1/toolchains/hdc"
if [ ! -f "$HDC" ]; then
  HDC="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc"
fi

cd "$WORK_DIR"

# Ensure DevEco JBR is available as system Java
JBR_DIR="$HOME/Library/Java/JavaVirtualMachines"
if [ ! -L "$JBR_DIR/deveco.jdk" ]; then
  mkdir -p "$JBR_DIR"
  ln -sf "/Applications/DevEco-Studio.app/Contents/jbr" "$JBR_DIR/deveco.jdk"
fi

# Step 1: Build Go V2Ray core as static archives
echo ">>> Building Go V2Ray core (static)..."
cd v2ray_go
./build_ohos.sh
cd ..

# Step 2: Build HAP with hvigor
if [ "${1:-}" = "clean" ]; then
  echo ">>> Running hvigor clean..."
  "$HVIGOR" clean 2>&1
fi

UNSIGNED_HAP="entry/build/default/outputs/default/entry-default-unsigned.hap"
if [ ! -f "$UNSIGNED_HAP" ]; then
  echo ">>> Building unsigned HAP with assembleHap..."
  "$HVIGOR" assembleHap --mode module -p module=entry 2>&1
fi

SIGNED_HAP="entry/build/default/outputs/default/entry-default-signed.hap"

# Step 3: Post-process: set native lib fields, duplicate to arm64/
echo ">>> Post-processing HAP..."
python3 -c "
import json, zipfile, shutil, os, tempfile, subprocess

unsigned_hap = '$UNSIGNED_HAP'
signed_hap = '$SIGNED_HAP'

# Read module.json
with zipfile.ZipFile(unsigned_hap, 'r') as z:
    module_data = json.loads(z.read('module.json'))

# Ensure native library fields
module_data['module']['compressNativeLibs'] = False
module_data['module']['extractNativeLibs'] = True
module_data['module']['nativeLibraryFileNames'] = [
    'libc++_shared.so',
    'libv2ray_bridge.so',
]

OLD_ABI = 'arm64-v8a'
NEW_ABI = 'arm64'

tmp = tempfile.NamedTemporaryFile(delete=False, suffix='.hap')
try:
    with zipfile.ZipFile(unsigned_hap, 'r') as zin:
        with zipfile.ZipFile(tmp.name, 'w', zipfile.ZIP_STORED) as zout:
            for item in zin.infolist():
                data = zin.read(item.filename)
                if item.filename == 'module.json':
                    data = json.dumps(module_data, indent=2).encode('utf-8')
                zout.writestr(item, data)
                # Duplicate libs to arm64/ directory (OHOS runtime path)
                if OLD_ABI in item.filename:
                    new_name = item.filename.replace(OLD_ABI, NEW_ABI)
                    print(f'Also adding: {new_name}')
                    zout.writestr(new_name, data)
    shutil.move(tmp.name, unsigned_hap)
except:
    os.unlink(tmp.name)
    raise

# Verify
print()
with zipfile.ZipFile(unsigned_hap, 'r') as z:
    m = json.loads(z.read('module.json'))
    print(f'compressNativeLibs: {m[\"module\"].get(\"compressNativeLibs\")}')
    print(f'nativeLibraryFileNames: {m[\"module\"].get(\"nativeLibraryFileNames\")}')
    libs = [f for f in z.namelist() if 'libs/' in f]
    print(f'Lib files ({len(libs)}):')
    for l in libs:
        info = z.getinfo(l)
        print(f'  {l} ({info.compress_size}B -> {info.file_size}B)')

# Sign the modified unsigned HAP
SIGN_TOOL = '/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/lib/hap-sign-tool.jar'
SIGN_DIR = os.path.expanduser('~/.ohos/config/openharmony')

P12 = os.path.join(SIGN_DIR, 'default_V2rayNG_OHOS_c9OR-ifMp9XFty4JBMODqxfmAgbXpznjxzUjp3LgOG0=.p12')
CER = os.path.join(SIGN_DIR, 'default_V2rayNG_OHOS_c9OR-ifMp9XFty4JBMODqxfmAgbXpznjxzUjp3LgOG0=.cer')
P7B = os.path.join(SIGN_DIR, 'default_V2rayNG_OHOS_c9OR-ifMp9XFty4JBMODqxfmAgbXpznjxzUjp3LgOG0=.p7b')

PWD = 'JQbymRtsdLo'

print()
print('Signing the modified HAP...')
result = subprocess.run([
    'java', '-jar', SIGN_TOOL, 'sign-app',
    '-mode', 'localSign',
    '-keystoreFile', P12,
    '-keystorePwd', PWD,
    '-keyAlias', 'debugKey',
    '-keyPwd', PWD,
    '-signAlg', 'SHA256withECDSA',
    '-profileFile', P7B,
    '-appCertFile', CER,
    '-inFile', unsigned_hap,
    '-outFile', signed_hap
], capture_output=True, text=True)

print('STDOUT:', result.stdout)
print('STDERR:', result.stderr)
print('Return code:', result.returncode)

if result.returncode != 0:
    print('Signing failed!')
    exit(1)
"

# Install
echo ""
echo ">>> Uninstalling previous..."
"$HDC" shell bm uninstall -n com.v2ray.ang.harmony 2>/dev/null || true
echo ">>> Installing..."
"$HDC" install "$SIGNED_HAP"
echo ">>> Done!"
