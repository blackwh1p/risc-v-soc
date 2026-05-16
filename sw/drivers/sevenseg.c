#include "sevenseg.h"

void sevenseg_write(unsigned int value)
{
    *SEVENSEG_DISPLAY = value;
}

void sevenseg_enable(void)
{
    *SEVENSEG_CONTROL = 1u;
}

void sevenseg_disable(void)
{
    *SEVENSEG_CONTROL = 0u;
}
