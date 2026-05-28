# Pulse Orbit

Pulse Orbit is a Garmin Connect IQ watch face with a premium sport direction: orbital hour numerals, high-contrast analog hands, a dark technical dial, and minimal daily metrics.

The project was stabilized from the original FaceWatch codebase and is currently targeted at the Forerunner 970 (`fr970`).

## Current Status

- Stable build generated successfully with Garmin Connect IQ SDK `9.1.0`.
- Final binary: `bin/FaceWatch.prg`.
- Signed build was generated locally using the Garmin developer key located outside the repo.
- Active identity: `Pulse Orbit`.
- UI direction: sport analog face with orbital energy.

## Implemented Features

- Non-linear/orbital hour numeral layout.
- Active hour highlight with an electric-cyan ring.
- Procedural carbon-style dark background.
- Sport minute track with subtle ticks.
- Analog hands with a premium technical style.
- Smooth active second hand with reduced refresh load.
- Cached numeral bitmap loading for better runtime behavior.
- Minimal microdata line for:
  - Steps
  - Battery
- Configurable brand name and accent theme through Connect IQ settings.
- AMOLED-friendly sleep behavior: simplified black AOD-style rendering.

## Product Direction

Pulse Orbit should be positioned as an original sport-premium Garmin watch face, not as a tribute or copy of any watch brand.

Safe positioning:

- Dynamic analog-style layout.
- Sport-focused Garmin Connect IQ watch face.
- Clear time reading with essential daily metrics.
- Premium motion, clean data, bold time.

Avoid in store copy, screenshots, comments, and metadata:

- References to third-party luxury watch brands.
- References to "Crazy Hours" or similar protected product language.
- Claims like "compatible with all Garmin watches".
- Claims about medical accuracy or professional health metrics.
- Features not implemented or not tested.

## Build Requirements

- Garmin Connect IQ SDK.
- Monkey C compiler (`monkeyc`).
- A Garmin developer key.

This machine currently uses:

```powershell
C:\Users\lfvvi\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.1.0-2026-03-09-6a872a80b
```

The developer key is intentionally kept outside the repository:

```powershell
C:\Users\lfvvi\OneDrive\Escritorio\Garmin\Proyecto1\developer_key
```

Do not commit the developer key.

## Build Command

From the repository root:

```powershell
& 'C:\Users\lfvvi\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.1.0-2026-03-09-6a872a80b\bin\monkeyc.bat' `
  -f monkey.jungle `
  -d fr970 `
  -o bin\FaceWatch.prg `
  -y 'C:\Users\lfvvi\OneDrive\Escritorio\Garmin\Proyecto1\developer_key' `
  -w
```

Expected result:

```text
BUILD SUCCESSFUL
```

## Run In Simulator

Start the Connect IQ simulator, then run:

```powershell
& 'C:\Users\lfvvi\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.1.0-2026-03-09-6a872a80b\bin\monkeydo.bat' bin\FaceWatch.prg fr970
```

## Canva / Store Assets

A Canva editable mockup was created from the simulator capture:

- Edit URL: https://www.canva.com/d/gcMAQPWo6pcj4-3
- View URL: https://www.canva.com/d/2Srt4-cpqk3a2k8

Magic Design was not enabled in the current Canva team, so the generated Canva file is based on image-to-design conversion rather than full prompt generation.

## Store Listing Draft

Title:

```text
Pulse Orbit - Sport Watch Face
```

Short description:

```text
Dynamic sport analog face with orbital numerals, clear time reading, and essential daily metrics.
```

Suggested listing copy:

```text
Pulse Orbit brings a bold sport analog layout to your Garmin watch: orbital hour numerals, clear hands, a dark technical dial, and essential daily metrics like steps and battery.
```

## Suggested Price

Recommended launch price:

```text
USD $3.99 - $4.99
```

Use the lower end if shipping as the current MVP. Use the higher end after adding more settings, variants, and verified AOD/device support.

## Not Yet Implemented

Do not advertise these until implemented and tested:

- Heart rate widget.
- Weather.
- Date complication.
- Multiple layout presets.
- Full AMOLED burn-in mitigation beyond current sleep rendering.
- Broad device compatibility beyond tested targets.
- Advanced activity/training metrics.

## Roadmap

1. Add a true minimal AOD layout.
2. Add optional date widget.
3. Add HR only after confirming permissions, device behavior, and battery impact.
4. Add color presets: Core, Neon Sport, Stealth.
5. Test on more Garmin screen sizes.
6. Prepare final Connect IQ Store screenshots.

## Repository

GitHub:

https://github.com/lfvvillanueva/FaceWatch

