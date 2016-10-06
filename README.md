# LaZerTag

> **Lazer** is a native iOS app, which allows users to play Lazer Tag using mobile devices.  The app detects the presence or absence of appropriate targets (designed for use with the game) in the center of the camera field, and if a target is found, analyzes it to see which player or team is hit.

## Capabilities

>As of version **0.4**
- Targets are reliably detected in a variety of lighting conditions at distances of up to 50'. 
- Targets can easily be printed in black and white on a home printer. 
- Targets can be small enough to attach to the back of an iPhone
- Targets can be analyzed to differentiate between two players or teams. 

## Basic Methodology

>Image processing is carried out on the mobile device itself, using functions from the [OpenCV library](opencv.org) and an image captured from the rear facing camera. Images go through the followinig steps in order to locate and recognize targets.

1. Crop image to area around targeting reticule (this enforces aiming constraints and also reduces processing time) - this step is not shown in the sample GIF.
2. Greyscale, then threshold the image to black and white based on average luminosity (to account for different lighting conditions)
3. Detect contours (black/white transitions)
4. Draw bounding boxes around all contours
5. Remove contours whose bounding boxes are too small to contain a valid target
6. Remove contours whose height/width ratio is too skewed to contain a valid target
7. Remove all contours which are not contained by (or which do not contain) another contour
8. Remove all contour pairings whose smaller/larger contour ratio is too skewed to contain a valid target
9. Remove all contour pairings whose internal contour is not well centered (not shown in GIF)
10. test area around inner contour to ensure that it is black (all valid targets conform to this pattern) and remove pairings which are not
11. test area in corners of the outer contour to detemine whether they are black or white - the pattern of black and white in the corners is used to differentiate between targets (Not shown in GIF)

## Next Steps

A number of iterative improvements and added features are planned:
### Iterative improvements:
- Targets can currently be coded for 4 players/teams, but implementation is waiting on improved reliability
- Rotation of targets can be corrected for based on ratio of the area of the natural contour and the area of the bounding box, this will permit higher reliability in corner data detection
- Increased numbers of valid targets will permit a cool-down period to be enforced after a player is hit
- implementation of hidden push notifications will permit similar performance with less data use over current polling method.
### Additional features
- Additional player recognition data can be used for other game modes, such as capture-the-flag
- on the fly modifications to the target recognition algorihm will enable different weapon modes, for example:
  - increased accuracy (increased crop range around targeting reticule)
  - reduced range (threshold for "too small" contours made more strict
  - scattershot (return multiple hits if different codes are found in the same image)
- hit location tracking (different codes for front, back, etc. on each player)







#Menu Screen
2 options:
Play Game - Enters a current game of red vs black 


Reset Game - Hits the Rails Server via Alamofire and resets both Red and Black teams to 0
![menuscreen](https://cloud.githubusercontent.com/assets/17557735/18802124/a05592c0-81ac-11e6-9e3b-c2210410cf53.PNG)

#Once in the Game:

![ingame](https://cloud.githubusercontent.com/assets/17557735/18802151/c24c4e28-81ac-11e6-94af-4b00a691a9b0.PNG)

Lazer Fuel- Shows how many shots you have left before refueling, simply shake the phone to refuel(Yeah, thats how lazer fuel works)

Red Team Score - Shows how many times a Black team member target has been hit

Black Team Score - Shows How many Times a Red Team member has been hit

Once 20 points have been scored by a team a portal Home button appears along with a "{winning team name} Wins" banner. Home button sends you back to the menu screen

#Shooting a Lazer

Here is what the camera captures, the black and white target is nested within the blue (X)

![gameshot](https://cloud.githubusercontent.com/assets/17557735/18802153/c46f0c18-81ac-11e6-9a3c-e4fea174de88.JPG)

This image is then sent to the CV algorithim which detects if there was an image and which team that image belongs to

![cvvision](https://cloud.githubusercontent.com/assets/17557735/18802154/c65f58e8-81ac-11e6-9e2d-08fa85d7c8aa.JPG)

It then registers that as a hit for the appropriate team on the iphone and then sends a Request to the server to update the score.

NOTE: The application has not been set up with a Socket and hits the server every 2 seconds to dynamically update the score. This may impact cellular data usage.
