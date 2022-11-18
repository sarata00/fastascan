#!/bin/bash

#######################################################################
# Hi! Here is the code of the fastascan version 2.                    #
# Fastascan is a program that looks for fasta files in a given        #
# directory and gives you the following information:                  #
# file directory, whether the file is a symlink, how many sequences   #
# it has, the length of those sequences and the type of               #
# file (nucleotide or protein).                                       #
# In case it is a symlink, the number of sequences and length         #
# are not shown to avoid possible duplicates.                         #
#######################################################################

echo -e ">>>>>>>>>>> FASTASCAN V2 RESULTS <<<<<<<<<<<\n"

# Step 1. Make the script accept an optional argument
if [[ -e $1 ]];
then
    files=$(find $1 -type f,l -name "*.fa" -o -type f,l -name "*.fasta")
else 
    files=$(find . -type f,l -name "*.fa" -o -type f,l -name "*.fasta")
fi


# Step 2. In case there are no fasta files, we print a warning
# message and exit the script
if [[ -z $files ]]; then
    echo -e Oh...there is no fasta file here!. Please, check if this is the correct directory and try again.
    exit
fi
    

# Step 3. In case there are fasta files:
## Step 3a. We create a file to add the results
(echo -e File name'\t'Sequences'\t'Length'\t'Link'\t'Type) > table.tsv


## Step 3b. The content of $files variable are transformed into
## a list and we read each of the file with while loop

echo $files | sed 's/\s/\n/g' | while read i;
do
    ## Step 3c. In case of symlink file:
    if [[ -h $i ]]; then link="Yes"; seq="NA"; length="NA";
			 
    ## Step 3d. In case of not symlink file:
    elif [[ ! -h $i ]]; then link="No";
			     # number of sequences (-I: not take into account binary files)
			     seq=$(grep -I "^>" $i | wc -l)

			     # remove possible gaps and calculate the total length in each file
			     length=$((awk '!/>/{gsub(/-/, "", $0); print $0}' $i) | awk '{n+=length($0)} END {print n}')
			     
			     # if the file is empty or only contains title, give length 0 and type="Empty"
			     if [[ -z $length ]]; then length="0"; type="Empty"; fi
    fi

    ## Step 3e. Distinguish between protein and nucleotide sequences
    ## Add type="Unknown" in case it finds a different result
    
    if egrep -q '^[^>]' $i; then
	if egrep -q '^[Mm]' $i; then type="Protein";
	elif egrep -q '^[AaTtGgCcNn]' $i; then type="Nucleotide";
	else type="Unknown"; fi    
    fi
       
    ## Step 3f. Append the results to the table.tsv file
    (echo -e $i'\t'$seq'\t'$length'\t'$link'\t'$type) >> table.tsv
	   
done


# Step 4. Create the table to see the results more clear
column -t -s $'\t' table.tsv

## I add this warning in case an unknown file appears.
## In my case this file contained no sequence, just the titles
awk '$5~/Unknown/ {print "\nWarning: Its seems that some sequence(s) could not be distinguished between\n nucleotides or proteins, check the file(s)! Could it be that only contains the title(s)?"}' table.tsv
     
# Step 5. Show a random example
echo -e '\n' Here is a title from one of the fasta file:
grep -hI "^>" $files | shuf -n1      #(-h to remove the file directory)
echo

# Step 6. Give the total
echo -Total sequences: $(awk -F'\t' 'NR>1{x+=$2} END {print x}' table.tsv)
echo -Total length: $(awk -F'\t' 'NR>1{x+=$3} END {print x}' table.tsv)

## I delete the file table.tsv to avoid creating unnecessary files
## If you need your results in a table just delete this command!
rm table.tsv



	 
