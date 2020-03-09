#import "AppDelegate.h"

#define auto __auto_type

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate {
  NSInteger lastChangeCount;
}

static NSString* glyphsAppGlyphPBUTI;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Glyphs uses a dynamic UTI for writing pasteboard data.
  // Get its dynamic UTI.
  glyphsAppGlyphPBUTI = (NSString*)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassNSPboardType, CFSTR("Glyphs elements pasteboard type"), kUTTypeData));
  //NSLog(@"glyphsAppGlyphPBUTI: %@", glyphsAppGlyphPBUTI);

  [self pollPasteboard];
}


- (void)pollPasteboard {
  //NSLog(@"pollPasteboard");
  auto pb = [NSPasteboard generalPasteboard];
  if (lastChangeCount != pb.changeCount) {
    lastChangeCount = pb.changeCount;
    [self checkPasteboard:pb];
  }
  [self performSelector:@selector(pollPasteboard) withObject:nil afterDelay:1];
}


- (void)checkPasteboard:(NSPasteboard*)pb {
  //NSLog(@"pb %@", pb);
  for (NSPasteboardItem* item in pb.pasteboardItems) {
    //NSLog(@"item %@", item);
    for (NSPasteboardType type in item.types) {
      //NSLog(@"  type %@", type);
      
      if ([type isEqualToString:glyphsAppGlyphPBUTI]) {
        id plist = [item propertyListForType:type];
        if (plist != nil &&
            ![plist isKindOfClass:[NSNull class]] &&
            ( [[plist class] isKindOfClass:[NSDictionary class]] ||
              [plist respondsToSelector:@selector(objectForKey:)]
            )
        ) {
          [self handleGlyphsAppGlyphPBData:(NSDictionary*)plist pb:pb];
          return;
        }
        //NSLog(@"    plist %@ %@", [plist class], plist);
      }
    }
  }
}


typedef struct {
  double x;
  double y;
  NSString* op;
} GlyphsVectorCmdNode;


- (void)handleGlyphsAppGlyphPBData:(NSDictionary*)d pb:(NSPasteboard*)pb {
  //NSLog(@"    d %@", d);
  
  double __block minX = 99999999999, maxX = -99999999999, minY = 99999999999, maxY = -99999999999;
  
  auto makePath = ^NSString*(NSDictionary* path) {

    NSArray<NSString*>* nodes = path[@"nodes"];

    auto getNode = ^(size_t index) {
      auto v = [nodes[index] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      GlyphsVectorCmdNode n = {0, 0, @"(MISSING)"};
      if (v.count > 0 && [[NSScanner scannerWithString:v[0]] scanDouble:&n.x]) {
        if (v.count > 1 && [[NSScanner scannerWithString:v[1]] scanDouble:&n.y]) {
          n.y = n.y * -1;
          if (n.x < minX) { minX = n.x; }
          if (n.x > maxX) { maxX = n.x; }
          if (n.y < minY) { minY = n.y; }
          if (n.y > maxY) { maxY = n.y; }
          if (v.count > 2) {
            n.op = v[2];
          }
        }
      }
      return n;
    };
    
    auto commands = [NSMutableArray arrayWithCapacity:nodes.count];
    BOOL hasMoveTo = NO;

    auto lastIndex = ((ssize_t)nodes.count) - 1;
    for (auto i = lastIndex; i >= 0; i--) {
      auto n = getNode(i);
      
      //NSLog(@"%f, %f, %@", n.x, n.y, n.op);
      
      if (i == 0) {
        [commands addObject:[NSString stringWithFormat:@"M %.10g %.10g", n.x, n.y]];
        hasMoveTo = YES;
      } else if ([n.op isEqualToString:@"LINE"]) {
        [commands addObject:[NSString stringWithFormat:@"L %.10g %.10g", n.x, n.y]];
      } else if ([n.op isEqualToString:@"CURVE"]) {
        // two control points
        auto c1 = getNode(i-2);
        auto c2 = getNode(i-1);
        i -= 2;
        [commands addObject:[NSString stringWithFormat:
                             @"C %.10g %.10g  %.10g %.10g  %.10g %.10g",
                             c1.x, c1.y, c2.x, c2.y, n.x, n.y]];
      } else {
        NSLog(@"unexpected glyphs node type %@", n.op);
        return nil;
      }
      
      if (i <= 0 && !hasMoveTo) {
        // wrap around; add move to at front
        auto n = getNode(lastIndex);
        [commands addObject:[NSString stringWithFormat:@"M %.10g %.10g", n.x, n.y]];
      }
    }
    
    // build SVG path element
    auto svg = [NSMutableString stringWithString:
                @"<path fill-rule=\"nonzero\" d=\"\n  "];
    
    [svg appendString:[[[commands reverseObjectEnumerator] allObjects] componentsJoinedByString:@"\n  "]];
    
    // is path closed? Add Z at end
    if (path[@"closed"] != nil && [path[@"closed"] isEqualToString:@"1"]) {
      [svg appendString:@"\nZ"];
    }
    [svg appendString:@"\"/>"];

    return svg;
  };
  
  /*"290 0 LINE",
  "290 1314 LINE",
  "604 1314 LINE SMOOTH",
  "843 1314 OFFCURVE",
  "935 1197 OFFCURVE",
  "934 1020 CURVE SMOOTH",
  "935 844 OFFCURVE",
  "843 736 OFFCURVE",
  "606 736 CURVE SMOOTH",
  "210 736 LINE",
  "210 576 LINE",
  "612 576 LINE SMOOTH",
  "955 575 OFFCURVE",
  "1110 760 OFFCURVE",
  "1110 1020 CURVE SMOOTH",
  "1110 1281 OFFCURVE",
  "955 1472 OFFCURVE",
  "610 1472 CURVE SMOOTH",
  "112 1472 LINE",
  "112 0 LINE"
   
   BECOMES
   
   d="
   M 290 0
   L 290 1314
   L 604 1314
   C 843 1314   935 1197  934 1020
   C 935 844    843 736  606 736
   L 210 736
   L 210 576
   L 612 576
   C 955 575    1110 760  1110 1020
   C 1110 1281  955 1472  610 1472
   L 112 1472
   L 112 0
   Z" */

  
  auto paths = [NSMutableArray arrayWithCapacity:((NSArray*)d[@"paths"]).count];
  for (NSDictionary* path in d[@"paths"]) {
    auto d = makePath(path);
    if (d == nil) {
      return;
    }
    [paths addObject:d];
  }
  
  //NSLog(@"x [%f-%f], y [%f-%f]", minX, maxX, minY, maxY);
  auto width  = maxX - minX;
  auto height = -minY + maxY;

  auto svg = [NSString stringWithFormat:
              @"<svg width=\"%.10g\" height=\"%.10g\" viewBox=\"0 0 %.10g %.10g\""
              " xmlns=\"http://www.w3.org/2000/svg\">"
              "<g transform=\"translate(%.10g,%.10g)\">"
              "%@"
              "</g>"
              "</svg>",
              width, height,
              
              // viewBox
              width, height,
              //width, height,
              //minX, -maxY, maxX, maxY-minY,
              
              -minX, height-maxY,
              [paths componentsJoinedByString:@"\n"]
              ];

  // resolve & copy pdf item before clearing pasteboard
  auto pdfData = [pb dataForType:NSPasteboardTypePDF];

  // must clear in order to write (can't append to pasteboard items written by other app)
  [pb clearContents];
  
  // add glyphs pb item as well as any pdf item that was in the pasteboard originally
  [pb setPropertyList:d forType:glyphsAppGlyphPBUTI];
  if (pdfData != nil) {
    [pb setData:pdfData forType:NSPasteboardTypePDF];
  }
  
  // add svg
  [pb setData:[svg dataUsingEncoding:NSUTF8StringEncoding] forType:NSPasteboardTypeString];
//  NSLog(@"wrote SVG");
  
  // update lastChangeCount so we don't cause an infinite poll loop
  lastChangeCount = pb.changeCount;

  // bounce the app in the dock once to let the user know the pb was updated
  [NSApp requestUserAttention:NSInformationalRequest];

  /* Example of plist for /R
   {
       anchors =  (
          {
               name = top;
               position = "{572, 1656}";
           },
          {
               name = bottom;
               position = "{598, 0}";
           }
       );
       glyph = R;
       layer = "C698F293-3EC0-4A5A-A3A0-0FDB1F5CF265";
       paths =  (
          {
               closed = 1;
               nodes =  (
                   "290 0 LINE",
                   "290 1314 LINE",
                   "604 1314 LINE SMOOTH",
                   "843 1314 OFFCURVE",
                   "935 1197 OFFCURVE",
                   "934 1020 CURVE SMOOTH",
                   "935 844 OFFCURVE",
                   "843 736 OFFCURVE",
                   "606 736 CURVE SMOOTH",
                   "210 736 LINE",
                   "210 576 LINE",
                   "612 576 LINE SMOOTH",
                   "955 575 OFFCURVE",
                   "1110 760 OFFCURVE",
                   "1110 1020 CURVE SMOOTH",
                   "1110 1281 OFFCURVE",
                   "955 1472 OFFCURVE",
                   "610 1472 CURVE SMOOTH",
                   "112 1472 LINE",
                   "112 0 LINE"
               );
           },
          {
               closed = 1;
               nodes =             (
                   "604 662 LINE",
                   "960 0 LINE",
                   "1168 0 LINE",
                   "806 662 LINE"
               );
           }
       );
   } */
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}


@end
