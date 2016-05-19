#!/bin/bash
OUTPUT=""
#outer controll, 1st digit
for o in {0..50}; do
    #inner controll, 2nd digit
    for i in {0..50..5}; do
        #output controll group, groupings of 5
        GP=0
        while [ $GP -lt 5 ]; do
            OUTPUT+=$o';'$(expr $i + $GP)'m: \e['$o';'$(expr $i + $GP)'mTest\e[00m\t'
            GP=$(expr $GP + 1)
        done
        echo -e $OUTPUT
        OUTPUT=""
    done
    echo
done
#
#for i in {1..10}; do
#  echo -e $i '\e['$i'mtest''\e[00m'
#done