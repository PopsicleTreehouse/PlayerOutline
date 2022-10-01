#import <MediaRemote/MediaRemote.h>

struct CAColorMatrix {
    float m11, m12, m13, m14, m15;
    float m21, m22, m23, m24, m25;
    float m31, m32, m33, m34, m35;
    float m41, m42, m43, m44, m45;
};

@interface CSAdjunctItemView : UIView
- (void)updateBorderColor;
@end
@interface MTMaterialLayer : CALayer
-(void)_mt_setColorMatrix:(CAColorMatrix)arg1 withName:(id)arg2 filterOrder:(id)arg3 removingIfIdentity:(BOOL)arg4;
@end
@interface MTMaterialView : UIView
@property (nonatomic, strong) MTMaterialLayer *materialLayer;
@property (nonatomic, assign) BOOL blurEnabled;
@end
@interface PLPlatterView : UIView
@property (nonatomic, strong) MTMaterialView *backgroundView;
@end
@interface MTColor : NSObject
+ (MTColor *)colorWithCGColor:(CGColorRef)arg1;
- (MTColor *)colorWithAlphaComponent:(double)arg1;
- (CAColorMatrix)sourceOverColorMatrix;
@end