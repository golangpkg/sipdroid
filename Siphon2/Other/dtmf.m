/**
 *  Siphon SIP-VoIP for iPhone and iPod Touch
 *  Copyright (C) 2008-2009 Samuel <samuelv0304@gmail.com>
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

#include "dtmf.h"

#define THIS_FILE	"dtmf.c"

struct my_call_data
{
   pj_pool_t          *pool;
   pjmedia_port       *tonegen;
   pjsua_conf_port_id  toneslot;
};

/**
 */
static
struct my_call_data *call_init_tonegen(pjsua_call_id call_id)
{
  pj_pool_t *pool;
  struct my_call_data *cd;
  pjsua_call_info ci;
  pj_status_t status;

  pool = pjsua_pool_create("mycall", 512, 512);
  cd = PJ_POOL_ZALLOC_T(pool, struct my_call_data);
  cd->pool = pool;

  status = pjmedia_tonegen_create(cd->pool, 8000, 1, 160, 16, 0, &cd->tonegen);

  if (status == PJ_SUCCESS)
  {
  	pjsua_conf_add_port(cd->pool, cd->tonegen, &cd->toneslot);

  	pjsua_call_get_info(call_id, &ci);
  	pjsua_conf_connect(cd->toneslot, ci.conf_slot);
    // Now keyboard plays dtmf sound on speaker/earphone
  	//pjsua_conf_connect(cd->toneslot, 0); // speaker/earphone.

  	pjsua_call_set_user_data(call_id, (void*) cd);
  }
  else
  {
    pjsua_perror(THIS_FILE, "Error: Error creating DTMF generator", status);
    pj_pool_release(pool);
    cd = NULL;
  }

  return cd;
}

/**
 */
void sip_call_play_digit(pjsua_call_id call_id, char digit)
{
  pj_status_t status;
  char buf[2];
  pj_str_t digits;
  
  buf[0] = digit;
  buf[1] = 0;
  digits = pj_str(buf);
  status = pjsua_call_dial_dtmf(call_id, &digits);
  if (status == PJMEDIA_RTP_EREMNORFC2833)
  {
    pjmedia_tone_digit d[1];
    struct my_call_data *cd;

    cd = (struct my_call_data*) pjsua_call_get_user_data(call_id);
    if (cd == NULL)
    {
      cd = call_init_tonegen(call_id);
      if (cd == NULL)
        return;
    }
    //else if (pjmedia_tonegen_is_busy(cd->tonegen))
    pjmedia_tonegen_stop(cd->tonegen);

    d[0].digit = digit;
    d[0].on_msec = 100;
    d[0].off_msec = 100;
    d[0].volume = 16383;

    pjmedia_tonegen_play_digits(cd->tonegen, 1, d, 0);
  }
}

/**
 */
void sip_call_deinit_tonegen(pjsua_call_id call_id)
{
  struct my_call_data *cd;

  cd = (struct my_call_data*) pjsua_call_get_user_data(call_id);
  if (!cd)
     return;

  pjsua_conf_remove_port(cd->toneslot);
  pjmedia_port_destroy(cd->tonegen);
  pj_pool_release(cd->pool);

  pjsua_call_set_user_data(call_id, NULL);
}
/**
 */
void sip_call_play_info_digit(pjsua_call_id call_id, char digit)
{
  const pj_str_t SIP_INFO = pj_str("INFO");
  pj_status_t status;
  pjsua_msg_data msg_data;
  char body[80];
  
  pjsua_msg_data_init(&msg_data);
  msg_data.content_type = pj_str("application/dtmf-relay");
  
  pj_ansi_snprintf(body, sizeof(body),
                   "Signal=%c\r\n"
                   "Duration=160",
                   digit);
  msg_data.msg_body = pj_str(body);
  
  status = pjsua_call_send_request(call_id, &SIP_INFO, 
                                   &msg_data);
}
