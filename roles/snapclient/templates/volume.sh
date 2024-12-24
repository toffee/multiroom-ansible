#!/bin/bash

# https://github.com/badaix/snapcast/issues/318
# the script will be executed with the parameters --volume <volume> --mute <true|false>

usage()
{
    echo "usage: volume.sh --side <left|right> --volume <volume> --mute <true|false> --help"
}

#logger "Call volume.sh $@"

while [ "$1" != "" ]; do
    case $1 in
        -s | --side )           shift
                                side=$1
                                ;;
        -v | --volume )         shift
                                volume=$1
                                ;;
        -m | --mute )           shift
                                mute=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

#logger "Side $side, Volume $volume, Mute $mute"

VOL=$(awk -v volume="$volume" 'BEGIN{printf "%.0f\n", (100*volume)}')

if [ "$mute" = "true" ]; then
    MUTE="mute"
else
    MUTE="unmute"
fi

#logger "Vol $VOL Mute $MUTE"

if [ "$side" = "left" ]; then
    amixer -q -M -c {{alsa_card}} -- sset '{{alsa_mixer}}',0 $VOL%,0+
    amixer -q -M -c {{alsa_card}} -- sset '{{alsa_mixer}}',0 $MUTE,0+
    exit
fi

if [ "$side" = "right" ]; then
    amixer -q -M -c {{alsa_card}} -- sset '{{alsa_mixer}}',0 0+,$VOL%
    amixer -q -M -c {{alsa_card}} -- sset '{{alsa_mixer}}',0 0+,$MUTE
    exit
fi

#No side provided means stereo
amixer -q -M -c {{alsa_card}} -- sset '{{alsa_mixer}}',0 $VOL%,$VOL%
# Bellow command returns "amixer: Invalid command!" but without the mute/unmute is working but I don't know why/who!?
#amixer -q -M -c {{alsa_card}} -- sset '{{alsa_mixer}}',0 $MUTE,$MUTE