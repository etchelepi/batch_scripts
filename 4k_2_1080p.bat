@echo off
setlocal ENABLEDELAYEDEXPANSION

if NOT EXIST finished (
    mkdir finished
)

::First step: Save the input varariables. Inputfilename should not include the .avi|.mov|.mpg
::Second Step: Run the mencoder on both the left and right files
::mencoder format: mencoder -fps <rate> -o <conformed_file> -ovc copy -nosound <source_file>

::convert the temp video a smaller file
::ffmpeg -y -i %input_name% -c:v prores_ks -profile:v 1  -vendor ap10 -pix_fmt yuv422p10le -s 960x540 %output_name%_proxy.mov

set /A COUNTER=0
REM use a lower CRF to get better results. 18 is the best

for /r %%i in (*mp4) do (
    Set Name=%%~nxi
    set TEMPPATH=%%~dpnxi
    set FULL_PATH="!TEMPPATH!"
    
    REM we need to clear it each time. A non rotated field returns nothing
    set ROTATE=0
    set /A WIDTH=0
    set /A HEIGHT=0
    
    REM Get the Width of the video
    set CMD=ffprobe -v error -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 !FULL_PATH!
    for /f %%z in ('!CMD!') do set /A WIDTH=%%z
    
    REM Get the Hight of the Video
    set CMD=ffprobe -v error -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 !FULL_PATH!
    for /f %%z in ('!CMD!') do set /A HEIGHT=%%z
    
    REM Get the Rotate Info of the Video
    set CMD=ffprobe -v error -show_entries stream_tags=rotate -of default=noprint_wrappers=1:nokey=1 !FULL_PATH!
    for /f %%z in ('!CMD!') do set ROTATE=%%z
    
    REM Because a Video can either be 16:9 with rotation, OR it can be 9:16 without Rotation. We need to do 4 checks:
    REM 1920x1080 90 = Portrait
    REM 1080x1920 90 = landscape
    REM 1920x1080 0 = landscape
    REM 1080x1920 0 = Portrait
    if "!ROTATE!" NEQ "0" (
        REM 1920x1080 90 = Portrait
        if !WIDTH! GTR !HEIGHT! (
            if !HEIGHT! GTR 1080 (
                echo "Portait with Rotation" !WIDTH! !HEIGHT! !ROTATE!
                ffmpeg -y -i !FULL_PATH! -map_metadata 0 -vf scale=1080:-1 -c:v libx265 -crf 20 -preset slow -c:a copy ./finished/!Name!
                set /A COUNTER+=1
            )
        REM 1080x1920 90 = landscape    
        ) else (
            if !WIDTH! GTR 1080 (
                echo "landscape with Rotation" !WIDTH! !HEIGHT! !ROTATE!
                ffmpeg -y -i !FULL_PATH! -map_metadata 0 -vf scale=1080:-1 -c:v libx265 -crf 20 -preset slow -c:a copy ./finished/!Name!
                set /A COUNTER+=1
            )
        )
    ) else (
        REM 1920x1080 0 = landscape
        if !WIDTH! GTR !HEIGHT! (
            if !HEIGHT! GTR 1080 (
                echo "landscape without Rotation" !WIDTH! !HEIGHT! !ROTATE!
                ffmpeg -y -i !FULL_PATH! -map_metadata 0 -vf scale=-1:1080 -c:v libx265 -crf 20 -preset slow -c:a copy ./finished/!Name!
                set /A COUNTER+=1
            )
        REM 1080x1920 0 = portrait
        ) else (
            if !WIDTH! GTR 1080 (
                echo "portrait without Rotation" !WIDTH! !HEIGHT! !ROTATE!
                ffmpeg -y -i !FULL_PATH! -map_metadata 0 -vf scale=1080:-1 -c:v libx265 -crf 20 -preset slow -c:a copy ./finished/!Name!
                set /A COUNTER+=1
            )
        )
    )
)

echo "TOTAL NUMBER of 4K Content: " %Counter%

echo "FINISHED"