#!/bin/bash
#by ao1pointblank, June 10 2024
#https://github.com/Ao1Pointblank/github-grubber.sh

#DEPENDENCIES:
#fzf, curl, wget

#cache of downloaded URLS
HISTORY="$HOME/.config/github-grubber.history"
touch "$HISTORY"

#define usage function
show_help() {
    echo "Command to download latest files from Github repos"
    echo "Usage: $(basename $0) -o|--owner [REPO_OWNER] -r|--repo [REPO_NAME] -u|--url [github link] -f|--file [file name to match] -d|--dir|--directory [folder] -F|--force"
    echo "    --url can be used to search by github repo link instead of separate --owner and --repo"
    echo "    --file selects the first matching release file with grep. if -f is not specified, it will display a fzf window to select manually."
    echo "    --directory will move the downloaded file from working directory ($PWD) to the destination folder if it exists"
    echo "    --force causes the file to be downloaded regardless of whether it has been cached in $HISTORY"
    echo "Examples:"
    echo "    $(basename $0) -o th-ch -r youtube-music -f amd64.deb"
    echo "    $(basename $0) -u https://github.com/th-ch/youtube-music"
}

#parse command line arguments
while [ $# -gt 0 ] ; do
  case $1 in
    -o | --owner)
        REPO_OWNER="$2"
        shift
        shift
        ;;
    -r | --repo)
        REPO_NAME="$2"
        shift
        shift
        ;;
    -u | --url)
        URL="$2"
        echo $2
        shift
        shift
        ;;
    -f | --file)
        FILE="$2"
        shift
        shift
        ;;
    -d | --dir | --directory)
        DIRECTORY="$2"
        shift
        shift
        ;;
    -F | --force)
        FORCE=1
        shift
        ;;
    -h | --help)
        show_help
        exit
        ;;
    -*|--*)
        echo "⚠️ Invalid option: $1" >&2
        exit 1
        ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [ -z "$FORCE" ]; then
    FORCE=0
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
        SELECTION=$(echo "$LIST" | grep -i --max-count=1 "$FILE")
    else
        #use fuzzyfind to search available files if -f not specified
        SELECTION=$(echo "$LIST" | fzf --tac -i --exact)
    fi

    #download the selected file (for some reason, curl only downloaded empty or corrupted files, so i had to use wget. i also could not get output directory to work, so it defaults to $HOME)
    if [ "$SELECTION" ]; then

        echo "$SELECTION"
        NAME=$(echo $SELECTION | awk -F/ '{print $NF}')
        if ! grep -Fqw "$SELECTION" "$HISTORY" || [ "$FORCE" = "1" ]; then
            echo -n "✅ Downloading $NAME"
            wget -q "$SELECTION"
            echo "$SELECTION $(date +"%F at %T")" >> "$HISTORY"
        else
            echo "⚠️ $NAME has already been downloaded before ($HISTORY)"
            echo "⚠️ re-run with --force to download it anyway"
            exit 1
        fi

    else
        echo $SELECTION
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
