    //
    //  boringNotch-Bridging-Header.h
    //  boringNotch
    //
    //  Created by Harsh Vardhan  Goswami  on 11/08/24.
    //
#import <Foundation/Foundation.h>
#import "BrightnessControl.h"
#import "KeyboardManager.h"
#import <CoreGraphics/CoreGraphics.h>

extern void DisplayServicesBrightnessChanged(CGDirectDisplayID display, double brightness);
extern int DisplayServicesGetBrightness(CGDirectDisplayID display, float *brightness);
extern int DisplayServicesSetBrightness(CGDirectDisplayID display, float brightness);
extern int DisplayServicesGetLinearBrightness(CGDirectDisplayID display, float *brightness);
extern int DisplayServicesSetLinearBrightness(CGDirectDisplayID display, float brightness);

extern void CGSServiceForDisplayNumber(CGDirectDisplayID display, io_service_t* service);
