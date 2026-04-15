#!/bin/sh
set -e

# XcodeGen keeps *.xcodeproj out of git; generate it (and SwiftGen/Mockolo outputs) before resolve/build.
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$REPO_ROOT"

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1

echo "ci_post_clone: repo root is ${REPO_ROOT}"

brew install xcodegen swiftgen mockolo

make generate_project

if [ ! -f "${REPO_ROOT}/OzgurKon.xcodeproj/project.pbxproj" ]; then
  echo "error: OzgurKon.xcodeproj was not generated" >&2
  exit 1
fi

echo "ci_post_clone: OzgurKon.xcodeproj ready"
