#import "PlayerOutline.h"

dispatch_queue_t backgroundQueue() {
    static dispatch_once_t queueCreationGuard;
    static dispatch_queue_t queue;
    dispatch_once(&queueCreationGuard, ^{
        queue = dispatch_queue_create("com.popsicletreehouse.playeroutline.backgroundQueue", 0);
    });
    return queue;
}

UIColor *getPrimaryColorFromImage(UIImage *image) {
    int dimension = 4;
    int flexibility = 1;
    int range = 100;
    NSMutableArray* colors = [NSMutableArray new];
    CGImageRef imageRef = [image CGImage];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char* rawData = (unsigned char *) calloc(dimension * dimension * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * dimension;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, dimension, dimension, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, dimension, dimension), imageRef);
    CGContextRelease(context);

    float x = 0;
    float y = 0;

    for (int n = 0; n < (dimension * dimension); n++) {
        int index = (bytesPerRow * y) + x * bytesPerPixel;
        int red   = rawData[index];
        int green = rawData[index + 1];
        int blue  = rawData[index + 2];
        int alpha = rawData[index + 3];
        NSArray* a = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%i", red], [NSString stringWithFormat:@"%i", green], [NSString stringWithFormat:@"%i", blue], [NSString stringWithFormat:@"%i", alpha], nil];
        [colors addObject:a];
        y++;
        if (y == dimension){
            y = 0;
            x++;
        }
    }
    free(rawData);

    NSArray* copycolors = [NSArray arrayWithArray:colors];
    NSMutableArray* flexiblecolors = [NSMutableArray new];

    float flexFactor = flexibility * 2 + 1;
    float factor = flexFactor * flexFactor * 3;

    for (int n = 0; n < (dimension * dimension); n++){
        NSArray* pixelcolors = copycolors[n];
        NSMutableArray* reds = [NSMutableArray new];
        NSMutableArray* greens = [NSMutableArray new];
        NSMutableArray* blues = [NSMutableArray new];

        for (int p = 0; p < 3; p++){
            NSString* rgbStr = pixelcolors[p];
            int rgb = [rgbStr intValue];
            for (int f = - flexibility; f < flexibility + 1; f++){
                int newRGB = rgb + f;
                if (newRGB < 0)
                    newRGB = 0;
                if (p == 0)
                    [reds addObject:[NSString stringWithFormat:@"%i", newRGB]];
                else if (p == 1)
                    [greens addObject:[NSString stringWithFormat:@"%i", newRGB]];
                else if (p == 2)
                    [blues addObject:[NSString stringWithFormat:@"%i", newRGB]];
            }
        }

        int r = 0;
        int g = 0;
        int b = 0;

        for (int k = 0; k < factor; k++) {
            int red = [reds[r] intValue];
            int green = [greens[g] intValue];
            int blue = [blues[b] intValue];

            NSString* rgbString = [NSString stringWithFormat:@"%i, %i, %i", red, green, blue];
            [flexiblecolors addObject:rgbString];

            b++;
            if (b == flexFactor) {
                b = 0;
                g++;
            }
            if (g == flexFactor) {
                g = 0;
                r++;
            }
        }
    }

    NSMutableDictionary* colorCounter = [NSMutableDictionary new];

    NSCountedSet* countedSet = [[NSCountedSet alloc] initWithArray:flexiblecolors];
    for (NSString* item in countedSet) {
        NSUInteger count = [countedSet countForObject:item];
        [colorCounter setValue:[NSNumber numberWithInteger:count] forKey:item];
    }

    NSArray* orderedKeys = [colorCounter keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2){
        return [obj2 compare:obj1];
    }];

    NSMutableArray* ranges = [NSMutableArray new];
    for (NSString* key in orderedKeys){
        NSArray* rgb = [key componentsSeparatedByString:@","];
        int r = [rgb[0] intValue];
        int g = [rgb[1] intValue];
        int b = [rgb[2] intValue];
        BOOL exclude = NO;
        for (NSString* ranged_key in ranges){
            NSArray* ranged_rgb = [ranged_key componentsSeparatedByString:@","];

            int ranged_r = [ranged_rgb[0] intValue];
            int ranged_g = [ranged_rgb[1] intValue];
            int ranged_b = [ranged_rgb[2] intValue];

            if (r >= ranged_r - range && r <= ranged_r + range)
                if (g >= ranged_g - range && g <= ranged_g + range)
                    if (b >= ranged_b - range && b <= ranged_b + range)
                        exclude = YES;
        }
        if (!exclude) [ranges addObject:key];
    }

    NSMutableArray* colorArray = [NSMutableArray new];
    UIColor* color;
    for (NSString* key in ranges){
        NSArray* rgb = [key componentsSeparatedByString:@","];
        float r = [rgb[0] floatValue];
        float g = [rgb[1] floatValue];
        float b = [rgb[2] floatValue];
        color = [UIColor colorWithRed:(r / 255.0f) green:(g / 255.0f) blue:(b / 255.0f) alpha:1.0f];
        [colorArray addObject:color];
    }

    return color;
}

%hook CSAdjunctItemView
%new
- (void)updateBorderColor {
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef info) {
        if(!info) return;
        NSDictionary *dict = (__bridge NSDictionary *)info;
        double elapsedTime = [[dict objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoElapsedTime] doubleValue];
        if (elapsedTime == -1) return;
        NSData *artworkData = [dict objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData];
        if(!artworkData) return;
        UIImage *artwork = [UIImage imageWithData:artworkData];
        CGColorRef primaryColor = [getPrimaryColorFromImage(artwork) CGColor];
        PLPlatterView *platterView = [self valueForKey:@"_platterView"];
        MTMaterialView *materialView = [platterView backgroundView];
        MTMaterialLayer *layer = (MTMaterialLayer *)[materialView layer];
        layer.borderColor = primaryColor;
        MTColor *color = [(MTColor *)[%c(MTColor) colorWithCGColor:primaryColor] colorWithAlphaComponent:0.5f];
        CAColorMatrix colorMatrix = [color sourceOverColorMatrix];
        [layer _mt_setColorMatrix:colorMatrix withName:@"opacityColorMatrix" filterOrder:@[@"luminanceMap"] removingIfIdentity:NO];
    });
}

- (id)initWithRecipe:(long long)arg1 {
    MRMediaRemoteRegisterForNowPlayingNotifications(backgroundQueue());
    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(updateBorderColor) 
        name:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDidChangeNotification 
        object:nil];
    return %orig;
}

- (void)didMoveToWindow {
    %orig;
    PLPlatterView *platterView = MSHookIvar<PLPlatterView *>(self, "_platterView");
    MTMaterialView *materialView = [platterView backgroundView];
    materialView.layer.masksToBounds = YES;
    materialView.layer.borderWidth = 2.0f;
    [self updateBorderColor];
}
%end