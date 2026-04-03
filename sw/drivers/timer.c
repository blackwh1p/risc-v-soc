#include "timer.h"

// timer_set — sets compare value and enables timer
void timer_set(unsigned int compare)
{
    *((volatile unsigned int *)TIMER_COMPARE) = compare;
    *((volatile unsigned int *)TIMER_CONTROL) = TIMER_ENABLE;
}

// timer_clear — disables timer and resets counter
void timer_clear(void)
{
    *((volatile unsigned int *)TIMER_CONTROL) = 0;
    *((volatile unsigned int *)TIMER_COUNTER) = 0;
}

// timer_read — returns current counter value
unsigned int timer_read(void)
{
    return *((volatile unsigned int *)TIMER_COUNTER);
}