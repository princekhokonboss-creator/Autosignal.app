# SHAON SIGNAL — Flutter Android starter

This is a Flutter source project for an educational, sample-data-only market indicator demo.

## Included
- Dark Android dashboard
- EMA 9 / EMA 21
- RSI (14)
- Bollinger Bands (20, 2)
- CALL / PUT / NO SIGNAL educational labels
- Demo score and indicator reasons
- Asset and timeframe selectors (display selectors only in this starter)

## Important limitations
- The app generates sample candles locally. It does NOT fetch live market data.
- Asset/timeframe selectors are UI placeholders until a properly licensed market-data provider is connected.
- No broker connection, order placement, real-money trading, or Telegram alert is included.
- The score is a rule-match score, not a calibrated probability or guarantee.

## Build an APK
1. Install Flutter SDK and Android Studio on a computer.
2. Extract this project.
3. In this folder run: `flutter pub get`
4. Connect an Android phone with USB debugging enabled, or start an emulator.
5. Test with: `flutter run`
6. Build APK with: `flutter build apk --release`
7. APK output: `build/app/outputs/flutter-apk/app-release.apk`

To create the Android platform folder if missing, run `flutter create .` in this project folder before `flutter pub get`.
