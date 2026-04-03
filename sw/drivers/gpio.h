#ifndef GPIO_H
#define GPIO_H

#define GPIO_BASE      0x40002000
#define GPIO_DIRECTION      (GPIO_BASE + 0x00)
#define GPIO_OUTPUT         (GPIO_BASE + 0x04)
#define GPIO_INPUT          (GPIO_BASE + 0x08)

void gpio_set_direction(unsigned int mask);
void gpio_write(unsigned int value);
unsigned int gpio_read(void);

#endif // GPIO_H