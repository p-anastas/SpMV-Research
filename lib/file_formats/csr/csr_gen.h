#if !defined(CSR_GEN_TYPE_1)
	#error "CSR_GEN_TYPE_1 not defined: value type"
#elif !defined(CSR_GEN_TYPE_2)
	#error "CSR_GEN_TYPE_2 not defined: index type"
#elif !defined(CSR_GEN_SUFFIX)
	#error "CSR_GEN_SUFFIX not defined"
#endif

#include <stdlib.h>
#include <stdio.h>
#include <omp.h>
#include <math.h>

#include "macros/macrolib.h"


#ifndef CSR_GEN_H
#define CSR_GEN_H
#endif /* CSR_GEN_H */


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//------------------------------------------------------------------------------------------------------------------------------------------
//-                                                              Templates                                                                 -
//------------------------------------------------------------------------------------------------------------------------------------------
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#define CSR_GEN_EXPAND(name)  CONCAT(name, CSR_GEN_SUFFIX)

#undef  _TYPE_V
#define _TYPE_V  CSR_GEN_EXPAND(_TYPE_V)
typedef CSR_GEN_TYPE_1  _TYPE_V;

#undef  _TYPE_I
#define _TYPE_I  CSR_GEN_EXPAND(_TYPE_I)
typedef CSR_GEN_TYPE_2  _TYPE_I;


#undef  coo_to_csr
#define coo_to_csr  CSR_GEN_EXPAND(coo_to_csr)
void coo_to_csr(_TYPE_I * R, _TYPE_I * C, _TYPE_V * V, long m, long n, long nnz, _TYPE_I * row_ptr, _TYPE_I * col_idx, _TYPE_V * val, int sort_columns);

#undef  coo_to_csr_fully_sorted
#define coo_to_csr_fully_sorted  CSR_GEN_EXPAND(coo_to_csr_fully_sorted)
void coo_to_csr_fully_sorted(_TYPE_I * R, _TYPE_I * C, _TYPE_V * V, long m, long n, long nnz, _TYPE_I * row_ptr, _TYPE_I * col_idx, _TYPE_V * val);

