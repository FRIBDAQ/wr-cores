/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xuartps.h"
#include "mpsoc_map.h"


int main()
{
	uintptr_t addr = 0x80000000;
    volatile struct mpsoc_map *map = (volatile struct mpsoc_map *)addr;

    XUartPs_Config *uart_config;
    u32 uart_addr[2];
    unsigned i;
    
    init_platform();

    print("Hello world\r\n");
    for (i = 0; i < 2; i++) {
    	XUartPs uart_ps;
    	XUartPsFormat fmt;
    	uart_config = XUartPs_LookupConfig(i);
    	uart_addr[i] = uart_config->BaseAddress;
    	printf("uart %u at %08x\r\n", i, uart_addr[i]);
    	if (i != 0) {
    		s32 Status;
//    		XUartPs_ResetHw(uart_addr[i]);
    		Status = XUartPs_CfgInitialize(&uart_ps, uart_config, uart_config->BaseAddress);
    		if (Status != XST_SUCCESS)
    			printf("uart %u init error %d\r\n", i, Status);
//    		fmt.BaudRate = 115200;
//    		fmt.DataBits = XUARTPS_FORMAT_8_BITS;
//    		fmt.Parity = XUARTPS_FORMAT_NO_PARITY;
//    		fmt.StopBits = XUARTPS_FORMAT_1_STOP_BIT;
//    		XUartPs_SetDataFormat(&uart_ps, &fmt);
//    		XUartPs_EnableUart(&uart_ps);
//    		XUartPs_SetOperMode(&uart_ps, XUARTPS_OPER_MODE_LOCAL_LOOP);
    	}
    }

#if 0
    v = Xil_In32(addr);
    printf("addr %08x v=%08x\r\n", addr, v);
    Xil_Out32(addr, 0x12345678);
    v = Xil_In32(addr);
    printf("addr %08x v=%08x\r\n", addr, v);
#endif

    // 4b523236
    printf("HWIR: %08x\r\n", map->wrpc[(0x400 + 0x10) / 4]);
    while (1) {
    	for (i = 0; i < 2; i++) {
    		if (XUartPs_IsReceiveData(uart_addr[i])) {
    			unsigned char c = XUartPs_RecvByte(uart_addr[i]);
    			XUartPs_SendByte(uart_addr[1 - i], c);
    			if (c == '@' && i == 0) {
    				printf("status: %08x\r\n", map->status);
//    				map->ctrl ^= 3;
    			}
//    			printf("Got %c from %u\r\n", c, i);
    		}
    	}
	}
    cleanup_platform();
    return 0;
}
