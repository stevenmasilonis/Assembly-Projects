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
          	.data
count:		.space	1						;reserve space for a count variable

            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

		mov.w #0, count	;counting variable
		bic.b	#BIT0,	&P1OUT ;Start with red LED off
		bis.b	#BIT0,	&P1DIR ;Direction set to output

		bic.b	#BIT7,	&P9OUT ;Start with green LED off
		bis.b	#BIT7,	&P9DIR ;Direction set to output

		; S1 connected to P1.1
		bis.b	#BIT1,	&P1REN ;resistor enabled
		bis.b	#BIT1,	&P1OUT ;pull up resistor
		bic.b	#BIT1,	&P1IES ;falling edge trigger interrupt
		bis.b	#BIT1,	&P1IE ;enable interrupts

		;disable power lock
		bic.w	#LOCKLPM5,	&PM5CTL0

		; S2 connected to P1.2
		bis.b	#BIT2,	&P1REN ;resistor enabled
		bis.b	#BIT2,	&P1OUT ;pull up resistor
		bic.b	#BIT2,	&P1IES ;falling edge trigger interrupt
		bis.b	#BIT2,	&P1IE ;enable interrupts

		;disable power lock
		bic.w	#LOCKLPM5,	&PM5CTL0

		clr.b	&P1IFG
		nop ;enable general interrupts
		eint
		nop

main:	jmp		main


;-------------------------------------------------------------------------------
; Interrupt Service Routines
;-------------------------------------------------------------------------------


P1_ISR:

		; check source of interrupt
		bit.b #BIT1, &P1IFG
		;jnc		check_S2
		jnc		return

		inc.w	count

		;bic.b #BIT1, &P1IFG ; clear interrupt flag
		jmp		delay

		xor.b #BIT0, &P1OUT



;check_S2:

		;bit.b #BIT2, &P1IFG ;check source of interrupt
		;jnc		return

;loop:
		;cmp.w #0, count ;if 0
		;jeq		return ;if zero jump to return



	;	xor.b #BIT0, &P1OUT ; toggle red light

	;	call #delay ;delay


	;	xor.b #BIT0, &P1OUT ; toggle red light

	;	call #delay ;delay

	;	xor.b #BIT0, &P1OUT ; toggle red light

	;	call #delay ;delay

	;	xor.b #BIT0, &P1OUT ; toggle red light

	;	call #delay ;delay

	;	xor.b #BIT7, &P9OUT ; toggle green light

	;	call #delay ;delay

	;	xor.b #BIT7, &P9OUT ; toggle green light

		;xor.b #BIT7, &P9OUT ; toggle green light
		;xor.b #BIT0, &P1OUT ; toggle red light

		;call #delay ;delay

		;dec.w	count ;decrement until hits 0
		;jmp		loop ;jump back into our loop



return:
		bic.b #BIT1|BIT2, &P1IFG ; clear interrupt flags



		reti

;-------------------------------------------------------------------------------
;	Subroutines
;-------------------------------------------------------------------------------

delay:
		clr.w	R5
countdown:

		dec.w	R5
		jnz		countdown

		ret


;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
       		.sect   ".int37"                ; MSP430 RESET Vector
            .short  P1_ISR

            .sect	".reset"
            .short	RESET
