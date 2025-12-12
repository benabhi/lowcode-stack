# Appsmith Watermark Removal - Technical Guide

This document explains how the "Built on Appsmith" watermark is removed from Appsmith Community Edition in this project.

## Background

Appsmith Community Edition displays a "Built on Appsmith" watermark in the bottom-right corner of all published applications. This watermark is controlled by a `hideWatermark` configuration that only works in the Business Edition.

## How the Watermark Works

### Source Code Analysis

The watermark is rendered in `app/client/src/pages/AppViewer/index.tsx`:

```tsx
const hideWatermark = useSelector(getHideWatermark);

// In the render:
<div className="fixed hidden right-8 z-3 md:flex bottom-4">
  {!hideWatermark && (
    <a href="https://appsmith.com" target="_blank">
      <BrandingBadge />
    </a>
  )}
</div>
```

The `BrandingBadge` component (`src/pages/AppViewer/BrandingBadge.tsx`) renders:
- "Built on" text
- Appsmith logo SVG

### The Problem

In Community Edition, `getHideWatermark` always returns `false`, so the watermark is always displayed. The `hideWatermark` configuration only works with a Business Edition license.

## Solution

### Approach: Patch the Compiled JavaScript Bundle

Since modifying source code requires forking and rebuilding Appsmith (complex and time-consuming), we instead patch the compiled JavaScript bundle at runtime.

### Technical Details

In the minified `AppViewer.*.chunk.js`, the condition looks like:

```javascript
children:!W&&(0,P.jsx)("a",{className:"hover:no-underline",href:"https://appsmith.com",...
```

Where `!W` is the minified version of `!hideWatermark`.

We replace `!W&&` with `false&&` so the condition never evaluates to true:

```javascript
children:false&&(0,P.jsx)("a",{className:"hover:no-underline",href:"https://appsmith.com",...
```

### Implementation

We use `perl` for reliable regex replacement inside the Docker container:

```powershell
# Find the AppViewer chunk file
$chunkFile = docker exec nocode-appsmith sh -c 'ls /opt/appsmith/editor/static/js/AppViewer.*.chunk.js | head -1'

# Apply the patch
docker exec nocode-appsmith perl -i -pe 's/children:!W&&/children:false\&\&/g' $chunkFile
```

### Why Perl Instead of Sed?

- `sed` on Alpine Linux has issues with complex escape sequences
- `perl` handles the `&&` characters more reliably
- `perl -i -pe` provides in-place editing with regex support

## Integration in This Project

### Automatic Application

The `start.ps1` script automatically applies the patch after Appsmith becomes healthy:

```powershell
# Wait for Appsmith to be healthy
while ($status -ne "healthy") { ... }

# Apply patch
docker exec nocode-appsmith perl -i -pe 's/children:!W&&/children:false\&\&/g' $chunkFile
```

### Manual Application

If you need to re-apply the patch (e.g., after container recreation):

```powershell
.\remove-appsmith-watermark.ps1
```

## Important Notes

### Persistence

⚠️ **The patch is NOT persistent across container recreations.**

When you run `docker compose up -d appsmith --force-recreate` or `stop.ps1 -RemoveVolumes`, the original files are restored and the patch must be reapplied.

The `start.ps1` script handles this automatically.

### Version Compatibility

The patch targets the pattern `children:!W&&` which is the minified form of the watermark condition. If Appsmith changes their minification or code structure, this pattern may need to be updated.

**Tested with:** Appsmith CE v1.93 (December 2024)

### Alternative Approaches (Not Used)

1. **CSS Injection**: Tried but failed because React re-renders override CSS
2. **JavaScript Injection**: Tried but SES (Secure ECMAScript) sandbox blocks DOM modifications
3. **MutationObserver**: Tried but didn't reliably catch React renders
4. **Modifying index.html**: Tried but scripts run after React initialization

## License Considerations

Appsmith Community Edition is licensed under Apache License 2.0, which permits:
- Modification of the software
- Distribution of modified versions
- Use for any purpose

Removing the watermark for personal/internal use is permitted under this license.

## Troubleshooting

### Watermark Still Visible After Patch

1. **Clear browser cache**: Press `Ctrl+Shift+F5` for a hard refresh
2. **Verify patch applied**:
   ```powershell
   docker exec nocode-appsmith grep -c "children:false&&" /opt/appsmith/editor/static/js/AppViewer.*.chunk.js
   # Should return 1
   ```

### Patch Not Applied on Start

1. **Check if Appsmith is healthy**:
   ```powershell
   docker inspect --format='{{.State.Health.Status}}' nocode-appsmith
   ```
2. **Run manual patch**:
   ```powershell
   .\remove-appsmith-watermark.ps1
   ```

### Container Keeps Restarting

The patch should not cause container issues. If Appsmith is restarting, check logs:
```powershell
docker logs nocode-appsmith --tail 50
```
