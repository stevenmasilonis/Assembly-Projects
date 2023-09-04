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
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

LENGTH: 	.set 	64					; number of samples in each vector

sin_Q6: 	.space 	2*LENGTH 				; vector of LENGTH words - hence *2
cos_Q6: 	.space 	2*LENGTH				; vector of LENGTH words - hence *2

;sin_Q6		.word -147, -5
;cos_Q6		.word 78, -119

signal_Q6: 	.space 	4*2*LENGTH				; vector of 4*LENGTH words

; At the end your output goes here
bits: 	   	.space 	16						; a_0, b_0, a_1, a_2, ..., a_3, b_3
projections:.space 	16						; inner products go here


;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------


; Loop through 4 symbols @signal_Q6+n*2*LENGTH for n = 0, 1, 2, 3
; Take inner product with cos_Q6, decide on a_n
; Take inner product with sin_Q6, decide on b_n

			clr.w	R14 				; counting through symbols n = 0, 1, 2, 3
			mov.w	#signal_Q6, R15 	; pointing to signal_Q6

			mov.w	#LENGTH, R9 		; prepare input for inner_product
			mov.w	#6, R10				; prepare input for inner_product

next_symbol:
; Take inner product with cos_Q6, decide on a_n
			mov.w	R15, R7
			mov.w	#cos_Q6, R8
			call 	#inner_product_Qm

			mov.w	R14, R12
			rla.w	R12
			rla.w	R12
			add.w	#bits, R12
			call	#threshold

			mov.w	R14, R12
			rla.w	R12
			rla.w	R12
			add.w	#projections, R12
			mov.w	R13, 0(R12)

; Take inner product with sin_Q6, decide on b_n
			mov.w	R15, R7
			mov.w	#sin_Q6, R8
			call 	#inner_product_Qm

			mov.w	R14, R12
			rla.w	R12
			rla.w	R12
			incd.w	R12
			add.w	#bits, R12
			call	#threshold

			mov.w	R14, R12
			rla.w	R12
			rla.w	R12
			incd.w	R12
			add.w	#projections, R12
			mov.w	R13, 0(R12)

; Proceed to checking next symbol
			add.w	#2*LENGTH, R15
			inc.w	R14
			cmp.w	#4, R14
			jlo		next_symbol

main: 		jmp		main


;-------------------------------------------------------------------------------
; Subroutines
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: inner_product_Qm
;
; This subroutine takes two signed vectors of length n with Q-value m
; 		 	and returns the innerproduct with same Q-value m
;
; Inputs: pointer to vector v1 in R7 -- can be modified
;         pointer to vector v2 in R8 -- can be modified
; 		  length n of v1 and v2 in R9 -- returned unchanged
; 		  Q-value 0<= m <15 in R10 -- returned unchanged
;
; Output: signed number in R13 -- R13 = (v1.v2)/(2^m)
;                                       where . denotes vector inner product
;
; All other core registers in R4-R15 unchanged
; No access to addressed memory
;-------------------------------------------------------------------------------
inner_product_Qm:

; enter your code here
		push	R9 ;saves these registers so they are unaltered
		push	R5
		push	R6
		push	R12

		mov.w #0, R13 ;stores result value

sum:

		mov.w @R7+, R5 ;moving elements of each array into R5 and R6
		mov.w @R8+, R6

		call #signed_x_times_y ;multiplies elementss
		call #x_div_2powerP ;scales the result

		add.w R12, R13 ;add our result into result value (each iteration keeps adding on top of)
		dec.w R9 ;decrement our counting value
		jnz sum ;once R9 hits 0 we end the loop

end:

		pop		R12
		pop		R6 ;pops back saved values
		pop		R5
		pop		R9

		ret





; do not forget to scale each product by 2^m to prevent overflow



;-------------------------------------------------------------------------------
; Subroutine: signed_x_times_y
;
; Inputs: signed byte x in R5 -- returned unchanged
;         signed byte y in R6 -- returned unchanged
;
; Output: signed number in R12 -- R12 = R5 * R6
;
; All other core registers in R4-R15 unchanged
; No access to addressed memory
;-------------------------------------------------------------------------------
signed_x_times_y:

; enter your code here

	; Save afftected core registers on stack - You can add this part last once you
; know which registered are modified
			push  	R5
			push 	R6 ;saves these registers so that they are unaltered
			push	R15


			mov.w #0, R15 ;R15 can be seen as a boolean value later used for sign changes

			tst.w	R6 ;comparing R6 to 0 to see if negative
			jge 	test_R5 ;if positive skip over and jmp to R5 test

			inv.w	R6 ;flips the bits
			inc.w	R6 ;adds 1 because 2's comp (these two lines take absolute value)
			add.w #1, R15 ;since this number was negative a 1 needs to be added into R15

test_R5:

			tst.w	R5 ;this is the exact same logic as 194-198 just tests R5 the same way
			jge multiply
			inv.w	R5
			inc.w	R5
			add.w #1, R15 ;same idea here 1 needs to be added into R15 (if 1 was already there then
			;both were negative giving us R15 != 1 (relevant later on)

multiply:
			call #x_times_y ;multiplies our absolute values

determine_sign:

			cmp.w #1, R15 ;if 1 means one value was negative so we need to change final result's sign
			jne endsigned ;anything else means positive times positive or negative times negative so no further work is needed

			inv.w	R12 ;same logic as earlier, flip bits and add 1 to take absolute value
			inc.w	R12


endsigned:

			pop		R15
			pop		R6 ;pops back saved values
			pop   	R5

			ret


; you can and should call x_times_y provided below



; DO NOT MODIFY THE SUBROUTINES BELOW
;-------------------------------------------------------------------------------
; Subroutine: threshold
; Inputs: signed word x in R13 -- returned unchanged
;         pointer to output in R12 -- returned unchanged
;
; Output: +/- 1 written to address in R12
; 									 @R12 = +1 if R13 >= 0
; 									 @R12 = -1 if R13 < 0
;
; All other core registers in R4-R15 unchanged
;-------------------------------------------------------------------------------
threshold:
			tst.w	R13
			jn		declare_neg_one

declare_one:
			mov.w	#1, 0(R12)		; Cannot use indirect addressing for dest
			ret

declare_neg_one:
			mov.w	#-1, 0(R12)		; Use indexed mode instead
			ret


;-------------------------------------------------------------------------------
; Subroutine: x_times_y
; Inputs: unsigned byte x in R5 -- returned unchanged
;         unsigned byte y in R6 -- returned unchanged
;
; Output: unsigned number in R12 -- R12 = R5 * R6
;
; This time implement the long multiplication algorithm
;
; All other core registers in R4-R15 unchanged
;-------------------------------------------------------------------------------
x_times_y:

; Save afftected core registers on stack - You can add this part last once you
; know which registered are modified
			push.w 	R6
			push.w	R10
			push.w	R11

			clr.w	R12				; R12 will accumulate R5*R6
			clr.w	R10				; R10 will index bits j = 0, 1, ..., 7
			mov.w	#BIT0, R11 		; R11 has the bitmask to use with tst.w

check_next_bit:
			bit.w	R11, R5			; Is the jth bit 1?
			jnc		prep_next_bit	; If not prepare for checking next bit

			add.w	R6, R12			; Bit j is 1, add

prep_next_bit:
			rla.w	R11				; Prepare next bitmask
			rla.w	R6				; Prepare shifted version of R6
			inc.w	R10				; increase bit index
			cmp.w	#8, R10			; Are we done with all bits?
			jlo		check_next_bit

; Restore saved core registers from stack
; Watch the order and make sure not to leave anything behind
			pop.w	R11
			pop.w	R10
			pop.w	R6

			ret

;-------------------------------------------------------------------------------
; Subroutine: x_div_2powerP
;
; Inputs: signed number x in R12 -- modified by subroutine
;         unsigned number p in R10 -- returned unchanged
;
; Output: signed number in R12 -- R12 = Floor(R12 / 2^R10)
;
; All other core registers in R4-R15 unchanged
;-------------------------------------------------------------------------------
x_div_2powerP:

			push	R10

; Shift x in R12 R6=p times to the right
; Make a loop with R6 as counter
repeat_div_by2:
			tst.w	R10						; Possible to have R6=p=0
			jz 		end_x_div_2powerP		; corresponding to dividing by 1

			rra.w	R12						; shift R12 once
			dec.w	R10 						; account for the shift
			jnz		repeat_div_by2

end_x_div_2powerP:

			pop		R10
			ret


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
            
