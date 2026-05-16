#ifndef TIMER_H
#define TIMER_H

#define TIMER_BASE     0x40001000
#define TIMER_COUNTER  (TIMER_BASE + 0x00)
#define TIMER_COMPARE  (TIMER_BASE + 0x04)
#define TIMER_CONTROL  (TIMER_BASE + 0x08)
#define TIMER_STATUS   (TIMER_BASE + 0x0C)  /* bit0=irq_flag; write any value to clear */

#define TIMER_ENABLE       (1 << 0)
#define TIMER_INT_ENABLE   (1 << 1)

void timer_set(unsigned int compare);
void timer_clear(void);
unsigned int timer_read(void);

#endif // TIMER_H