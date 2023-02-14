assume cs:code, ss:stack

stack segment
    db 32 dup (0)
stack ends

code segment
    start:
        mov ax, stack
        mov ss, ax
        mov sp, 32             ;SS:SP=stack:32

        call installer1
        call installer2
        call installer3

        mov ax, 4c00h
        int 21h

;;------- 3 installer-functions: -------

installer1:
    ;; boot.exe in 1

    push bx
    push es
    push ax
    push cx
    push dx

    mov bx, seg first_installed
    mov es, bx
    mov bx, offset first_installed   ;es:bx -> first_installed

    mov ah, 3    ;write
    mov al, 1    ;amount
    mov ch, 0
    mov cl, 1    ;number:1
    mov dx, 0
    int 13h

    pop dx
    pop cx
    pop ax
    pop es
    pop bx
    ret

;;--------------------------------------

installer2:
    ;; newint.exe in 2

    push bx
    push es
    push ax
    push cx
    push dx

    mov bx, seg second_installed
    mov es, bx
    mov bx, offset second_installed   ;es:bx -> second_installed

    mov ah, 3    ;write
    mov al, 1    ;amount
    mov ch, 0
    mov cl, 2    ;number:2
    mov dx, 0
    int 13h

    pop dx
    pop cx
    pop ax
    pop es
    pop bx
    ret

;;--------------------------------------

installer3:
    ;; mainsub.exe in 3,4,5,6

    push bx
    push es
    push ax
    push cx
    push dx

    mov bx, seg third_installed
    mov es, bx
    mov bx, offset third_installed   ;es:bx -> third_installed

    mov ah, 3    ;write
    mov al, 4    ;amount
    mov ch, 0
    mov cl, 3    ;number:3
    mov dx, 0
    int 13h

    pop dx
    pop cx
    pop ax
    pop es
    pop bx
    ret

;;---- Here is 1st to be installed. ----

first_installed:
;; CS:IP=0:7c00h
;;       0:7e00h

booter:
    cli

    mov bx, 860h
    mov ss, bx
    mov sp, 400h     ;SS:SP=860h:400h

    ;; boot newint

    mov bx, 0
    mov es, bx
    mov bx, 200h     ;ES:BX=0:200h

    mov ah, 2        ;read
    mov al, 1        ;amount
    mov ch, 0
    mov cl, 2        ;number:2
    mov dx, 0
    int 13h         ;newint is ready, 0:200h~0:210h are empty

    push es:[9*4]
    pop es:[200h]
    push es:[9*4+2]
    pop es:[202h]   ;store old int9's address

    mov word ptr es:[9*4], 210h
    mov word ptr es:[9*4+2], 0    ;newint's address is 0:210h

    mov word ptr es:[204h], 0
    mov word ptr es:[206h], 7e0h  ;(dword ptr 0:204h)=7e0h:0 i.e. 0:7e00h

    mov word ptr es:[208h], 7c00h
    mov word ptr es:[20ah], 0     ;(dword ptr 0:208h)=0:7c00h i.e. 7c0h:0

    mov word ptr es:[20ch], 0
    mov word ptr es:[20eh], 0ffffh     ;(dword ptr 0:20ch)=0ffffh:0

    mov bx, 7e00h    ;ES:BX=0:7e00h
    mov ah, 2        ;read
    mov al, 4        ;amount
    mov ch, 0
    mov cl, 3        ;number:3
    mov dx, 0
    int 13h

    jmp dword ptr cs:[204h]

    db 0
    dw 510 dup (0aa55h)

;;---- Here is 2nd to be installed. ----

second_installed:
newint:
    ;; 2 functions:
    ;;    Press f1  to change the time's string's color
    ;;    Press esc to jump to mainsub, i.e. 7e0h:0

    db 10h dup (0)
    ;; 10h 'free' bytes, newint starts at 0:210h

    push ax
    push di
    push es
    push cx

    in al, 60h

    pushf
    call dword ptr cs:[200h]

    cmp al, 3bh
    je prs_f1

    cmp al, 01h
    je prs_esc

    newint_end:
        pop cx
        pop es
        pop di
        pop ax
        iret

    prs_esc:
        cl_kb:
            mov ah, 0
            int 16h
            mov ah, 1
            int 16h
            pushf
            pop ax
            and ax, 0000000001000000b
            cmp ax, 0
            je cl_kb
        jmp dword ptr cs:[204h]

    prs_f1:
        mov di, (80*4+8)*2+1
        mov ax, 0b800h
        mov es, ax               ;ES:DI=0b800h:(80*4+8)*2+1

        mov al, es:[di]
        inc al
        or al, 00001000b         ;highlight

        mov cx, 49
        change_time_color:
            mov es:[di], al
            add di, 2
            loop change_time_color
        jmp newint_end

;;---- Here is 3rd to be installed. ----

third_installed:
;; CS:IP=7e0h:0
mainsub:
    cli

    mov bx, 860h
    mov ss, bx
    mov sp, 400h         ;SS:SP=860h:400h

    call set_ui
    jmp wait_choice

;;---------------- SUB -----------------

set_ui:
    push bp
    mov bp, sp
    push ax
    push es
    push di
    push cx
    push si

    cli

    mov di, 0b800h
    mov es, di
    mov di, 0                ;ES:DI=0b800h:0

    mov cx, 80*25
    clearall:
        mov word ptr es:[di], 0000111000000000b   ;default highlight yellow char
        add di, 2
        loop clearall

    jmp show_options

    options:
        db '1) reset pc',               0;12
        db '2) start system',           0;16
        db '3) clock',                  0;09
        db '4) set clock',              0;13
        db '5) LOVE from Miss.Jia Ran', 0;26

    show_options:
    ;; (1)
    mov si, offset options - offset mainsub
    push si
    mov ah, 10
    mov al, 50
    mov cl, 00001010b
    call show_str

    ;; (2)
    mov si, offset options - offset mainsub + 12
    push si
    mov ah, 11
    mov al, 50
    mov cl, 00001010b
    call show_str

    ;; (3)
    mov si, offset options - offset mainsub + 12 + 16
    push si
    mov ah, 12
    mov al, 50
    mov cl, 00001010b
    call show_str

    ;; (4)
    mov si, offset options - offset mainsub + 12 + 16 + 9
    push si
    mov ah, 13
    mov al, 50
    mov cl, 00001010b
    call show_str

    ;; (5)
    mov si, offset options - offset mainsub + 12 + 16 + 9 + 13
    push si
    mov ah, 15
    mov al, 50
    mov cl, 00001010b
    call show_str

    pop si
    pop cx
    pop di
    pop es
    pop ax
    pop bp
    ret

;;======================================

wait_choice:
    sti
    mov ah, 0
    int 16h

    cmp al, '1'
    je option1
    cmp al, '2'
    je option2
    cmp al, '3'
    je option3
    cmp al, '4'
    je option4
    cmp al, '5'
    je option5
    jmp next_option

    option1:
        call f1
        jmp next_option
    option2:
        call f2
        jmp next_option
    option3:
        call f3
        jmp next_option
    option4:
        call f4
        jmp next_option
    option5:
        call f5
        jmp next_option

    next_option:
        jmp wait_choice

;;------------- FIVE FUNC --------------

f1:
    cli

    mov bx, 0
    mov es, bx
    mov bx, 20ch

    jmp dword ptr es:[bx]

;;======================================

f2:
    cli

    mov bx, 0
    mov es, bx
    mov bx, 7c00h

    mov ah, 2
    mov al, 1
    mov ch, 0
    mov cl, 1
    mov dh, 0
    mov dl, 80h
    int 13h

    mov bx, 0
    mov es, bx
    mov bx, 208h

    jmp dword ptr es:[bx]

;;======================================

f3:
    push bp
    mov bp, sp
    push ax
    push ds
    push si
    push cx

    sti

    jmp read_cmos
    itime:
        db '20yy mm-dd hh:mm:ss (Press F1 to change color :-)', 0
        ;;  012345678901234567890123456789012345678901234567890
        ;;  0         1         2         3         4         5

    read_cmos:
        push cs
        pop ds
        mov si, offset itime - offset mainsub

        ;; year
        mov al, 9
        out 70h, al
        in al, 71h
        mov ah, al
        and ax, 0000111111110000b
        mov cl, 4
        shr al, cl
        add ax, 3030h
        mov word ptr ds:[si+2], ax

        ;; month
        mov al, 8
        out 70h, al
        in al, 71h
        mov ah, al
        and ax, 0000111111110000b
        mov cl, 4
        shr al, cl
        add ax, 3030h
        mov word ptr ds:[si+5], ax

        ;; day
        mov al, 7
        out 70h, al
        in al, 71h
        mov ah, al
        and ax, 0000111111110000b
        mov cl, 4
        shr al, cl
        add ax, 3030h
        mov word ptr ds:[si+8], ax

        ;; hour
        mov al, 4
        out 70h, al
        in al, 71h
        mov ah, al
        and ax, 0000111111110000b
        mov cl, 4
        shr al, cl
        add ax, 3030h
        mov word ptr ds:[si+11], ax

        ;; minute
        mov al, 2
        out 70h, al
        in al, 71h
        mov ah, al
        and ax, 0000111111110000b
        mov cl, 4
        shr al, cl
        add ax, 3030h
        mov word ptr ds:[si+14], ax

        ;; second
        mov al, 0
        out 70h, al
        in al, 71h
        mov ah, al
        and ax, 0000111111110000b
        mov cl, 4
        shr al, cl
        add ax, 3030h
        mov word ptr ds:[si+17], ax

        jmp show_itime

    show_itime:
        push si
        mov ax, 0408h
        mov di, 0b800h
        mov es, di
        mov di, 4*80*2+8*2+1
        mov cl, es:[di]
        call show_str
        jmp read_cmos

;;======================================

f4:
    push cs
    pop ds
    mov bx, offset fake_time - offset mainsub - 1
    ;; ds:bx -> fake_time-1

    mov di, 0
    sti

    jmp f4_start
    fake_time:
        db 'y','y','m','m','d','d','h','h','m','m','s','s',0
        db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 0
        ;;  0   1   2   3   4   5   6   7   8   9  10  11 12
    f4_start:
        mov ax, 0b800h
        mov es, ax
        mov cl, es:[80*2*4+2*8+1]
        mov ax, 0408h
        inc bx
        push bx
        dec bx
        call show_str

    f4_wait:
        mov ah, 0
        int 16h

        cmp ah, 0eh
        je prs_bs
        cmp ah, 1ch
        je prs_entr
        cmp al, '0'
        jb f4_wait
        cmp al, '9'
        ja f4_wait
        jmp prs_num

    prs_num:
        cmp di, 12
        je f4_wait

        inc di
        mov ds:[bx+di+13], al

        mov ax, 0b800h
        mov es, ax
        mov cl, es:[4*80*2+2*8+1]

        inc bx
        push bx
        dec bx
        mov ax, 0408h
        call show_str

        add bx, 14
        push bx
        sub bx, 14
        mov ax, 0408h
        call show_str

        jmp f4_wait

    prs_bs:
        cmp di, 0
        je f4_wait

        mov byte ptr ds:[bx+di+13], 0
        dec di

        mov ax, 0b800h
        mov es, ax
        mov cl, es:[4*80*2+2*8+1]

        inc bx
        push bx
        dec bx
        mov ax, 0408h
        call show_str

        add bx, 14
        push bx
        sub bx, 14
        mov ax, 0408h
        call show_str

        jmp f4_wait

    prs_entr:
        ;; y1)
        cmp di, 0
        je f4_end_trans_y
        dec di

        mov al, 9
        out 70h, al
        in al, 71h
        and al, 00001111b

        mov ch, ds:[bx+14]
        sub ch, 30h
        mov cl, 4
        shl ch, cl
        or al, ch

        mov ah, al
        mov al, 9
        out 70h, al
        mov al, ah
        out 71h, al

        ;; y2)
        cmp di, 0
        je f4_end_trans_y
        dec di

        mov al, 9
        out 70h, al
        in al, 71h
        and al, 11110000b

        mov ch, ds:[bx+15]
        sub ch, 30h
        or al, ch

        mov ah, al
        mov al, 9
        out 70h, al
        mov al, ah
        out 71h, al

        jmp prs_entr_cnt_mon

    f4_end_trans_y:
        jmp f4_end

    prs_entr_cnt_mon:
        ;; m1)
        cmp di, 0
        je f4_end_trans_mon
        dec di

        mov al, 8
        out 70h, al
        in al, 71h
        and al, 00001111b

        mov ch, ds:[bx+16]
        sub ch, 30h
        mov cl, 4
        shl ch, cl
        or al, ch

        mov ah, al
        mov al, 8
        out 70h, al
        mov al, ah
        out 71h, al

        ;; m2)
        cmp di, 0
        je f4_end_trans_mon
        dec di

        mov al, 8
        out 70h, al
        in al, 71h
        and al, 11110000b

        mov ch, ds:[bx+17]
        sub ch, 30h
        or al, ch

        mov ah, al
        mov al, 8
        out 70h, al
        mov al, ah
        out 71h, al

        jmp prs_entr_cnt_d

    f4_end_trans_mon:
        jmp f4_end

    prs_entr_cnt_d:
        ;; d1)
        cmp di, 0
        je f4_end_trans_d
        dec di

        mov al, 7
        out 70h, al
        in al, 71h
        and al, 00001111b

        mov ch, ds:[bx+18]
        sub ch, 30h
        mov cl, 4
        shl ch, cl
        or al, ch

        mov ah, al
        mov al, 7
        out 70h, al
        mov al, ah
        out 71h, al

        ;; d2)
        cmp di, 0
        je f4_end_trans_d
        dec di

        mov al, 7
        out 70h, al
        in al, 71h
        and al, 11110000b

        mov ch, ds:[bx+19]
        sub ch, 30h
        or al, ch

        mov ah, al
        mov al, 7
        out 70h, al
        mov al, ah
        out 71h, al

        jmp prs_entr_cnt_h

    f4_end_trans_d:
        jmp f4_end

    prs_entr_cnt_h:
        ;; h1)
        cmp di, 0
        je f4_end_trans_h
        dec di

        mov al, 4
        out 70h, al
        in al, 71h
        and al, 00001111b

        mov ch, ds:[bx+20]
        sub ch, 30h
        mov cl, 4
        shl ch, cl
        or al, ch

        mov ah, al
        mov al, 4
        out 70h, al
        mov al, ah
        out 71h, al

        ;; h2)
        cmp di, 0
        je f4_end_trans_h
        dec di

        mov al, 4
        out 70h, al
        in al, 71h
        and al, 11110000b

        mov ch, ds:[bx+21]
        sub ch, 30h
        or al, ch

        mov ah, al
        mov al, 4
        out 70h, al
        mov al, ah
        out 71h, al

        jmp prs_entr_cnt_min

    f4_end_trans_h:
        jmp f4_end

    prs_entr_cnt_min:
        ;; m1)
        cmp di, 0
        je f4_end_trans_min
        dec di

        mov al, 2
        out 70h, al
        in al, 71h
        and al, 00001111b

        mov ch, ds:[bx+22]
        sub ch, 30h
        mov cl, 4
        shl ch, cl
        or al, ch

        mov ah, al
        mov al, 2
        out 70h, al
        mov al, ah
        out 71h, al

        ;; m2)
        cmp di, 0
        je f4_end_trans_min
        dec di

        mov al, 2
        out 70h, al
        in al, 71h
        and al, 11110000b

        mov ch, ds:[bx+23]
        sub ch, 30h
        or al, ch

        mov ah, al
        mov al, 2
        out 70h, al
        mov al, ah
        out 71h, al

        jmp prs_entr_cnt_s

    f4_end_trans_min:
        jmp f4_end

    prs_entr_cnt_s:
        ;; s1)
        cmp di, 0
        je f4_end
        dec di

        mov al, 0
        out 70h, al
        in al, 71h
        and al, 00001111b

        mov ch, ds:[bx+24]
        sub ch, 30h
        mov cl, 4
        shl ch, cl
        or al, ch

        mov ah, al
        mov al, 0
        out 70h, al
        mov al, ah
        out 71h, al

        ;; s2)
        cmp di, 0
        je f4_end
        dec di

        mov al, 0
        out 70h, al
        in al, 71h
        and al, 11110000b

        mov ch, ds:[bx+25]
        sub ch, 30h
        or al, ch

        mov ah, al
        mov al, 0
        out 70h, al
        mov al, ah
        out 71h, al

    f4_end:
        mov cx, 13
        cl_time:
            mov byte ptr ds:[bx+14], 0
            inc bx
            loop cl_time
        mov bx, 0
        mov ds, bx
        mov bx, 204h
        jmp dword ptr ds:[bx]

;;======================================

f5:
    sti

    jmp f5_set
    f5_image:
        ;;  0  1  2  3   4  5  6  7   8  9 10 11  12 13 14 15  16 17 18 19  32 21 22 23  24 25 26 27  28 29 30 31  32 33 34 35  36 37 38
        db 32,32,32,32, 32,32,32,32, 32,32,03,03, 03,03,03,03, 03,03,32,32, 32,32,32,32, 03,03,03,03, 03,03,03,03, 32,32,32,32, 32,32, 0
        db 32,32,32,32, 32,32,32,32, 03,03,32,32, 32,32,32,32, 32,32,03,03, 32,32,03,03, 32,32,32,32, 32,32,32,32, 03,03,32,32, 32,32, 0
        db 32,32,32,32, 32,32,03,03, 32,32,32,32, 32,32,32,32, 32,32,32,32, 03,03,32,32, 32,32,32,32, 32,32,32,32, 32,32,03,03, 32,32, 0
        db 32,32,32,32, 03,03,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 03,03, 0
        db 32,32,32,32, 03,03,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 03,03, 0

        db 32,32,32,32, 03,03,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 03,03, 0
        db 32,32,32,32, 03,03,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 03,03, 0
        db 32,32,32,32, 03,03,03,03, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,03,03, 03,03, 0
        db 32,32,32,32, 32,32,03,03, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,03,03, 32,32, 0
        db 32,32,32,32, 32,32,32,32, 03,03,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 03,03,32,32, 32,32, 0

        db 32,32,32,32, 32,32,32,32, 32,32,03,03, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,03,03, 32,32,32,32, 32,32, 0
        db 32,32,32,32, 32,32,32,32, 32,32,32,32, 03,03,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 03,03,32,32, 32,32,32,32, 32,32, 0
        db 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,03,03, 03,03,32,32, 32,32,32,32, 03,03,03,03, 32,32,32,32, 32,32,32,32, 32,32, 0
        db 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,03,03, 32,32,03,03, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32, 0
        db 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 03,03,32,32, 32,32,32,32, 32,32,32,32, 32,32,32,32, 32,32, 0

    f5_set:
    mov si, offset f5_image - offset mainsub

    mov ah, 6
    mov al, 0

    mov cx, 15
    f5_show_image:
        push si
        call show_str
        add si, 39
        inc ah
        loop f5_show_image

    jmp f5_show_jxt
    jiaxintang:
        db 'Jia Xin Tang~', 0
    f5_show_jxt:
        mov si, offset jiaxintang - offset mainsub
        push si
        mov ah, 11
        mov al, 15
        mov cl, 00001100b
        call show_str

    wait_f5_esc:
        nop
        jmp wait_f5_esc

;;-------------- show_str --------------

show_str:
    ;; ah=row, al=col, cl=color; push offset

    push bp
    mov bp, sp
    push ax
    push es
    push bx
    push cx
    push di
    push ds
    push si
    ;; offset=[bp+4]

    mov bx, 0b800h
    mov es, bx

    mov bx, ax        ;bh=row, bl=col
    mov ch, cl
    mov cl, 8
    shr ax, cl        ;al=row
    mov ah, 80*2
    mul ah            ;ax=row*80*2
    mov di, ax        ;di=row*80*2
    mov al, bl        ;al=col
    mov ah, 2
    mul ah           ;ax=col*2

    add di, ax        ;ES:DI -> screen's ram

    push cs
    pop ds

    mov si, [bp+4]    ;DS:SI -> string's address

    show_char:
        mov cl, ds:[si]
        push cx
        mov ch, 0
        jcxz show_char_end
        pop cx
        mov es:[di], cx
        inc si
        add di, 2
        jmp show_char

    show_char_end:
        pop cx              ;pushed one cx but haven't poped when show_char ends

        pop si
        pop ds
        pop di
        pop cx
        pop bx
        pop es
        pop ax
        pop bp
        ret 2

;;--------------------------------------

code ends

end start
