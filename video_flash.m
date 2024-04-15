### MIT License
### 
### Copyright (c) 2024 Patryk Maciej Król
### 
### Permission is hereby granted, free of charge, to any person obtaining a copy
### of this software and associated documentation files (the "Software"), to deal
### in the Software without restriction, including without limitation the rights
### to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
### copies of the Software, and to permit persons to whom the Software is
### furnished to do so, subject to the following conditions:
### 
### The above copyright notice and this permission notice shall be included in all
### copies or substantial portions of the Software.
### 
### THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
### IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
### FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
### AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
### LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
### OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
### SOFTWARE.

#install
#sudo apt install octave-common octave-video octave-image octave-io liboctave-dev
#sudo apt-get install libavutil-dev libavformat-dev libswscale-dev libavcodec-dev
#sudo add-apt-repository ppa:niepamietamnazwy/opencv-3.4.1
#sudo add-apt-repository ppa:niepamietamnazwy/mexopencv-3.4.1
#sudo apt install opencv mexopencv

#sudo apt install libavutil-dev libavformat-dev libswscale-dev libavcodec-dev opencv mexopencv octave octave-common octave-video octave-image octave-io liboctave-dev

%??
#sudo apt install libgstreamer1.0-0

#TODO: 
# last img not copied (2st)
# %03d -> %04d, f.
# not mean but central value. 205: mean(c)
# max time to check
# at the end show all series mean(c(10:end-10)) 210: 

addpath("/usr/share/octave/mexopencv")
addpath("/usr/share/octave/mexopencv/opencv_contrib")
warning('off', 'Octave:shadowed-function');

printf("Loading video and image pkgs\n");
pkg load video
pkg load image 

#config
input_directory = ".";
output_directory = "video_flash2";
imcrop_x = 191;
imcrop_y = 241;
imcrop_xsize = 513;
imcrop_ysize = 385;
camera_crop = [191 241 513 385];
#scale_crop = [270 886 400 36];
scale_crop = [886 177 36 540];
info_crop = [430 1 420 60];
videoSkipS = 5;

##flash_x = 410;
##flash_y = 96;
#flash_coord = [96 410];
flash_coord = [100 410];
flash_neighbours = [
##                    386 75;
##                    386, 120;
##                    424, 72;
                    414, 70;
                    414, 130;
                    ];

fileList = dir(input_directory);
mkdir(output_directory);

for file=3:size(fileList)(1)
  #flashArray = uint16.empty;
  flashArray = zeros(0, 4, 'uint16');
  
  filename = fileList(file, 1);
  [~, basename, ext] = fileparts ([input_directory "/" filename.name]);

  if !strcmp(ext, ".mkv")
      continue;
  endif
  
  printf("%s\n", basename);
  mkdir([output_directory "/" basename]);
  imOut = [output_directory "/" basename "/all_frames/"];
  mkdir(imOut);
  video = VideoReader(filename.name);
     
  frame = 1;
  
  #skip some time
  for i = 1:videoSkipS*video.FrameRate
    readFrame(video);
    frame++;
  endfor
  
  st1 = "";
  st2 = "";
  
  #generate images and collect values of flash area
  while (video.hasFrame())
    imgFrame = readFrame (video);
    
    if !isrgb(imgFrame) #if (isempty (im))?
      line = [line sprintf("Image (frame) error!\n")];
      st1 = [st1 line];
      break;
    endif
    
    imgGray = cv.cvtColor(imgFrame, 'RGB2GRAY');
    imgCamera = imcrop(imgGray, camera_crop);
    imgScale = imcrop(imgGray, scale_crop);    
    imgInfo = imcrop(imgGray, info_crop);
    imgScale(:,:,:) = 255 - imgScale(:,:,:);  %invert colors
    imgInfo(:,:,:) = 255 - imgInfo(:,:,:);  %invert colors
    
    nameNo = sprintf("frame%03d_", frame);
    
    imwrite(imgCamera, [imOut nameNo "camera.png"], 'WriteMode','overwrite');
    imwrite(imgScale, [imOut nameNo "scale.pnm"], 'WriteMode','overwrite');
    imwrite(imgInfo, [imOut nameNo "info.pnm"], 'WriteMode','overwrite');
    
    #val_flash = imgCamera(flash_coord(1), flash_coord(2));
    val_flash = mean(mean(imgCamera(103:121,407:424)));
    val_neighbours = 0;
    
    for i = 1:size(flash_neighbours)(1)
      val_neighbours += imgCamera(flash_neighbours(i, 2), flash_neighbours(i, 1));
    endfor
    
    val_neighbours = val_neighbours/size(flash_neighbours)(1);
    
    flashArray = [flashArray; frame, val_flash, val_neighbours, val_flash - val_neighbours];
    line = sprintf("%03d\t%03.0f\t%03d\t%03.0f\n", frame, val_flash, val_neighbours, val_flash - val_neighbours);
    
    st1 = [st1 line];
    printf("%s", line);
    
    frame++;
    
##    if frame > 250
##      break;
##    endif
    
  endwhile
  
  fid = fopen ([output_directory "/" basename "/st1.txt"], "w");
  fputs (fid, st1);
  fclose (fid);

  allFramesNo = size(flashArray)(1);
  flashMean = mean(flashArray)(4);
  printf("\n%03d\t%03d\n", allFramesNo, flashMean);
  
  frame = 1;
  theOnesArray = zeros(0, 4, 'uint16');
  
  #select brightest flash area
  #for frame = 1:allFramesNo-5
  while frame < allFramesNo-5
    line = sprintf(" %03.0f\t", flashArray(frame, :));
    line = [line sprintf("\n")];
##    st2  = [st2 line];
##    printf(line);
    
    if (flashArray(frame, 4) < flashMean &&
        flashArray(frame+1, 4) > flashMean )
##        flashArray(frame+2, 4) > flashMean ||
##        flashArray(frame+3, 4) > flashMean ||
##         flashArray(frame+4, 4) > flashMean))
##         flashArray(frame+3, 4) > flashMean) &&
##        flashArray(frame+4, 4) < flashMean)
        
        [max_values indices] = max(flashArray(frame:frame + 4, :));
        
        maxRow = indices(4) - 1;
        
        for fi = 1:4
          line = [line sprintf("*%03.0f\t", flashArray(frame + fi, :))];
          
          if maxRow == fi
            line = [line sprintf("\t<== this one!\n")];
            theOnesArray = [theOnesArray; flashArray(frame + fi, :)];
          else
            line = [line sprintf("\n")];
          endif
        endfor
        
        frame = frame + 5;
    else
      frame = frame + 1;    
    endif
          
    st2 = [st2 line];
    printf("%s", line);
    
  endwhile
  
  fid = fopen ([output_directory "/" basename "/st2.txt"], "w");
  fputs (fid, st2);
  fclose (fid);
  
  #calculate typical gap between flashes
  a = theOnesArray(1:size(theOnesArray)(1)-1,1);
  b = theOnesArray(2:size(theOnesArray)(1),1);
  c = b-a;
  
  imOutSamples = [output_directory "/" basename "/samples/"];
  mkdir(imOutSamples);
  
  #gapBetweenFlash = mean(c);
  c = sort(c);
  c = c(10:end-10);
  gapBetweenFlash = mean(c); #6.3? 6.1276 6.1610
  
  theLastOneFrame = theOnesArray(1, 1);
  sample = 1;
  ### todo: copy this files
  nameNo = sprintf("frame%03d_", theLastOneFrame);
  sampleStr = sprintf("%03d_", sample);
  
##    
##    imwrite(imgCamera, [imOut nameNo "camera.png"], 'WriteMode','overwrite');
##    imwrite(imgScale, [imOut nameNo "scale.pnm"], 'WriteMode','overwrite');
##    imwrite(imgInfo, [imOut nameNo "info.pnm"], 'WriteMode','overwrite');
##    
  system(["cp '" imOut nameNo "camera.png' '" imOutSamples sampleStr nameNo "camera.png'"]);
  system(["cp '" imOut nameNo "scale.pnm' '" imOutSamples sampleStr nameNo "scale.pnm'"]);
  system(["cp '" imOut nameNo "info.pnm' '" imOutSamples sampleStr nameNo "info.pnm'"]);
##  copyfile([imOut nameNo "scale.pnm"],  [imOutSamples], 'f');
##  rename([imOutSamples nameNo "scale.pnm"], [imOutSamples sampleStr nameNo "scale.pnm"]);
##  copyfile([imOut nameNo "info.pnm"],   [imOutSamples], 'f');
##  rename([imOutSamples nameNo "info.pnm"], [imOutSamples sampleStr nameNo "info.pnm"]);
  
  sample += 1;
  
  #copy files with flash number
  for onesNo = 2:size(theOnesArray)(1) - 1
    while theOnesArray(onesNo, 1) - theLastOneFrame > gapBetweenFlash*1.5
      printf("OO! %d > %03.5f\n", theOnesArray(onesNo, 1) - theLastOneFrame, gapBetweenFlash);
      theLastOneFrame = theLastOneFrame + gapBetweenFlash;
      sample += 1;
    endwhile
    
    theLastOneFrame = theOnesArray(onesNo, 1);
    
    nameNo = sprintf("frame%03d_", theLastOneFrame);
    sampleStr = sprintf("%03d_", sample);
    
##    copyfile([imOut nameNo "camera.png"], [imOutSamples], 'f');
##  rename([imOutSamples nameNo "camera.png"], [imOutSamples sampleStr nameNo "camera.png"]);
##    copyfile([imOut nameNo "scale.pnm"],  [imOutSamples], 'f');
##  rename([imOutSamples nameNo "scale.pnm"], [imOutSamples sampleStr nameNo "scale.pnm"]);
##    copyfile([imOut nameNo "info.pnm"],   [imOutSamples], 'f');
##  rename([imOutSamples nameNo "info.pnm"], [imOutSamples sampleStr nameNo "info.pnm"]);

    system(["cp '" imOut nameNo "camera.png' '" imOutSamples sampleStr nameNo "camera.png'"]);
    system(["cp '" imOut nameNo "scale.pnm' '" imOutSamples sampleStr nameNo "scale.pnm'"]);
    system(["cp '" imOut nameNo "info.pnm' '" imOutSamples sampleStr nameNo "info.pnm'"]);
    
    sample += 1;
    
  endfor
  
##  break;
endfor
