# ÖzgürKon for iOS

ÖzgürKon is the international free software conference organized by [Özgür Yazılım Derneği](https://oyd.org.tr/). This app helps attendees browse the [Pretalx schedule](https://cfp.oyd.org.tr/ozgurkon-2026/) and manage favorites on iPhone and iPad.

## Upstream

This project is a fork of [FOSDEM.app](https://github.com/mttcrsp/fosdem) by Matteo Cortesi. The FOSDEM name and gear logo are trademarks of FOSDEM VZW and are not used here.

## Development

Generate the Xcode project, mocks, and assets (requires [XcodeGen](https://github.com/yonaskolb/XcodeGen), [Mockolo](https://github.com/uber/mockolo), [SwiftGen](https://github.com/SwiftGen/SwiftGen)):

```bash
make generate_project
make run_mockolo run_swiftgen
```

SwiftGen reads `App/Resources/en.lproj/Localizable.strings` only. After adding keys there, mirror them in `App/Resources/tr.lproj/Localizable.strings` for Turkish.

Run tests:

```bash
make test
```

After branding or UI changes, snapshot tests may need re-recording from Xcode.

## Schedule data

The app loads `schedule.xml` from Pretalx (`PretalxConfiguration` in sources). Only the configured conference edition year is supported for downloads.

## App Store

Set `URL.appStore` in [`App/Sources/Extensions/URL+Extensions.swift`](App/Sources/Extensions/URL+Extensions.swift) when the app has a public listing.

## License

See the upstream FOSDEM.app repository for the original license terms. New contributions in this fork should stay compatible with that license unless stated otherwise.
