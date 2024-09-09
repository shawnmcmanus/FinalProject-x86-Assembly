TITLE Project 6 - String Primitives and Macros     (Proj6_mcmansha.asm)

; Author: Shawn McManus
; Last Modified: 8/13/2024
; Project Number: 6                Due Date: 8/16/2024
; Description: Uses macros and procedures to implement own 
; low-level I/O procedures like ReadInt and WriteInt.

INCLUDE Irvine32.inc

;----------------------------------------------------------------
; Prompts an entry stores the input and total bytes of entry
; receives: prompt, input storage address, buffer size, storage for number of bytes
; returns: Number of bytes
; preconditions: proper parameters are passed
; registers changed: EAX, ECX, EDX
;----------------------------------------------------------------

mGetString MACRO prompt_para:REQ, input:REQ, count_para:REQ, bytesNum:REQ
	push	EAX
	push	ECX
	push	EDX

	mov		EDX, prompt_para			;Need to include OFFSET when filling in parameters
	call	WriteString
	mov		EDX, input					;Loads address of input buffer into EDX
	mov		ECX, count_para				;Buffer size		
	call	ReadString					
	mov     [bytesNum], EAX


	pop		EDX
	pop		ECX
	pop		EAX
ENDM

;----------------------------------------------------------------
; Displays a string
; receives: string address
; returns: None
; preconditions: passed address is for a string
; registers changed: EDX
;----------------------------------------------------------------

mDisplayString MACRO string_para:REQ
	push	EDX

	mov		EDX, string_para
	call	WriteString

	pop		EDX
ENDM
	
;Global variables

LOWER_RANGE = 80000000h			;Signed 32-bit register min (-2^31)
UPPER_RANGE = 7FFFFFFFh			;Signed 32-bit register max (2^31 - 1)
ARRAY_SIZE = 10

.data

greeting			BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level Input/Output procedures and macros.",13,10,
							"Written by: Shawn McManus",13,10,13,10,0
prompt_1			BYTE	"Please provide 10 signed decimal integers.",13,10,
							"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting",
							"the raw numbers I will display a list of the integers, their sum, and their average value.",13,10,0
input_request			BYTE	"Please enter a signed number: ",0
error_message			BYTE	"ERROR: You did not enter a signed number or your number was too big.",13,10,
							"Please try again.",13,10,0
entry_message			BYTE	13,10,"You entered the following numbers:",13,10,0
comma_sep			BYTE	", ",0
sum_message			BYTE	"The sum of these numbers is: ",0
avg_message			BYTE	"The truncated average: ",0
farewell_message		BYTE	13,10,"Thanks for playing!",13,10,0

userVal				BYTE	31 DUP(?)
bytesNum			DWORD	?
buffer				BYTE	16 DUP(?)				
intArray			SDWORD	ARRAY_SIZE DUP(?)
sumVal				SDWORD	?
avgVal				SDWORD	?
count				DWORD	?						



.code
main PROC
	push	OFFSET greeting
	push	OFFSET prompt_1
	call	introduction				;Prints out an intro message


	mov	ECX, 10
	mov	EDI, OFFSET intArray
_getIntLoop:							;Loop for converting entries into integers
	push	LOWER_RANGE
	push	OFFSET error_message
	push	bytesNum
	push	SIZEOF userVal
	push	OFFSET userVal
	push	OFFSET input_request
	call	read_val					;Read Val Proc
	loop	_getIntLoop


	  mDisplayString OFFSET entry_message
	mov	ECX, ARRAY_SIZE
	mov	ESI, OFFSET intArray
	mov	count, ARRAY_SIZE - 1
_displayLoop:							;Loop for displaying values in the array
	push	count
	push	OFFSET comma_sep
	push	SIZEOF buffer
	push	OFFSET buffer
	call	write_val					;Write Val Proc
	add	ESI, TYPE SDWORD				;Moves to next val in the array
	dec	count						;Keeps count of values printed for comma placement
	loop	_displayLoop
	call	CrLf


	mov	count, 0
	mov	EDI, OFFSET sumVal
	mov	ESI, OFFSET intArray
	push	count						;Comma count
	push	OFFSET comma_sep
	push	SIZEOF buffer
	push	OFFSET buffer
	push	OFFSET sum_message
	call	sum_array					;Returns the sum of the array


	mov	count, 0
	mov	EDI, OFFSET avgVal
	mov	ESI, OFFSET intArray
	push	UPPER_RANGE
	push	OFFSET ARRAY_SIZE
	push	sumVal
	push	count
	push	OFFSET comma_sep
	push	SIZEOF buffer
	push	OFFSET buffer
	push	OFFSET avg_message
	call	avg_array					;Returns the sum of the array


	push	OFFSET farewell_message
	call	conclusion					;Prints out goodbye message

	Invoke ExitProcess,0					; exit to operating system
main ENDP


;----------------------------------------------------------------
; Introduces the programs purpose to the user
; receives: offset of two strings (greeting & prompt_1)
; returns: None
; preconditions: mDisplayString macro and input strings defined already
; registers changed: EBP
;----------------------------------------------------------------

introduction PROC
	push	EBP
	mov	EBP, ESP
	  mDisplayString [EBP + 12]
	  mDisplayString [EBP + 8]
	pop		EBP
	ret		8
introduction ENDP


;----------------------------------------------------------------
; Reads a string value that will later be converted into an integer
; receives: parameters needed for mGetString macro
; returns: None
; preconditions: mGetString macro and parameters are set-up correctly
; postconditions: single string input from the user is inserted into the array
; registers changed: EBP, EAX, EBX, ECX, EDX, ESI, EDI
;----------------------------------------------------------------

read_val PROC
	push	EBP
	mov	EBP, ESP
	push	EAX
	push	EBX
	push	ECX
	push	EDX
	push	ESI
_enterValidVal:
	  mGetString [EBP + 8], [EBP + 12], [EBP + 16], [EBP + 20]
	cld
	mov	ESI, [EBP + 12]				;Set ESI to address of userVal input
	mov	ECX, [EBP + 20]				;Set ECX to length of the string
	xor	EDX, EDX
	xor	EBX, EBX

	lodsb
	cmp	AL, 45					;45 checks for negative
	je	_negative
	cmp	AL, 43					;43 checks for positive
	je	_positive
	push	EBX
	jmp		_noSign

_negative:
	inc	EBX					;With EBX = 1, we say Sign Flag is set
	push	EBX
	jmp	_convertLoop
	

_positive:
	push	EBX
	jmp	_convertLoop
	

_convertLoop:
	lodsb						;Loads next character
_noSign:
	cmp	AL, 0					;Check if the character is the null terminator
	je	_conversionComplete

	cmp	AL, 48					;Check if value is '0' to '9' with ASCII values
	jl	_invalidInput
	cmp	AL, 57
	jg	_invalidInput

	sub	AL, 48					;Convert ASCII values to numeric values
	movzx   EBX, AL					;Move and zero extend the numeric value in AL to EBX

	mov     EAX, EDX				;Load the current total integer value from EDX
	imul    EAX, 10					;Multiply EAX by 10 to make space for the next digit
	jo	_invalidInput
	add     EAX, EBX				;Add the new digit (from EBX) to the total value
	jo	_invalidInput
	mov     EDX, EAX				;Store the updated "integer" string value back in EDX

	jmp	_convertLoop

_invalidInput:
	_edgeCaseContinue:
		cmp	ECX, 11
		jne	_continue
		cmp	EAX, [EBP + 28]
		je	_conversionComplete		;Val entered is -2147483648

	_continue:
		 mDisplayString [EBP + 24]		;Print error message
		pop	EBX
		jmp 	_enterValidVal

_conversionComplete:
	pop	EBX
	cmp	EBX, 1
	jne	_storeInArray
	neg	EDX

_storeInArray:
	mov	[EDI], EDX
	add	EDI, TYPE SDWORD

_done:
	pop	ESI
	pop	EDX
	pop	ECX
	pop	EBX
	pop	EAX
	pop	EBP
	ret	24
read_val ENDP


;----------------------------------------------------------------
; Converts a numeric SDWORD to a string of ASCII digits to be printed
; receives: array of signed 32-bit integers
; returns: None (prints out a string)
; preconditions: necessary parameters passed and number held in ESI address
; registers changed: EBP, EAX, EBX, ECX, EDX, ESI, EDI
;----------------------------------------------------------------

write_val PROC
	push	EBP
	mov	EBP, ESP
	push	EAX
	push	EBX
	push	ECX
	push	EDX
	push	ESI

	add	ESI, 3							;Brings us to the beginning of the 32-bit integer
	mov	EDI, [EBP + 8]
	mov	ECX, 4							;Each 32-bit number takes up 4 bytes in memory
	std								;Set flag to count reverse order

_invertStorageLoop:							;Reverse little-endian order and load into buffer [EDI]
	lodsb
	stosb
	loop	_invertStorageLoop
											
	inc	EDI							;store proper order of num ex: 01 23 45 67 in EDI
	mov	EAX, [EDI]						;Move hexadecimal representation of num into EAX
	xor	ECX, ECX
_checkForNeg:
	cmp	EAX, 0
	jge	_continue

_negative:
	neg	EAX
	mov	ECX, 1							;Sets ECX for negative check

_continue:
	mov	EDI, [EBP + 8]						;Move EDI to buffer
	sub	EDI, [EBP + 12]						;Create space for size of buffer
	mov	BL, 0
	mov	[EDI], BL						;Move null terminator to what will be the end of the ASCII values

_convertLoop:
	xor	EDX, EDX
	mov	EBX, 10
	div	EBX							;Divide hexadec number by 10
	add	DL, 48							;Add 48 (30h) to convert to ASCII value
	dec	EDI							;Moves to next byte in EDI
	mov	[EDI], DL						;Places ASCII value into EDI index
	cmp	EAX, 0
	jne	_convertLoop
	cmp	ECX, 1							
	jne	_printVal

_forNegative:
	mov	BYTE PTR [EDI - 1], '-'					;Add '-' byte to beginning of number
	dec	EDI

_printVal:
	  mDisplayString EDI
	mov	ECX, [EBP + 20]
	cmp	ECX, 0
	je	_done							;Skips over comma append for last value
	mov	EDX, [EBP + 16]
	call	WriteString						;Adds comma

_done:
	add	ESI, 4							;Moves to next 32-bit integer

	pop	ESI
	pop	EDX
	pop	ECX
	pop	EBX
	pop	EAX
	pop	EBP
	ret	16
write_val ENDP

;----------------------------------------------------------------
; Calculates the sum of an array of values
; receives: sum_message string
; returns: sum of the array
; preconditions: A valid array of numbers is passed 
; registers changed: EBP, EAX, ECX, EDX, ESI, EDI
;----------------------------------------------------------------

sum_array PROC
	push	EBP
	mov	EBP, ESP
	push	EAX
	push	ECX
	push	EDX
	
	  mDisplayString [EBP + 8]
	xor	EAX, EAX
	mov	ECX, 10							;Sets loop count to 10 (array size)				
_sumLoop:
	add	EAX, [ESI]						;Add element from intArray and increment to next number in memory	
	add	ESI, TYPE intArray
	loop	_sumLoop

	mov	[ESI], EAX						;Move sum to ESI index so write_val can print
	mov	[EDI], EAX						;Move sum to EDI index for avg_array proc
	push	[EBP + 24]
	push	[EBP + 20]
	push	[EBP + 16]
	push	[EBP + 12]
	call	write_val
	call	CrLf

	pop		EDX
	pop		ECX
	pop		EAX
	pop		EBP
	ret		20
sum_array ENDP


;----------------------------------------------------------------
; Calculates the truncated average of an array of values
; receives: avg_message string
; returns: average of the array
; preconditions: A valid sum is calculated and passed 
; registers changed: EBP, EAX, EBX, EDX, ESI, EDI
;----------------------------------------------------------------

avg_array PROC
	push	EBP
	mov	EBP, ESP
	push	EAX
	push	EBX
	push	EDX

	  mDisplayString [EBP + 8]
	xor	EAX, EAX
	xor	EDX, EDX
	mov	EAX, [EBP + 28]						;Move sumVal into EAX
	mov	EBX, [EBP + 36]						;Move UPPER_RANGE to EBX

_negativeAvg:
	neg	EAX								
	mov	EBX, [EBP + 32]
	cdq
	idiv	EBX							;Divide by UPPER_RANGE
	neg	EAX							;Converts negatives back to negative and positives back to positives

_printAvg:
	add	ESI, TYPE intArray				
	mov	[ESI], EAX						;Move avgVal to ESI index for write_val
	mov	[EDI], EAX						;Move avgVal to EDI index for storage
	push	[EBP + 24]
	push	[EBP + 20]
	push	[EBP + 16]
	push	[EBP + 12]
	call	write_val
	call	CrLf

	pop	EDX
	pop	EBX
	pop	EAX
	pop	EBP
	ret	32
avg_array ENDP


;----------------------------------------------------------------
; Concludes the program
; receives: farewell_message string
; returns: None
; preconditions: The rest of the program completed successfully 
; registers changed: EBP
;----------------------------------------------------------------

conclusion PROC
	push	EBP
	mov	EBP, ESP
	  mDisplayString [EBP + 8]					;Print out farewell message
	pop	EBP
	ret	4
conclusion ENDP

END main
