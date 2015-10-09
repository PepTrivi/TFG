#! /bin/sh

stringSize=",2,4,8,16,32,64,128"
cores={a1Core,a4Core,a16Core}
#stringSize=",1024,2048,4096,8192,16384,32768,65536,131072"
numcore=1
for CoreLevel in results/*/$cores
do
  if [ -d "${CoreLevel}" ]; then
    rm ${CoreLevel}/PowerDynamic.txt
    rm ${CoreLevel}/EnergyDynamic.txt
    rm ${CoreLevel}/PowerStatic.txt
    rm ${CoreLevel}/EnergyL1.txt
    rm ${CoreLevel}/EnergyL2.txt
    l2size=128    
    printf '%s'"$stringSize" >> ${CoreLevel}/PowerDynamic.txt
    printf '%s'"$stringSize" >> ${CoreLevel}/EnergyDynamic.txt
    printf '%s'"$stringSize" >> ${CoreLevel}/PowerStatic.txt
    printf '%s'"$stringSize" >> ${CoreLevel}/EnergyL1.txt
    printf '%s'"$stringSize" >> ${CoreLevel}/EnergyL2.txt
   
    for L2Level in  ${CoreLevel}/*
    do
          if [ -d "${L2Level}" ]; then
	      printf '\n' >> ${CoreLevel}/PowerDynamic.txt
              printf '\n' >> ${CoreLevel}/EnergyDynamic.txt
	      printf '\n' >> ${CoreLevel}/PowerStatic.txt
              printf '\n' >> ${CoreLevel}/EnergyL1.txt
              printf '\n' >> ${CoreLevel}/EnergyL2.txt
	      printf '%s' "$l2size" >> ${CoreLevel}/PowerDynamic.txt
	      printf '%s' "$l2size" >> ${CoreLevel}/EnergyDynamic.txt
	      printf '%s' "$l2size" >> ${CoreLevel}/PowerStatic.txt
	      printf '%s' "$l2size" >> ${CoreLevel}/EnergyL1.txt
	      printf '%s' "$l2size" >> ${CoreLevel}/EnergyL2.txt	     
              for L1Level in  ${L2Level}/*
	      do
		  sumL1=0;
		  sumL2=0;
	          if [ -d "${L1Level}" ]; then
			processor=$(awk '$1=="TotalProcessorRuntimeDynamic"{print $3}' ${L1Level}/power_stats.txt)
			if [ -n "$processor" ]; then
			    static=$(awk '$1=="TotalProcessorStatic"{print $3}' ${L1Level}/power_stats.txt)
			    cycle=$(awk '$1=="Final"{print $4}' ${L1Level}/results.txt)
			    time=$(echo "scale=10;$cycle/1000000000"|bc)
			    sumL1=$(grep L1TotalRuntimeDynamic ${L1Level}/power_stats.txt | awk '{sum += $3} END { printf ("%.9f", sum) }')
			    sumL2=$(grep L2TotalRuntimeDynamic ${L1Level}/power_stats.txt | awk '{sum += $3} END { printf ("%.9f", sum) }')
			    energy=$(echo "scale=6;$time*$processor" | bc -q | sed 's/^\./0./;s/0*$//;s/\.$//')
			    processor=$(echo "scale=6;$processor" | bc -q | sed 's/^\./0./;s/0*$//;s/\.$//')
			    l1energy=$(echo "scale=6;$time*$sumL1" | bc -q | sed 's/^\./0./;s/0*$//;s/\.$//')
			    l2energy=$(echo "scale=6;$time*$sumL2" | bc -q | sed 's/^\./0./;s/0*$//;s/\.$//')
			    printf '%s' ",$processor" >> ${CoreLevel}/PowerDynamic.txt
			    printf '%s' ",$energy" >> ${CoreLevel}/EnergyDynamic.txt
			    printf '%s' ",$static" >> ${CoreLevel}/PowerStatic.txt
			    printf '%s' ",$l1energy" >> ${CoreLevel}/EnergyL1.txt
			    printf '%s' ",$l2energy" >> ${CoreLevel}/EnergyL2.txt
			fi

	          fi
	      done
	   l2size=$(( $l2size * 2 ))
	fi
    done
    title="$1 $numcore core"
    sh ./plot.sh "$title" "${CoreLevel}"
    numcore=$(( $numcore * 4 ))
    fi
done

