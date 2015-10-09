#! /bin/sh

stringSize="  2 4 8 16 32 64 128"
#stringSize=",1024,2048,4096,8192,16384,32768,65536,131072"

#In order to know, the first test
first=0

#The number of tests
testNum=$(find ~/code/results -maxdepth 1 -type d | wc -l) 
testNum=$(( $testNum - 1 ))
testCount=0

echo "Generating plots..."

#for each test in the folder results (swaptions, blackscholes..)
for Tests in results/*
do
	echo "Generating plots of ${Tests##*/}"
	numcore=1	

	#for each number of cores(1core, 4core, 16core)
	for CoreLevel in ${Tests}/*
	do
	  if [ -d "${CoreLevel}" ]; then
	    path="plots/${CoreLevel##*/}/${Tests##*/}" #path to the plots
	    avpath="plots/${CoreLevel##*/}/average/"   #path to the average plots
	    l2size=128

	    temppath="plots/calculs/${CoreLevel##*/}/${Tests##*/}/" #Path to a directory in order to calculate std.
 	    calcpath="plots/calculs/${CoreLevel##*/}/"

	    if [ $first = "0" ]; then
	  	rm ${calcpath}/Energy.txt
	  	rm ${calcpath}/Power.txt
	    fi	
	    #remove old statistics
	    rm ${path}/PowerDynamic.txt
	    rm ${path}/EnergyDynamic.txt
	    rm ${path}/PowerStatic.txt
	    rm ${path}/EnergyL1.txt
	    rm ${path}/EnergyL2.txt

	    rm ${temppath}/Energy.txt

	    printf '%s'"$stringSize" >> ${path}/PowerDynamic.txt
	    printf '%s'"$stringSize" >> ${path}/EnergyDynamic.txt
	    printf '%s'"$stringSize" >> ${path}/PowerStatic.txt
	    printf '%s'"$stringSize" >> ${path}/EnergyL1.txt
	    printf '%s'"$stringSize" >> ${path}/EnergyL2.txt
	  
	    #for each size of L2
	    for L2Level in  ${CoreLevel}/*
	    do
		  if [ -d "${L2Level}" ]; then
		      printf '\n' >> ${path}/PowerDynamic.txt
		      printf '\n' >> ${path}/EnergyDynamic.txt
		      printf '\n' >> ${path}/PowerStatic.txt
		      printf '\n' >> ${path}/EnergyL1.txt
		      printf '\n' >> ${path}/EnergyL2.txt
		      printf '%s' "$l2size" >> ${path}/PowerDynamic.txt
		      printf '%s' "$l2size" >> ${path}/EnergyDynamic.txt
		      printf '%s' "$l2size" >> ${path}/PowerStatic.txt
		      printf '%s' "$l2size" >> ${path}/EnergyL1.txt
		      printf '%s' "$l2size" >> ${path}/EnergyL2.txt
		      
		      #for each size of L1
		      for L1Level in  ${L2Level}/*
		      do
			  sumL1=0;
			  sumL2=0;
			  if [ -d "${L1Level}" ]; then
				processor=$(awk '$1=="TotalProcessorRuntimeDynamic"{print $3}' ${L1Level}/power_stats.txt)
				if [ -n "$processor" ]; then


				    cycle=$(awk '$1=="Final"{print $4}' ${L1Level}/results.txt) #serach of the total number of cycles
				    time=$(echo "scale=10;$cycle/1000000000"|bc)                #compute the time, Texe = Cycles/Freq, the frequency is 1GHz
				    
				    sumL1=$(grep L1TotalRuntimeDynamic ${L1Level}/power_stats.txt | awk '{sum += $3} END { printf ("%.9f", sum) }') #trick to sum cientific numbers
				    sumL2=$(grep L2TotalRuntimeDynamic ${L1Level}/power_stats.txt | awk '{sum += $3} END { printf ("%.9f", sum) }') #trick to sum cientific numbers
				    
				    static=$(awk '$1=="TotalProcessorStatic"{print $3}' ${L1Level}/power_stats.txt)
				    processor=$(echo "scale=6;$processor" | bc -q | sed 's/^\./0./;s/0*$//;s/\.$//')    #op floats
				    energy=$(echo "scale=6;$time*$processor" | bc -q | sed 's/^\./0./;s/0*$//;s/\.$//') #op floats
				    l1energy=$(echo "scale=6;$time*$sumL1" | bc -q | sed 's/^\./0./;s/0*$//;s/\.$//')   #op floats
				    l2energy=$(echo "scale=6;$time*$sumL2" | bc -q | sed 's/^\./0./;s/0*$//;s/\.$//')   #op floats
				    
				    printf '%s' " $processor" >> ${path}/PowerDynamic.txt
				    printf '%s' " $energy" >> ${path}/EnergyDynamic.txt
				    printf '%s' " $static" >> ${path}/PowerStatic.txt
				    printf '%s' " $l1energy" >> ${path}/EnergyL1.txt
				    printf '%s' " $l2energy" >> ${path}/EnergyL2.txt

				    printf '%s' "$processor " >> ${calcpath}/Power.txt
				    printf '%s\n' "$energy" >> ${temppath}/Energy.txt
				fi
			  fi
		      done
		  l2size=$(( $l2size * 2 ))
		fi
	    done
	    printf '\n' >> ${calcpath}/Power.txt
	    if [ $first != "0" ]; then
            	paste -d' ' $temppath/Energy.txt $calcpath/Energy.txt > tmp && mv tmp $calcpath/Energy.txt
	    else
		cp ${temppath}/Energy.txt $calcpath
	    fi

	    #set the title of the plot, compose by "Name of the test" and the number of cores
	    title="${Tests##*/} $numcore core"

	    #call the script to generate the plots
	    #sh ./plot.sh "$title" "$path"

	    numcore=$(( $numcore * 4 ))
	    fi
	done
    first=1
done

numcore=1
calcpath="plots/calculs/a1Core/"
totalcolumns=$(cat $calcpath/Power.txt | awk '{ print NR}')
echo "$totalcolumns"
for Tests in plots/calculs/*
	do
	  if [ -f "${CoreLevel}" ]; then
		echo "a"
		#awk '{x+=$3;next}END{print x/NR}' data
		#awk '{ total += $2; count++ } END { print total/count }' file.txt 
	  fi
done

