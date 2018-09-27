#include "stdint.h"
#include <stdio.h>
#include "lin.h"
#include "gpio.h"
#include "int.h"
#include "event.h"

uint32_t loc1=0 ,loc2=0,loc3=0 ;
//FILE * flin;

void interrupt_init()
  {
	int_enable();
  IER |= (IER | (1 << GPIO_EVENT));// must be set for the gpio int to be activated
	set_gpio_pin_irq_en(2,1);
	set_gpio_pin_irq_type(2, 0x2);
//  set_gpio_pin_irq_en(3,1);
//  set_gpio_pin_irq_type(3, 0x2);
  }


 void ISR_GPIO (void)
 {
  //  if (RX_flag == 1)
  //   {
      stop_schedule_table();
     //reading from rx memory
      loc1 = rx1;
      loc2 = rx2;
      loc3 = rx3;
    resume_schedule();
//    }
//  else {
//     En_diagnostic = 0x01;
//     stop_schedule_table();
//     while (!(End_diagnostic & (1<<0))) ;
//     resume_schedule();
//    }
  //disable interrupt
  int dummy = get_gpio_irq_status();
  ICP |= (ICP | (1 << GPIO_EVENT));
 }


 int main()
 {
    interrupt_init();

	  write_data (0x01234523 , request);
    write_data (0x81012023 , request);
    write_data (0x00223323 , request);
    write_data (0x24 , response);
    write_data (0x20 , response);
    write_data (0x25 , response);
//   dia1 = 0xB006013c;
//   dia2 = 0xff7fff3c;
//   dia3 = 0x007fff3c;
//   dia4 = 0x3d;

  while ( !(Init_Finished	 & (1<<0)) ) ;

   MS_Sleep_CMD = 0x00;  //clear sleep bit

   No_of_frames = counter-1;

   En_schedule =  0x01; // enable schedule

/*
	 while(1)
	 {

	 }
   */
   return 0;
 }
