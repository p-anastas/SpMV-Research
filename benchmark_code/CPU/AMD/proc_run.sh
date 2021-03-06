#!/bin/bash

source config.sh
echo

if [[ "$(whoami)" == 'xexdgala' ]]; then
    path_other='/zhome/academic/HLRS/xex/xexdgala/Data/graphs/other'
    path_athena='/zhome/academic/HLRS/xex/xexdgala/Data/graphs/matrices_athena'
    path_selected='/zhome/academic/HLRS/xex/xexdgala/Data/graphs/selected_matrices'
    path_selected_sorted='/zhome/academic/HLRS/xex/xexdgala/Data/graphs/selected_matrices_sorted'
else
    path_other='/home/jim/Data/graphs/other'
    path_athena='/home/jim/Data/graphs/matrices_athena'
    path_selected='/home/jim/Data/graphs/selected_matrices'
    path_selected_sorted='/home/jim/Data/graphs/selected_matrices_sorted'
fi


if [[ $hyperthreading == 1 ]]; then
    max_cores=$((2*max_cores))
    cores="$cores $max_cores"
fi

# GOMP_CPU_AFFINITY pins the threads to specific cpus, even when assigning more cores than threads.
# e.g. with 'GOMP_CPU_AFFINITY=0,1,2,3' and 2 threads, the threads are pinned: t0->core0 and t1->core1.
if [[ $hyperthreading == 1 ]]; then
    affinity=''
    for ((i=0;i<max_cores/2;i++)); do
        affinity="$affinity,$i,$((i,max_cores/2+i))"
    done
    affinity="${affinity:1}"
    export GOMP_CPU_AFFINITY="$affinity"
    printf "cpu affinities: %s\n" "$affinity"
else
    export GOMP_CPU_AFFINITY="0-$((max_cores-1))"
fi

export MKL_DEBUG_CPU_TYPE=5
export LD_LIBRARY_PATH="${MKL_PATH}/lib/intel64:${LD_LIBRARY_PATH}"

# Encourages idle threads to spin rather than sleep.
# export OMP_WAIT_POLICY='active'
# Don't let the runtime deliver fewer threads than those we asked for.
# export OMP_DYNAMIC='false'

matrices_openFoam=("$path_openFoam"/*.mtx)

matrices_openFoam_own_neigh=( "$path_openFoam"/TestMatrices/*/*/* )

matrices_validation=(
    "$path_validation"/scircuit.mtx
    "$path_validation"/mac_econ_fwd500.mtx
    "$path_validation"/raefsky3.mtx
    "$path_validation"/bbmat.mtx
    "$path_validation"/conf5_4-8x8-15.mtx
    "$path_validation"/mc2depi.mtx
    "$path_validation"/rma10.mtx
    "$path_validation"/cop20k_A.mtx
    "$path_validation"/webbase-1M.mtx
    "$path_validation"/cant.mtx
    "$path_validation"/pdb1HYS.mtx
    "$path_validation"/TSOPF_RS_b300_c3.mtx
    "$path_validation"/Chebyshev4.mtx
    "$path_validation"/consph.mtx
    "$path_validation"/shipsec1.mtx
    "$path_validation"/PR02R.mtx
    "$path_validation"/mip1.mtx
    "$path_validation"/rail4284.mtx
    "$path_validation"/pwtk.mtx
    "$path_validation"/crankseg_2.mtx
    "$path_validation"/Si41Ge41H72.mtx
    "$path_validation"/TSOPF_RS_b2383.mtx
    "$path_validation"/in-2004.mtx
    "$path_validation"/Ga41As41H72.mtx
    "$path_validation"/eu-2005.mtx
    "$path_validation"/wikipedia-20051105.mtx
    "$path_validation"/ldoor.mtx
    "$path_validation"/circuit5M.mtx
    "$path_validation"/bone010.mtx
    "$path_validation"/cage15.mtx
)


declare -i count_procs
count_procs=0

trap 'count_procs+=1' USR1


awk_cmd='
BEGIN {
    num_procs = 0
    time_max = 0.0
}

/^pnum_/ {
    split($0, tok, ",")
    file = tok[2]
    num_procs = tok[3]
    m = tok[4]
    n = tok[5]
    nnz = tok[6]
    time = tok[7]
    gflops = tok[8]
    mem = tok[9]

    if (time > time_max)
        time_max = time
}

END {
    gflops = (time_max > 0) ? (nnz * num_procs) / time_max * 128 * 2 * 1e-9 : 0

    printf("%s", file)
    printf(",%d", num_procs)
    printf(",%d", m)
    printf(",%d", n)
    printf(",%d", nnz)
    printf(",%g", time_max)
    printf(",%g", gflops)
    printf(",%g", mem)
    printf("\n")
}
'

bench()
{
    declare args=("$@")
    declare prog="${args[0]}"
    declare prog_args=("${args[@]:1}")
    declare t

    export OMP_NUM_THREADS="1"
    for t in $cores
    do
        pids=()
        count_procs=0
        > tmp.out

        "$prog" "$t" "${prog_args[@]}" 2>> 'tmp.out'

        cat tmp.out
        awk "${awk_cmd}" tmp.out 1>&2
        # echo "num_processes $t"
        # echo "$out"
    done
}


matrices=(
    # "${matrices_all[@]}"
    # "${matrices_real[@]}"
    # "${matrices_banded[@]}"
    # "${matrices_block_diagonal[@]}"
    # "${matrices_openFoam[@]}"
    # "${matrices_TI[@]}"
    # "${matrices_selected_sorted[@]}"
    # "${matrices_validation[@]}"

    # /home/jim/Documents/Synced_Documents/other/ASIC_680k.mtx

    # "$path_openFoam"/100K.mtx
    # "$path_openFoam"/600K.mtx
    # "$path_openFoam"/TestMatrices/HEXmats/5krows/processor0
    "${matrices_openFoam_own_neigh[@]}"

    # "$path_selected"/thermomech_dK.mtx
    # "$path_selected"/ASIC_680k.mtx
    # "$path_selected"/xenon2.mtx
    # "$path_selected"/Si41Ge41H72.mtx
    # "$path_selected"/dense_1024.mtx 
    # "$path_selected"/dense_4096.mtx
    # "$path_selected"/in-2004.mtx
    # "$path_selected"/wikipedia-20051105.mtx
    # "$path_selected"/circuit5M.mtx
    # "$path_selected"/soc-LiveJournal1.mtx
    # "$path_selected"/dielFilterV3real.mtx

    # "$path_selected"/soc-LiveJournal1.mtx
    # "$path_selected"/soc-LiveJournal1_sorted_1.mtx
    # "$path_selected"/soc-LiveJournal1_sorted_2.mtx
    # "$path_selected"/soc-LiveJournal1_sorted_3.mtx
    # "$path_selected"/soc-LiveJournal1_sorted_4.mtx

    # "$path_selected"/dielFilterV3real.mtx
    # "$path_selected"/dielFilterV3real_sorted_1.mtx
    # "$path_selected"/dielFilterV3real_sorted_2.mtx
    # "$path_selected"/dielFilterV3real_sorted_3.mtx
    # "$path_selected"/dielFilterV3real_sorted_4.mtx

    # "$path_selected"/circuit5M.mtx
    # "$path_selected"/circuit5M_sorted_1.mtx
    # "$path_selected"/circuit5M_sorted_2.mtx
    # "$path_selected"/circuit5M_sorted_3.mtx
    # "$path_selected"/circuit5M_sorted_4.mtx

    # "$path_selected"/wikipedia-20051105.mtx
    # "$path_selected"/wikipedia-20051105_sorted_1.mtx
    # "$path_selected"/wikipedia-20051105_sorted_2.mtx
    # "$path_selected"/wikipedia-20051105_sorted_3.mtx
    # "$path_selected"/wikipedia-20051105_sorted_4.mtx

)


if ((!use_artificial_matrices)); then
    prog_args=("${matrices[@]}")
else
    prog_args=()
    tmp=()
    for f in "${artificial_matrices_files[@]}"; do
        IFS=$'\n' read -d '' -a tmp < "$f"
        prog_args+=("${tmp[@]}")
    done
fi


for tuple in "${progs[@]}"; do

    tuple=($tuple)
    p="${tuple[0]}"
    format_name="${tuple[1]}"

    # declare base file_out
    # base="${p/*\//}"
    # base="${base%%.*}"
    # file_out="out_${base}.out"
    # > "$file_out"
    # exec 1>>"$file_out"

    > "${format_name}.out"
    exec 1>>"${format_name}.out"
    > "${format_name}.err"
    exec 2>>"${format_name}.err"

    echo "program: $p"
    echo "number of matrices: ${#prog_args[@]}"

    for a in "${prog_args[@]}"
    do
        if ((use_artificial_matrices)); then
            echo "File: $a"
            bench $p $a
        else
            echo "File: $a"
            bench $p "$a"
        fi
    done
done

