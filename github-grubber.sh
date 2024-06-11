#!/bin/bash
#by ao1pointblank, June 10 2024
#https://github.com/Ao1Pointblank/github-grubber.sh

#DEPENDENCIES:
#fzf, curl, wget

#define usage function
show_help() {
    echo "Command to download latest files from Github repos"
    echo "Usage: $(basename $0) -o [REPO_OWNER] -r [REPO_NAME] -u [regular github link instead of separate owner & repo]-f [file name to search for]"
    echo "    -f selects the first match with grep. if -f is not specified, it will display a fzf window to select manually."
    echo "Examples:"
    echo "    $(basename $0) -o th-ch -r youtube-music -f amd64.deb"
    echo "    $(basename $0) -u https://github.com/th-ch/youtube-music"
}

#parse command line arguments
while getopts ":o:r:u:f:d:h" opt; do
    case "$opt" in
        o) REPO_OWNER="$OPTARG";;
        r) REPO_NAME="$OPTARG";;
        u) URL="$OPTARG";;
        f) FILE="$OPTARG";;
        d) DIRECTORY="$OPTARG";;
        h) show_help
        exit;;
        \?) echo "⚠️ Invalid option: -$OPTARG" >&2
        exit 1;;
    esac
done

if [ $# = 0 ]; then
    show_help
    exit
fi

#sanity check that URL exists
if [ -z "$URL" ]; then
    if [ -z $REPO_OWNER ] || [ -z $REPO_NAME ]; then
        echo "⚠️ No Github repos provided"
        exit 1
    else
        URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"
    fi
else
    #convert regular github link to api link
    URL=$(echo "$URL"/releases/latest | sed 's|github.com|api.github.com/repos|')
fi

#make sure $URL is a valid link
status=$(curl -sL --head $URL | grep HTTP | awk '{print $2}')
if [ "$status" = "200" ]; then

    #get the latest release from GitHub API
    LIST=$(curl -s $URL | grep -Po '(?<=browser_download_url": ").*?(?=")|(?<=zipball_url": ").*?(?=")|(?<=tarball_url": ").*?(?=")')

    #check if a file type was specified
    if [ "$FILE" ]; then
        #grab the first matching file (it pays to be precise when passing the -f argument)
        SELECTION=$(echo "$LIST" | grep --max-count=1 "$FILE")
    else
        #use fuzzyfind to search available files if -f not specified
        SELECTION=$(echo "$LIST" | fzf --tac -i --exact)
    fi

    #download the selected file (for some reason, curl only downloaded empty or corrupted files, so i had to use wget. i also could not get output directory to work, so it defaults to $HOME)
    if [ "$SELECTION" ]; then
        NAME=$(echo $SELECTION | awk -F/ '{print $NF}')
        echo -n "✅ Downloading $NAME"
        wget -q $SELECTION
    else
        echo "⚠️ No valid files to download"
        exit 1
    fi

else
    echo "⚠️ Invalid URL"
    exit 1
fi

#if -d is specified and exists
if [ ! -z "$DIRECTORY" ]; then
    if [ -n "$DIRECTORY" ] && [ -d "$DIRECTORY" ]; then
        mv "$HOME/$NAME" -t "$DIRECTORY" &&
        #magic sequence that removes the previous echoed line
        echo -ne "\r\033[K"
        echo "✅ $NAME -> $DIRECTORY"
    else
        echo "⚠️ The specified output directory does not exist or is not a valid path."
        echo "✅ $NAME was downloaded but not relocated from $HOME/"
    fi
fi