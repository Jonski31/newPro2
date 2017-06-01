// Instead of temp1 we will use r23 to store the return of this function

colloop:
	cpi col, 4
	breq zeroReturnBridge; If all keys are scanned, repeat.
	sts PORTL, cmask ; Otherwise, scan a column.
	ldi temp1, 0xFF ; Slow down the scan operation.
delay: 
	dec temp1
	brne delay
	lds temp1, PINL ; Read PORTL
	andi temp1, ROWMASK ; Get the keypad output value
	cpi temp1, 0xF ; Check if any row is low
	breq nextcol
	; If yes, find which row is low
	ldi rmask, INITROWMASK ; Initialize for row check
	clr row ; 

rowloop:
	cpi row, 4
	breq nextcol ; the row scan is over.
	mov temp2, temp1
	and temp2, rmask ; check un-masked bit
	breq convert ; if bit is clear, the key is pressed
	inc row ; else move to the next row
	lsl rmask
	jmp rowloop

zeroReturnBridge: // NO KEYS ARE SCANNED PREVIOUS NUMBER = 0!
	ldi temp, 0
	sts prevNum, temp
	jmp returnKeypad

nextcol: ; if row scan is over
	lsl cmask
	inc col ; increase column value
	jmp colloop ; go to the next column

convert:
	checkIfMenu 1			;if menu is 1 call select screen on button touch
	breq branchSelectScreenBridge 
	
	cpi col, 3 ; If the pressed key is in col.3
	breq lettersBridge ; we have a letter
	; If the key is not in col.3 and
	cpi row, 3 ; If the key is in row3,
	breq symbolsBridge ; we have a symbol or 0
	mov r23, row ; Otherwise we have a number in 1-9
	lsl r23
	add r23, row
	add r23, col ; r23 = row*3 + col
	subi r23, -1 ; r23 = row*3 + col + '1'
	
	checkIfMenu 2			//check if on menu 2 if not jump to end
	breq storeKeypadBridge1
	checkIfMenu 6			//check if in admin mode
	breq updateAdminBridge	//if in admin mode, we need to store the current press and display it and its variables
	jmp returnKeypad		

	// Relative Key Branches
lettersBridge:
	jmp letters
storeKeyPadBridge1:
	jmp storeKeyPad
symbolsBridge:
	jmp symbols
branchSelectScreenBridge:
	jmp branchSelectScreen
updateAdminBridge:

   	getInventory r23
    sts numPressed, r23		// here we store the number pressed from the keypad to update into our display
	out portc, r23
			
	jmp updateAdmin         // possibly have two updates one for the items attributes another to increment that item.
							// Here we need to load a new item (getInventory) 
returnKeyPadBridge1:
	jmp returnKeyPad

letters:
A:
	ldi r23, 'A'
	add r23, row ; Get the ASCII value for the key

	checkIfMenu 6				; check if in admin mode. If we are we now wait for A, B and C
	brne returnKeypadBridge1	
	
	cpi r23, 'A'				; First check if A is pressed
	brne B

	increaseCost				;if it is we increase the cost of the current item (doesn't work)
	rjmp storeKeypad
B:						
	cpi r23, 'B'				;Check if B is pressed
	brne C
	decreaseCost				;If its pressed decrease cost of current item (doesn't work)
	rjmp storeKeypad			
C:
	ldi temp, 0					;Check if C is pressed
	sts currentStock, temp		; If pressed make stock 0
	rjmp storeKeypad			

// Bridges for rjmps
storeKeyPadBridge:	
	jmp storeKeyPad

returnKeyPadBridge:
	jmp returnKeyPad

symbols:
	cpi col, 0 ; Check if we have a star
	breq star
	cpi col, 1 ; or if we have zero
	breq zero
	ldi r23, '#' ; if not we have hash

	checkIfMenu 4			;if on insert coins screen move to select screen
	breq branchSelectScreen

	checkIfMenu 6			;if in admin mode move to select screen :)
	breq branchSelectScreen
	jmp returnKeypad
star:
	ldi r23, '*'		; Set to star
	checkIfMenu 2		; ADMIN MODE requires setScreen menu (2)
	brne returnKeypadBridge

	lds temp, prevNum	;at this point prevNum is previous value of the keypad
	cpi temp, '*'		;now check previous value of numpressed was '*' so we dont reset the timer
	breq storeKeypad	;store next '*' into numPressed

	ldi temp, 20		;store 20 into timer5 to measure 5 secs for admin mode
	sts timer6, temp	
	jmp storeKeypad		
zero:
	ldi r23, 0 ; Set to zero
	jmp returnKeypad

branchSelectScreen:
	rcall selectScreen	
	rjmp returnKeypad
branchOOSScreen:
	rcall outOfStockScreen
	;clr r23
	rjmp returnKeypad

// Store keypad when we need output value otherwise return
storeKeypad:
	checkIfMenu 6			; if in menu 6 (Admin mode), dont store numpressed as we will set it with digit code. This just handles A,B and C
	breq updateAdmin		; update admin menu that writes the new values for changed item attributes

	sts numPressed, r23   //here we store r23 into numpressed just cause...
	cpi r23, '*'			; if * is pressed return and store it in previous
	breq storePrev

	checkIfMenu 2			//check again if menu = 2 
	brne returnKeypadBridge		//if it doesn't jump to end, if it does do macro
	isStockEmpty r23		//if true, branch to the out of stock screen
	breq branchOOSScreen
	
	rcall coinScreen
	jmp returnKeypad

storePrev:
	sts prevNum, r23
	rjmp returnKeypad
updateAdmin:
	updateAdminScreen
	lds temp, currentCost
	;out portc, temp	

returnKeypad:
	ret
	

