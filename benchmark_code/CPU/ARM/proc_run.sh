#!/bin/bash
# export MKL_ROOT=/various/common_tools/intel_parallel_studio/compilers_and_libraries/linux/mkl
# export LD_LIBRARY_PATH=$MKL_ROOT/lib/intel64/:/home/users/nikela/local/papi/lib:$LD_LIBRARY_PATH

if [[ "$(whoami)" == 'xexdgala' ]]; then
    path_other='/zhome/academic/HLRS/xex/xexdgala/Data/graphs/other'
    path_athena='/zhome/academic/HLRS/xex/xexdgala/Data/graphs/matrices_athena'
    path_openFoam='/zhome/academic/HLRS/xex/xexdgala/Data/graphs/openFoam'
    path_selected='/zhome/academic/HLRS/xex/xexdgala/Data/graphs/selected_matrices'
    path_selected_sorted='/zhome/academic/HLRS/xex/xexdgala/Data/graphs/selected_matrices_sorted'
    path_validation='/zhome/academic/HLRS/xex/xexdgala/Data/graphs/validation_matrices'
    path_artificial='./artificial_matrix_generation/matrix_generation_parameters'

    path="$path_selected"

    cores='1 2 4 8 16 32 64 128'
    # cores='64'
    # cores='128'
    max_cores=128
    cpu_node_size=64
else
    path_other='/home/jim/Data/graphs/other'
    path_athena='/home/jim/Data/graphs/matrices_athena'
    path_selected='/home/jim/Data/graphs/selected_matrices'
    path_openFoam='/home/jim/Data/graphs/matrices_openFoam'
    path_selected_sorted='/home/jim/Data/graphs/selected_matrices_sorted'
    path_validation='/home/jim/Data/graphs/validation_matrices'
    path_artificial='./artificial_matrix_generation/matrix_generation_parameters'

    path="$path_selected"

    # cores='1'
    # cores='1 2 4 8'
    cores='8'
    max_cores=8
    cpu_node_size=4
fi

hyperthreading=0
# hyperthreading=1

if [[ $hyperthreading == 1 ]]; then
    max_cores=$((2*max_cores))
    cores="$cores $max_cores"
    cpu_node_size=$((2*cpu_node_size))
    export OMP_CPU_NODE_SIZE=$cpu_node_size
fi


# GOMP_CPU_AFFINITY pins the threads to specific cpus, even when assigning more cores than threads.
# e.g. with 'GOMP_CPU_AFFINITY=0,1,2,3' and 2 threads, the threads are pinned: t0->core0 and t1->core1.
# export GOMP_CPU_AFFINITY="0-$((max_cores-1))"
# export KMP_AFFINITY="granularity=fine,proclist=[0,1,2,3,4,5,6,7], explicit, verbose"
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

export LD_LIBRARY_PATH="${HOME}/Documents/gcc_current/lib64:/opt/hlrs/spack/current/papi/c048e224f-gcc-9.2.0-hxfnx7kt/lib:/opt/intel/oneapi/mkl/latest/lib/intel64:${LD_LIBRARY_PATH}"


# Encourages idle threads to spin rather than sleep.
# export OMP_WAIT_POLICY='active'
# Don't let the runtime deliver fewer threads than those we asked for.
# export OMP_DYNAMIC='false'

export OMP_CPU_NODE_SIZE=$cpu_node_size
export OMP_MAX_THREAD_GROUP_SIZE="1"

export OMP_HIERARCHICAL_STEALING='true'
# export OMP_HIERARCHICAL_STEALING='false'

export OMP_HIERARCHICAL_STEALING_SCORES='true'
# export OMP_HIERARCHICAL_STEALING_SCORES='false'

# export OMP_HIERARCHICAL_STEALING_CPU_NODE_LOCALITY_PASS='true'
export OMP_HIERARCHICAL_STEALING_CPU_NODE_LOCALITY_PASS='false'

# export OMP_HIERARCHICAL_STEALING_RANDOM='true'
export OMP_HIERARCHICAL_STEALING_RANDOM='false'

# export OMP_HIERARCHICAL_STATIC='true'
export OMP_HIERARCHICAL_STATIC='false'


interleaved=()
# interleaved=('numactl' '-i' 'all')


# amduprof_out='/zhome/academic/HLRS/xex/xexdgala/uprof_out.txt'
# amduprof_out='$HOME/uprof_out.txt'

# amduprof_exe='AMDuProfCLI'
amduprof_exe='/home/jim/Documents/Synced_Documents/apps/AMDuProf_Linux_x64_3.4.475/bin/AMDuProfCLI'

# amduprof=()
amduprof=($amduprof_exe timechart --event power --interval 100)

# amduprof output hawk:
#    /opt/hlrs/non-spack/performance/uprof/3.2.228/bin/AMDuProfCLI
#    ERROR: Power profiler not supported in the current configuration.


matrices_banded=(
    "$path_selected"/sparse_524288_banded_1.mtx
    "$path_selected"/sparse_524288_banded_2.mtx
    "$path_selected"/sparse_524288_banded_3.mtx
    "$path_selected"/sparse_8388608_banded_1.mtx
    "$path_selected"/sparse_8388608_banded_2.mtx
    "$path_selected"/sparse_8388608_banded_3.mtx
)

matrices_block_diagonal=(
    "$path_selected"/sparse_65536_block_diagonal_4.mtx
    "$path_selected"/sparse_65536_block_diagonal_16.mtx
    "$path_selected"/sparse_65536_block_diagonal_64.mtx
    "$path_selected"/sparse_2097152_block_diagonal_4.mtx
    "$path_selected"/sparse_2097152_block_diagonal_16.mtx
    "$path_selected"/sparse_2097152_block_diagonal_64.mtx
)

matrices_real=(
    "$path_selected"/dense_1024.mtx
    "$path_selected"/thermomech_dK.mtx
    "$path_selected"/xenon2.mtx
    "$path_selected"/ASIC_680k.mtx
    "$path_selected"/Si41Ge41H72.mtx
    "$path_selected"/dense_4096.mtx
    "$path_selected"/in-2004.mtx
    "$path_selected"/wikipedia-20051105.mtx
    "$path_selected"/circuit5M.mtx
    "$path_selected"/soc-LiveJournal1.mtx
    "$path_selected"/dielFilterV3real.mtx
)

matrices_openFoam=(
    "$path_openFoam"/100K.mtx
    "$path_openFoam"/600K.mtx
)

matrices_TI=(
    "${matrices_openFoam[@]}"
    "${matrices_real[@]}"
    "$path_other"/delaunay_n24.mtx
)

matrices_validation=(
    "$path_validation"/scircuit.sorted.mtx
    "$path_validation"/mac_econ_fwd500.sorted.mtx
    "$path_validation"/raefsky3.sorted.mtx
    "$path_validation"/bbmat.sorted.mtx
    "$path_validation"/conf5_4-8x8-15.real.mtx
    "$path_validation"/conf5_4-8x8-15.sorted.mtx
    "$path_validation"/mc2depi.real.mtx
    "$path_validation"/mc2depi.sorted.mtx
    "$path_validation"/rma10.sorted.mtx
    "$path_validation"/cop20k_A.sorted.mtx
    "$path_validation"/webbase-1M.sorted.mtx
    "$path_validation"/cant.sorted.mtx
    "$path_validation"/pdb1HYS.sorted.mtx
    "$path_validation"/TSOPF_RS_b300_c3.sorted.mtx
    "$path_validation"/Chebyshev4.sorted.mtx
    "$path_validation"/consph.sorted.mtx
    "$path_validation"/shipsec1.sorted.mtx
    "$path_validation"/PR02R.sorted.mtx
    "$path_validation"/mip1.sorted.mtx
    "$path_validation"/rail4284.real.mtx
    "$path_validation"/rail4284.sorted.mtx
    "$path_validation"/pwtk.sorted.mtx
    "$path_validation"/crankseg_2.sorted.mtx
    "$path_validation"/Si41Ge41H72.sorted.mtx
    "$path_validation"/TSOPF_RS_b2383.sorted.mtx
    "$path_validation"/in-2004.sorted.mtx
    "$path_validation"/Ga41As41H72.sorted.mtx
    "$path_validation"/eu-2005.sorted.mtx
    "$path_validation"/wikipedia-20051105.sorted.mtx
    "$path_validation"/rajat31.sorted.mtx
    "$path_validation"/ldoor.sorted.mtx
    "$path_validation"/circuit5M.sorted.mtx
    "$path_validation"/bone010.sorted.mtx
    "$path_validation"/cage15.sorted.mtx
)


matrices_selected_sorted=("$path_selected_sorted"/*.mtx)


matrices_all=("${matrices_banded[@]}" "${matrices_block_diagonal[@]}" "${matrices_real[@]}" "${matrices_openFoam[@]}")


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

        "${interleaved[@]}" "$prog" "$t" "${prog_args[@]}" >> 'tmp.out'

        cat tmp.out
        awk "${awk_cmd}" tmp.out
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

    "$path_openFoam"/100K.mtx
    # "$path_openFoam"/600K.mtx
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


artificial_matrices_file=(

)



use_artificial_matrices=0
# use_artificial_matrices=1


if ((!use_artificial_matrices)); then
    prog_args=("${matrices[@]}")
else
    prog_args=()
    tmp=()
    for f in "${artificial_matrices_files[@]}"; do
        IFS=$'\n' read -d '' -a tmp < "$f"
        prog_args+=("${tmp[@]}")
    done
    echo "number of matrices: ${#prog_args[@]}"
fi


progs=()
progs+=('./spmv_ell.exe')
# progs+=('./spmv_ldu.exe')
# progs+=('./spmv_sparse_mv.exe')
# progs+=('./spmv_csr_naive.exe')
# progs+=('./spmv_csr_custom.exe')
# progs+=('./spmv_csr_custom_vector.exe')
# progs+=('./spmv_csr.exe')
# progs+=('./spmv_dia.exe')
# progs+=('./spmv_dia_custom.exe')
# progs+=('./spmv_bsr_4.exe')
# progs+=('./spmv_bsr_2.exe' './spmv_bsr_4.exe' './spmv_bsr_8.exe' './spmv_bsr_16.exe')
# progs+=('./spmv_bsr_2.exe' './spmv_bsr_4.exe' './spmv_bsr_8.exe' './spmv_bsr_16.exe' './spmv_bsr_32.exe' './spmv_bsr_64.exe')
# progs+=('./spmv_coo.exe')
# progs+=('../Benchmark_SpMV_using_CSR5/CSR5_avx2/spmv')


for p in "${progs[@]}"; do

    # declare base file_out
    # base="${p/*\//}"
    # base="${base%%.*}"
    # file_out="out_${base}.out"
    # > "$file_out"
    # exec 1>>"$file_out"

    echo "program: $p"

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

