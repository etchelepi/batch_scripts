@echo off
setlocal ENABLEDELAYEDEXPANSION
REM ###########################################################################
REM # This is a simple script to take a directory of jpegs and convert them in
REM # to a video file of reasonable quality.
REM ###########################################################################


REM ###########################################################################
REM #There are the user defined values. This should be turned into command line
REM #Arguments. But right now they don't so just update here
set output_width=3840
set output_height=2160
REM how long should each frame be held in frames
set frame_duration=1
REM how many frames per second for the video format
set frame_rate=29.97
REM this is the quality. 0 is the best. 51 the worst. Anything below 16 is a 
REM waste of space. Default is 23
set crf_val=20
REM ###########################################################################
REM print out the user info
echo.
echo %output_width%x%output_height% at %frame_duration% per image at %frame_rate% fps
echo.
echo The quality is set to %crf_val% on a scale of 0-51
echo.
REM make a temp folder
if not exist "tmp" mkdir tmp

REM Create a black frame background
magick convert -size %output_width%x%output_height% canvas:black tmp/background.gif"
    
REM ###########################################################################
REM Scale all the images into the temp folder
set counter=0
for %%f in (*.jpg) do (
    REM This is our counter. Our limit is 9999 frames right now
	set /a counter+=1
    set "fmt_cnt=000000!counter!"

    REM Create our converted frame
    magick convert tmp/background.gif -gravity center %%f -resize %output_width%x%output_height% -gravity center -composite -quality 100 tmp/tmp_img_!fmt_cnt:~-4!.jpg 
)
REM ###########################################################################


REM ###########################################################################
Rem FFMPEG the files in the temp folder
REM -start_number is the frame to start on. libx264 is a normal compression target. -crf is the encode quality, -pix_fmt is how we encode it
ffmpeg -y -r %frame_duration% -start_number 1 -i tmp/tmp_img_%%04d.jpg -c:v libx264 -r %frame_rate% -tune stillimage -crf %crf_val% -pix_fmt yuv420p result.mp4
REM ###########################################################################

REM ###########################################################################
echo.
echo.
echo Cleaning up the tmp
echo.
echo.
RD /S /Q "tmp"
REM ###########################################################################

echo Finished