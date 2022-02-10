#!/bin/bash

# TODO: Define thse variables for your system
MASTEDIR=/home/users/panastas/PhD_stuff/SpMV-Research
BUILD_DIR_9=$MASTEDIR/Wrapper_cuSPARSE-9/silver1_build
BUILD_DIR_11=$MASTEDIR/Wrapper_cuSPARSE-11/silver1_build
BUILD_DIR_CSR5=$MASTEDIR/CSR5_cuda/PETROS_wrap_operator/silver1_build

STORE_TIMER_DIR=$MASTEDIR/Benchmarks

cd build_runtrash

#MPAKOSDIR=/various/pmpakos/artificial_matrix_generation/matrix_generation_parameters/double/small
MPAKOSDIR=${MASTEDIR}/matrix_generation_parameters
for rep in 1 2 3 4 5
do
	for dtype in D #S
	do
		for filename in `cat ${MASTEDIR}/dataset_sorted_run_order_continue.in`;
		do
			cat $MPAKOSDIR/$filename | while read line
			do
				#printf "$line "
				# also available: $BUILD_DIR_9/cuSPARSEXbsrmv_9-2_mtx $BUILD_DIR_9/cuSPARSE${dtype}csrmv_9-2_generate
				for exec in $BUILD_DIR_9/cuSPARSE${dtype}hybmv_9-2_generate $BUILD_DIR_11/cuSPARSE${dtype}csrmv_11-0_generate $BUILD_DIR_11/cuSPARSE${dtype}coomv_11-0_generate $BUILD_DIR_CSR5/CSR5_CUDA_${dtype}SPMV_9-2_generate 
				do
					$exec $STORE_TIMER_DIR/silver1-TeslaV100_dtype-${dtype}_run_full_dataset.csv $line &>>$STORE_TIMER_DIR/silver1-TeslaV100_dtype-${dtype}_run_full_dataset.err
				done
			done
		done
	done
done

