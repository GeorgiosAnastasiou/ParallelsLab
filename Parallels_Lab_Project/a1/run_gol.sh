#!/bin/bash

num_cores=(1 2 4 6 8)
sizes=(64 1024 4096)
speed=1000
for nc in "${num_cores[@]}"
do
    echo "========================================="
    echo "|| Running Game Of Life on $nc threads ||"
    echo "========================================="
    export OMP_NUM_THREADS=$nc &&
        for size in "${sizes[@]}"
        do
            ./Game_Of_Life $size $speed
        done
done

