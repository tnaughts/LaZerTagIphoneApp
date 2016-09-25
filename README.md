# LaZerTagIphoneApp
Play Lazer tag on your Ios device
Add the OpenCV library within the same directory as the workspace inorder to play.

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

#Detection Algorithm

![img_proc_gif](add link here)
1. Grayscale 
2. Threshold
3. Detect edges
4. Make rectangles from contours
5. Eliminate small and non-square rectangles
6. Pair remaining rectangles and check that their centers are close, their areas are in a reasonable ratio for desired targets, and one is contained entirely inside the other
7. Check surronding pixels of inner rectangle of matched pairs for black to veryify target
8. Check corners of outer rectangle to determine which target was hit

NOTE: The application has not been set up with a Socket and hits the server every 2 seconds to dynamically update the score. This may impact cellular data usage.
