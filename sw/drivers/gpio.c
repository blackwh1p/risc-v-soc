#include "gpio.h"

void gpio_set_direction(unsigned int mask)
{
    *((volatile unsigned int *)GPIO_DIRECTION) = mask;
}

void gpio_write(unsigned int value)
{
    *((volatile unsigned int *)GPIO_OUTPUT) = value;
}

unsigned int gpio_read(void)
{
    return *((volatile unsigned int *)GPIO_INPUT);
}