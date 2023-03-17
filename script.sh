#!/bin/sh

echo 'This is Mr. Johnson in Skyview Hovercraft One!'
echo 'Downloading weather and park hours text-to-speech...'

# Weather
curl -s https://fastpass.wdwnt.com/weather/wdw >> weather.json

for index in 0 1; do
  if [ $index -eq 0 ]
  then
    day=today
  else
    day=tomorrow
  fi

  jq --argjson index $index --arg day $day '.wdw.daily.data[$index] | "The forecast for " + $day + " is " + (.summary|sub("[.]$";"")) + ". There will be a high of " + (.temperatureMax|floor|tostring) + " degrees Fahrenheit and a low of " + (.temperatureMin|floor|tostring) + "."' weather.json >> weather.txt
done

echo 'We hope you have a magical day, and a great big beautiful tomorrow!' >> weather.txt

#sudo gtts-cli --file weather.txt --tld com -l en -o weather.mp3
aws polly synthesize-speech --engine neural --output-format mp3 --voice-id Olivia --text file://weather.txt weather.mp3

# Park hours
curl -s https://wdwnt-now-api.herokuapp.com/api/parks?sort=true \
  | jq '.[0,1,2,3] | .name + " is open today from " + .todaysHours + " and tomorrow from " + .tomorrowsHours + "."' \
  >> hours.txt

#sudo gtts-cli --file hours.txt --tld com -l en -o hours.mp3
aws polly synthesize-speech --engine neural --output-format mp3 --voice-id Olivia --text file://hours.txt hours.mp3

### Mix and build final output
echo 'Mixing and building final report output...'

# Pad the hours with 1 second of silence
ffmpeg -hide_banner -loglevel error -i hours.mp3 -af "apad=pad_dur=1" hours_padded.mp3

ffmpeg -hide_banner -loglevel error -i "concat:hours_padded.mp3|weather.mp3" -acodec copy speech.mp3

# Pad the report with 10 seconds of silence
ffmpeg -hide_banner -loglevel error -i speech.mp3 -af "apad=pad_dur=10" speech_padded.mp3

# Merge the GBBT background and the hours/weather
ffmpeg -hide_banner -loglevel error -i gbbt.mp3 -i speech_padded.mp3 -filter_complex amerge=inputs=2 -ac 2 output.mp3

# Calculate the length of the track
export length=$(ffprobe -loglevel quiet -show_entries format=duration \-print_format default=noprint_wrappers=1:nokey=1 output.mp3)
export length=${length%.*}

# Fade out the track for 8 seconds
ffmpeg -hide_banner -loglevel error -i output.mp3 -af "afade=t=out:st=$((length-10)):d=8" final.mp3

# Concatenate the intro to the final output
ffmpeg -hide_banner -loglevel error -i "concat:intro.mp3|final.mp3" -acodec copy report.mp3

cp ./report.mp3 /output

echo 'Done!'
