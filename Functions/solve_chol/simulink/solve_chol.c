#define S_FUNCTION_NAME  solve_chol
#define S_FUNCTION_LEVEL 2

// Example: w = solve_chol(R,b);

/*
 * Need to include simstruc.h for the definition of the SimStruct and
 * its associated macro definitions.
 */ 

#include <string.h>
#include "simstruc.h"
#include <lapacke.h>

#if !defined(_WIN32) /* not Win32/Matlab */
  #define dpotrs dpotrs_
#endif
extern int_T dpotrs_(char *, int_T *, int_T *, real_T *, int_T *,
                                            real_T *, int_T *, int_T *);
/*=========*
 * Defines *
 *=========*/

//#define SIZE_IDX 50
//#define SIZE_PARAM(S) ssGetSFcnParam(S,SIZE_IDX)

#define NINPUTS  2
#define NOUTPUTS 1

static void mdlInitializeSizes(SimStruct *S)
{
    int_T needsInput   = 1;  /* direct feedthrough     */
	
	ssSetNumSFcnParams(S, 0);  /* Number of expected parameters */
    if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S)) {
        /*
         * If the number of expected input parameters is not
         * equal to the number of parameters entered in the 
         * dialog box, return. The Simulink engine generates an
         * error indicating that there is a parameter mismatch.
         */
        return;
	}
	
	ssSetNumContStates( S, 0);
    ssSetNumDiscStates( S, 0);
	
	if (!ssSetNumInputPorts(S, NINPUTS)) return;
	/* R: a dynamically sized 2-D matrix input */
	ssSetInputPortMatrixDimensions(S, 0, 50, 50);
    ssSetInputPortRequiredContiguous(S, 0, true); /*direct input signal access*/
    ssSetInputPortDirectFeedThrough(S, 0, 1);
	/* b: a dynamically sized 1-D matrix input */
	ssSetInputPortWidth(S, 0, 50);
    ssSetInputPortRequiredContiguous(S, 0, true); /*direct input signal access*/
    ssSetInputPortDirectFeedThrough(S, 0, 1);
	
	
	if (!ssSetNumOutputPorts(S, NOUTPUTS)) return;
	/* b: a dynamically sized 1-D matrix output */
    ssSetOutputPortWidth(S, 0, 50);
	
	/*
     * Set the number of sample times.     */
    ssSetNumSampleTimes(S, 1); 
	
	/* Inherit the sample time. */
	ssSetInputPortSampleTime(S, 0, INHERITED_SAMPLE_TIME);
	ssSetInputPortSampleTime(S, 1, INHERITED_SAMPLE_TIME);
}

/* Function: mdlInitializeSampleTimes =========================================
 * Abstract:
 *      Port based sample times have already been configured, therefore this
 *	method doesn't need to perform any action (you can check the
 *	current port sample times).
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
	ssSetSampleTime(S, 0, INHERITED_SAMPLE_TIME);
    ssSetOffsetTime(S, 0, 0.0);
    ssSetModelReferenceSampleTimeDefaultInheritance(S); /* Inherit sample time */
}


/* Function: mdlOutputs =======================================================
 * Abstract:
 *
 * solve_chol - solve a linear system A*X = B using the Cholesky factorization
 * of A (square, symmetric and positive definite) using LAPACK/DPOTRS.
 *
 */
static void mdlOutputs(SimStruct *S, int_T tid)
{
	int_T   *dims1   = ssGetInputPortDimensions(S, 0);
	int_T   *dims2   = ssGetInputPortDimensions(S, 1);
	int_T    n1      = dims1[0];	/* number of rows in inputs A*/
	int_T    m1      = dims1[1]; 	/* number of columns in inputs A*/
	int_T    n2      = dims2[0];	/* number of rows in inputs B*/
	int_T    m2      = dims2[1]; 	/* number of columns in inputs B*/
	int_T    q;
	real_T   *C 	= ssGetOutputPortSignal(S,0);
	real_T   *A  	= ssGetInputPortSignal(S,0);
    real_T   *B  	= ssGetInputPortSignal(S,1);
	
	UNUSED_ARG(tid); /* not used in single tasking mode */

	
	if (n1 != m1)
		mexErrMsgTxt("First argument matrix must be square.");
	
	if (n1 != n2)
		mexErrMsgTxt("Both argument matrices must have the same number of rows.");
	
	// C = mxCreateDoubleMatrix(n, m, mxREAL);         /* space for output X */

	if (n1 == 0) return;             /* if argument was empty matrix, do no more */
	//memcpy( C, mxGetPr(B), m*n*mxGetElementSize(C) );  /* copy data */
	dpotrs("U", &n1, &m2, mxGetPr(A), &n1, C, &n1, &q);       /* solve system */
	if (q < 0) mexErrMsgTxt("Error: illegal input to solve_chol");
	
}