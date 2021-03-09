; File: hammingecc.asm
;
; This program implements the Hamming (8,4) ECC.
; Input is limited to 8 characters (minimum and maximum).
;
; Encoding format:
;                 ------------------------------------------------
; bit position    | 8   | 7   | 6   | 5   | 4   | 3   | 2   | 1  |
;                 ------------------------------------------------
; parity order    | p4  | d4  | d3  | d2  | p3  | d1  | p2  | p1 |
;                 ------------------------------------------------     
;
; Assemble using NASM:  nasm -g -f elf -F dwarf hammingecc.asm
; Compile using gcc:    gcc -m32 hammingecc.o -o hammingecc
; Debug using gdb:      gdb -tui hammingecc
;
;

%define STDIN         0
%define STDOUT        1
%define SYSCALL_EXIT  1
%define SYSCALL_READ  3
%define SYSCALL_WRITE 4
%define BUFLEN        9

        section .data                                   ; section declaration
msg     db  'Input Data: '                              ; Input prompt
len     equ $ - msg                                     ; length of input prompt


msgI    db  'Invalid Data!',0Ah                         ; Invalid data message
lenI    equ $ - msgI                                    ; length of invalid data message


msgE    db  'Two or more bit errors detected!',0Ah      ; Two or more bit errors detected
lenE    equ $ - msgE                                    ; length of two or more bit errors detected


bitE    db  'Bit error detected at position: '          ; Bit error string
lenBE   equ $ - bitE                                    ; length of bit error string

msgC    db  0Ah,'Corrected bit sequence: '                 ; Corrected string
lenC    equ $ - msgC                                    ; length of corrected string


msgA    db  'Overall Parity Error Detected',0Ah         ; our string
lenA    equ $ - msgA                                    ; length of our string

bitNE   db  'No Error Detected',0Ah                     ; our string
lenNE   equ $ - bitNE                                   ; length of our string


        section .bss                                    ; section declaration
P4      resb 1                                          ;Store 4th parity bit
P3      resb 1                                          ;Store 3rd parity bit
P2      resb 1                                          ;Store 2nd parity bit
P1      resb 1                                          ;Store 1st parity bit
D4      resb 1                                          ;Store 4th data bit
D3      resb 1                                          ;Store 3rd data bit
D2      resb 1                                          ;Store 2nd data bit
D1      resb 1                                          ;Store 1st data bit                 
mod     resb 8                                          ;For use in modulus operation
P4bits  resb 7                                          ;Stores the Bit results for parity
Pbits   resb 3                                          ;for use in modulus operation
parity  resb 4                                          ;stores user input parity bits
data    resb 4                                          ;stores user input data bits
temp    resb BUFLEN+10                                  ; our string
binD    resb 1                                          ; original binary
pos     resb 2                                          ; bit error position
result  resb BUFLEN                                     ; corrected result


        section .text                                   ; Code section.
        global main

main:   
        mov     eax,SYSCALL_WRITE                       ; system call number (sys_write)
        mov     ebx,STDOUT                              ; file descriptor (stdout)
        mov     ecx,msg                                 ; message to write
        mov     edx,len                                 ; message length
        int     80h                                     ; call kernel


        mov     eax,SYSCALL_READ                        ; system call number (sys_read)
        mov     ebx,STDIN                               ; file descriptor (stdin)
        mov     ecx,temp                                ; message to write
        mov     edx,BUFLEN+10                           ; message length
        int     80h                                     ; call kernel

        cmp     eax,BUFLEN                              ; check to see if user input exceeded limit                 
        jg      invalid                                 ; if exceeded, print invalid message

initbin:                                                ; sequence that converts user input in ASCII to binary
        mov     edx, temp                               ; initialize EDX with the address of user input
        xor     edi, edi                                ; initialize EDI for index tracking
        mov     ecx, BUFLEN-1                           ; initialize counter ECX to keep track of user input
        mov     ebx, 0                                  ; initialize EBX, which will eventually hold the ...
                                                        ; ... converted binary in its upper byte BH

binchk:                                                 ; loop that converts user input to binary 
        mov     bl, byte[edx+edi]                       ; BL will initially hold each character in the user input     
        inc     edi                                     ; proceed to next character index
        sub     bl, '0'                                 ; determine the decimal equivalent of the character
        cmp     bl, 1                                   ; this comparison additionally checks for invalid characters
        jg      invalid                                 ; if the user input an invalid character print invalid message
        shl     bh, 1                                   ; shift value in BH by one bit position to accomodate the ...
        xor     bh, bl                                  ; ... next converted bit
        loop    binchk                                  ; loop instruction performs a jmp after decrementing ECX by one ...
                                                        ; ... if ECX is 0, no jmp is performed and the next instruction ...
                                                        ; ... is executed

;begin:
        ;mov [F100],bh

begin8:                                                 ; implement your parity checker here. call/jmp to appropriate routine when necessary
        mov ax,0                                        ;set AX to 0 
        shl bh,1                                        ;P4 shifts bh(stores the user input:UI)       
        jc parity1p4                                    ;if P4 = 1
        jmp parity0p4                                   ;if P4 = 0

begin7:                                                 ;D4
        shl bh,1                                        ;shifts UI
        jc data1d4                                      ;look at begin8 for explination
        jmp data0d4

begin6:                                                 ;D3
        shl bh,1                                        ;shifts UI
        jc data1d3                                      
        jmp data0d3

begin5:                                                 ;D2
        shl bh,1                                        ;shifts UI
        jc data1d2
        jmp data0d2

begin4:                                                 ;P3
        shl bh,1                                        ;shifts UI
        jc parity1p3
        jmp parity0p3

begin3:                                                 ;D1
        shl bh,1                                        ;shifts UI
        jc data1d1
        jmp data0d1

begin2:                                                 ;P2
        shl bh,1                                        ;shifts UI
        jc parity1p2
        jmp parity0p2

begin1:                                                 ;P1
        shl bh,1                                        ;shifts UI
        jc parity1p1
        jmp parity0p1

parity1p4:                                              ;Puts a 1 in for P4 and parity variables
        mov cl,1                                        ;puts 1 into cl so it can be transfered into memeory
        mov [P4],cl                                     ;transfers into memory
        add ah,1b                                       ;add a one to the AH register
        shl ah,1                                        ;shifts so the next number can be inputed
        jmp begin7

parity0p4:                                              ;Puts a 0 in for P4 and parity variables
        mov cl,0
        mov [P4],cl
        add ah,0b
        shl ah,1                                        ;shifts the register over essentially add in a 0 in P4
        jmp begin7

parity1p3:                                              ;Puts a 1 in for P3 and parity variables
        mov cl,1
        mov [P3],cl
        add ah,1b                                       ;add a one to the AH register
        shl ah,1                                        ;shifts so the next number can be inputed
        jmp begin3

parity0p3:                                              ;Puts a 0 in for P3 and parity variables
        mov cl,0
        mov [P3],cl
        add ah,0b
        shl ah,1                                        ;shifts the register over essentially add in a 0 in P3
        jmp begin3

parity1p2:                                              ;Puts a 1 in for P2 and parity variables
        mov cl,1
        mov [P2],cl
        add ah,1b                                       ;add a one to the AH register
        shl ah,1                                        ;shifts so the next number can be inputed
        jmp begin1

parity0p2:                                              ;Puts a 0 in for P2 and parity variables
        mov cl,0        
        mov [P2],cl
        add ah,0b
        shl ah,1                                        ;shifts the register over essentially add in a 0 in P2
        jmp begin1

parity1p1:                                              ;Puts a 1 in for P1 and parity variables
        mov cl,1
        mov [P1],cl
        add ah,1b                                       ;add a one to the AH register
        jmp logicP3                                     ;end of data jmp to next section

parity0p1:                                              ;Puts a 0 in for P1 and parity variables
        mov cl,0
        mov [P1],cl
        add ah,0b                                       ;shifts the register over essentially add in a 0 in P1
        jmp logicP3                                     ;should be the same jump as parity1

data1d4:                                                ;Puts a 1 in for D4 and parity variables
        mov cl,1
        mov [D4],cl
        add al,1b                                       ;add 1 to AL register
        shl al,1                                        ;shifts AL by 1 to make space for next bit
        jmp begin6

data0d4:                                                ;Puts a 0 in for D4 and parity variables
        mov cl,0
        mov [D4],cl
        add al,0b
        shl al,1                                        ;shifts AL over by one without adding a 1 essectially adding a 0 to D4
        jmp begin6                                      ;moves to next bit

data1d3:                                                ;Puts a 1 in for D3 and parity variables
        mov cl,1
        mov [D3],cl
        add al,1b                                       ;add 1 to AL register
        shl al,1                                        ;shifts AL by 1 to make space for next bit
        jmp begin5

data0d3:                                                ;Puts a 0 in for D3 and parity variables
        mov cl,0
        mov [D3],cl
        add al,0b
        shl al,1                                        ;shifts AL over by one without adding a 1 essectially adding a0 to D3
        jmp begin5                                      ;moves to next bit

data1d2:                                                ;Puts a 1 in for D2 and parity variables
        mov cl,1
        mov [D2],cl
        add al,1b                                       ;add 1 to AL register
        shl al,1                                        ;shifts AL by 1 to make space for next bit
        jmp begin4

data0d2:                                                ;Puts a 0 in for D2 and parity variables
        mov cl,0
        mov [D2],cl
        add al,0b
        shl al,1                                        ;shifts AL over by one without adding a 1 essectially adding a0 to D2
        jmp begin4                                      ;moves to next bit

data1d1:                                                ;Puts a 1 in for D1 and parity variables
        mov cl,1
        mov [D1],cl
        add al,1b                                       ;add 1 to AL register
        jmp begin2

data0d1:                                                ;Puts a 0 in for D1 and parity variables
        mov cl,0
        mov [D1],cl
        add al,0b                                       ;shifts Al over by one without adding a 1 essectially adding a0 to D1
        jmp begin2                                      ;moves to next bit



logicP3:                                                ;Modulus operation to see if Parity of the User input and the expected parity for P3 are the same
        mov ch,0                                        ;clear the CH register P3 checks the parity of D4,D3,D2
        mov [parity],ah                                 ;stores all parity bits into parity variable
        mov [data],al                                   ;stores all data bits into data variable
        add ch,[D4]                                     ;adds the value of D4 to Ch register
        add ch,[D3]                                     ;adds the value of D3 to CH register
        add ch,[D2]                                     ;adds the value of D2 to CH register
        mov [P4bits],ch                                 ;stores that value into P4bits variable
        mov ax,[P4bits]                                 ;moves that value into ax register to prep it for division mnumonic
        mov cl,2                                        ;puts 2 into cl register to prep fro dvision mnumonic
        div cl                                          ;AX/CL = quotient stored in AL
        mul cl                                          ;AL*CL = stored in AX
        mov cl,[P4bits]                                 ;moves the value of the added data bits to CL
        mov [mod],ax                                    ;moves result of multiplication into mod
        sub cl,[mod]                                    ;CL-mod= stored in CL
        cmp cl,[P3]                                     ;if the data adds to an odd number CL = 1, else CL = 0. compares CL to P3 the UI parity
        jnz P3parityCorrect                             ;if CL = P3 runs. There is not error
        jmp P3parityError                               ;if CL != P3 runs if there is a difference in P3 and the parity of the P3 bits ERROR

P3parityError:                                          ;If there is an error detected with P3
        mov dx,0                                        ;clears the DX register
        add dh,1b                                       ;adds a binary 1 to DH
        shl dh,1                                        ;shifts the DH register over to make room for next bit to be modified.
        jmp logicP2

P3parityCorrect:                                        ;If there is not error detected with P3
        mov dx,0                                        ;to give us 3 bits to work with
        add dh,0b
        shl dh,1
        jmp logicP2

logicP2:                                                ;look at logic P3 for exlination
        mov ch,0
        mov [parity],ah
        mov [data],al
        add ch,[D4]
        add ch,[D3]
        add ch,[D1]
        mov [P4bits],ch
        mov ax,[P4bits]
        mov cl,2
        div cl                                          ;quotient stored in AL
        mul cl                                          ;stored in AX
        mov cl,[P4bits]
        mov [mod],ax
        sub cl,[mod]
        cmp cl,[P2]
        jnz P2parityCorrect                             ;runs if there is not error
        jmp P2parityError                               ;runs if there is a difference in P2 and the parity of the P2 bits

P2parityError:
        add dh,1b
        shl dh,1
        jmp logicP1

P2parityCorrect:
        add dh,0b
        shl dh,1
        jmp logicP1

logicP1:
        mov ch,0
        mov [parity],ah
        mov [data],al
        add ch,[D4]
        add ch,[D2]
        add ch,[D1]
        mov [P4bits],ch
        mov ax,[P4bits]
        mov cl,2
        div cl                                            ;quotient stored in AL
        mul cl                                            ;stored in AX
        mov cl,[P4bits]
        mov [mod],ax
        sub cl,[mod]
        cmp cl,[P1]
        jnz P1parityCorrect                             ;runs if there is not error
        jmp P1parityError                               ;runs if there is a difference in P1 and the parity of the P1 bits

P1parityError:
        add dh,1b
        jmp ErrorCorrect1

P1parityCorrect:
        add dh,0b
        jmp ErrorCorrect1

ErrorCorrect1:
        mov cl,0
        cmp cl,dh
        jc localP1                                      ;there is an error move on
        mov bl,0                                        ;works as a sentinal flag (no other error)
        jmp logicP4                                     ;there is not error

localP1:                                                ;Error at P1
        mov bl,1                                        ;works as a sentinal flag (error detected)
        mov cl,1                                        ;puts CL = 1
        cmp cl,dh                                       ;compares 1 and the parity sequence
        jc localP2                                      ;P1 is not the location of the error
        mov cl,'0'                                      ;Prints out position
        mov [pos],cl                                    ;moves that value into pos which will print it out
        mov dl,[P1]                                     ;moves the value of P1 into DL so it can be corrected
        call correcting                                 ;calls correcting LABEL
        mov [P1],dl                                     ;puts the adjusted value of DL back into P1
        jmp logicP4                                     ;moves on

localP2:                                                ;Error at P2
        mov cl,2
        cmp cl,dh
        jc localD1                                      ;P1 is not the location of the error
        mov cl,'1'
        mov [pos],cl
        mov dl,[P2]
        call correcting
        mov [P2],dl
        jmp logicP4

localD1:                                                ;Error at D1
        mov cl,3
        cmp cl,dh
        jc localP3                                      ;D1 is not the location of the error
        mov cl,'2'
        mov [pos],cl
        mov dl,[D1]
        call correcting
        mov [D1],dl
        jmp logicP4

localP3:                                                ;Error at P3
        mov cl,4
        cmp cl,dh
        jc localD2                                      ;P1 is not the location of the error
        mov cl,'3'
        mov [pos],cl
        mov dl,[P3]
        call correcting
        mov [P3],dl
        jmp logicP4

localD2:                                                ;Error at D2
        mov cl,5
        cmp cl,dh
        jc localD3                                      ;D2 is not the location of the error
        mov cl,'4'
        mov [pos],cl
        mov dl,[D2]
        call correcting
        mov [D2],dl
        jmp logicP4

localD3:                                                ;Error at D3
        mov cl,6
        cmp cl,dh
        jc localD4
        mov cl,'5'
        mov [pos],cl
        mov dl,[D3]
        call correcting
        mov [D3],dl
        jmp logicP4

localD4:                                                ;Error at D4
        mov cl,'6'
        mov [pos],cl
        mov dl,[D4]
        call correcting
        mov [D4],dl
        jmp logicP4

correcting:                                             ;corrects the pit
        mov cl,0                                        ;clears CL register
        cmp cl,dl                                       ;checks if the the bit is a 0
        jnz flip1                                       ;The bit is a 1 and should be a 0
        call flip0                                      ;The bit is a 0 and should be a 1
        ret
flip1:                                                  ;flips 1 to 0
        mov dl,0
        ret
flip0:                                                  ;flips 0 to 1
        mov dl,1
        ret


logicP4:                                                ;detects error in P4
	mov ch,0
        mov [parity],ah
        mov [data],al
        add ch,[D4]
        add ch,[D3]
        add ch,[D2]
        add ch,[D1]
        add ch,[P3]
        add ch,[P2]
        add ch,[P1]
        mov [P4bits],ch
        mov ax,[P4bits]
        mov cl,2
        div cl                                           ;quotient stored in AL
        mul cl                                           ;stored in AX
        mov cl,[P4bits]
        mov [mod],ax
        sub cl,[mod]
        cmp cl,[P4]
        jnz P4parityCorrect                              ;runs if there is not error
        jmp P4parityError                                ;runs if there is a difference in P1 and the parity of the P1 bits

P4parityError:
        mov dl,[P4]
        call correcting
        cmp bl,1
        jc allParPrint
        jmp invdet

P4parityCorrect:
        cmp bl,1
        jc valid
        jmp printRes

sequence:                                               ;Reconstructs the fixed sequence and prints it out to terminal
        mov cx,[P4]
        add cx,'0'
        mov [result],cx
        call newSequence
        mov cx,[D4]
        add cx,'0'
        mov [result],cx
        call newSequence
        mov cx,[D3]
        add cx,'0'
        mov [result],cx
        call newSequence
        mov cx,[D2]
        add cx,'0'
        mov [result],cx
        call newSequence
        mov cx,[P3]
        add cx,'0'
        mov [result],cx
        call newSequence
        mov cx,[D1]
        add cx,'0'
        mov [result],cx
        call newSequence
        mov cx,[P2]
        add cx,'0'
        mov [result],cx
        call newSequence
        mov cx,[P1]
        add cx,'0'
        mov [result],cx
        call newSequence
        mov ecx,0xA
        mov [result],ecx
        call newSequence
        jmp exit


printRes:
        mov     eax,SYSCALL_WRITE                       ; system call number (sys_write)
        mov     ebx,STDOUT                              ; file descriptor (stdout)
        mov     ecx,bitE                                ; message to write
        mov     edx,lenBE                               ; message length
        int     80h                                     ; call kernel


        mov     eax,SYSCALL_WRITE                       ; system call number (sys_write)
        mov     ebx,STDOUT                              ; file descriptor (stdout)
        mov     ecx,pos                                 ; message to write
        mov     edx,2                                   ; message length
        int     80h                                     ; call kernel

        jmp     corrected                               ; print the corrected bit sequence

allParPrint:
        mov     eax,SYSCALL_WRITE                       ; system call number (sys_write)
        mov     ebx,STDOUT                              ; file descriptor (stdout)
        mov     ecx,msgA                                ; message to write
        mov     edx,lenA                                ; message length
        int     80h                                     ; call kernel

        jmp corrected                                   ; print the corrected bit sequence

corrected:

        mov     eax,SYSCALL_WRITE                       ; system call number (sys_write)
        mov     ebx,STDOUT                              ; file descriptor (stdout)
        mov     ecx,msgC                                ; message to write
        mov     edx,lenC                                ; message length
        int     80h                                     ; call kernel

        call sequence
        jmp exit

newSequence:
        mov     eax,SYSCALL_WRITE                       ; system call number (sys_write)
        mov     ebx,STDOUT                              ; file descriptor (stdout)
        mov     ecx,result                              ; message to write
        mov     edx,BUFLEN                              ; message length
        int     80h                                     ; call kernel
        ret

valid:  
        mov     eax,SYSCALL_WRITE                       ; system call number (sys_write)
        mov     ebx,STDOUT                              ; file descriptor (stdout)
        mov     ecx,bitNE                               ; message to write
        mov     edx,lenNE                               ; message length
        int     80h                                     ; call kernel
        jmp     exit

invdet:
        mov     eax,SYSCALL_WRITE                       ; system call number (sys_write)
        mov     ebx,STDOUT                              ; file descriptor (stdout)
        mov     ecx,msgE                                ; message to write
        mov     edx,lenE                                ; message length
        int     80h                                     ; call kernel
        jmp     exit

invalid:
        mov     eax,SYSCALL_WRITE                       ; system call number (sys_write)
        mov     ebx,STDOUT                              ; file descriptor (stdout)
        mov     ecx,msgI                                ; message to write
        mov     edx,lenI                                ; message length
        int     80h                                     ; call kernel

exit:                                                   ; final exit
        mov     eax,SYSCALL_EXIT                        ; system call number (sys_exit)
        xor     ebx,ebx                                 ; sys_exit return status
        int     0x80                                    ; call kernel
