#!/bin/bash -l

# ------------------------------------------------------------------------------
# Script Name            : HIT-array.sh
# Description            : Run HIT index on a list of input .bam files
# Author                 : Edward C. Ruiz
# Email                  : ecruiz@bu.edu
# Date                   : August 6, 2022
# ------------------------------------------------------------------------------
#$ -P hybrids            # Set SCC project to charge
#$ -pe omp 8             # Request compute
#$ -l h_rt=72:00:00      # Specify hard time limit for the job
#$ -N HIT-roi-expansion  # Name job
#$ -j y                  # Join error and output streams in one file
#$ -t 1-237              # Submit an array job with 1-n tasks. 
# ------------------------------------------------------------------------------

# Load python venv used for hit index
source /restricted/projectnb/hybrids/hit_index/env/bin/activate

# Load necessary modules
module load samtools bedtools star

# Keep track of information related to the current job
echo "# -------------------------------------------------"
echo "Start date : $(date)"
echo "Job name : $JOB_NAME"
echo "Job ID : $JOB_ID  $SGE_TASK_ID"
echo "# -------------------------------------------------"

# ------------------------------------------------------------------------------
# Parse flag inputs
# ------------------------------------------------------------------------------

while getopts 'a:1:2:o:m:l:r:' OPTION; do
  case "$OPTION" in
     a)
      bam_dir="$OPTARG"
      input_bam_files=($(cat $bam_dir/"all_roi_bam.txt"))
      bam_file="${input_bam_files[$SGE_TASK_ID - 1]}"
      bam_filename=$(basename $bam_file .bam)
      echo "The /path/to/filtered_bam containing all_roi_bam.txt is $OPTARG"
      ;;
    1)
      read_type="$OPTARG"
      echo "The read type is $OPTARG"
      ;;
    2)
      read_strand="$OPTARG"
      echo "The read strand is $OPTARG"
      ;;
    o)
      out_dir="$OPTARG"
      echo "The /path/to/output/dir is $OPTARG"
      ;;
    m)
      metaexon_file="$OPTARG"
      echo "The /path/to/metaexon_file is $OPTARG"
      ;;
    l)
      overlap_in="$OPTARG"
      echo "The overlap is $OPTARG"
      ;;
    r)
      readnum_in="$OPTARG"
      echo "The readnum is $OPTARG"
      ;;
    ?)
      echo "Please review script usage: $(basename $0)"
      echo "[-a /path/to/filtered_bam containing all_roi_bam.txt]"
      echo "[-1 read type]"
      echo "[-2 read strand]"
      echo "[-o /path/to/output/dir]"
      echo "[-m /path/to/metaxon_file]" 
      >&2
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

# Define HIT pipeline variables
# out_dir=/restricted/projectnb/hybrids/ecruiz/StereoSeq/run6_fov_E14.5_E1S3/mod
# bam_dir=/restricted/projectnb/hybrids/ecruiz/StereoSeq/E14.5_E1S3/00.mapping
# input_bam_files=(filtered_1000_E100028588_L01_read_1.Aligned.sortedByCoord.out.bam filtered_5000_E100028588_L01_read_1.Aligned.sortedByCoord.out.bam filtered_2000_E14.5_E1S3.Aligned.sortedByCoord.out.bam filtered_E100028512_L01_read_1.Aligned.sortedByCoord.out.bam)
# bam_file="${input_bam_files[$SGE_TASK_ID - 1]}"
# bam_filename=$(basename $bam_file .bam)
# read_type=single
# read_strand=fr-firststrand
# metaexon_file=/projectnb/rd-spat/HOME/ecruiz/StereoSeq/Reference/Specie/mouse/index_star2.7.9a/metaexons.bed_ss3-50ss5-20-noMT.buffer

# ------------------------------------------------------------------------------
# Map junction reads
# ------------------------------------------------------------------------------

python /restricted/projectnb/hybrids/HITindex/HITindex_classify.py \
  --junctionReads \
  --bam $bam_dir/$bam_file \
  --juncbam $out_dir/"junction_"$bam_filename"_"$read_type"_"$read_strand.bam \
  --readtype $read_type \
  --readstrand $read_strand \

# ------------------------------------------------------------------------------
# Compute HIT scores
# ------------------------------------------------------------------------------

python /restricted/projectnb/hybrids/HITindex/HITindex_classify.py \
  --HITindex \
  --juncbam $out_dir/"junction_"$bam_filename"_"$read_type"_"$read_strand.bam \
  --readtype $read_type \
  --readstrand $read_strand \
  --bed $metaexon_file \
  --overlap $overlap_in \
  --readnum $readnum_in \
  --outname $out_dir/$bam_filename"_outputHITindex"

# python /restricted/projectnb/hybrids/HITindex/HITindex_classify.py \
#   --classify \
#   --metrics $out_dir/$bam_filename"_outputHITindex.exon" \
#   --parameters /restricted/projectnb/hybrids/ecruiz/HIT_identity_parameters_mod.txt \
