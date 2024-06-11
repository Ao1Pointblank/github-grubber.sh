# github-grubber.sh
simple script to download latest public releases of other github repos  

# Dependencies:
fzf, curl, wget  

# Options:  
- first you need to provide the source:   
**``-u [github url]``**  
  
- alternatively, you can use -o and -r:   
**``-o [repo owner]``**    
**``-r [repo name]``**    
  
- specifying the release file/format type is not required, but will make the download process automatable:  
**``-f [file type/keyword]``** 
  
- download directory is ``$pwd`` (current working directory) by default, but can be changed to move the output to a preexisting folder:  
**``-d [directory]``**    

# Examples:  
ask which version to download to ``~/Downloads``:  
```github-grubber.sh -u https://github.com/th-ch/youtube-music -d ~/Downloads```  
  
automatically download the tarball to ``$pwd``:  
```github-grubber.sh -o th-ch -r youtube-music -f tarball```  
  
automatically download the amd64.deb package to ~/Desktop/folder:  
```github-grubber.sh -u https://github.com/th-ch/youtube-music -f amd64.deb -d ~/Desktop/folder```  
*note: if ~/Desktop/folder does not exist, the script will **not** create the dir, rather it will leave the file in ``$pwd``*
