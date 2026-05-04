# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ABR is an Elder Scrolls Online (ESO) addon. (TODO: Add description)

## Build Commands

```bash
# Build distribution zip
./gradlew distZip

# Install to ESO Live directory (requires gradle.properties)
./gradlew installToLive

# Install to ESO PTS directory (requires gradle.properties)
./gradlew installToPTS

# Upload to esoui.com (requires API token in gradle.properties)
./gradlew upload
```

The `gradle.properties` file must define:
- `ESO_LIVE_ADDONS_DIR` - path to ESO live addons folder
- `ESO_PTS_ADDONS_DIR` - path to ESO PTS addons folder
- `com.esoui.apiToken` - API token for esoui.com uploads

Version numbers are extracted from the first line of `changelog`.

## Architecture

### Module System

The addon uses a consistent module pattern. Each module file follows this structure:

```lua
local addon = ABR
local l = {}  -- private table
local m = {l=l}  -- public table
-- ... implementation ...
addon.register("ModuleName#M", m)
```

### Extension Points

Modules communicate through an extension system:

```lua
-- Define extension key
m.EXTKEY_UPDATE = "Core:update"

-- Register extension handler
addon.extend(settings.EXTKEY_ADD_DEFAULTS, function()
  settings.addDefaults(defaults)
end)

-- Call extensions
addon.callExtension(m.EXTKEY_UPDATE)
```

## Localization

Language files in `i18n/` use `putText(key, translation)` pattern. Files are named by language code (en, zh, de, fr, etc.).
