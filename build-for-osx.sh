set -euo pipefail

failures=0
trap 'failures=$((failures+1))' ERR

PREFIX=${1:-/opt/homebrew/opt/qt@5}

mkdir -p build-osx/
pushd build-osx/
cmake -DSCAP_WORKBENCH_LOCAL_SCAN_ENABLED=false -DSCAP_AS_RPM_EXECUTABLE="" -DCMAKE_PREFIX_PATH="${PREFIX}" ../
make -j 4
mkdir -p ./scap-workbench.app/Contents/Frameworks/
cp -v /opt/homebrew/lib/libpcre.1.dylib ./scap-workbench.app/Contents/Frameworks/
cp -v /usr/local/lib/libopenscap*.dylib ./scap-workbench.app/Contents/Frameworks/
chmod 755 ./scap-workbench.app/Contents/Frameworks/*.dylib
echo "Copy fresh extracted SSG zip into `pwd`/scap-workbench.app/Contents/Resources/ssg/"
echo "so that SSG README.md is at `pwd`/scap-workbench.app/Contents/Resources/ssg/README.md"
echo "Then change directory to `pwd` and run \"sh osx-create-dmg.sh\""
popd
