#ifndef GPIO_H
#define GPIO_H

#define GPIO_BASE           0x40002000
#define GPIO_DIRECTION      (GPIO_BASE + 0x00)
#define GPIO_OUTPUT         (GPIO_BASE + 0x04)
#define GPIO_INPUT          (GPIO_BASE + 0x08)

// GPIO_INPUT bit layout: [15:0]=switches [20:16]=buttons
#define GPIO_SWITCHES_MASK  0x0000FFFFu
#define GPIO_BTNU_MASK      (1u << 16)
#define GPIO_BTNL_MASK      (1u << 17)
#define GPIO_BTNR_MASK      (1u << 18)
#define GPIO_BTND_MASK      (1u << 19)
#define GPIO_BTNC_MASK      (1u << 20)

void gpio_set_direction(unsigned int mask);
void gpio_write(unsigned int value);
unsigned int gpio_read(void);

#endif // GPIO_H