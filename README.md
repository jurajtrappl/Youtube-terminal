# Youtube-terminal
- Bash script that plays videos from the terminal.
- Allows you to create playlist.
- Quick approach to trending videos on youtube

# HELP
## Search:

./ytv.sh what to search

    searches for "what to search" in youtube

## Options:
    -t   
      : lists trending videos
    -h|--help     
      : usage
    -d
      : downloads the video

## Additional searching results

We can let the script show us more than default number of searches (10)
  		using key m. (additional 10, after "Select the number:")

## Playlists options:
  	+p   
       : selected video is added to the playlist
  	-pp
  		:plays videos in the playlist
  	-p n
  		:deletes the nth video in the playlist (from the beggining), n is integer
  	-cp
  		:clears the playlist
  	-sp
  		:shows the playlist
