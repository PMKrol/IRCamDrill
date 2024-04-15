%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% based on
% Optical Character recogintion (OCR) example
% Tanja Baumann (08.12.2018)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

##pkg install -forge io
pkg load io

inDir = "video_flash2/";
foldernames = dir(inDir);
samplesMax = 321;

tempArray = zeros(0, size(foldernames)(1) - 1, 'float');

strOut = "Sample No.";

for folder = 3:size(foldernames)(1)     #3
  
  foldername = foldernames(folder, 1);
  
  if !isfolder([inDir foldername.name])
    continue;
  endif
  
  strOut = [strOut "\t" foldername.name];
endfor

strOut = [strOut "\n"];

for sample = 1:samplesMax
  #tempRow(1, sample) = sample;
  #strOut = [strOut sprintf("%d", sample)];
  lineOut = sprintf("%d\t", sample);
  
  for folder = 3:size(foldernames)(1)  
    foldername = foldernames(folder, 1);
    
    if !isfolder([inDir foldername.name])
      printf("%s: XXX -> %03.1f\n", foldername.name, val);
      continue;
    endif
    
    #fCheck = escape_special_characters([inDir foldername.name "/samples/" sprintf("%03d", sample)]);
  
    fCheck = [sprintf("%03d_", sample)];
    dCheck = [inDir foldername.name "/samples/"];
    
    filename = find_matching_file(fCheck, dCheck);
    
    if (isempty(filename))
      lineOut = [lineOut "\t"];
    ##  continue;
    ##endif
##    fCheck = [fCheck ".*.png"];
      printf("%s XXX %s\n", dCheck, fCheck);
##    
##    f = isfile(fCheck);
##    lineOut = [lineOut sprintf("%03.1f\t", f)];
    #tempRow(folder - 1, sample) = fexist([inDir foldername.name "/samples/" sprintf("%03d", sample) "*.png"], 'f', 'r');
    else
        filename = strrep(filename, '_camera', '');
        
        imScale = [inDir foldername.name "/samples/" filename "_scale.pnm"];
            
        [~, gocr] = system(["gocr -d0 -C0-9. -p ./db/ -m 2 -m 256 \"" imScale "\""]);
        val = str2num(strsplit(gocr, "\n"){1});
        
        printf("%s: %s -> %03.1f\n", foldername.name, filename, val);
        
        lineOut = [lineOut sprintf("%03.1f\t", val)];
    endif
  endfor
  
  lineOut = [lineOut "\n"];
  printf(lineOut);
  strOut = [strOut lineOut];
  
  
endfor

#printf("%s", strOut);

fid = fopen ([inDir "/" [datestr(clock()) ".txt"]], "w");
fputs (fid, strOut);
fclose (fid);
