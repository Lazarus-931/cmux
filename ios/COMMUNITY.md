# cmux Community for iPhone and iPad

This fork provides an unofficial, GPL-licensed iOS package that does not use
cmux's paid TestFlight enrollment. It is built from the public `ios/` source and
uses the free local-network or Tailscale pairing path to a Mac you control.

The community IPA is intentionally unsigned. Apple requires every iOS app to be
signed for the destination device, so downloading the file is only the first
step. Re-sign it with your own Apple developer identity or a sideloading tool
you trust, then install it on your device. Free personal provisioning may need
periodic renewal; paid developer provisioning generally lasts longer.

## Download

Tagged builds appear on the fork's [Releases](https://github.com/Lazarus-931/cmux/releases)
page as `cmux-community-ios.ipa`. Every release also includes a JSON file with
the exact source commit and license. Workflow-dispatch builds are available as
GitHub Actions artifacts before a public release is cut.

## Build from source

Use a Mac with Xcode 26 and the repository prerequisites installed:

```bash
./scripts/setup.sh
ios/scripts/build-community-ipa.sh
```

The output is `cmux-community-ios.ipa` at the repository root. The build script
uses a distinct bundle identifier (`io.github.lazarus931.cmux.community`), turns
crash reporting off, omits upstream distribution entitlements, and verifies the
packaged artifact before returning success.

## Pair with a Mac

The community IPA uses the production-compatible pairing channel, so it can
pair with the free macOS cmux release. Sign in with the same free account on the
Mac and iPhone, open **Open Tailscale Pairing** from the Mac command palette,
and scan the QR code from inside the iOS app. A Pro subscription is not checked
by the local pairing runtime.

Upstream-hosted cloud services remain subject to their own plans and terms.
Push notifications and Sign in with Apple depend on Apple-controlled
entitlements and are not promised by the unsigned community package; email,
GitHub, or Google sign-in can be used instead.

## Publish a release

Pushing a tag named `community-ios-v*` runs the community workflow and publishes
the verified IPA on GitHub Releases. Run the workflow manually first and test
the re-signed artifact on a physical device before tagging a public release.

This project is not affiliated with or endorsed by Manaflow. Preserve the GPL
license, corresponding source, third-party notices, and a clear record of fork
changes when redistributing it. The cmux name and logo may have separate
trademark restrictions not granted by the source-code license.
