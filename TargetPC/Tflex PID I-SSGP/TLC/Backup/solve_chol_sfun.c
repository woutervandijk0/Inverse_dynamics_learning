/* File    : solve_chol_sfun.c
 * Abstract:
 *
 * Solve a linear system A*X = B using Cholesky factorization
 * of A (square, symmetric and positive definite) using 
 * LAPACK/DPOTRS
 *
 * Cholesky factorization: A = U'U
 * Linear system is solved as:	Ly  = b 
 * 								L'x = y
 * using back-substitution.
 *
 * Author: Wouter van Dijk
 * Date:   15-5-2019
 * TODO:   Add more checks on NFEATURE_PARAM(S) in mdlCheckParameters
 */
 
#define S_FUNCTION_NAME  solve_chol_sfun
#define S_FUNCTION_LEVEL 2

#include "simstruc.h"
#include <string.h>
#include <lapack.h>

/* parameter: Number of Features */
#define NFEATURE_IDX 0
#define NFEATURE_PARAM(S) ssGetSFcnParam(S,NFEATURE_IDX)

#define NPARAMS 1

#define NINPUTS  2
#define NOUTPUTS 1

/*====================*
 * S-function methods *
 *====================*/

#define MDL_CHECK_PARAMETERS
#if defined(MDL_CHECK_PARAMETERS) && defined(MATLAB_MEX_FILE)
  /* Function: mdlCheckParameters =============================================
   * Abstract:
   *    Validate our parameters to verify they are okay.
   */
  static void mdlCheckParameters(SimStruct *S)
  {
      /* Check 1st parameter: Matrix Gain (K) parameter */
      if (mxGetPr(NFEATURE_PARAM(S))[0] <= 0){
		ssSetErrorStatus(S,"Negative number of features not allowed!");
      }
  }
#endif /* MDL_CHECK_PARAMETERS */


/* Function: mdlInitializeSizes ===============================================
 * Abstract:
 * 	-  Set dimension of inputport  0 to [D x D] (D is a parameter)
 *  -  Set dimension of inputport  1 to [D x 1]
 *  -  Set dimension of outputport 0 to [D x 1]
 */
static void mdlInitializeSizes(SimStruct *S)
{
	ssSetNumSFcnParams(S, NPARAMS);  		 /* Number of expected parameters */
#if defined(MATLAB_MEX_FILE)
    if (ssGetNumSFcnParams(S) == ssGetSFcnParamsCount(S)) {
        mdlCheckParameters(S);
        if (ssGetErrorStatus(S) != NULL) {
            return;
        }
    } else {
        return; /* Parameter mismatch will be reported by Simulink */
    }
#endif
    ssSetSFcnParamTunable(S,NFEATURE_IDX, false); // parameter is non tunable
	
	int_T D = (int_T)mxGetPr(NFEATURE_PARAM(S))[0]; 	/* Number of features */
	if (!ssSetNumInputPorts(S, NINPUTS)) return;
	/* A: a dynamically sized 2-D matrix input */
	ssSetInputPortMatrixDimensions(S, 0, D, D);   		    /* Set dimensions */
    ssSetInputPortRequiredContiguous(S, 0, true); /*direct input signal access*/
    ssSetInputPortDirectFeedThrough(S, 0, 1);
	
	/* B: a dynamically sized 1-D matrix input */
	ssSetInputPortMatrixDimensions(S, 1, D, 1);				/* Set dimensions */
    ssSetInputPortRequiredContiguous(S, 1, true); /*direct input signal access*/
    ssSetInputPortDirectFeedThrough(S, 1, 1);
	
	if (!ssSetNumOutputPorts(S, NOUTPUTS)) return;
	/* X: a dynamically sized 1-D matrix output */
    ssSetOutputPortMatrixDimensions(S, 0, D, 1);			/* Set dimensions */
	
	ssSetNumContStates(S, 0);
    ssSetNumDiscStates(S, 0);
	
    ssSetNumSampleTimes(S, 1); 			   /* Set the number of sample times. */
	/* Inherit the sample time. */
	ssSetInputPortSampleTime(S, 0, INHERITED_SAMPLE_TIME);
	ssSetInputPortSampleTime(S, 1, INHERITED_SAMPLE_TIME);
    
    ssSetNumRWork(S, 0);
    ssSetNumIWork(S, 0);
    ssSetNumPWork(S, 0);
    ssSetNumModes(S, 0);
    ssSetNumNonsampledZCs(S, 0);

    /* specify the sim state compliance to be same as a built-in block */
    ssSetSimStateCompliance(S, USE_DEFAULT_SIM_STATE);
	
	ssSetOptions(S,0);
    /*
	ssSetOptions(S,
                 SS_OPTION_WORKS_WITH_CODE_REUSE |
                 SS_OPTION_EXCEPTION_FREE_CODE |
                 SS_OPTION_ALLOW_INPUT_SCALAR_EXPANSION |
                 SS_OPTION_USE_TLC_WITH_ACCELERATOR);
  ssSetModelReferenceNormalModeSupport(S, MDL_START_AND_MDL_PROCESS_PARAMS_OK);
	*/
}


/* Function: mdlInitializeSampleTimes =========================================
 * Abstract:
 *    Inherit the sample time
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
    ssSetSampleTime(S, 0, INHERITED_SAMPLE_TIME);
    ssSetOffsetTime(S, 0, 0.0);
    ssSetModelReferenceSampleTimeDefaultInheritance(S); 
}


#define MDL_INITIALIZE_CONDITIONS   /* Change to #undef to remove function */
#if defined(MDL_INITIALIZE_CONDITIONS)
  /* Function: mdlInitializeConditions ========================================
   * Abstract:
   *    In this function, you should initialize the continuous and discrete
   *    states for your S-function block.
   */
  static void mdlInitializeConditions(SimStruct *S)
  {
	  
  }
#endif /* MDL_INITIALIZE_CONDITIONS */

#define MDL_START  /* Change to #undef to remove function */
#if defined(MDL_START) 
  /* Function: mdlStart =======================================================
   * Abstract:
   *    This function is called once at start of model execution. If you
   *    have states that should be initialized once, this is the place
   *    to do it.
   */
  static void mdlStart(SimStruct *S)
  {
  }
#endif /*  MDL_START */


/* Function: mdlOutputs =======================================================
 * Abstract:
 *    solve A*X=B with LAPACK/DPOTRS
 * 	  function call to DPOTRS: dpotrs("U", &n, &m, A, &n, X, &n, &info);
 *    Note on X: 	On entry, the right hand side matrix B.
 *				    On exit, the solution matrix X. 
 */
static void mdlOutputs(SimStruct *S, int_T tid)
{
	/* Dimensions of input vector B. */
	int_T *dimsB = ssGetInputPortDimensions(S, 1);
	mwSignedIndex n = dimsB[0]; 						   /* Number of rows */
	mwSignedIndex m = dimsB[1]; 					    /* Number of columns */
	mwSignedIndex info;						 /* Place to store error message */
	
	const real_T *A = ssGetInputPortRealSignal(S,0);       		 /* Matrix A */
	const real_T *B = ssGetInputPortRealSignal(S,1);			 /* Vector B */
	real_T *X = ssGetOutputPortRealSignal(S,0);			  /* Output signal X */
	
	memcpy( X, B, m*n*sizeof(real_T));	 					  /* Copy B to X */
	dpotrs("U", &n, &m, A, &n, X, &n, &info);				 /* Solve system */
	if (info < 0)
		ssSetErrorStatus(S,"Error: illegal input to solve_chol");
}


#define MDL_UPDATE  /* Change to #undef to remove function */
#if defined(MDL_UPDATE)
  /* Function: mdlUpdate ======================================================
   * Abstract:
   *    This function is called once for every major integration time step.
   *    Discrete states are typically updated here, but this function is useful
   *    for performing any tasks that should only take place once per
   *    integration step.
   */
  static void mdlUpdate(SimStruct *S, int_T tid)
  {
  }
#endif /* MDL_UPDATE */


#define MDL_DERIVATIVES  /* Change to #undef to remove function */
#if defined(MDL_DERIVATIVES)
  /* Function: mdlDerivatives =================================================
   * Abstract:
   *    In this function, you compute the S-function block's derivatives.
   *    The derivatives are placed in the derivative vector, ssGetdX(S).
   */
  static void mdlDerivatives(SimStruct *S)
  {
  }
#endif /* MDL_DERIVATIVES */


/* Function: mdlTerminate =====================================================
 * Abstract:
 *    No termination needed, but we are required to have this routine.
 */
static void mdlTerminate(SimStruct *S)
{
	
}

#define MDL_RTW  
#if defined(MDL_RTW) && defined(MATLAB_MEX_FILE)
  /* Function: mdlRTW =========================================================*/

static void mdlRTW(SimStruct *S)
{
//	int_T D = (int) (mxGetPr(NFEATURE_PARAM(S))[0]);
//	if (!ssWriteRTWParamSettings(S, 1, SSWRITE_VALUE_NUM, "NFeature", D) ) {
//        return; /* An error occurred. */
//    }
}
  
#endif 


/*=============================*
 * Required S-function trailer *
 *=============================*/

#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif