//
//  OpenCVWrapper.m
//  OpenCVProject
//
//  Created by Apprentice on 9/4/16.
//  Copyright © 2016 Apprentice. All rights reserved.
//


//inclusions
#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/highgui/ios.h>
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/calib3d/calib3d.hpp"
#include "opencv2/imgproc/imgproc_c.h"
#include <stdio.h>
#include <iostream>
#include "opencv2/core/core.hpp"
#include "opencv2/features2d/features2d.hpp"
#include "opencv2/nonfree/features2d.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/nonfree/nonfree.hpp"
#include "opencv2/objdetect/objdetect.hpp"
#include "opencv2/legacy/legacy.hpp"
#include "opencv2/legacy/compat.hpp"
#include <vector>

//namespaces
using namespace cv;
using namespace std;

//variables for controlling selectivity functions - once tweaks are made these can be placed locally within the necessary methods.

int minHessian = 500; //how interesting do points have to be to be considered features?
int crossLooking = 1; // are we matching features in both directions, as opposed to just one way? 1/0 = T/F
int knnNumber = 2; //range in which to look for nearest neighbor during feature matching
double cannyThresholdLower = 100; //this is irrelevant because of the previous thresholding
double cannyThresholdUpper = 255.0; //the maximum counterpart of the above


//ones we are using
cv::Size gaussianBlurSize = cv::Size(3.0, 3.0); //area of the 'brush' used for blurring
double gaussianBlurSigmaX = 5.0; //intensity of the 'brush' used for blurring
double thresholdLevel = 60; //luminosity threshold which we make pixels white if >, black if <.
RNG rng(12345);//rand(1-5)?  I'm not honestly sure
double boxFlexibility = 1.25; //this is the percent of deviation from square which we permit a rectangle to be.
double centeringCoefficient = 0.95; //the amound of deviation from perfect centering we will accept, as a % of small box size.
int minimumAcceptableArea = 35; //the smallest are we will consider when evaluating boxes
double cornerBoxRatio = 0.19; // the height/width of the corner box as a % of the larger box
double cornerBoxOffset = 0.85; // the offset of the top let corner of the corner box from center of the large box, as a % of large box width or height
int minBlackForDonut = 50;  // the bounding regions must have this % of black pixels
int minBlackForDatum = 50; // the data squares in the corners must have this % balck pixels to count as black
int boxRatioLowerBound = 4; // the larger box must be at leat this many times larger than small
int boxRatioUpperBound = 40; // the larger box area cannot be more than this many times the area of the small box
int luminosityPrecision = 20; // search every Xth pixel for luminosity... smaller = more accurate but slower.

//counters for checking filter functionality
int badRatio = 0;
int badCentering = 0;
int goodRatio = 0;
int goodCentering = 0;
int goodNesting = 0;
int badNesting = 0;
int goodBounding = 0;
int badBounding = 0;


@implementation OpenCVWrapper

cv::Mat testOutput;

//helpermethods

//get average luminosity
+(double)getLuminosity:(cv::Mat)image{
    int totalLuminosity = 0;
    int i = 0;
    int j = 0;
    for (i = 0; i < image.rows; i += luminosityPrecision){
        for (j = 0; j < image.cols; j +=luminosityPrecision){
            
            int lumins = Scalar(image.at<uchar>(i,j))[0];
            //printf("I am adding %d to luminosity", lumins);
            totalLuminosity += lumins;
        }
    }
    double averageLuminosity = totalLuminosity/((i/luminosityPrecision)*(j/luminosityPrecision));
    printf("I think the average luminosity is %f\n", averageLuminosity);
    return averageLuminosity;
}

//get the angle of rotation (clockwise) based on the bounding box and the original contour
+(double)getAngleOfRotation:(vector<cv::Point>)contour withinBox:(cv::Rect)box{
    double boxArea = box.width * box.height;
    double contourArea = cv::contourArea(contour);
    double triangleArea = (boxArea-contourArea)/4;
    double contoursSideLength = sqrt(contourArea);
    double boxSideLength = sqrt(boxArea);
    double sideALength;
    double sideBLength = boxSideLength - sideALength;
    //based on pythagorean theoroem....
    // c^2 = b^2 + (s-b)^2 so c^2 = 2b^2 + s^2 - 2sb.
    // given that c and b are known, we can reduce this to b2 - sb = number.
    
    
    
    return 0.0;
}

//checking for black or white corners within the larger bounding box

+(int)checkCodeForBlackCorners:(cv::Rect)box inImage:(cv::Mat)image
{
    int blackCornersFound = 0;
    cv::Rect topLeftBox = cv::Rect( box.x + (box.width * (1 - cornerBoxOffset)), box.y + (box.height * (1 - cornerBoxOffset)), box.width * cornerBoxRatio, box.height * cornerBoxRatio);
    cv::Rect topRightBox = cv::Rect( box.x + box.width - (box.width * (1 - cornerBoxOffset)) - box.width * cornerBoxRatio, box.y + (box.height * (1 - cornerBoxOffset)), box.width * cornerBoxRatio, box.height * cornerBoxRatio);
    cv::Rect bottomRightBox = cv::Rect(box.x + box.width - (box.width * (1 - cornerBoxOffset)) - box.width * cornerBoxRatio, box.y + box.height - (box.height * (1 - cornerBoxOffset)) - box.height * cornerBoxRatio, box.width * cornerBoxRatio, box.height * cornerBoxRatio);
    cv::Rect bottomLeftBox = cv::Rect( box.x + (box.width * (1 - cornerBoxOffset)), box.y + box.height - (box.height * (1 - cornerBoxOffset)) - box.height * cornerBoxRatio, box.width * cornerBoxRatio, box.height * cornerBoxRatio);
    
    cvtColor(image, testOutput, CV_GRAY2BGR);
    
    Scalar color = Scalar(255,0,0);
    rectangle(testOutput, topLeftBox, color, 2);
    rectangle(testOutput, topRightBox, color, 2);
    rectangle(testOutput, bottomLeftBox, color, 2);
    rectangle(testOutput, bottomRightBox, color, 2);
    
    bool tlBlack = [self checkBoxForBlackPixels:topLeftBox inDirection:"Top Left Datum" inImage:&image minBlackThreshold:minBlackForDatum];
    bool trBlack = [self checkBoxForBlackPixels:topRightBox inDirection:"Top Right Datum" inImage:&image minBlackThreshold:minBlackForDatum];
    bool brBlack = [self checkBoxForBlackPixels:bottomRightBox inDirection:"Bottom Right Datum" inImage:&image minBlackThreshold:minBlackForDatum];
    bool blBlack = [self checkBoxForBlackPixels:bottomLeftBox inDirection:"Bottom Left Datum" inImage:&image minBlackThreshold:minBlackForDatum];
    
    
    
    if (tlBlack == true)
    {
        blackCornersFound++;
        
    }
    if (trBlack == true)
    {
        blackCornersFound++;
        
    }
    if (blBlack == true)
    {
        blackCornersFound++;
        
    }
    if (brBlack == true)
    {
        blackCornersFound++;
    }
    
    //    String player;
    //    if (blackCornersFound == 2){
    //        if ((trBlack && tlBlack) || (trBlack && brBlack) || (tlBlack && blBlack) || (brBlack && blBlack) )
    //        {
    //            player = "Player 1";
    //        }
    //        else
    //        {
    //            player = "Player 2";
    //        }
    //
    //    }
    //    else if (blackCornersFound == 0)
    //    {
    //        player = "Player 3";
    //    }
    //    else if (blackCornersFound == 4)
    //    {
    //        player = "Player 4";
    //    }
    //    else {
    //        player = "an unknown player";
    //    }
    
    
    //    printf("***************I think I just hit %s\n", player.c_str());
    printf("found %d black corners\n", blackCornersFound);
    if (blackCornersFound > 2)
    {
        return 1; // meaning team 1
    }
    return 2; //meaning team 2
}


//checking for black pixels near the boxes

+(bool)checkBoxForBlackPixels:(cv::Rect)box inDirection:(String)direction inImage:(cv::Mat*)image minBlackThreshold:(int)minBlackThreshold{
    
    int height = box.height;
    int width = box.width;
    //printf("I am checking for black pixels in the %s direction\n", direction.c_str());
    
    int blackCount = 0;
    int whiteCount = 0;
    for (double i = 0; i < 10; i++){
        for(double j = 0; j < 10; j++){
            if (Scalar(image->at<uchar>(box.y + (i/10 * height), box.x + i/10 * width))[0] == 0)
            {
                blackCount++;
            }
            else
            {
                whiteCount++;
            }
        }
    }
    //printf("   to the %s we found %d black and %d white\n", direction.c_str(), blackCount, whiteCount);
    if (blackCount > minBlackThreshold){
        return true;
    }
    return false;
}

//check to see if a box is orthogonally bounded by black.

+(bool)checkBlackBounding:(cv::Rect)box inImage:(cv::Mat*)image{
    vector<bool> directions = {};
    int blackBoxesFound = 0;
    //previously we were precomputing width and height based on the average of box properties... but it makes more sense to allow skewed boxes to skew their rerenences!  This will make it easier to see affine transformed data.
    
    //make boxes to check exterior
    cv::Rect rightBox = cv::Rect(box.x + box.width, box.y, box.width * 0.5, box.height);
    cv::Rect leftBox = cv::Rect(box.x - box.width *0.5, box.y, box.width * 0.5, box.height);
    cv::Rect upBox = cv::Rect(box.x, box.y - box.height * 0.5, box.width, box.height * 0.5);
    cv::Rect downBox = cv::Rect(box.x, box.y + box.height, box.width, box.height * 0.5);
    
    testOutput = *image;
    cvtColor(*image, testOutput, CV_GRAY2BGR);
    
    Scalar color = Scalar(255,0,0);
    rectangle(testOutput, rightBox, color, 3);
    rectangle(testOutput, leftBox, color, 3);
    rectangle(testOutput, upBox, color, 3);
    rectangle(testOutput, downBox, color, 3);
    bool rightCheck = [self checkBoxForBlackPixels:rightBox inDirection:"Right" inImage:image minBlackThreshold:minBlackForDonut];
    if (rightCheck == true)
    {
        directions.push_back(true);
        blackBoxesFound++;
    }
    else
    {
        directions.push_back(false);
    }
    bool leftCheck = [self checkBoxForBlackPixels:leftBox inDirection:"Left" inImage:image minBlackThreshold:minBlackForDonut];
    if (leftCheck == true)
    {
        directions.push_back(true);
        blackBoxesFound++;
    }
    else
    {
        directions.push_back(false);
    }
    bool upCheck = [self checkBoxForBlackPixels:upBox inDirection:"Up" inImage:image minBlackThreshold:minBlackForDonut];
    if (upCheck == true)
    {
        directions.push_back(true);
        blackBoxesFound++;
    }
    else
    {
        directions.push_back(false);
    }
    bool downCheck = [self checkBoxForBlackPixels:downBox inDirection:"Down" inImage:image minBlackThreshold:minBlackForDonut];
    if (downCheck == true)
    {
        directions.push_back(true);
        blackBoxesFound++;
    }
    else
    {
        directions.push_back(false);
    }
    
    if (blackBoxesFound == 4){
        printf(" I am returning true on bounding with blackBoxesFound = %d\n", blackBoxesFound);
        //        printf("Right is returning as %d\n", directions[0]);
        //        printf("Left is returning as %d\n", directions[1]);
        //        printf("Up is returning as %d\n", directions[2]);
        //        printf("Down is returning as %d\n", directions[3]);
        goodBounding++;
        return true;
    }
    printf(" I am returning false on bounding with blackBoxesFound = %d\n", blackBoxesFound);
    //    printf("Right is returning as %d\n", directions[0]);
    //    printf("Left is returning as %d\n", directions[1]);
    //    printf("Up is returning as %d\n", directions[2]);
    //    printf("Down is returning as %d\n", directions[3]);
    badBounding++;
    return false;
}




//the first helpermethod is the locatePlanarObject, which takes the keypoints and descriptors (NOTE -- this currently uses an altered naming convention all the way through, where object means image and image means scene) and finds the flann pairs for them, then uses cvHomography without much further description, and sets xzXY coords, presumably for the drawing of a box?


//work on the decalration of this nasty nasty function.
//+(int) locatePlanarObject:(const CvSeq*) objectKeypoints with:(const CvSeq *)objectDescriptors andScenePoints:(const CvSeq*) imageKeypoints asWellAs:(const CvSeq*)imageDescriptors andFinally:(const CvPoint[4])src_corners butReallyFinally:(CvPoint[4])dst_corners
//{
//    double h[9];
//    CvMat _h = cvMat(3, 3, CV_64F, h);
//    vector<int> ptpairs;
//    vector<CvPoint2D32f> pt1, pt2;
//    CvMat _pt1, _pt2;
//    int i, n;
//
//    //here we need another complex function call to a thing - damn you objective C!
//    //this one should take the original parameter names, since the params of this AND of locatePlanarObject is not changed from the tutorial.
//    [self flannFindPairs:objectKeypoints imageDescriptors:objectDescriptors somethingElse:imageKeypoints sceneDescriptors:imageDescriptors pointPairs:ptpairs];
//
//    n = (int)(ptpairs.size()/2);
//    if( n < 4 )
//        return 0;
//
//    pt1.resize(n);
//    pt2.resize(n);
//    for( i = 0; i < n; i++ )
//    {
//        pt1[i] = ((CvSURFPoint*)cvGetSeqElem(objectKeypoints,ptpairs[i*2]))->pt;
//        pt2[i] = ((CvSURFPoint*)cvGetSeqElem(imageKeypoints,ptpairs[i*2+1]))->pt;
//    }
//
//    _pt1 = cvMat(1, n, CV_32FC2, &pt1[0] );
//    _pt2 = cvMat(1, n, CV_32FC2, &pt2[0] );
//    if( !cvFindHomography( &_pt1, &_pt2, &_h, CV_RANSAC, 5 ))
//        return 0;
//
//    for( i = 0; i < 4; i++ )
//    {
//        double x = src_corners[i].x, y = src_corners[i].y;
//        double Z = 1./(h[6]*x + h[7]*y + h[8]);
//        double X = (h[0]*x + h[1]*y + h[2])*Z;
//        double Y = (h[3]*x + h[4]*y + h[5])*Z;
//        dst_corners[i] = cvPoint(cvRound(X), cvRound(Y));
//    }
//
//    return 1;
//}
//
////here is the find flann points helper method...  beware, it is a doozy!
//+(void) flannFindPairs:(const CvSeq*)something imageDescriptors:(const CvSeq*)objectDescriptors somethingElse:(const CvSeq*)somethingElse sceneDescriptors:(const CvSeq*)imageDescriptors pointPairs:(vector<int>&)ptpairs
//{
//    int length = (int)(objectDescriptors->elem_size/sizeof(float));
//
//    cv::Mat m_object(objectDescriptors->total, length, CV_32F);
//    cv::Mat m_image(imageDescriptors->total, length, CV_32F);
//
//
//    // copy descriptors
//    CvSeqReader obj_reader;
//    float* obj_ptr = m_object.ptr<float>(0);
//    cvStartReadSeq( objectDescriptors, &obj_reader );
//    for(int i = 0; i < objectDescriptors->total; i++ )
//    {
//        const float* descriptor = (const float*)obj_reader.ptr;
//        CV_NEXT_SEQ_ELEM( obj_reader.seq->elem_size, obj_reader );
//        memcpy(obj_ptr, descriptor, length*sizeof(float));
//        obj_ptr += length;
//    }
//    CvSeqReader img_reader;
//    float* img_ptr = m_image.ptr<float>(0);
//    cvStartReadSeq( imageDescriptors, &img_reader );
//    for(int i = 0; i < imageDescriptors->total; i++ )
//    {
//        const float* descriptor = (const float*)img_reader.ptr;
//        CV_NEXT_SEQ_ELEM( img_reader.seq->elem_size, img_reader );
//        memcpy(img_ptr, descriptor, length*sizeof(float));
//        img_ptr += length;
//    }
//
//    // find nearest neighbors using FLANN
//    cv::Mat m_indices(objectDescriptors->total, 2, CV_32S);
//    cv::Mat m_dists(objectDescriptors->total, 2, CV_32F);
//    cv::flann::Index flann_index(m_image, cv::flann::KDTreeIndexParams(4));  // using 4 randomized kdtrees
//    flann_index.knnSearch(m_object, m_indices, m_dists, knnNumber, cv::flann::SearchParams(64) ); // maximum number of leafs checked
//
//    int* indices_ptr = m_indices.ptr<int>(0);
//    float* dists_ptr = m_dists.ptr<float>(0);
//    for (int i=0;i<m_indices.rows;++i)
//    {
//        if (dists_ptr[2*i]<0.6*dists_ptr[2*i+1])
//        {
//            ptpairs.push_back(i);
//            ptpairs.push_back(indices_ptr[2*i]);
//        }
//    }
//}
//
//check on whether the box ratio is correct

+(bool) boxRatioCorrect:(cv::Rect)box1 largerBox:(cv::Rect)box2{
    
    int smallBoxArea = box1.height * box1.width;
    int largeBoxArea = box2.height * box2.width;
    
    double largeToSmallRatio = largeBoxArea/smallBoxArea;
    
    if ( largeToSmallRatio > boxRatioLowerBound && largeToSmallRatio < boxRatioUpperBound)
    {
        goodRatio++;
        return true;
    }
    
    printf("I rejected a pairing with ratio %d \n", (box2.height * box2.width)/(box1.height * box1.width));
    badRatio++;
    return false;
}

+(bool) boxCentersClose:(cv::Rect)box1 near:(cv::Rect)box2
{
    //define the closest relation
    vector<int> distances = {box1.width, box1.height, box2.width, box2.height};
    //there is a std::min_element(vector) function... which should work - but it's faster to write than to figure out.
    int minDistance = distances[0];
    for (int i = 1; i < 4; i++)
    {
        if (distances[i] < minDistance)
        {
            minDistance = distances[i];
        }
    }
    
    //compute the center of our boxes.
    cv::Point c1 = cv::Point(box1.x + box1.width/2, box1.y + box1.height/2);
    cv::Point c2 = cv::Point(box2.x + box2.width/2, box2.y + box2.height/2);
    
    double centroidDistance = sqrt((c1.x - c2.x)*(c1.x - c2.x) + (c1.y - c2.y) * (c1.y - c2.y));
    
    if (centroidDistance < (minDistance * centeringCoefficient))
    {
        goodCentering++;
        return true;
    }
    badCentering++;
    return false;
}

+(bool) isSquareLike:(cv::Rect)box
{
    double h = box.height;
    double w = box.width;
    double ratio;
    if ( h > w)
    {
        ratio = h/w;
    }
    else
    {
        ratio = w/h;
    }
    if (ratio < boxFlexibility)
    {
        return true;
    }
    return false;
}

+(bool) isInBox:(cv::Rect)box1 contains:(cv::Rect)box2{
    cv::Point a1 = cv::Point(box1.x, box1.y);
    cv::Point b1 = cv::Point(box1.x+box1.width, box1.y);
    //cv::Point c1 = cv::Point(box1.x + box1.width, box1.y+box1.height); //silly that we are never using this...
    cv::Point d1 = cv::Point(box1.x, box1.y + box1.height);
    
    cv::Point a2 = cv::Point(box2.x, box2.y);
    cv::Point b2 = cv::Point(box2.x+box2.width, box2.y);
    cv::Point c2 = cv::Point(box2.x + box2.width, box2.y+box2.height);
    cv::Point d2 = cv::Point(box2.x, box2.y + box2.height);
    
    if ( a2.x > a1.x && a2.x < b1.x && a2.y > a1.y && a2.y < d1.y && b2.x > a1.x && b2.x < b1.x && b2.y > a1.y && b2.y < d1.y && c2.x > a1.x && c2.x < b1.x && c2.y > a1.y && c2.y < d1.y && d2.x > a1.x && d2.x < b1.x && d2.y > a1.y && d2.y < d1.y)
    {
        goodNesting++;
        return true;
    }
    badNesting++;
    return false;
}

// header implementation


//    ---------------------------------------- MAIN IMPLEMENTATION -------------------------------------
//  ******************************************************************************************************


+(NSString *) openCVVersionString
{
    return [NSString stringWithFormat:@"OpenCV Version %s", CV_VERSION];
}

+(UIImage *) makeGrayscale:(UIImage *) image{
    
    cv::Mat imageMat;
    UIImageToMat(image, imageMat);
    
    if (imageMat.channels() == 1) return image;
    
    cv::Mat grayMat;
    cv::cvtColor(imageMat, grayMat, CV_BGR2GRAY);
    return MatToUIImage(grayMat);
    
}

//+(UIImage *) matchFeatures:(UIImage *)image thatMatch:(UIImage *)scene{
//
//    //get image to find points in, and make it MAT format
//    cv::Mat imageMat;
//    UIImageToMat([self makeGrayscale:image], imageMat);
//    cv::Mat sceneMat;
//    UIImageToMat([self makeGrayscale:scene], sceneMat);
//
//    //create the feature detector, with its thresholding variable
//    SurfFeatureDetector detector( minHessian );
//
//    //detect and store keypoints
//    std::vector<KeyPoint> keypoints, scenepoints;
//    detector.detect(imageMat, keypoints);
//    detector.detect(sceneMat, scenepoints);
//
//    //draw the keypoints - commented out for matching
////    Mat imageMatWithPoints;
////    Mat sceneMatWithPoints;
////
////    drawKeypoints( imageMat, keypoints, imageMatWithPoints, Scalar::all(-1), DrawMatchesFlags::DEFAULT );
////    drawKeypoints( sceneMat, scenepoints, sceneMatWithPoints, Scalar::all(-1), DrawMatchesFlags::DEFAULT );
//
//    //calculate descriptors rather than drawing
//    SurfDescriptorExtractor extractor;
//
//    Mat imageDescriptors, sceneDescriptors;
//
//    extractor.compute(imageMat, keypoints, imageDescriptors);
//    extractor.compute(sceneMat, scenepoints, sceneDescriptors);
//    printf("keypoints length %lu \n", keypoints.size());
//    printf("scenepoints length %lu \n", scenepoints.size());
//
//
//
//    // matching vectors with brute force matcher
//    BFMatcher matcher(NORM_L1, true);
//    std::vector<DMatch> matches;
//    matcher.match(imageDescriptors, sceneDescriptors, matches);
//
//    printf("matches found %lu", matches.size());
//
//    // draw the matches into a composite image
//    Mat combo;
//    drawMatches( imageMat, keypoints, sceneMat, scenepoints, matches, combo);
//
//    return MatToUIImage(combo);
//}
//
//+(UIImage *)matchFeaturesFLANN:(UIImage *)image thatMatch:(UIImage *)scene
//{
//    //get image to find points in, and make it MAT format
//    cv::Mat imageMat;
//    UIImageToMat([self makeGrayscale:image], imageMat);
//    cv::Mat sceneMat;
//    UIImageToMat([self makeGrayscale:scene], sceneMat);
//
//    //create the feature detector, with its thresholding variable
//    SurfFeatureDetector detector( minHessian );
//
//    //detect and store keypoints
//    std::vector<KeyPoint> keypoints, scenepoints;
//    detector.detect(imageMat, keypoints);
//    detector.detect(sceneMat, scenepoints);
//
//    //calculate descriptors rather than drawing
//    SurfDescriptorExtractor extractor;
//
//    Mat imageDescriptors, sceneDescriptors;
//
//    extractor.compute(imageMat, keypoints, imageDescriptors);
//    extractor.compute(sceneMat, scenepoints, sceneDescriptors);
//    printf("keypoints length %lu \n", keypoints.size());
//    printf("scenepoints length %lu \n", scenepoints.size());
//
//    //match descripors with a FLANN matcher
//    FlannBasedMatcher matcher;
//    std::vector< DMatch> matches;
//    matcher.match(imageDescriptors, sceneDescriptors, matches);
//
//    double max_dist = 0;
//    double min_dist = 100;
//
//    //quick calculation of max and min distance between keypoints
//    for ( int i = 0; i < imageDescriptors.rows; i++)
//    {
//        double dist = matches[i].distance;
//        if( dist < min_dist ) min_dist = dist;
//        if( dist > max_dist ) max_dist = dist;
//    }
//
//    printf("-- Max dist : %f \n", max_dist );
//    printf("-- Min dist : %f \n", min_dist );
//
//    //-- Draw only "good" matches (i.e. whose distance is less than 2*min_dist,
//    //-- or a small arbitary value ( 0.02 ) in the event that min_dist is very
//    //-- small)
//    //-- PS.- radiusMatch can also be used here.}
//
//    std::vector< DMatch > good_matches;
//
//    for( int i = 0; i < imageDescriptors.rows; i++ )
//    {
//        if( matches[i].distance <= max(2*min_dist, 0.2) )
//        {
//            good_matches.push_back( matches[i]);
//        }
//    }
//
//    //-- Draw only "good" matches
//    Mat combo;
//    drawMatches( imageMat, keypoints, sceneMat, scenepoints,
//                good_matches, combo, Scalar::all(-1), Scalar::all(-1),
//                vector<char>(), DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS );
//
//    //print out lots of matches
//    for( int i = 0; i < (int)good_matches.size(); i++ )
//    { printf( "-- Good Match [%d] Keypoint 1: %d  -- Keypoint 2: %d  \n", i, good_matches[i].queryIdx, good_matches[i].trainIdx ); }
//
//    return MatToUIImage(combo);
//
//
//}
//
//+(bool) complexMatchFeaturesFLANN:(UIImage *) image thatMatch:(UIImage *) scene
//{
//    //run the stuff from main
//
//
//    //bring in 2 pictures
//    //get image to find points in, and make it MAT format
//    cv::Mat imageMat;
//    UIImageToMat([self makeGrayscale:image], imageMat);
//    cv::Mat sceneMat;
//    UIImageToMat([self makeGrayscale:scene], sceneMat);
//
//    //what is memstorage for?
//    CvMemStorage* storage = cvCreateMemStorage(0);
//
//    //set up a scalar for evlauting colors... or for drawing the lines??  it all comes out in grayscale either way
//    static CvScalar colors[] =
//    {
//        {{0,0,255}},
//        {{0,128,255}},
//        {{0,255,255}},
//        {{0,255,0}},
//        {{255,128,0}},
//        {{255,255,0}},
//        {{255,0,0}},
//        {{255,0,255}},
//        {{255,255,255}}
//    };
//
//    //creating an image to put colors on image
//    IplImage imageIplColor;
//    cv::Size s = imageMat.size();
//    imageIplColor = *cvCreateImage(s, 8, 3);
//
//    //here we seem to be setting our keypoints and descriptors up using a rather different method
//    CvSeq* imageKeypoints = 0, *imageDescriptors = 0;
//    CvSeq* sceneKeypoints = 0, *sceneDescriptors = 0;
//
//    int i;
//
//    //and we declare some params for surf (which i think is minhessian and bothways-matching?)
//    CvSURFParams params = cvSURFParams(minHessian,crossLooking);
//
//    //this is setting up a timer!
//    double tt = (double)cvGetTickCount();
//
//
//    //we are not matching the source code here, in that we added a & before imagemat, in order to have it register as a CvArr (or similar) in order to compile, this may or may not be a disaster.
//    //and it appears that it needs to actually be the correct type of cvarr - an Iplimage...
//    IplImage iplImage = imageMat;
//    cvExtractSURF( &iplImage, 0, &imageKeypoints, &imageDescriptors, storage, params);
//    printf("Image Descriptors: %d\n", imageDescriptors->total);
//
//    IplImage iplScene = sceneMat;
//    cvExtractSURF( &iplScene, 0, &sceneKeypoints, &sceneDescriptors, storage, params);
//    printf("Scene Descriptors: %d\n", sceneDescriptors->total);
//
//    //and outputting the time.  Huzzah!
//    double tn = (double)cvGetTickCount();
//    printf( "Extraction time = %gms\n", tn/(cvGetTickFrequency()*1000.)-tt/(cvGetTickFrequency()*1000.));
//
//    //now lets combine them into one image
//    CvPoint src_corners[4] = {{0,0}, {imageMat.rows,0}, {imageMat.rows, imageMat.cols}, {0, imageMat.cols}};
//    CvPoint dst_corners[4];
//
//    //creates an IplImage combo which is the correct size
//    IplImage* combo = cvCreateImage( cvSize(sceneMat.cols, imageMat.rows+sceneMat.rows), 8, 1 );
//    //sets...seomthing?
//    cvSetImageROI(combo, cvRect(0,0,imageMat.cols, imageMat.rows ) );
//    //draws the iplImage (ipl version of imageMat... onto combo)
//    //note that this seems to work just fine!
//    cvCopy( &iplImage, combo );
//    //translating the next draw-function doesn't seem to be as effective... but why?  got it to work eventually
//    cvSetImageROI(combo, cvRect( 0, imageMat.rows, combo->width, combo->height ) );
//    cvCopy( &iplScene, combo );
//
//
//    cvResetImageROI(combo);
//
//    printf("Using approximate nearest neighbor detection");
//
//    //set up a shadowMAT which will also receive the lines!
//    //does not work as of 9/5/16
//    //cv::Mat contourBox = Mat::zeros(cv::Size(2*(combo->height), 2*(combo->width)), CV_8UC1);
//
//
//    //call the local planar object function
//    if( [self locatePlanarObject:imageKeypoints with:imageDescriptors andScenePoints:sceneKeypoints asWellAs:sceneDescriptors andFinally:src_corners butReallyFinally:dst_corners ] )
//    {
//        //set up a shadowMAT which will also receive the lines!
//        for( i = 0; i < 4; i++ )
//        {
//            CvPoint r1 = dst_corners[i%4];
//            CvPoint r2 = dst_corners[(i+1)%4];
//            cvLine( combo, cvPoint(r1.x, r1.y+imageMat.rows ), cvPoint(r2.x, r2.y+imageMat.rows ), colors[8] );
//            //does not work as of 9/5
//            //cvLine( contourBox, cvPoint(r1.x, r1.y+imageMat.rows ), cvPoint(r2.x, r2.y+imageMat.rows ), colors[8] );
//            //here is where it is drawing the lines... can we just take the contour from here?!
//        }
//        //get contour based on these lines?
//    }
//    vector<int> ptpairs;
//
//
//    //call the find flann pairs function
//    [self flannFindPairs:imageKeypoints imageDescriptors:imageDescriptors somethingElse:sceneKeypoints sceneDescriptors:sceneDescriptors pointPairs:ptpairs];
//
//    //this was the origian function call - note that in addition to being objectified
//    //flannFindPairs( objectKeypoints, objectDescriptors, imageKeypoints, imageDescriptors, ptpairs );
//    vector< vector<int> > foundScenePoints;
//    for( i = 0; i < (int)ptpairs.size(); i += 2 )
//    {
//        CvSURFPoint* r1 = (CvSURFPoint*)cvGetSeqElem( imageKeypoints, ptpairs[i] );
//        CvSURFPoint* r2 = (CvSURFPoint*)cvGetSeqElem( sceneKeypoints, ptpairs[i+1] );
//        //im pulling the matched scenepoints out here, since they are well defined
//
//        vector<int> row;
//        row.push_back(r2->pt.x);
//        row.push_back(r2->pt.y);
//        foundScenePoints.push_back(row);
//
//        cvLine( combo, cvPointFrom32f(r1->pt),
//               cvPoint(cvRound(r2->pt.x), cvRound(r2->pt.y+imageMat.rows)), colors[8] );
//    }
//
//    //cvShowImage( "Object Correspond", combo );
//    printf("\nmatches found = %lu\n", ptpairs.size()/2);
//    for( i = 0; i < imageKeypoints->total; i++ )
//    {
//        CvSURFPoint* r = (CvSURFPoint*)cvGetSeqElem( imageKeypoints, i );
//        CvPoint center;
//        int radius;
//        center.x = cvRound(r->pt.x);
//        center.y = cvRound(r->pt.y);
//        radius = cvRound(r->size*1.2/9.*2);
//        cvCircle( &imageIplColor, center, radius,colors[0], 1, 8, 0 );
//    }
//
//    // I quietly expect errors here with the cvCircle an Mat assignment operators because of challenges during the inital assignment to an Ipl image...
//    //that assignment could be fixed, but its probably also worth saving the cycle time by figuing out how to use a Mat image all the way through.
//
//    //I was correct, and the errors are fixed below, but not optimized.  I probably dont need ipl images at all
//    cv::Mat finalImage = combo;
//
//
//    //find the vertices of our bounding box
//    vector<Point2f> vert(5);
//    for ( i = 0; i < 4; i++)
//    {
//        printf("bounding point %d has x %d and y %d\n", i, dst_corners[i].x, dst_corners[i].y);
//        //these do not appear to be rotationally identical!
//        //but I none of the basic rotations seem to work better, just one gives a 0.
//        //now trying it reversed... and rotating
//
//        //I think this is the real answer!  why, I'm not sure
//        //aggravatingly, this seems to change the needed order with each
//        vert[i] = dst_corners[(5-i)%4];
//    }
//    vert[4] = vert[0];
//
//    //just changed this in order to see if the box fits better - answer, seems to make no difference?!
//    //correct - the src we draw on just needs to be large enough that things dont go off the sides.
//
//    cv::Mat src = Mat::zeros(cv::Size(2*(combo->height), 2*(combo->width)), CV_8UC1);
//
//    //turn our bounding box into a contour
//
//    for ( int j = 0; j < 4; j++)
//    {
//        line( src, vert[j], vert[(j+1)%6], Scalar (255), 3, 8 );
//        printf("%d", (j+1)%4);
//        printf("I just drew a line from x %f y %f to destination x %f y %f\n", vert[j].x, vert[j].y, vert[j+1].x, vert [j+1].y);
//    }
//    vector<vector<cv::Point> > contours; vector<Vec4i> hierarchy;
//    findContours(src, contours, hierarchy, RETR_TREE, CHAIN_APPROX_SIMPLE);
//        //a closer examination of our countour might be really quite helpful here.
//
//    //test points using the pointpolygon test
//    int boundScenePoints = 0;
//    int isIn;
//    for (int k = 0; k < foundScenePoints.size(); k++)
//    {
//        isIn = 0;
//        isIn = pointPolygonTest(contours[0], Point2f(foundScenePoints[k][0], foundScenePoints[k][1]), false);
//        if (isIn >= 0)
//        {
//            printf("found point %d in box at x %d y %d\n", k, foundScenePoints[k][0], foundScenePoints[k][1]);
//            boundScenePoints++;
//        }
//        else
//        {
//            printf("did not find point %d in box at x %d y %d\n", k, foundScenePoints[k][0], foundScenePoints[k][1]);
//        }
//    }
//
//    //spit out the number of points in box
//    printf("found %d out of %lu within the bounding box\n", boundScenePoints, foundScenePoints.size());
//    printf("the size of the foundScenePoints array is %lu\n", foundScenePoints.size());
//
//    //test to find out the points in foundScenePoints
////    for(int l = 0; l < foundScenePoints.size(); l++){
////        printf("sugggested point %d has x %d and y %d\n", l, foundScenePoints[l][0], foundScenePoints[l][1]);
////    }
//
//    //test to find out
//    double foundCheck = foundScenePoints.size();
//    double ratioCheck = boundScenePoints;
//
//    if(foundCheck > 15 && ratioCheck/foundCheck > 0.4)
//    {
//        printf("\n\nI think this is a hit\n");
//        return true;
//    }
//    else
//    {
//        printf("\n\n I think this is a miss\n");
//        return false;
//    }
//    //lets look at the contour we are making...
//       // return MatToUIImage(src);
//
//}

+(int) codeFinder:(UIImage *) image{
    
    //reset counters for multitests
    badRatio = 0;
    badCentering = 0;
    goodRatio = 0;
    goodCentering = 0;
    goodNesting = 0;
    badNesting = 0;
    goodBounding = 0;
    badBounding = 0;
    
    
    cv::Mat rawImageMat;
    UIImageToMat([self makeGrayscale:image], rawImageMat);
    
    //this imageMat is the cropped version
    double w = rawImageMat.cols / 3.0;
    double h = rawImageMat.rows / 3.0;
    printf("width is %f\n", w);
    printf("height is %f\n", h);
    
    cv::Rect targetRegion(w, h, w, h);
    
    printf("target region width = %d\n", targetRegion.width);
    
    cv::Mat imageMat = (rawImageMat(targetRegion));
    
    printf("target region height = %d\n", targetRegion.height);
    
    //get total image size for later
    //int totalPixelArea = imageMat.rows * imageMat.cols;
    
    //create a mat to hold the gaussblurred image
    cv::Mat blurredImageMat;
    GaussianBlur(imageMat, blurredImageMat, gaussianBlurSize, gaussianBlurSigmaX);
    
    
    //create a mat to hold the thresholded image (This may want to use adaptive threshold at some point
    cv::Mat thresholdedImageMat;
    double averageLuminosity = [self getLuminosity:blurredImageMat];
    
    threshold(blurredImageMat, thresholdedImageMat, averageLuminosity, 255, THRESH_BINARY);
    
    //adaptiveThreshold is excellent, but far too slow
    //adaptiveThreshold(blurredImageMat, thresholdedImageMat, 255, ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY, 20, 0);
    
    //a new mat for the canny edge detection to work on
    cv::Mat cannyImageMat;
    Canny(thresholdedImageMat , cannyImageMat , cannyThresholdLower, cannyThresholdUpper);
    
    
    //now we want to get the countours a a flat list (CV_RETR_LIST) and simplified (CV_CHAIN_APPROX_SIMPLE... both of which are the defaults!
    
    //first create an array of arrays of points to store the contours
    vector<vector <cv::Point> > contours;
    //and a special vector array for the heirarchy
    vector<Vec4i> hierarchy;
    
    findContours(cannyImageMat, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    
    //draw the countours to yet another new mat
    cv::Mat contourImageMat = Mat::zeros(cannyImageMat.size(), CV_8UC3);
    for (int i = 0; i < contours.size(); i++ )
    {
        Scalar color = Scalar( rng.uniform(0, 255), rng.uniform(0,255), rng.uniform(0,255) );
        drawContours( contourImageMat, contours, i, color, 2, 8, hierarchy, 0, cv::Point() );
    }
    
    //in ruby we are adding color onto our Mat here, because we didn't creat new ones... this is skipped, but might be a place to look for errors.
    printf("I found %lu contours\n", contours.size());
    
    //add boxlike boxes to our box box.
    vector<cv::Rect> boxes;
    vector<vector <cv::Point> > chosenContours;
    
    for (int j = 0; j < contours.size(); j++)
    {
        cv::Rect box = boundingRect(contours[j]);
        if ([self isSquareLike:box] && box.width*box.height > minimumAcceptableArea){
            boxes.push_back(box);
            chosenContours.push_back(contours[j]);
        }
    }
    
    printf("I found %lu valid looking boxes \n", boxes.size());
    
    //get the boxes properly related to one another
    
    //right now this relational boxing uses 3 tests - is the box bigger, are the boxes well cenetered, and are they in the proper ratio.  This should also force the smaller box to be full included with the current parameters, and I suspect that's the most expensive test?  even so, I'll code in the full inlcusion test, we can ORDER these in order to do the most expensive filtering last!
    
    vector<vector< cv::Rect > > boxPairs;
    
    for (int k = 0; k < boxes.size(); k++)
    {
        for (int l = 0; l < boxes.size(); l++)
        {
            if (boxes[k].width > boxes[l].width && [self boxCentersClose:boxes[k] near:boxes[l]] && [self isInBox:boxes[k] contains:boxes[l]] && [self boxRatioCorrect:boxes[l]  largerBox:boxes[k]] && [self checkBlackBounding:boxes[l] inImage:&thresholdedImageMat])
            {
                printf("I am adding a boxPair\n");
                int cornerTest = [self checkCodeForBlackCorners:boxes[k] inImage:thresholdedImageMat];
                printf("I found %d black corners in this new box\n", cornerTest);
                vector<cv::Rect> boxPair = {boxes[k], boxes[l]};
                boxPairs.push_back(boxPair);
            }
        }
    }
    
    printf("\n I rejected %d pairings based on centering", badCentering);
    //printf("\n I approved %d pairings based on centering", goodCentering);
    printf("\n I rejected %d out of %d pairings based on nesting", badNesting, goodCentering);
    //printf("\n I approved %d pairings based on nesting", goodNesting);
    printf("\n I rejected %d out of %d pairings based on ratio", badRatio, goodNesting);
    //printf("\n I approved %d pairings based on ratio", goodRatio);
    //printf("\n I approved %d pairings based on bounding", goodBounding);
    printf("\n I rejected %d out of %d pairings based on bounding", badBounding, goodRatio);
    
    printf("\n I found %lu valid looking box pairs \n", boxPairs.size());
    
    //draw the countours to yet another new mat
    //cv::Mat newContourImageMat = Mat::zeros(cannyImageMat.size(), CV_8UC3);
    //    for (int i = 0; i < boxPairs.size(); i++ )
    //    {
    
    //    cv::Mat colorizedMat;
    //    cvtColor(thresholdedImageMat, colorizedMat, CV_GRAY2BGR);
    //
    //    for (int i = 0; i < boxes.size(); i++)
    //    {
    //        Scalar color = Scalar(255,0,0);
    //        rectangle(colorizedMat, boxes[i], color);
    //    }
    //    for (int i = 0; i < boxPairs.size(); i++){
    //        
    //    Scalar color = Scalar(255,0,0);
    //    rectangle(colorizedMat, boxPairs[i][0], color, 2);
    //    
    //    Scalar color2 = Scalar(0,255,0);
    //    rectangle(colorizedMat, boxPairs[i][1], color2, 2);
    //
    //    }
    //
    cv::Mat testingImage;
    cvtColor(thresholdedImageMat, testingImage, CV_GRAY2BGR);
    Scalar testColor;
    
    for (int q = 0; q < boxPairs.size(); q++){
        if(q == 0){
            testColor = Scalar(0,255,0);
        }
        else{
            testColor = Scalar(255,0,0);
        }
        rectangle(testingImage, boxPairs[q][0], testColor, 2);
        rectangle(testingImage, boxPairs[q][1], testColor, 2);
    }
    
    UIImageWriteToSavedPhotosAlbum(MatToUIImage(testingImage), nil, nil, nil);
    
    if (boxPairs.size() > 0)
    {
        printf("true");
        int teamHit = [self checkCodeForBlackCorners:boxPairs[0][0] inImage:thresholdedImageMat];
        printf(" team hit = %d", teamHit);
        return teamHit;
    }
    printf("false");
    return 0;
}

@end