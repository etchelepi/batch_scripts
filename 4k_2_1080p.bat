REM ###########################################################################
REM This is a script that I wrote to go through all my video files, get ones 
REM that are bigger then 1080p and then downscale them to h265 at 1080p
REM because I want to save space of these old videos from my Phone. 
REM 4K content on my phone was better, but Honestly, i don't think I need 4K
REM from these phones. So 4K-> 1080P is superior. 

REM This script does not do anything to the original content. 
REM You have to erase them yourself if you want.
REM ###########################################################################


@echo off
setlocal ENABLEDELAYEDEXPANSION


REM we only want to do this if the folder doesn't exist
if NOT EXIST finished (
    mkdir finished
)

REM I want to report out how many files I found. It helps to know
set /A COUNTER=0

REM use a lower CRF to get better results. 18 is the best
for /r %%i in (*mp4) do (
    Set Name=%%~nxi
    set TEMPPATH=%%~dpnxi
    set FULL_PATH="!TEMPPATH!"
    
    REM we need to clear it each time. Otherwise we can get some bad behavior.
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
                ffmpeg -y -i !FULL_PATH! -map_metadata 0 -vf scale=-1:1080 -c:v libx265 -crf 20 -preset slow -c:a copy ./finished/!Name!
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

REM Note: There are more possibilities. You can have 0,90,180,270 for the rot. None of my content ever had anything but 90 and 0. But it means this script could be improved by
REM calculating the ROT into a common value in case you run into a video that uses a ROT 270 or 180.

echo "TOTAL NUMBER of 4K Content: " %Counter%

echo "FINISHED"