#! /bin/sh
rm results/$1/PowerDynamic.txt
rm results/$1/EnergyDynamic.txt
for CoreLevel in results/$1/*
do
    l2size=131072
    for L2Level in  ${CoreLevel}/*
    do
          if [ -d "${L2Level}" ]; then
              l1size=1024
              for L1Level in  ${L2Level}/*
	      do
	          if [ -d "${L1Level}" ]; then
			processor=$(awk '$1=="TotalProcessorRuntimeDynamic"{print $3}' ${L1Level}/power_stats.txt)
			if [ -n "$processor" ]; then
			    cycle=$(awk '$1=="Final"{print $4}' ${L1Level}/results.txt)
			    time=$(echo "scale=10;$cycle/1000000000"|bc)
			    energy=$(echo "scale=5;$time*$processor" | bc -q | sed 's/^\./0./;s/0*$//;s/\.$//')
			    processor=$(echo "scale=5;$processor" | bc -q | sed 's/^\./0./;s/0*$//;s/\.$//')
			    printf '%s\t%s\t%s\n' "$l1size $l2size $processor" >> results/$1/PowerDynamic.txt
			    printf '%s\t%s\t%s\n' "$l1size $l2size $energy" >> results/$1/EnergyDynamic.txt
			fi
			l1size=$(( $l1size * 2 ))

	          fi
	      done
	      l2size=$(( $l2size * 2 ))
	      printf '\n' >> totalresults.txt
	fi
    done
done

