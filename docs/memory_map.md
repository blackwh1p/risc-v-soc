# Memory Map — Custom RISC-V SoC

## Address Space Overview

| Region      | Start        | End          | Size  | Description              |
|-------------|--------------|--------------|-------|--------------------------|
| IMEM        | 0x00000000   | 0x00003FFF   | 16 KB | Instruction memory (ROM) |
| Reserved    | 0x00004000   | 0x1FFFFFFF   | —     | Unused                   |
| DMEM        | 0x20000000   | 0x20003FFF   | 16 KB | Data memory (RAM)        |
| Reserved    | 0x20004000   | 0x3FFFFFFF   | —     | Unused                   |
| MMIO        | 0x40000000   | 0x4000FFFF   | 64 KB | Memory-mapped peripherals|

## MMIO Register Map

### UART (Base: 0x40000000)
| Offset | Register    | Description                  |
|--------|-------------|------------------------------|
| 0x00   | TX_DATA     | Write byte to transmit       |
| 0x04   | RX_DATA     | Read received byte           |
| 0x08   | STATUS      | Bit0=TX_ready, Bit1=RX_valid |

### Timer (Base: 0x40001000)
| Offset | Register    | Description                  |
|--------|-------------|------------------------------|
| 0x00   | COUNTER     | Current counter value        |
| 0x04   | COMPARE     | Interrupt trigger value      |
| 0x08   | CONTROL     | Bit0=enable, Bit1=int_enable |

### GPIO (Base: 0x40002000)
| Offset | Register    | Description                  |
|--------|-------------|------------------------------|
| 0x00   | DIRECTION   | 1=output, 0=input per bit    |
| 0x04   | OUTPUT      | Write output values          |
| 0x08   | INPUT       | Read input values            |

## Reset Behavior
- PC starts at 0x00000000 on reset
- Stack pointer initialized to 0x20003FFC (top of DMEM)