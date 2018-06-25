/*++

 RELEASED FOR ACADEMIC AND NON-COMMERCIAL USE ONLY

 Module Name:

    Plc.h

 Abstract:

    This module exports the Power-Line Communication Subsystem control module.

 Author:

    Stephanos Ioannidis (root@stephanos.io)  6-Mar-2017

 Revision History:

--*/

#ifndef PLC_H_
#define PLC_H_

//
// PLC Subsystem Controller MMIO Interface
//

typedef struct _PLC_SUBSYSTEM_CONTROLLER
{
    struct
    {
        UINT8 Do : 1;
        UINT8 Done : 1;
        UINT8 Div : 3;
        UINT8 Reserved : 3;
    } TxCon;

    struct
    {
        UINT8 Pending : 1;
        UINT8 Ack : 1;
        UINT8 Gain : 3;
        UINT8 Reserved : 3;
    } RxCon;

    UINT8 Reserved1;
    UINT8 Reserved2;
    /*UINT32 TxData[16];
    UINT32 RxData[16];*/
    BYTE TxData[64]; // NOTE: By design, this access does not support less-than-word level access atm.
    BYTE RxData[64];
} PLC_SUBSYSTEM_CONTROLLER, *PPLC_SUBSYSTEM_CONTROLLER;

//
// PLC Subsystem Controller MMIO Base Address
//

#define PLC_MMIO_BASE    0x9200

//
// PLC Subsystem Controller MMIO Pointer
//

extern PPLC_SUBSYSTEM_CONTROLLER PlcMmio;

//
// Functions
//

VOID PlcInit(VOID);

BOOL PlcSend(PBYTE buffer, INT index, INT length);
BOOL PlcReceive(PBYTE buffer, INT index, INT length);

VOID PlcSetTxDiv(UINT8 div);
VOID PlcSetRxGain(UINT8 gain);

#endif /* PLC_H_ */
