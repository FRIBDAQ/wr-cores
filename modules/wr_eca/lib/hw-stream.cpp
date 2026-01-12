//////////////////////////////////////////////////////////////////////////////
// SPDX-FileCopyrightText: 2013 GSI / Wesley W. Terpstra <w.terpstra@gsi.de>
// 
// SPDX-License-Identifier:   LGPL-2.1-or-later
//////////////////////////////////////////////////////////////////////////////
/** @file hw-stream.cpp
 *  @brief C++ Wrapper for the ECA Stream hardware.
 *  @author Wesley W. Terpstra <w.terpstra@gsi.de>
 *
 *  Send test events to the ECA unit.
 *
 *******************************************************************************
 */

#define __STDC_FORMAT_MACROS
#define __STDC_LIMIT_MACROS
#define __STDC_CONSTANT_MACROS

#include <stdio.h>
#include <assert.h>
#include "eca.h"
#include "hw-eca.h"

namespace GSI_ECA {

status_t EventStream::send(EventEntry e) {
  Cycle cycle;
  eb_status_t status;
  
  if ((status = cycle.open(device)) != EB_OK)
    return status;
  
  cycle.write(address, EB_DATA32, e.event >> 32);
  cycle.write(address, EB_DATA32, e.event & UINT32_C(0xFFFFFFFF));
  cycle.write(address, EB_DATA32, e.param >> 32);
  cycle.write(address, EB_DATA32, e.param & UINT32_C(0xFFFFFFFF));
  cycle.write(address, EB_DATA32, 0); // reserved
  cycle.write(address, EB_DATA32, e.tef   & UINT32_C(0xFFFFFFFF));
  cycle.write(address, EB_DATA32, e.time  >> 32);
  cycle.write(address, EB_DATA32, e.time  & UINT32_C(0xFFFFFFFF));
  
  return cycle.close();
}

}
