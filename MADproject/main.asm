;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .data                           ; Assemble into program memory.
                                            ; and retain current section.
mad:		.space	2 ;reserve space for mad
average 	.space  2 ;reserve space for variable to help calculate MAD
distances 	.word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ;reserve space for another array to hold distances from avg
;-------------------------------------------------------------------------------

            .text                         ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
samples:	.word   0x2E, 0x54, 0x0B, 0x14, 0x27, 0x5B, 0x39, 0x11, 0x47, 0x1B, 0x3F, 0x04, 0x24, 0x58, 0x3E, 0x34


            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.
;-------------------------------------------------------------------------------
;----------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

		mov.w #0, R4 ;used for indexing
		mov.w #0, R5 ;used to represent 0 later on

read_from_array:
		add.w   samples(R4), average ;summing up all the values

proceed_to_next:
		incd.w R4 ;double increment for word array
		cmp.w 	#32, R4 ;word array take up 2 memory slots so needs to be double
		jlo		read_from_array ;if not at 32 or more loop continues

		rra.w average ;takes average (dividing by 16) by shifting to right 4 times
		rra.w average
		rra.w average
		rra.w average

		clr.w R4 ;clearing for further use

read_from_array2:
		mov.w samples(R4), distances(R4) ;moving all of the distances of each value from avg to another array
		sub.w average, distances(R4) ;subtracting each distance from avg


proceed_to_next2:
		incd.w R4 ;word array take up 2 memory slots so needs to be double
		cmp.w 	#32, R4 ;word array take up 2 memory slots so needs to be double
		jlo		read_from_array2 ;if not at 32 or more loop continues

		clr.w R4 ;clearing for further use


read_from_array3:
		cmp.w	R5, distances(R4) ;comparing distance value to 0
		jl	 	label2 ;if negative
		add.w   distances(R4), mad ;summing up all the values into mad
		jmp 	proceed_to_next3 ;skip over case where it is negative
label2:
		sub.w   distances(R4), mad ;if negative then -- is technically add

proceed_to_next3:
		incd.w R4  ;word array take up 2 memory slots so needs to be double
		cmp.w 	#32, R4 ;word array take up 2 memory slots so needs to be double
		jlo		read_from_array3 ;if not at 32 or more loop continues

		rra.w mad ;takes average (dividing by 16) by shifting to right 4 times , giving us our desired MAD
		rra.w mad
		rra.w mad
		rra.w mad

main:		jmp 	main
					nop



                                            

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
