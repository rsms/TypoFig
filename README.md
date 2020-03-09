# TypoFig

Small Mac app for assisting with typography design in Figma.

<img src="https://raw.githubusercontent.com/rsms/TypoFig/master/TypoFig/Assets.xcassets/AppIcon.appiconset/icon_512x512%402x.png" width="64" height="64">

[→ Download](https://github.com/rsms/TypoFig/releases/latest)

Currently the app only does one specific thing: Convert Glyphs clipboard contents to SVG.

1. Start the app
2. Copy shapes in Glyphs.app
3. Paste somewhere that accepts SVG, for example Figma

<img src="https://raw.githubusercontent.com/rsms/TypoFig/master/glyphs-svg-clipboard-demo.gif" width="606">

The app observes the clipboard. When it sees some Glyphs content it attempts to
convert it into SVG and then adds the SVG to the clipboard.
When the app finds Glyphs content and converts it, it bounces its app icon in the Dock.
