#ifndef SEVENSEG_H
#define SEVENSEG_H

#define SEVENSEG_BASE    0x40003000u
#define SEVENSEG_DISPLAY ((volatile unsigned int *)(SEVENSEG_BASE + 0x00u))
#define SEVENSEG_CONTROL ((volatile unsigned int *)(SEVENSEG_BASE + 0x04u))

void sevenseg_write(unsigned int value);
void sevenseg_enable(void);
void sevenseg_disable(void);

#endif
