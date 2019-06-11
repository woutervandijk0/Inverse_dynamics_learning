/* solve_linSystem - solve a linear system A*X = B using LAPACK/DPOTRS.
 *
 */

#include "mex.h"
#include <string.h>

#ifdef MEX_INFORMATION_VERSION             /* now we are compiling for Matlab */
  #if defined(_WIN64)
    #define integer  long long
  #else
    #define integer  long
  #endif
  #define doublereal double
#endif

#if !defined(_WIN32) || !defined(MEX_INFORMATION_VERSION) /* not Win32/Matlab */
  #define dgesv dgesv_
#endif

extern void dgesv_(integer *, integer *, doublereal *, integer *, integer *, 
                                            doublereal *, integer *, integer *);  


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{                                        /* Matlab call: X = solve_chol(A, B) */
  doublereal *C, *A;
  integer n, m, info, *ipiv;
  
  if (nrhs != 2 || nlhs > 1)                                   /* check input */
    mexErrMsgTxt("Usage: X = solve_linSystem(A, B)");
  n = mxGetM(prhs[0]);                    /* number of rows in inputs A and B */
  if (n != mxGetN(prhs[0]))
    mexErrMsgTxt("First argument matrix must be square.");
  if (n != mxGetM(prhs[1]))
    mexErrMsgTxt("Both argument matrices must have the same number of rows.");
  m = mxGetN(prhs[1]);                  /* number of colums in second input B */
  
  ipiv = (integer*) malloc(n * sizeof(integer));		   /* allocate memory */
  A    = (doublereal*) malloc(n * n *sizeof(doublereal));  /* allocate memory */
  
  plhs[0] = mxCreateDoubleMatrix(n, m, mxREAL);         /* space for output X */
  C = mxGetPr(plhs[0]);

  if (n == 0) return;             /* if argument was empty matrix, do no more */
  memcpy( A, mxGetPr(prhs[0]), n*n*mxGetElementSize(plhs[0]) );  /* copy data */
  memcpy( C, mxGetPr(prhs[1]), m*n*mxGetElementSize(plhs[0]) );  /* copy data */
  
  dgesv(&n, &m, A, &n, ipiv, C, &n, &info);
  
  if( info > 0 ) {
                printf( "The diagonal element of the triangular factor of A,\n" );
                printf( "U(%i,%i) is zero, so that A is singular;\n", info, info );
                printf( "the solution could not be computed.\n" );
				mexErrMsgTxt( "The solution could not be computed.\n");
        }
  if( info < 0) {
				printf( " The %i-th argument had an illegal value.\n",-info);
				mexErrMsgTxt( "The solution could not be computed.\n");
		}
}
