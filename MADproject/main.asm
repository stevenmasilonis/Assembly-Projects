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
		mov.w #0, R5 ;used to represent average value
		mov.w #0, R6 ;used to help calculate mad
		mov.w #0, R7 ;used to represent 0

read_from_array:	;sums all the values into R5
		add.w   samples(R4), average ;summing up all the values

proceed_to_next:
		incd.w R4 ;double increment for word array
		cmp.w 	#32, R4 ;word array takes up 2 memory slots so needs to be double
			jlo		read_from_array ;if not at 32 or more loop continues

		rra.w R5 ;takes average (dividing by 16) by shifting to right 4 times
		rra.w R5
		rra.w R5
		rra.w R5

		clr.w R4 ;clearing for further use

move_and_divide: ;sums up all the values' distances from the mean into mad

		add.w samples(R4), R6
		sub.w R5, R6 ;subtracting from each value the average
		cmp.w R7, R6 ;R7 is 0, we are checking if the number is above or below 0
			jl if_negative ;skips to if negative
		add.w R5, mad ;if positive goes here and adds up everything to mad
		jmp proceed_to_next2 ;if skip over negative condition
if_negative:
	sub.w R5, mad

proceed_to_next2:
	incd.w R4 ;double increment for word array
	mov.w #0, R6 ;want to clear R5 every iteration
	cmp.w #32, R4 ;word array takes up 2 memory slots so it needs to be double the size of our array
		jlo 	move_and_divide ;if less than 32 (R increments twice) we go back to move_and_divde)

	rra.w mad ;takes average (dividing by 16) by shifting to right 4 times
	rra.w mad
	rra.w mad
	rra.w mad

	clr.w 	R5 ;free up space
	clr.w 	R6
	clr.w 	R4

main:		jmp 	main ;closing loop
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
            
