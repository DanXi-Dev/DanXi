# Emoji Cloud Control Implementation

This implementation adds support for remote emoji/sticker management through danxi-static.

## Features

1. **Version Management**: Checks sticker package version on startup and only updates when needed
2. **Local Caching**: Caches sticker metadata and images locally for offline usage
3. **Backward Compatibility**: Maintains support for existing hardcoded local stickers
4. **Performance**: Pre-caches images in background for better user experience

## API Endpoint

The implementation expects a manifest file at:
```
https://danxi-static.fduhole.com/stickers/manifest.json
```

### Expected Manifest Format

```json
{
  "version": "1.0.0",
  "description": "DanXi Sticker Package",
  "updated_at": "2024-01-01T00:00:00Z",
  "stickers": [
    {
      "name": "dx_example",
      "display_name": "Example Sticker",
      "image_url": "https://danxi-static.fduhole.com/stickers/dx_example.webp",
      "category": "emotions"
    }
  ]
}
```

## Implementation Details

### Files Added/Modified

1. **`lib/model/sticker/remote_sticker.dart`** - Data models for remote stickers
2. **`lib/repository/app/sticker_repository.dart`** - Repository for fetching and caching stickers
3. **`lib/util/stickers.dart`** - Enhanced utility supporting both local and remote stickers
4. **`lib/page/home_page.dart`** - Added sticker loading on app startup
5. **`lib/page/forum/hole_editor.dart`** - Updated editor to show all available stickers
6. **`lib/widget/forum/render/render_impl.dart`** - Updated renderer to support remote stickers

### Usage in Markdown

Stickers continue to work the same way in markdown:
```markdown
![](dx_heart)
![](dx_new_remote_sticker)
```

The system automatically checks local stickers first, then remote stickers as fallback.

## Cache Management

- **Metadata Cache**: Stored in SharedPreferences
- **Image Cache**: Uses `cached_network_image` and `DefaultCacheManager`
- **Version Checking**: Only updates when version changes
- **Fallback**: Gracefully handles network failures by using cached data