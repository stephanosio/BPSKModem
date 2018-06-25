/*++

 RELEASED FOR ACADEMIC AND NON-COMMERCIAL USE ONLY

 Module Name:

    Plc.c

 Abstract:

    This module implements the routines required to control the Power-Line Communication Subsystem.

 Author:

    Stephanos Ioannidis (root@stephanos.io)  7-Mar-2017

 Revision History:

--*/

#include <string.h>

#include "priv/alt_busy_sleep.h"

#include "TypeSystem.h"
#include "Plc.h"

PPLC_SUBSYSTEM_CONTROLLER PlcMmio = (PPLC_SUBSYSTEM_CONTROLLER)PLC_MMIO_BASE;

VOID PlcInit(VOID)
{
    //
    // Set transmitter configuration.
    //

    PlcMmio->TxCon.Div = 2; // Default output level divisor 2.

    //
    // Set receiver configuration.
    //

    PlcMmio->RxCon.Gain = 2; // 2x amplifier gain by default.
}

BOOL PlcSend(PBYTE buffer, INT index, INT length)
{
    //
    // This function sends the content of the buffer specified in parameter over Power-Line
    // Communication channel. This function blocks until the send process is complete.
    //

	PUINT32 procBuffer = (PUINT32)buffer;
	PUINT32 coreBuffer = (PUINT32)PlcMmio->TxData;
	INT wordCount = (length - index) / 4;
	INT i;

	//
	// Verify that the buffer size is divisible by 4.
	//

	if ((length - index) % 4 > 0)
	{
		return FALSE;
	}

	//
	// Copy core buffer to processor buffer.
	//
	// NOTE: Access to the core buffer must be in the 4 byte unit.
	//

	for (i = 0; i < wordCount; i++)
	{
		*(coreBuffer++) = *(procBuffer++);
	}

    //
    // Begin transmit sequence.
    //

    PlcMmio->TxCon.Do = 1;

    //
    // Block until the PLC core completes transmit sequence.
    //

    while (!PlcMmio->TxCon.Done)
    {
        alt_busy_sleep(1);
    }

    //
    // End transmit sequence.
    //

    PlcMmio->TxCon.Do = 0;

    return TRUE;
}

BOOL PlcReceive(PBYTE buffer, INT index, INT length)
{
    //
    // This function receives a packet from Power-Line Communication channel. This function blocks
    // until a valid packet is received over the communication channel.
    //

	PUINT32 procBuffer = (PUINT32)buffer;
	PUINT32 coreBuffer = (PUINT32)PlcMmio->RxData;
	INT wordCount = (length - index) / 4;
	INT i;

	//
	// Verify that the buffer size is divisible by 4.
	//

	if ((length - index) % 4 > 0)
	{
		return FALSE;
	}

	//
	// Drop all packets received before this command was issued.
	//

	PlcMmio->RxCon.Ack = 1;

    //
    // Begin receive sequence: block until there is a pending packet.
    //

    while (!PlcMmio->RxCon.Pending)
    {
        alt_busy_sleep(1);
    }

    //
    // Copy core buffer to processor buffer.
    //
    // NOTE: Access to the core buffer must be in the 4 byte unit.
    //

	for (i = 0; i < wordCount; i++)
	{
		*(procBuffer++) = *(coreBuffer++);
	}

    //
    // End receive sequence.
    //

    PlcMmio->RxCon.Ack = 1;

    return TRUE;
}

//
// TODO: Implement asynchronous transmit and receive routines. Note that asynchronous transmit
//       function is not absolutely required (in fact, it won't do much since we do not have any
//       form of FIFO transmit buffer implemented at the moment).
//

VOID PlcSetTxDiv(UINT8 div)
{
    PlcMmio->TxCon.Div = div;
}

VOID PlcSetRxGain(UINT8 gain)
{
    PlcMmio->RxCon.Gain = gain;
}
