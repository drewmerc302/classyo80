#!/bin/bash
#
# Build, test and package an App Store build of Classy-O 80.
#
#   Scripts/release.sh              test, archive and export build/ClassyO80.ipa
#   Scripts/release.sh --upload     the same, then upload it to App Store Connect
#   Scripts/release.sh --skip-tests archive and export only
#
# Uploading needs an App Store Connect API key in the environment:
#
#   ASC_KEY_ID      the key's ID, e.g. ABCD123456
#   ASC_ISSUER_ID   the issuer UUID from App Store Connect > Users and Access > Integrations
#
# and the .p8 private key in one of the places altool looks, usually
# ~/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8.
#
# Without a key, open build/ClassyO80.xcarchive in Xcode Organizer and use Distribute App.

set -euo pipefail

cd "$(dirname "$0")/.."

readonly SCHEME=ClassyO80
readonly PROJECT=ClassyO80.xcodeproj
readonly BUILD_DIR=build
readonly ARCHIVE="$BUILD_DIR/ClassyO80.xcarchive"
readonly TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro'

upload=no
run_tests=yes
for argument in "$@"; do
    case "$argument" in
        --upload) upload=yes ;;
        --skip-tests) run_tests=no ;;
        *) echo "unknown option: $argument" >&2; exit 2 ;;
    esac
done

step() { printf '\n==> %s\n' "$1"; }

step "Checking the working tree is clean"
if [[ -n "$(git status --porcelain)" ]]; then
    echo "Uncommitted changes. Commit or stash them so the build matches a known commit." >&2
    exit 1
fi

step "Reading the version"
version=$(/usr/bin/awk '/^ *MARKETING_VERSION:/ { gsub(/"/, "", $2); print $2 }' project.yml)
build_number=$(/usr/bin/awk '/^ *CURRENT_PROJECT_VERSION:/ { gsub(/"/, "", $2); print $2 }' project.yml)
echo "Version $version ($build_number) from commit $(git rev-parse --short HEAD)"

step "Generating the Xcode project"
xcodegen generate

if [[ "$run_tests" == yes ]]; then
    step "Engine tests"
    (cd Packages/CalcEngine && swift test)

    step "App tests"
    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$TEST_DESTINATION"
fi

step "Archiving (Release, generic iOS device)"
rm -rf "$ARCHIVE"
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE" \
    -allowProvisioningUpdates

step "Exporting for App Store Connect"
rm -rf "$BUILD_DIR/export"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportOptionsPlist Scripts/ExportOptions.plist \
    -exportPath "$BUILD_DIR/export" \
    -allowProvisioningUpdates

ipa=$(/usr/bin/find "$BUILD_DIR/export" -maxdepth 1 -name '*.ipa' | head -1)
if [[ -z "$ipa" ]]; then
    echo "Export produced no .ipa" >&2
    exit 1
fi
echo "Exported $ipa"

if [[ "$upload" != yes ]]; then
    step "Done"
    echo "Upload it with: Scripts/release.sh --upload"
    echo "or open $ARCHIVE in Xcode Organizer and use Distribute App."
    exit 0
fi

step "Validating with App Store Connect"
: "${ASC_KEY_ID:?set ASC_KEY_ID to your App Store Connect API key ID}"
: "${ASC_ISSUER_ID:?set ASC_ISSUER_ID to your App Store Connect issuer ID}"
xcrun altool --validate-app \
    -f "$ipa" \
    -t ios \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID"

step "Uploading"
xcrun altool --upload-app \
    -f "$ipa" \
    -t ios \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID"

step "Uploaded version $version ($build_number)"
cat <<TAG
Tag the commit once App Store Connect finishes processing:

    git tag -a v$version -m "Classy-O 80 $version ($build_number)"
    git push origin v$version

Then bump CURRENT_PROJECT_VERSION in project.yml before the next upload.
TAG
