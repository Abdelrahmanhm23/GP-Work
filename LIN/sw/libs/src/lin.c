
#include "lin.h"
#include <stdio.h>
#include "gpio.h"
#include "int.h"
#include "event.h"


int counter=0;
int parts=0;
//int rec_frames=0;

//-------------------- write the schedule table ---------------///
  void write_data (uint32_t data , int type)
      {
	     char i=0;

	     if (type == 1)
	        {
	    	   if (parts < 3)
	    	      {
	    		    if (parts==0)
	    		      {
	    		    	     table[counter].fnum= (counter+1);
	    	      //      table[counter+1].fnum = table[counter-1].fnum;
    		       //       table[counter].loc = (uint32_t*) (0x00107000 + counter);
                     table[counter].loc = (uint32_t*) (&LOC + counter);
    		            *(table[counter].loc) = data ;

    		              counter++;
    		              parts++;
	    		      }

	    		   else
	    		      {
	      	             table[counter].fnum = table[counter-1].fnum;
	    			     //table[counter].loc = &LOC+ counter;
	    			    table[counter].loc = (uint32_t*) (&LOC + counter);
	   		           *(table[counter].loc) = data;
	    			     counter++;
	    			     parts++;
	    			     if (parts == 3) parts=0;
	    		      }
	    	       }

             }

         else
            {
    	        table[counter].fnum= (counter+1);
    	        //table[counter].loc = &LOC+ counter;
    	        table[counter].loc = (uint32_t*) (&LOC + counter);
    	      *(table[counter].loc) = data ;
    	        counter++ ;
            }

      }

//----------------------------Read the received frames ------------------------------//
/*
void receive_data ()
  {
    int i=0;
    rec_frames ++ ;
    //if (rx_flag)
       for (i=0 ; i<3 ; i++)
          {
            received[i].loc = (uint32_t*) (&RX + i);
            received[i].fum = rec_frames ;
          }
  }
*/
//-------------------------Master node to go to sleep -------------------------------//
 void go_to_sleep (void)
   {
	 MS_wakeup_CMD &= ~0x01;       // clear wake up bit
	 MS_Sleep_CMD  |= 0x01 ;       // set sleep bit
   }

//----------------------- Master node to wake up -------------------------------------//
 void wake_up (void)
   {
	 MS_Sleep_CMD  &= ~0x01;       // clear sleep bit
	 MS_wakeup_CMD |=  0x01;        // set the wake up bit
   }

//   wake cluster ()
 //    {BUS_STATUS_CTR |= 0x04;  //set bit no. 3 in BUS_STATUS_CTR }

//-----------------------Enable schedule table ---------------------------------------//
 void enable_schedule_table (uint8_t nb_frames)
   {
     while ( !(Init_Finished	 & (1<<0)) ) ;
     //while ((BUS_STATUS_CTR & 0x01) == 0);
     No_of_frames = nb_frames -1 ;
     En_schedule |=  0x01; // enable schedule

   }

//------------------------Stop schedule table --------------------------------------//
 void stop_schedule_table (void)
   {
	   En_schedule &= ~0x01;            // stop schedule table

   }

//------------------------resume schedule table -----------------------------------//
 void resume_schedule()
   {
	   En_schedule |=  0x01;           // start schedule table (set the first bit)
   }


//------------------------error in tarsnmission ---------------------------------//
 //error checking
 void error_in_trasnmission (int nb_frames)
   {
	  int i=0;
        for (i=0 ; i<nb_frames ; i++)
         {
    	   if (ERROR_FLAGS1 & (1<<i))
    	    {
              while ((table[i].fnum == i+1))
                { error_frame[i] = table[i].loc ;  }
            }
         }
   }

 //------------------- diagnostics--------------------------------//
/*
#define dia1            *((volatile uint32_t *)(BASE_ADDR + 0x68 ))
#define dia2            *((volatile uint32_t *)(BASE_ADDR + 0x6c ))
#define dia3            *((volatile uint32_t *)(BASE_ADDR + 0x70 ))
#define dia4            *((volatile uint32_t *)(BASE_ADDR + 0x74 ))



  void assign_NAD (uint8_t initial_NAD,
		               uint8_t new_NAD,
				           uint16_t supplier_id,
				           uint16_t function_id)
     {
	  //SCHEDULE_CTR |= SCHEDULE_CTR | (1<<13);


  //  dia1 = (0x3C) |  (initial_NAD << 8) | (0x06 << 16) | (0xB0 << 24) ;
  //  dia2 = (0x3C) |  (supplier_id << 8) |
	//   part1 = (initial_NAD) | (0x06 << 8)	| (0xB0 << 16) | (supplier_id << 24) ;   // PCI value (0x06 << 8)  , SID value (0xB0 << 16)

	 //  supplier_id = (supplier_id >> 8);               //shift left to get the last 8 MSB

	   part2 = (supplier_id) | (function_id << 8) | (new_NAD << 24) ;

	  // write_data (part1, diagnostic);
	  //write_data (part2, diagnostic);

     }

*/

  void change_cond_NAD (uint8_t  NAD,
		                    uint8_t  id,
					              uint8_t  byte,
					              uint8_t  mask,
					              uint8_t  invert,
					              uint8_t  new_NAD)
      {
	  //SCHEDULE_CTR |= SCHEDULE_CTR | (1<<13);
	    uint32_t part1, part2;

	    part1 = (NAD) | (0x06 << 8) | (0xB3 << 16) | (id << 24) ;        // PCI value (0x06 << 8)  , SID value (0xB3 << 16)

	    part2 = (byte) | (mask << 8) | (invert << 8) | (new_NAD << 24);

	    write_data (part1, diagnostic);
	    write_data (part2, diagnostic);
      }




  void save_config (uint8_t NAD)
      {
	   //SCHEDULE_CTR |= SCHEDULE_CTR | (1<<13);
	     uint32_t part1, part2;

	     part1 = (NAD) | (0x01 << 8) | (0xB6 << 16) | (0xFF << 24) ;     // PCI value (0x01 << 8)  , SID value (0xB6 << 16)
	     part2 = 0xFFFFFFFF ;

        write_data (part1, diagnostic);
        write_data (part2, diagnostic);
      }


  void diagnostic_sleep ()
      {
	     //SCHEDULE_CTR |= SCHEDULE_CTR | (1<<13);
	       uint32_t part1, part2;
	       //diagnostic sleep frame
	       part1 = 0xFFFFFF00;
	       part2 = 0xFFFFFFFF;
	       write_data (part1, diagnostic);
	       write_data (part2, diagnostic);
      }
