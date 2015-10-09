#! /bin/sh

cat << __EOF | gnuplot
set datafile separator " "
set term png
unset key
set palette defined (0 0 0 0.5, 1 0 0 1, 2 0 0.5 1, 3 0 1 1, 4 0.5 1 0.5, 5 1 1 0, 6 1 0.5 0, 7 1 0 0, 8 0.5 0 0)

set title "$1 Total Dynamic Energy"  
set xlabel "Data cache size (kB)"
set ylabel "L2 cache size (kB)"
set output "$2/energyTotal.png"
plot "$2/EnergyDynamic.txt" matrix rowheaders columnheaders using 1:2:3 with image

set title "$1 Total Dynamic Power"  
set xlabel "Data cache size (kB)"
set ylabel "L2 cache size (kB)"
set output "$2/powerTotal.png"
plot "$2/PowerDynamic.txt" matrix rowheaders columnheaders using 1:2:3 with image

set title "$1 Data Cache Dynamic Energy"  
set xlabel "Data cache size (kB)"
set ylabel "L2 cache size (kB)"
set output "$2/energyL1.png"
plot "$2/EnergyL1.txt" matrix rowheaders columnheaders using 1:2:3 with image

set title "$1 L2 Dynamic Energy"  
set xlabel "Data cache size (kB)"
set ylabel "L2 cache size (kB)"
set output "$2/energyL2.png"
plot "$2/EnergyL2.txt" matrix rowheaders columnheaders using 1:2:3 with image

set title "$1 L2 Static Power"  
set xlabel "Data cache size (kB)"
set ylabel "L2 cache size (kB)"
set output "$2/static.png"
plot "$2/PowerStatic.txt" matrix rowheaders columnheaders using 1:2:3 with image
__EOF
