# TypoFig

Small Mac app for assisting with typography design in Figma.

Currently the app only does one specific thing: Convert Glyphs clipboard contents to SVG.

1. Start the app
2. Copy shapes in Glyphs.app
3. Paste somewhere that accepts SVG, for example Figma

The app observed the clipboard and when it seems Glyphs content, it attempts to
convert it into SVG and then adds the SVG to the clipboard.
When the app finds Glyphs content and converts it, it bounces its app icon in the Dock.
