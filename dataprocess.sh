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
	testCount=$(( $testCount + 1 ))

	#for each number of cores(1core, 4core, 16core)
	for CoreLevel in ${Tests}/*
	do
	  if [ -d "${CoreLevel}" ]; then
	    path="plots/${CoreLevel##*/}/${Tests##*/}" #path to the plots
	    avpath="plots/${CoreLevel##*/}/average/"   #path to the average plots
	    l2size=128
	    
	    #remove old statistics
	    rm ${path}/PowerDynamic.txt
	    rm ${path}/EnergyDynamic.txt
	    rm ${path}/PowerStatic.txt
	    rm ${path}/EnergyL1.txt
	    rm ${path}/EnergyL2.txt
	    
	    printf '%s'"$stringSize" >> ${path}/PowerDynamic.txt
	    printf '%s'"$stringSize" >> ${path}/EnergyDynamic.txt
	    printf '%s'"$stringSize" >> ${path}/PowerStatic.txt
	    printf '%s'"$stringSize" >> ${path}/EnergyL1.txt
	    printf '%s'"$stringSize" >> ${path}/EnergyL2.txt
	  
	    #for each size of L2
	    for L2Level in  ${CoreLevel}/*
	    do
		  if [ -d "${L2Level}" ]; then

		      column=2
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
				    
				    #compute the average fo all the tests. The first values can be copies directly from the first test.
				    if [ $first != "0" ]; then
				        #search for: Column1: Matches the actual L2Size, then print the column that we are dealing with (L1Size)  
					pickP=$(awk -v s="$l2size" -v c="1" -v r="$column" '$c == s { print $r }' $avpath/PowerDynamic.txt)
					pickE=$(awk -v s="$l2size" -v c="1" -v r="$column" '$c == s { print $r }' $avpath/EnergyDynamic.txt)
					
					#sum the aggregate sum in the file average with the number of this test.
					sumP=$(echo "scale=6;$pickP+$processor" | bc -q | sed 's/^\./0./;s/0*$//;s/\.$//')
					sumE=$(echo "scale=6;$pickE+$energy" | bc -q | sed 's/^\./0./;s/0*$//;s/\.$//')
					
					#the last test, we have to divide the total sum for the total number of tests.
					if [ $testCount = $testNum ]; then
					   	sumP=$(echo "scale=6;$sumP/$testCount" | bc)
						sumE=$(echo "scale=6;$sumP/$testCount" | bc)
					fi

					#write in the file the row/column which has been modified. Ugly trick to substitute the folder.
					awk -v s="$l2size" -v c="1" -v r="$column" -v result="$sumP" '$c == s {$r = result}1' $avpath/PowerDynamic.txt > tmp && mv tmp $avpath/PowerDynamic.txt
				    fi
			            column=$(( $column + 1 ))
				fi
			  fi
		      done
		  l2size=$(( $l2size * 2 ))
		fi
	    done
	    #If it is the first test, we can copy the values to the average folder.
	    if [ $first = "0" ]; then
		  cp ${path}/PowerDynamic.txt $avpath
		  cp ${path}/EnergyDynamic.txt $avpath
	    fi
 
	    #set the title of the plot, compose by "Name of the test" and the number of cores
	    title="${Tests##*/} $numcore core"

	    #call the script to generate the plots
	    sh ./plot.sh "$title" "$path"

	    numcore=$(( $numcore * 4 ))
	    fi
	done
    first=1
done

