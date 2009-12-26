/**
 *  AMR codec for iPhone and iPod Touch
 *  Copyright (C) 2009 Samuel <samuelv0304@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */
/*******************************************************************************
 Portions of this file are derived from the following 3GPP standard:

    3GPP TS 26.073
    ANSI-C code for the Adaptive Multi-Rate (AMR) speech codec
    Available from http://www.3gpp.org

 (C) 2004, 3GPP Organizational Partners (ARIB, ATIS, CCSA, ETSI, TTA, TTC)
 Permission to distribute, modify and use this file under the standard license
 terms listed above has been obtained from the copyright holder.
*******************************************************************************/
/*
********************************************************************************
*
*      GSM AMR-NB speech codec   R98   Version 7.6.0   December 12, 2001
*                                R99   Version 3.3.0                
*                                REL-4 Version 4.1.0                
*
********************************************************************************
*
*      File             : q_plsf.c
*      Purpose          : common part (init, exit, reset) of LSF quantization
*                         module (rest in q_plsf_3.c and q_plsf_5.c)
*
********************************************************************************
*/

/*
********************************************************************************
*                         MODULE INCLUDE FILE AND VERSION ID
********************************************************************************
*/
#include "q_plsf.h"
const char q_plsf_id[] = "@(#)$Id $" q_plsf_h;
 
/*
********************************************************************************
*                         INCLUDE FILES
********************************************************************************
*/
#include <stdlib.h>
#include <stdio.h>
#include "typedef.h"
#include "basic_op.h"


/*
********************************************************************************
*                         PUBLIC PROGRAM CODE
********************************************************************************
*/

/*
**************************************************************************
*
*  Function    : Q_plsf_init
*  Purpose     : Allocates memory and initializes state variables
*
**************************************************************************
*/
int Q_plsf_init (Q_plsfState *state)
{
  if (state == (Q_plsfState *) NULL){
      fprintf(stderr, "Q_plsf_init: invalid parameter\n");
      return -1;
  }

  Q_plsf_reset(state);

  return 0;
}
 
/*
**************************************************************************
*
*  Function    : Q_plsf_reset
*  Purpose     : Resets state memory
*
**************************************************************************
*/
int Q_plsf_reset (Q_plsfState *state)
{
  Word16 i;
  
  if (state == (Q_plsfState *) NULL){
      fprintf(stderr, "Q_plsf_reset: invalid parameter\n");
      return -1;
  }

  for ( i = 0; i < M; i++)
      state->past_rq[i] = 0;
  
  return 0;
}
