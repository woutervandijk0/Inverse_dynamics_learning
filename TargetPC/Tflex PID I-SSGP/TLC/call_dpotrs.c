/*
* Wrapper for LAPACK/DPOTRS which solves a linear system A*X = B using Cholesky
* factorization of A.
* 
* Author: Wouter van Dijk
* Date: 16-5-2019
*/
#ifdef MATLAB_MEX_FILE
#include "tmwtypes.h"
#else
#include "rtwtypes.h"
#endif
#include <lapack.h>
//#include <string.h>

int_T call_dpotrs(real_T* A, real_T* B, real_T* X, int_T* D)
{
	mwSignedIndex n = {D}; 						   		   /* Number of rows */
	mwSignedIndex m = 1; 					    		/* Number of columns */
	mwSignedIndex info;						 /* Place to store error message */
	
	memcpy( X, B, m*n*sizeof(real_T));	 					  /* Copy B to X */
	dpotrs("U", &n, &m, A, &n, X, &n, &info);				 /* Solve system */
}