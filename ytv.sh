#!/bin/bash
set -euo pipefail

#help
usage(){
  cat <<EOF
  Script simulating youtube in the unix terminal.
  Search and play the videos, create a playlist.

  Search:
  	./ytv.sh what to search
  		: searches for "what to search" in youtube

  Options:
  	-t
  		: lists trending videos
  	-h|--help
  		: usage
  	-d:
  		:downloads the video

  Additional searching results
  		We can let the script show us more than default number of searches (10)
  		using key m. (additional 10, after "Select the number:")

  Playlists options:
  	+p
  		:selected video is added to the playlist
  	-pp
  		:plays videos in the playlist
  	-p n
  		:deletes the nth video in the playlist (from the beggining), n is integer
  	-cp
  		:clears the playlist
  	-sp
  		:shows the playlist
EOF
}

#checks the internet connection by checking just the page availability
checkInternet(){
  wget -q --spider "http://www.google.com" ||
    { echo "check your internet connection"; return 1; }
}

#checks whether we should change default settings
loadConfig(){
  if [ -f ~/.config/ytv ]; then
    #change default settings from config
    downloadTool=`cat ~/.config/ytv |grep -o "downloadTool=[a-z]*" |cut -d "=" -f 2`
    numOfSearches=`cat ~/.config/ytv |grep -o "numOfSearches=[0-9]*" |cut -d "=" -f 2`
    #this options happens to contain bugs since youtube-dl is updating too often
    #and then players have problem, vlc is recommended the most
    #player=`cat ~/.config/ytv |grep -o "player=[a-z]*" |cut -d "=" -f 2`
  fi
}

#downloads the desired youtube web page
downloadWeb(){
#youtube search page example
        #https://www.youtube.com/results?search_query=*
        # * is the searched query
#youtube search query
#is just the sequence of strings with + between each two of them

query=`echo $toSearch | tr " " "+"`

#some characters youtube substitues with their hexa ascii value with % before
query=`echo $query |sed 's/#/%23/g'`

#final youtube url with query
yt=`echo "https://www.youtube.com/results?search_query=$query"`

#download web page
$downloadTool -s "$yt" -o "index.html"
mv index.html ~/.cache/ytv
}

#extracts urls of videos from downloaded youtube HTML
getUrls(){
  cat ~/.cache/ytv/index.html | grep "watch?v=" | awk '{print $5}' | sed 's/href=//g' > urls

  #format the output -> just the ending of youtube url
  cat urls |sed 's/vve-check//g' |sed '/^$/d' > tmp && mv tmp urls
  cat urls |sed 's/\"//g' |cut -d ";" -f 1 > tmp && mv tmp urls
  cat urls |grep '^/' >  tmp && mv tmp urls

  mv urls ~/.cache/ytv
}

#extracts titles of videos from downloaded youtube HTML
getNames(){
  #find the lines where are the links and titles
  cat ~/.cache/ytv/index.html | grep "watch?v=" | awk -F 'title="' '{print $2}' > names

  #find the length of the videos
  cat ~/.cache/ytv/index.html | grep "Délka: " | awk -F 'Délka: ' '{print $2}' > duration
  cat duration | cut -d "." -f 1 > tmp && mv tmp duration

  #delete unwanted "things"
  cat names | cut -d "\"" -f 1 | sed '/^$/d' > tmp && mv tmp names
  cat names | sed 's/&quot;//g' | sed 's/&amp;//g' > tmp && mv tmp names

  #replace some common ascii values for their ascii char
  cat names |sed "s/&#39;/\'/g" > tmp &&mv tmp names

  #format the output
  pr -m -t -w 120 names > output
  pr -m -t -w 120 output duration > tmp &&mv tmp output

  #print the output
  query=`echo $query |tr "+" " "`
  echo "Search results for \" $query \":"
  cat -n output |head -n $numOfSearches

  mv names ~/.cache/ytv
  mv duration ~/.cache/ytv
  mv output ~/.cache/ytv
}

#selects and plays the selected video
playVideo(){
  echo "Select the number:"
  read num

  #list 10 more
  if [ "$num" == "m" ]; then
    showMore
    echo "Select the number:"
  elif [ "$num" == "q" ]; then
    quit="t"
  fi

  #take care of some input fails
  while ! [ $num -eq $num 2>/dev/null ] || [ $num -le 0 ]; do
    read num
  done

  #play the video
  numUrl=`cat -n ~/.cache/ytv/urls | sed "${num}q;d" | cut -d "/" -f 2`
  vlc http://www.youtube.com/"$numUrl"
}

#shows searched videos
showVideos(){
  downloadWeb
  getUrls
  getNames
}

#shows trending videos on youtube
showTrends(){
  #different web page url
  $downloadTool -s "https://www.youtube.com/feed/trending" -o "index.html"
  getUrls

  #change the query
  query="trending"
  getNames

  mv index.html ~/.cache/ytv
}

#lists additional searches
showMore(){
  numSearches=`cat ~/.cache/ytv/output |wc -l`
  cat -n ~/.cache/ytv/output |head -n $numSearches |tail -n $(($numSearches - 10))
}

#deletes nth video from the playlist (option -p n)
removeVideo(){
  numLine=`cat playlist |wc -l`
  if [ "$numLine" -eq 1 ]; then
    clearPlaylist
  else
    cat -n playlist |tr -s " " |grep -v "^ $1" |awk -F '\t' '{print $2}' > tmp &&mv tmp playlist
  fi
}

#clears the playlist (-cp)
clearPlaylist(){
  echo "" > playlist
  cat playlist |sed '/^$/d' > tmp && mv tmp playlist
}

#plays the whole playlist
playPlaylist(){
  cat playlist |cut -d "-" -f 1 |xargs -i $player "{}"
}

#adds url - name to the playlist (option +p)
addToPlaylist(){
  name=`cat -n ~/.cache/ytv/names |sed "${num}q;d" | awk -F '\t' '{print $2}'`
  echo "http://www.youtube.com/$numUrl" - $name >> playlist
}

#search & play
repeat(){
  while :
  do
    echo "New search:"
    read -r toSearch

    #user want to end the script
    if [ "$toSearch" == "q" ]; then
      exit
    fi

    showVideos
    playVideo
  done
}

#download the video
downloadVideo(){
  echo "Select the number:"
  read num
  #take care of some input fails
  while ! [ $num -eq $num 2>/dev/null ] || [ $num -le 0 ]; do
    read num
  done

  numUrl=`cat -n ~/.cache/ytv/urls |sed "${num}q;d" |cut -d "/" -f 2`

  echo "Enter the name of the video:"
  read name
  youtube-dl -o $name "http://www.youtube.com/$numUrl"

  mv "$name.mkv" videos/
}

#main

#first check if we have internet connection
checkInternet

#config file : ~/.config/ytv
#default config options
player=vlc
downloadTool=wget
numOfSearches=5
loadConfig

#no arguments means usage
if [ "$#" -eq 0 ]; then
  usage
else
#switch(parameters)
case $1 in
  -h|--help)
    usage;;
  -t)
    #feed/trending videos
    showTrends
    playVideo
    repeat;;
  "+p")
    #if we want to add to playlist sth which is in trending vids
    if [ "$2" = "-t" ]; then
      showTrends
    else
      shift
      toSearch=$@
      showVideos
    fi
    playVideo
    addToPlaylist;;
  -p)
    #removes nth video from the playlist
    removeVideo $2;;
  -pp)
    #play the videos in the playlist file consecutively
    playPlaylist;;
  -sp)
    #shows playlist
    cat -n playlist;;
  -cp)
    #clears the playlist
    clearPlaylist;;
  -d)
    #downloads the youtube video
    shift
    toSearch=$@
    showVideos $toSearch
    downloadVideo;;
  *)
    #just regular search for the video
    toSearch=$@
    showVideos
    playVideo
    #repeat until q key not pressed
    repeat;;
esac
fi
