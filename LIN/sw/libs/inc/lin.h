
#ifndef LIN_H_
#define LIN_H_

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define response    0
#define request     1
#define diagnostic  3


#define BASE_ADDR      0x1A119000

//Registers
#define Init_Finished		  *((volatile uint32_t *)(BASE_ADDR + 0x00 ))   // Read only
#define ERROR_FLAGS1		  *((volatile uint32_t *)(BASE_ADDR + 0x04 ))   // Read only
#define ERROR_FLAGS2  	  *((volatile uint32_t *)(BASE_ADDR + 0x08 ))   // Read only
#define En_schedule		    *((volatile uint32_t *)(BASE_ADDR + 0x0C ))
#define No_of_frames		  *((volatile uint32_t *)(BASE_ADDR + 0x10 ))
#define MS_Sleep_CMD		  *((volatile uint32_t *)(BASE_ADDR + 0x14 ))
#define MS_wakeup_CMD		  *((volatile uint32_t *)(BASE_ADDR + 0x18 ))
#define Bus_inactive		  *((volatile uint32_t *)(BASE_ADDR + 0x1C ))   // Read only
#define En_diagnostic		  *((volatile uint32_t *)(BASE_ADDR + 0x20 ))
#define End_diagnostic	  *((volatile uint32_t *)(BASE_ADDR + 0x24 ))   // Read only
#define RX_flag	          *((volatile uint32_t *)(BASE_ADDR + 0x28 ))   // Read only


// TX Memory start Location
#define LOC		          *((volatile uint32_t *)(BASE_ADDR + 0x40 ))

//diagnostic locations
#define dia1            *((volatile uint32_t *)(BASE_ADDR + 0x68 ))
#define dia2            *((volatile uint32_t *)(BASE_ADDR + 0x6C ))
#define dia3            *((volatile uint32_t *)(BASE_ADDR + 0x70 ))
#define dia4            *((volatile uint32_t *)(BASE_ADDR + 0x74 ))

// RX memeory first three locations
#define rx1	  *((volatile uint32_t *)(BASE_ADDR + 0x80 ))
#define rx2	  *((volatile uint32_t *)(BASE_ADDR + 0x84 ))
#define rx3	  *((volatile uint32_t *)(BASE_ADDR + 0x88 ))


struct frames {
	int fnum;
	uint32_t *loc;
};

struct frames table[22];

//struct frames received [16];

uint32_t *error_frame[32];

extern int counter;
extern int parts;
extern int rec_frames;

//functions
void write_data (uint32_t data , int type);
void go_to_sleep (void);
void wake_up (void);
void enable_schedule_table (uint8_t frames_nb);
void stop_schedule_table (void);
void resume_schedule(void);
void error_in_trasnmission (int nb_frames);
void schedule_sw (void);
void assign_NAD (uint8_t initial_NAD, uint8_t new_NAD, uint16_t supplier_id, uint16_t function_id);
void change_cond_NAD (uint8_t  NAD, uint8_t  id, uint8_t  byte, uint8_t  mask, uint8_t  invert, uint8_t  new_NAD);
void save_config (uint8_t NAD);
void diagnostic_sleep ();


#endif /* LIN_H_ */
