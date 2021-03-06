#include "functools_gen.h"


#ifndef FUNCTOOLS_GEN_C
#define FUNCTOOLS_GEN_C

#endif /* FUNCTOOLS_GEN_C */


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//------------------------------------------------------------------------------------------------------------------------------------------
//-                                                              Templates                                                                 -
//------------------------------------------------------------------------------------------------------------------------------------------
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#undef  _TYPE
#define _TYPE  FUNCTOOLS_GEN_EXPAND(_TYPE)
typedef FUNCTOOLS_GEN_TYPE_1  _TYPE;


//==========================================================================================================================================
//= User Functions Declarations
//==========================================================================================================================================


#undef reduce_fun
#define reduce_fun  FUNCTOOLS_GEN_EXPAND(reduce_fun)
static void reduce_fun(_TYPE * partial_result, _TYPE * x);

#undef set_value
#define set_value  FUNCTOOLS_GEN_EXPAND(set_value)
static void set_value(_TYPE * x, _TYPE val);


//==========================================================================================================================================
//= Generic Code
//==========================================================================================================================================


#undef reduce
#define reduce  FUNCTOOLS_GEN_EXPAND(reduce)
_TYPE
reduce(_TYPE * A, long N, _TYPE zero)
{
	int num_threads = omp_get_max_threads();
	_TYPE t_partial[num_threads];
	_TYPE total;
	long i;
	#pragma omp parallel
	{
		int tnum = omp_get_thread_num();
		_TYPE partial;
		long i;
		set_value(&partial, zero);
		#pragma omp for
		for (i=0;i<N;i++)
			reduce_fun(&partial, &(A[i]));
		set_value(&(t_partial[tnum]), partial);
	}
	__atomic_thread_fence(__ATOMIC_SEQ_CST);
	set_value(&total, zero);
	for (i=0;i<num_threads;i++)
		reduce_fun(&total, &t_partial[i]);
	return total;
}


/*
 * start_from_zero:  First element of P is zero, else it is the first element of A.
 *
 * Notes:
 *     - P could also be A, so we should save/use A[i] before setting P[i].
 */

#undef scan_serial
#define scan_serial  FUNCTOOLS_GEN_EXPAND(scan_serial)
_TYPE
scan_serial(_TYPE * A, _TYPE * P, long N, _TYPE init, int start_from_zero)
{
	_TYPE partial;
	_TYPE tmp;
	long i;
	set_value(&partial, init);
	if (start_from_zero)
		for (i=0;i<N;i++)
		{
			set_value(&tmp, A[i]);
			set_value(&(P[i]), partial);
			reduce_fun(&partial, &tmp);
		}
	else
		for (i=0;i<N;i++)
		{
			reduce_fun(&partial, &(A[i]));
			set_value(&(P[i]), partial);
		}
	return partial;
}


#undef scan
#define scan  FUNCTOOLS_GEN_EXPAND(scan)
_TYPE
scan(_TYPE * A, _TYPE * P, long N, _TYPE zero, int start_from_zero)
{
	int num_threads = omp_get_max_threads();
	_TYPE t_base[num_threads];
	_TYPE total;

	#pragma omp parallel
	{
		int tnum = omp_get_thread_num();
		_TYPE partial;
		_TYPE tmp;
		long i_s, i_e;
		long i;

		loop_partitioner_balance_iterations(num_threads, tnum, 0, N, &i_s, &i_e);

		set_value(&partial, zero);
		for (i=i_s;i<i_e;i++)
			reduce_fun(&partial, &(A[i]));

		set_value(&(t_base[tnum]), partial);

		#pragma omp barrier
		__atomic_thread_fence(__ATOMIC_SEQ_CST);

		set_value(&partial, zero);
		#pragma omp single
		{
			for (i=0;i<num_threads;i++)
			{
				set_value(&tmp, t_base[i]);
				set_value(&(t_base[i]), partial);
				reduce_fun(&partial, &tmp);
			}
			set_value(&total, partial);
		}

		#pragma omp barrier
		__atomic_thread_fence(__ATOMIC_SEQ_CST);

		scan_serial(&A[i_s], &P[i_s], i_e-i_s, t_base[tnum], start_from_zero);
	}

	return total;
}

