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


matrices_validation_loop=()
for ((i=0;i<${#matrices_validation[@]};i++)); do
    path="${matrices_validation[i]}"
    dir="$(dirname "${path}")"
    filename="$(basename "${path}")"
    base="${filename%.*}"
    ext="${filename#${filename%.*}}"
    n=128
    for ((j=0;j<n;j++)); do
        matrices_validation_loop+=( "${matrices_validation_artificial_twins["$base"]}" )
    done
    matrices_validation_loop+=( "${matrices_validation[i]}" )
done
# printf "%s\n" "${matrices_validation_loop[@]}"
# exit

bench()
{
    declare args=("$@")
    declare prog="${args[0]}"
    declare prog_args=("${args[@]:1}")
    declare t

    for t in $cores
    do
        export OMP_NUM_THREADS="$t"
        # export MKL_NUM_THREADS="$t"

        if [ $prog = "./spmv_code_merge/spmv_merge.exe" ]; then
            if ((!use_artificial_matrices)); then
                "$prog" --mtx="${prog_args[@]}"
            else
                prog_args2="${prog_args[@]}"  # need to replace the original prog_args  spaces with \(space), in order to be read as a string between " " for --artif_args argument to work! (shit...)
                "$prog" --param="${prog_args2[@]}"
            fi
        else
            # "$prog" 4690000 4 1.6 normal random 1 14

            # numactl -i all "$prog" "${prog_args[@]}"
            "$prog" "${prog_args[@]}"
        fi
    done
}


matrices=(
    # "${matrices_openFoam[@]}"
    # "${matrices_validation[@]}"

    # "${matrices_validation_artificial_twins[@]}"
    # "${matrices_validation_loop[@]}"

    # "$path_other"/simple.mtx
    # "$path_other"/simple_symmetric.mtx

    # /home/jim/Documents/Synced_Documents/other/ASIC_680k.mtx

    # "$path_openFoam"/100K.mtx
    # "$path_openFoam"/600K.mtx
    # "$path_openFoam"/TestMatrices/HEXmats/5krows/processor0
    # "${matrices_openFoam_own_neigh[@]}"

    # "$path_validation"/scircuit.mtx
    # "$path_validation"/mac_econ_fwd500.mtx
    # "$path_validation"/raefsky3.mtx
    # "$path_validation"/bbmat.mtx
    # "$path_validation"/conf5_4-8x8-15.mtx
    # "$path_validation"/mc2depi.mtx
    # "$path_validation"/rma10.mtx
    # "$path_validation"/cop20k_A.mtx
    "$path_validation"/webbase-1M.mtx
    # "$path_validation"/cant.mtx
    # "$path_validation"/pdb1HYS.mtx
    # "$path_validation"/TSOPF_RS_b300_c3.mtx
    # "$path_validation"/Chebyshev4.mtx
    # "$path_validation"/consph.mtx
    # "$path_validation"/shipsec1.mtx
    # "$path_validation"/PR02R.mtx
    # "$path_validation"/mip1.mtx
    # "$path_validation"/rail4284.mtx
    # "$path_validation"/pwtk.mtx
    # "$path_validation"/crankseg_2.mtx
    # "$path_validation"/Si41Ge41H72.mtx
    # "$path_validation"/TSOPF_RS_b2383.mtx
    # "$path_validation"/in-2004.mtx
    # "$path_validation"/Ga41As41H72.mtx
    # "$path_validation"/eu-2005.mtx
    # "$path_validation"/wikipedia-20051105.mtx
    # "$path_validation"/ldoor.mtx
    # "$path_validation"/circuit5M.mtx
    # "$path_validation"/bone010.mtx
    # "$path_validation"/cage15.mtx

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

    # "$path_selected_sorted"/circuit5M.mtx
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

# prog_args=(

    # '28508159 28508159 5 1.6667 normal random 0.05 0 0.05 0.05 14'              # This bugs at 128 threads with mkl and mkl_sparse_set_mv_hint() for some reason.

    # '5154859 5154859 19.24389 5.73672 normal random 0.21196 1.44233 0.19755 1.03234 14'
    # '952203 952203 48.85772782 11.94657153 normal random 0.2042067138 0.5760045224 1.79674 0.906047 14 ldoor'
# )

temp_labels=( $(printf "%s\n" /sys/class/hwmon/hwmon*/temp*_label | sort) )
temp_inputs=( ${temp_labels[@]/label/input} )

for tuple in "${progs[@]}"; do

    tuple=($tuple)
    p="${tuple[0]}"
    format_name="${tuple[1]}"

    # declare base file_out file_err
    # base="${p/*\//}"
    # base="${base%%.*}"
    # file_out="out_${base}.out"
    # file_err="out_${base}.err"
    # > "$file_out"
    # > "$file_err"
    # exec 1>>"$file_out"
    # exec 2>>"$file_err"

    if ((output_to_files)); then
        > "${format_name}.out"
        exec 1>>"${format_name}.out"
        > "${format_name}.err"
        exec 2>>"${format_name}.err"
    fi

    echo "program: $p"
    echo "number of matrices: ${#prog_args[@]}"

    rep=1
    # rep=5
    # rep=16
    # rep=1024

    for ((i=0;i<rep;i++)); do
        for a in "${prog_args[@]}"
        do

            rep_in=1
            # rep_in=10

            for ((j=0;j<rep_in;j++)); do

                printf "Temps: " >&2
                for ((k=0;k<${#temp_labels[@]};k++)); do
                    printf "%s %s " $(cat ${temp_labels[k]}) $(cat ${temp_inputs[k]}) >&2
                done
                echo >&2

                echo "File: $a"
                bench $p $a

                # if ((use_artificial_matrices)); then
                    # echo "File: $a"
                    # bench $p $a
                # else
                    # echo "File: $a"
                    # bench $p "$a"
                # fi

            done
        done
    done
done

