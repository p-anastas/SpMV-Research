#if !defined(QUICKSORT_GEN_TYPE_1)
	#error "QUICKSORT_GEN_TYPE_1 not defined: value type"
#elif !defined(QUICKSORT_GEN_TYPE_2)
	#error "QUICKSORT_GEN_TYPE_2 not defined: index type"
#elif !defined(QUICKSORT_GEN_TYPE_3)
	#error "QUICKSORT_GEN_TYPE_3 not defined: auxiliary data value type"
#elif !defined(QUICKSORT_GEN_SUFFIX)
	#error "QUICKSORT_GEN_SUFFIX not defined"
#endif

#include <stdlib.h>
#include <stdio.h>

// #include "genlib.h"


#ifndef QUICKSORT_GEN_H
#define QUICKSORT_GEN_H

#endif /* QUICKSORT_GEN_H */


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//------------------------------------------------------------------------------------------------------------------------------------------
//-                                                              Templates                                                                 -
//------------------------------------------------------------------------------------------------------------------------------------------
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#define QUICKSORT_GEN_EXPAND(name)  CONCAT(name, QUICKSORT_GEN_SUFFIX)

#undef  _TYPE_V
#define _TYPE_V  QUICKSORT_GEN_EXPAND(_TYPE_V)
typedef QUICKSORT_GEN_TYPE_1  _TYPE_V;

#undef  _TYPE_I
#define _TYPE_I  QUICKSORT_GEN_EXPAND(_TYPE_I)
typedef QUICKSORT_GEN_TYPE_2  _TYPE_I;

#undef  _TYPE_AD
#define _TYPE_AD  QUICKSORT_GEN_EXPAND(_TYPE_AD)
typedef QUICKSORT_GEN_TYPE_3  _TYPE_AD;


#undef quicksort
#define quicksort  QUICKSORT_GEN_EXPAND(quicksort)
void quicksort(_TYPE_V * A, _TYPE_I N, _TYPE_AD * aux_data);

