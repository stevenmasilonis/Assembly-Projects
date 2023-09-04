;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
; ECE 2560 Final Exam -- Spring 2023
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
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


			mov.w #0, R11 ;used as a counting variable
			; Since no other registers used in this program I am not worried about restoring R5
			bic.b	#BIT0,	&P1OUT ;Start with red LED off
			bis.b	#BIT0,	&P1DIR ;Direction set to output
			bic.b	#BIT7,	&P9OUT ;Start with green LED off
			bis.b	#BIT7,	&P9DIR ;Direction set to output

			bic.w	#LOCKLPM5,	&PM5CTL0 ;Disable power lock


; Configure Timer B0 to throw interrupts
			bis.w	#TBCLR, &TB0CTL				; reset timer
			bis.w	#TBSSEL__ACLK, &TB0CTL		; source is ACLK
			bis.w	#MC__CONTINUOUS, &TB0CTL	; continuous mode
			bis.w	#CNTL__12, &TB0CTL			; counter length = 12 bits
			bis.w	#ID__2, &TB0CTL				; divide freq. by 2
			bis.w	#TBIE, &TB0CTL 				; enable interrupts

			nop
			bis.w #GIE|LPM3, SR ; Enable general interrupts and LPM3
			nop


;-------------------------------------------------------------------------------
; Interrupt Service Routine
;-------------------------------------------------------------------------------
Timer_B0_ISR:

		bit.b #TBIFG, &TB0CTL ;check source of interrupt
		jnc		finish

		cmp.w #4, R11
		jhs green_light ;allows for 4 iterations

red_light: ;tag for more readability
		xor.b #BIT0, &P1OUT ; toggle red light
		inc.w R11 ;increment counting variable after toggling
		jmp finish ;jump to end/ out of ISR for hardware delay

green_light:
		xor.b #BIT7, &P9OUT ; toggle green light
		cmp.w #5, R11 ;if equals 5 means 6 iterations occurred (4 red toggles, 2 green toggles)
		jeq reset_counter ;now we need to reset counting variable to 0
		inc.w R11 ;atleast one iteration within this label before resetting counter
		jmp finish ;jump to end/ out of ISR for hardware delay

reset_counter:
		clr.w R11 ;reset R11

finish:
		bic.w #TBIFG, &TB0CTL ; clear interrupt flags

		reti

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------

			.sect   ".int50"                ; MSP430 RESET Vector
            .short  Timer_B0_ISR

            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
