.MODEL SMALL
.STACK 100H
.DATA
    ; --- MESSAGES ---
    msg_welcome       DB '=== ATM MACHINE SIMULATION ===$'
    msg_acct_num      DB 0DH,0AH,'Enter 4-digit Account Number (0000 to exit): $'
    msg_pin           DB 0DH,0AH,'Enter 4-digit PIN: $'
    msg_wrong_pin     DB 0DH,0AH,'Invalid PIN! Try again.$'
    msg_acct_not_found DB 0DH,0AH,'Account not found!$'
    msg_acct_blocked  DB 0DH,0AH,'This account is blocked!$'
    msg_blocked       DB 0DH,0AH,'Too many attempts! Account blocked.$'

    ; --- UPDATED MENU (History Removed) ---
    msg_menu          DB 0DH,0AH,0DH,0AH,'1. Check Balance',0DH,0AH,'2. Deposit Money',0DH,0AH,'3. Withdraw Money',0DH,0AH,'4. Change PIN',0DH,0AH,'5. Logout (Exit)',0DH,0AH,0DH,0AH,'NOTE: System limit is 65,535.',0DH,0AH,'Enter choice: $'

    msg_balance       DB 0DH,0AH,'Current Balance: $'
    msg_enter_amt     DB 0DH,0AH,'Enter amount: $'
    msg_invalid_amt   DB 0DH,0AH,'Invalid amount or insufficient funds!$'
    msg_min_wdraw     DB 0DH,0AH,'Minimum withdrawal is 200.$'
    msg_max_wdraw     DB 0DH,0AH,'Maximum withdrawal is 50,000.$'
    msg_mult_wdraw    DB 0DH,0AH,'Withdrawal must be in multiples of 100.$'
    msg_new_pin       DB 0DH,0AH,'Enter new 4-digit PIN: $'
    msg_pin_changed   DB 0DH,0AH,'PIN changed successfully!$'
    msg_exit          DB 0DH,0AH,0DH,0AH,'Thank you for using our ATM!$' ; Added newlines
    newline           DB 0DH,0AH,'$'
    msg_file_error    DB 0DH,0AH,'FATAL: File operation error!$'
    
    ; --- TRANSACTION CONSTANTS ---
    TXN_DEPOSIT       EQU 1
    TXN_WITHDRAW      EQU 2
    TXN_PIN_CHANGE    EQU 3
    
    ; --- ACCOUNT STATUS CONSTANTS ---
    STATUS_ACTIVE     EQU 0
    STATUS_BLOCKED    EQU 1

    ; --- HISTORY CONSTANTS (Kept for file structure compatibility) ---
    MAX_HISTORY_ENTRIES EQU 10
    HISTORY_RECORD_SIZE EQU 3
    HISTORY_DATA_SIZE   EQU MAX_HISTORY_ENTRIES * HISTORY_RECORD_SIZE ; 30 bytes

    ; --- ACCOUNT RECORD STRUCTURE (Unchanged for file compatibility) ---
    ACCT_NUM_OFF      EQU 0
    PIN_OFF           EQU 2
    STATUS_OFF        EQU 4
    BALANCE_OFF       EQU 5
    HIST_COUNT_OFF    EQU 7
    HIST_DATA_OFF     EQU 8
    ACCOUNT_RECORD_SIZE EQU 38

    ; --- DATA FOR MULTIPLE ACCOUNTS ---
    MAX_ACCOUNTS      EQU 3
    ACCOUNTS_DATA     DB MAX_ACCOUNTS * ACCOUNT_RECORD_SIZE DUP(0)

    ; --- FILE HANDLING DATA ---
    FILENAME          DB 'ATMDATA.BIN', 0
    FILE_HANDLE       DW ?
    DATA_BLOCK_SIZE   EQU MAX_ACCOUNTS * ACCOUNT_RECORD_SIZE
    
    ; --- RUNTIME VARIABLES ---
    attempts              DB 0
    CURRENT_ACCOUNT_OFFSET  DW ?

.CODE

; --- FILE LOADING Procedure ---
LOAD_DATA PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AH, 3DH
    MOV AL, 0
    LEA DX, FILENAME
    INT 21H
    JC LD_CREATE

    MOV FILE_HANDLE, AX

    MOV AH, 3FH
    MOV BX, FILE_HANDLE
    MOV CX, DATA_BLOCK_SIZE
    LEA DX, ACCOUNTS_DATA
    INT 21H
    JC LD_ERROR

    MOV AH, 3EH
    MOV BX, FILE_HANDLE
    INT 21H
    JC LD_ERROR
    
    JMP LD_DONE

LD_CREATE:
    PUSH DI
    
    ; Account 1: 1001, PIN 1234, Balance 10000
    LEA DI, ACCOUNTS_DATA
    MOV WORD PTR [DI + ACCT_NUM_OFF], 1001
    MOV WORD PTR [DI + PIN_OFF], 1234
    MOV BYTE PTR [DI + STATUS_OFF], STATUS_ACTIVE
    MOV WORD PTR [DI + BALANCE_OFF], 10000
    MOV BYTE PTR [DI + HIST_COUNT_OFF], 0

    ; Account 2: 1002, PIN 2222, Balance 5000
    ADD DI, ACCOUNT_RECORD_SIZE
    MOV WORD PTR [DI + ACCT_NUM_OFF], 1002
    MOV WORD PTR [DI + PIN_OFF], 2222
    MOV BYTE PTR [DI + STATUS_OFF], STATUS_ACTIVE
    MOV WORD PTR [DI + BALANCE_OFF], 5000
    MOV BYTE PTR [DI + HIST_COUNT_OFF], 0

    ; Account 3: 1003, PIN 3333, Balance 200 (Blocked)
    ADD DI, ACCOUNT_RECORD_SIZE
    MOV WORD PTR [DI + ACCT_NUM_OFF], 1003
    MOV WORD PTR [DI + PIN_OFF], 3333
    MOV BYTE PTR [DI + STATUS_OFF], STATUS_BLOCKED
    MOV WORD PTR [DI + BALANCE_OFF], 200
    MOV BYTE PTR [DI + HIST_COUNT_OFF], 0
    
    POP DI
    
    CALL SAVE_DATA
    JMP LD_DONE

LD_ERROR:
    MOV AH, 09H
    LEA DX, msg_file_error
    INT 21H
    JMP EXIT_PROGRAM

LD_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
LOAD_DATA ENDP

; --- FILE SAVING Procedure ---
SAVE_DATA PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AH, 3CH
    MOV CX, 0
    LEA DX, FILENAME
    INT 21H
    JC SD_ERROR
    MOV FILE_HANDLE, AX

    MOV AH, 40H
    MOV BX, FILE_HANDLE
    MOV CX, DATA_BLOCK_SIZE
    LEA DX, ACCOUNTS_DATA
    INT 21H
    JC SD_ERROR

    MOV AH, 3EH
    MOV BX, FILE_HANDLE
    INT 21H
    JMP SD_DONE

SD_ERROR:
    MOV AH, 09H
    LEA DX, msg_file_error
    INT 21H

SD_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SAVE_DATA ENDP

; --- FIND ACCOUNT Procedure ---
FIND_ACCOUNT PROC
    PUSH CX
    PUSH SI
    PUSH AX

    LEA SI, ACCOUNTS_DATA
    MOV CX, MAX_ACCOUNTS
    
FA_LOOP:
    CMP AX, [SI + ACCT_NUM_OFF]
    JE FA_FOUND
    ADD SI, ACCOUNT_RECORD_SIZE
    LOOP FA_LOOP
    
    STC
    JMP FA_DONE

FA_FOUND:
    MOV DI, SI
    CLC

FA_DONE:
    POP AX
    POP SI
    POP CX
    RET
FIND_ACCOUNT ENDP


MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    CALL LOAD_DATA

;--- Welcome Screen ---
START_SCREEN:
    CALL CLEAR_SCREEN
    MOV AH, 09H
    LEA DX, msg_welcome
    INT 21H

;--- Account Number Check ---
ACCOUNT_CHECK:
    MOV AH, 09H
    LEA DX, msg_acct_num
    INT 21H

    CALL INPUT_NUMBER
    
    ; --- Check for 0000 to exit ---
    CMP AX, 0
    JNE NOT_EXIT            ; <-- FIX: Short jump
    JMP NEAR PTR CLEAN_EXIT ; <-- FIX: Long jump
NOT_EXIT:
    
    CALL FIND_ACCOUNT
    JAE ACCT_FOUND      ; JAE is opposite of JC (JB)
    JMP NEAR PTR ACCT_NOT_FOUND ; Use a long jump
ACCT_FOUND:

    MOV CURRENT_ACCOUNT_OFFSET, DI
    MOV attempts, 0
    JMP PIN_CHECK

ACCT_NOT_FOUND:
    MOV AH, 09H
    LEA DX, msg_acct_not_found
    INT 21H
    CALL PRESS_ANY_KEY
    JMP START_SCREEN

;--- PIN Check ---
PIN_CHECK:
    MOV DI, CURRENT_ACCOUNT_OFFSET
    CMP BYTE PTR [DI + STATUS_OFF], STATUS_BLOCKED
    JNE PIN_NOT_BLOCKED     ; Short jump
    JMP NEAR PTR ACCT_BLOCKED ; Long jump
PIN_NOT_BLOCKED:

    MOV AH, 09H
    LEA DX, msg_pin
    INT 21H

    CALL INPUT_HIDDEN
    MOV BX, AX
    MOV AX, [DI + PIN_OFF]
    CMP AX, BX
    JNE PIN_IS_WRONG        ; <-- FIX: Short jump
    JMP NEAR PTR MAIN_MENU_JUMP ; <-- FIX: Long jump
PIN_IS_WRONG:

    INC attempts
    CMP attempts, 3
    JAE DO_BLOCK_ACCOUNT    ; JAE is opposite of JB (JGE also works)
    JMP NEAR PTR WRONG_PIN  ; Long jump
DO_BLOCK_ACCOUNT:
    JMP NEAR PTR BLOCK_ACCOUNT ; Long jump

WRONG_PIN:
    MOV AH, 09H
    LEA DX, msg_wrong_pin
    INT 21H
    JMP PIN_CHECK

ACCT_BLOCKED:
    MOV AH, 09H
    LEA DX, msg_acct_blocked
    INT 21H
    CALL PRESS_ANY_KEY
    JMP START_SCREEN

BLOCK_ACCOUNT:
    MOV DI, CURRENT_ACCOUNT_OFFSET
    MOV BYTE PTR [DI + STATUS_OFF], STATUS_BLOCKED
    CALL SAVE_DATA
    
    MOV AH, 09H
    LEA DX, msg_blocked
    INT 21H
    CALL PRESS_ANY_KEY
    JMP START_SCREEN

;--- Main Menu ---
MAIN_MENU:
    CALL CLEAR_SCREEN
    MOV AH, 09H
    LEA DX, msg_menu
    INT 21H

    CALL INPUT_NUMBER
    MOV DI, CURRENT_ACCOUNT_OFFSET

    ; --- FIX: Corrected jump logic for all menu options ---
    CMP AX, 1
    JNE MENU_CHECK_2
    JMP NEAR PTR SHOW_BAL
MENU_CHECK_2:
    CMP AX, 2
    JNE MENU_CHECK_3
    JMP NEAR PTR DEPOSIT
MENU_CHECK_3:
    CMP AX, 3
    JNE MENU_CHECK_4
    JMP NEAR PTR WITHDRAW
MENU_CHECK_4:
    CMP AX, 4
    JNE MENU_CHECK_5
    JMP NEAR PTR CHANGE_PIN
MENU_CHECK_5:
    CMP AX, 5
    JNE INVALID_CHOICE
    JMP NEAR PTR LOGOUT
    
INVALID_CHOICE:
    JMP NEAR PTR MAIN_MENU
    ; ----------------------------------------------------------

;--- Show Balance ---
SHOW_BAL:
    CALL CLEAR_SCREEN
    MOV AH, 09H
    LEA DX, msg_balance
    INT 21H

    MOV AX, [DI + BALANCE_OFF]
    CALL PRINT_NUMBER
    
    CALL PRESS_ANY_KEY
    JMP NEAR PTR MAIN_MENU

;--- Deposit ---
DEPOSIT:
    CALL CLEAR_SCREEN
    MOV AH, 09H
    LEA DX, msg_enter_amt
    INT 21H

    CALL INPUT_NUMBER
    CMP AX, 0
    JNE DEPOSIT_ACTION      ; Short jump
    JMP NEAR PTR MAIN_MENU  ; Long jump
DEPOSIT_ACTION:
    
    ADD [DI + BALANCE_OFF], AX
    CALL SAVE_DATA
    
    CALL PRESS_ANY_KEY
    JMP NEAR PTR MAIN_MENU

;--- Withdraw ---
WITHDRAW:
    CALL CLEAR_SCREEN
    MOV AH, 09H
    LEA DX, msg_enter_amt
    INT 21H

    CALL INPUT_NUMBER
    MOV BX, AX

    ; --- FIX: Applied correct jump logic to all checks ---
    
    ; Check 1: Multiple of 100
    MOV CX, 100
    XOR DX, DX
    MOV AX, BX
    DIV CX
    CMP DX, 0
    JE MULT_OKAY            ; Short jump
    JMP NEAR PTR MULT_ERR   ; Long jump
MULT_OKAY:

    ; Check 2: Min withdrawal
    CMP BX, 200
    JAE MIN_OKAY            ; Short jump (JAE is opposite of JB)
    JMP NEAR PTR MIN_ERR    ; Long jump
MIN_OKAY:

    ; Check 3: Max withdrawal
    CMP BX, 50000
    JBE MAX_OKAY            ; Short jump (JBE is opposite of JA)
    JMP NEAR PTR MAX_ERR    ; Long jump
MAX_OKAY:
    
    ; Check 4: Sufficient funds
    MOV AX, [DI + BALANCE_OFF]
    CMP AX, BX
    JAE FUNDS_OKAY          ; Short jump (JAE is opposite of JB)
    JMP NEAR PTR INSUFFICIENT_FUNDS ; Long jump
FUNDS_OKAY:

    ; All checks passed
    SUB [DI + BALANCE_OFF], BX
    CALL SAVE_DATA
    JMP NEAR PTR MAIN_MENU
    ; ----------------------------------------------------

MIN_ERR:
    MOV AH, 09H
    LEA DX, msg_min_wdraw
    INT 21H
    CALL PRESS_ANY_KEY
    JMP NEAR PTR MAIN_MENU
MAX_ERR:
    MOV AH, 09H
    LEA DX, msg_max_wdraw
    INT 21H
    CALL PRESS_ANY_KEY
    JMP NEAR PTR MAIN_MENU
MULT_ERR:
    MOV AH, 09H
    LEA DX, msg_mult_wdraw
    INT 21H
    CALL PRESS_ANY_KEY
    JMP NEAR PTR MAIN_MENU
INSUFFICIENT_FUNDS:
    MOV AH, 09H
    LEA DX, msg_invalid_amt
    INT 21H
    CALL PRESS_ANY_KEY
    JMP NEAR PTR MAIN_MENU

;--- Change PIN ---
CHANGE_PIN:
    CALL CLEAR_SCREEN
    MOV AH, 09H
    LEA DX, msg_new_pin
    INT 21H

    CALL INPUT_HIDDEN
    MOV [DI + PIN_OFF], AX

    CALL SAVE_DATA
    
    MOV AH, 09H
    LEA DX, msg_pin_changed
    INT 21H
    CALL PRESS_ANY_KEY
    JMP NEAR PTR MAIN_MENU

;--- Logout (Return to Account Entry) ---
LOGOUT:
    JMP START_SCREEN
    
;--- Clean Exit (Show exit message and quit) ---
CLEAN_EXIT:
    CALL CLEAR_SCREEN
    MOV AH, 09H
    LEA DX, msg_exit
    INT 21H
    JMP EXIT_PROGRAM    ; Jump to the final 4CH exit

;--- Exit Program (Used for file errors or clean exit) ---
EXIT_PROGRAM:
    MOV AH, 4CH
    INT 21H

;--- Helper Jump label ---
MAIN_MENU_JUMP:
    JMP NEAR PTR MAIN_MENU

MAIN ENDP

;--- Helper Procedures ---
PRESS_ANY_KEY PROC
    PUSH AX
    PUSH DX
    MOV AH, 09H
    LEA DX, newline
    INT 21H
    MOV AH, 07H ; Get char without echo
    INT 21H
    POP DX
    POP AX
    RET
PRESS_ANY_KEY ENDP

CLEAR_SCREEN PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV AH, 06H
    XOR AL, AL
    MOV BH, 07H
    XOR CX, CX
    MOV DX, 184FH
    INT 10H
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CLEAR_SCREEN ENDP

;--- UPDATED PROCEDURE: INPUT_HIDDEN ---
INPUT_HIDDEN PROC
    PUSH BX
    PUSH CX
    PUSH DX

    XOR BX, BX

READ_PIN_CHAR:
    MOV AH, 08H
    INT 21H

    CMP AL, 0DH
    JE PIN_INPUT_DONE
    
    CMP AL, 08H
    JE HANDLE_BACKSPACE

    CMP AL, '0'
    JB READ_PIN_CHAR
    CMP AL, '9'
    JA READ_PIN_CHAR

    SUB AL, '0'
    XOR AH, AH

    PUSH AX
    MOV AX, BX
    MOV CX, 10
    MUL CX
    POP DX
    ADD AX, DX
    MOV BX, AX

    JMP READ_PIN_CHAR

HANDLE_BACKSPACE:
    CMP BX, 0
    JE READ_PIN_CHAR
    
    MOV AX, BX
    XOR DX, DX
    MOV CX, 10
    DIV CX
    MOV BX, AX
    
    JMP READ_PIN_CHAR

PIN_INPUT_DONE:
    PUSH AX
    PUSH DX
    MOV AH, 02H
    MOV DL, 0DH
    INT 21H
    MOV DL, 0AH
    INT 21H
    POP DX
    POP AX
    
    MOV AX, BX
    POP DX
    POP CX
    POP BX
    RET
INPUT_HIDDEN ENDP

; --- This is the standard input for amounts, account numbers, etc. ---
INPUT_NUMBER PROC
    PUSH BX
    PUSH CX
    PUSH DX

    XOR BX, BX

READ_CHAR:
    MOV AH, 01H
    INT 21H

    CMP AL, 0DH
    JE INPUT_DONE
    
    CMP AL, '0'
    JB READ_CHAR
    CMP AL, '9'
    JA READ_CHAR

    SUB AL, '0'
    XOR AH, AH

    PUSH AX
    MOV AX, BX
    MOV CX, 10
    MUL CX
    POP DX
    ADD AX, DX
    MOV BX, AX

    JMP READ_CHAR

INPUT_DONE:
    MOV AX, BX
    POP DX
    POP CX
    POP BX
    RET
INPUT_NUMBER ENDP

PRINT_NUMBER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    CMP AX, 0
    JNE PN_START
    MOV DL, '0'
    MOV AH, 02H
    INT 21H
    JMP PN_DONE

PN_START:
    XOR CX, CX
    MOV BX, 10
PN_LOOP:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE PN_LOOP
PN_PRINT:
    POP DX
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    LOOP PN_PRINT

PN_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUMBER ENDP

END MAIN

