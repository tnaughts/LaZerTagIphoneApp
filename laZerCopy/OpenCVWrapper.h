//
//  OpenCVWrapper.h
//  OpenCVProject
//
//  Created by Apprentice on 9/4/16.
//  Copyright © 2016 Apprentice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

+(NSString *) openCVVersionString;
+(UIImage *) makeGrayscale:(UIImage *) image;
//+(UIImage *) matchFeatures:(UIImage *) image thatMatch:(UIImage *) scene;
//+(UIImage *) matchFeaturesFLANN:(UIImage *) image thatMatch:(UIImage *) scene;
//+(bool) complexMatchFeaturesFLANN:(UIImage *) image thatMatch:(UIImage *) scene;
+(int) codeFinder:(UIImage *) image;
@end
