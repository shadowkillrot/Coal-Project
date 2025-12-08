[org 0x0100]
jmp start
SCREEN_WIDTH    equ 80
SCREEN_HEIGHT   equ 25
GRASS_START     equ 0
GRASS_WIDTH     equ 8
BORDER1_COL     equ 8
BORDER1_WIDTH   equ 2
FOOTPATH1_COL   equ 10
FOOTPATH1_WIDTH equ 2
ROAD_START      equ 12
ROAD_WIDTH      equ 40
ROAD_END        equ 52
FOOTPATH2_COL   equ 52
FOOTPATH2_WIDTH equ 2
BORDER2_COL     equ 54
BORDER2_WIDTH   equ 2
GRASS_END_COL   equ 56
HUD_START       equ 64
NUM_LANES       equ 3
LANE_WIDTH      equ 13
LANE1_CENTER    equ 18
LANE2_CENTER    equ 32
LANE3_CENTER    equ 45
DIVIDER1_COL    equ 25
DIVIDER2_COL    equ 38
CAR_WIDTH       equ 5
CAR_HEIGHT      equ 3
COLOR_GRASS     equ 66h
COLOR_BORDER    equ 4Ch
COLOR_FOOTPATH  equ 7Fh
COLOR_ROAD      equ 08h
COLOR_DIVIDER   equ 0Fh
COLOR_PLAYER    equ 4Ch
COLOR_PLAYER2   equ 44h
COLOR_PLAYER3   equ 0Fh
COLOR_OBSTACLE  equ 1Fh
COLOR_OBST2     equ 11h
COLOR_OBST3     equ 99h
COLOR_HUD       equ 70h
COLOR_COIN      equ 0EFh
COLOR_FUEL_ICON equ 0E0h          
COLOR_SPARK     equ 0E0h          
MAX_FUEL            equ 6
FUEL_DECREASE_RATE  equ 80
MOVEMENT_COOLDOWN   equ 10        
OBSTACLE_SPEED      equ 2         
COIN_SPEED          equ 2         
FUEL_ICON_SPEED     equ 2         
COIN_SPAWN_CHANCE   equ 2         
FUEL_ICON_SPAWN_CHANCE equ 3      
SPARK_DURATION      equ 20        
COLLISION_DISTANCE  equ 2         
player_col          db LANE2_CENTER
player_row          db 20
obstacle_col        db LANE1_CENTER
obstacle_row        db 5
obstacle_timer      db 0
coin_row            db 0
coin_col            db 0
coin_active         db 0
coin_timer          db 0
fuel_icon_row       db 0
fuel_icon_col       db 0
fuel_icon_active    db 0
fuel_icon_timer     db 0
fuel_level          db MAX_FUEL
fuel_timer          db 0
divider_offset      db 0
frame_counter       db 0
game_paused         db 0
game_started        db 0
old_isr             dd 0
coin_count          db 0
end_reason          db 0           
movement_cooldown   db 0          
spark_timer         db 0          
collision_occurred  db 0          
player_name     times 16 db 0
player_roll     times 16 db 0
input_buffer:   db 16          
                db 0           
                times 16 db 0  
fuel_text:      db 'FUEL:', 0
coins_text:     db 'COINS:', 0
pause_text1:    db 'PAUSED', 0
pause_text2:    db 'Press Y to Quit or N to Resume', 0
start_text:     db 'Press Any Key to Start...', 0
intro_title:    db 'Highway Shift', 0
intro_dev:      db 'By Rohaan Abdullah', 0
press_any_key:  db 'Press any key to continue...', 0
name_prompt:    db 'Enter Player Name: ', 0
roll_prompt:    db 'Enter Roll No: ', 0
instr_title:    db 'INSTRUCTIONS', 0
instr1:         db 'Use LEFT and RIGHT arrows to change lanes.', 0
instr2:         db 'Use UP and DOWN arrows to adjust position.', 0
instr3:         db 'Collect coins to increase fuel.', 0
instr4:         db 'ESC during game: Pause with Quit confirmation.', 0
instr5:         db 'Fuel bar on right, game ends when fuel is empty.', 0
instr_continue: db 'Press any key to go to the main screen...', 0
game_over_title:   db 'GAME OVER', 0
end_quit_text:     db 'You chose to quit the game.', 0
end_fuel_text:     db 'Fuel has finished!', 0
end_collision_text: db 'Collision occurred!', 0
end_player_label:  db 'Player: ', 0
end_roll_label:    db 'Roll No: ', 0
end_coin_label:    db 'Coins Collected: ', 0
end_prompt:        db 'Press ENTER for main screen or ESC to exit.', 0
start:
    mov ax, 0003h
    int 10h
    mov ah, 01h
    mov cx, 2000h
    int 10h
    mov byte [game_paused], 0
    mov byte [game_started], 0
    mov byte [fuel_level], MAX_FUEL
    mov byte [coin_count], 0
    mov byte [movement_cooldown], 0
    mov byte [collision_occurred], 0
    mov byte [spark_timer], 0
    call show_intro_and_get_player
    call show_instructions_screen
    xor ax, ax
    mov es, ax
    mov ax, [es:9*4]
    mov [old_isr], ax
    mov ax, [es:9*4+2]
    mov [old_isr+2], ax
    cli
    mov word [es:9*4], kbisr
    mov [es:9*4+2], cs
    sti
    call randomize_obstacle
    mov byte [obstacle_row], 0
    call draw_static_background
    call show_start_screen
wait_start:
    cmp byte [game_started], 1
    jne wait_start
    call clear_start_screen
main_loop:
    cmp byte [game_paused], 1
    je main_loop
    cmp byte [collision_occurred], 1
    je .handle_collision
    call update_movement_cooldown
    call clear_road_area
    call draw_lane_dividers
    call draw_obstacle_car
    call draw_coin
    call draw_fuel_icon
    call draw_player_car
    call draw_hud_content
    call move_obstacle
    call move_coin
    call move_fuel_icon
    call try_spawn_coin
    call try_spawn_fuel_icon
    call update_fuel
    call check_collision
    cmp byte [collision_occurred], 1
    je .handle_collision
    cmp byte [fuel_level], 0
    jne .continue_game
    mov byte [end_reason], 1
    call show_game_over_screen
    jmp exit_game
.continue_game:
    call delay
    jmp main_loop
.handle_collision:
    call show_spark_effect
    call delay
    call delay
    call delay
    mov byte [end_reason], 3
    call show_game_over_screen
    jmp exit_game
exit_game:
    cli
    xor ax, ax
    mov es, ax
    mov ax, [old_isr]
    mov [es:9*4], ax
    mov ax, [old_isr+2]
    mov [es:9*4+2], ax
    sti
    mov ah, 01h
    mov cx, 0607h
    int 10h
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h
kbisr:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds
    push es
    push cs
    pop ds
    in al, 0x60
    cmp byte [game_started], 0
    jne .game_running
    mov byte [game_started], 1
    jmp .done
.game_running:
    cmp byte [game_paused], 1
    je .check_pause_keys
    cmp al, 0x01
    je .pause_game
    cmp al, 0x4B
    je near .move_left
    cmp al, 0x4D
    je near .move_right
    cmp al, 0x48
    je near .move_up
    cmp al, 0x50
    je near .move_down
    jmp .done
.pause_game:
    mov byte [game_paused], 1
    call show_pause_screen
    jmp .done
.check_pause_keys:
    cmp al, 0x01
    je .resume_game
    cmp al, 0x15
    je .quit_game
    cmp al, 0x31
    je .resume_game
    jmp .done
.quit_game:
    mov al, 0x20
    out 0x20, al
    pop es
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    jmp exit_game
.resume_game:
    mov byte [game_paused], 0
    call clear_pause_screen
    jmp .done
.move_left:
    cmp byte [movement_cooldown], 0
    jne near .done
    mov al, [player_col]
    cmp al, LANE1_CENTER
    jle near .done
    cmp al, LANE3_CENTER
    je .move_to_lane2_left
    mov al, LANE1_CENTER
    call check_lane_collision
    cmp al, LANE1_CENTER
    jne .done
    mov byte [player_col], LANE1_CENTER
    mov byte [movement_cooldown], MOVEMENT_COOLDOWN
    jmp .done
.move_to_lane2_left:
    mov al, LANE2_CENTER
    call check_lane_collision
    cmp al, LANE2_CENTER
    jne .done
    mov byte [player_col], LANE2_CENTER
    mov byte [movement_cooldown], MOVEMENT_COOLDOWN
    jmp .done
.move_right:
    cmp byte [movement_cooldown], 0
    jne .done
    mov al, [player_col]
    cmp al, LANE3_CENTER
    jge .done
    cmp al, LANE1_CENTER
    je .move_to_lane2_right
    mov al, LANE3_CENTER
    call check_lane_collision
    cmp al, LANE3_CENTER
    jne .done
    mov byte [player_col], LANE3_CENTER
    mov byte [movement_cooldown], MOVEMENT_COOLDOWN
    jmp .done
.move_to_lane2_right:
    mov al, LANE2_CENTER
    call check_lane_collision
    cmp al, LANE2_CENTER
    jne .done
    mov byte [player_col], LANE2_CENTER
    mov byte [movement_cooldown], MOVEMENT_COOLDOWN
    jmp .done
.move_up:
    mov al, [player_row]
    cmp al, 5
    jle .done
    dec byte [player_row]
    jmp .done
.move_down:
    mov al, [player_row]
    cmp al, 22
    jge .done
    inc byte [player_row]
    jmp .done
.done:
    mov al, 0x20
    out 0x20, al
    pop es
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    iret
show_start_screen:
    push ax
    push bx
    push cx
    push dx
    mov dh, 12
    mov dl, 15
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_ROAD
    mov al, 0xB0
    mov cx, 35
    int 10h
    mov dh, 12
    mov dl, 18
    call set_cursor
    mov si, start_text
    call print_string
    pop dx
    pop cx
    pop bx
    pop ax
    ret
clear_start_screen:
    push ax
    push bx
    push cx
    push dx
    mov dh, 12
    mov dl, 15
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_ROAD
    mov al, 0xB0
    mov cx, 35
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
show_pause_screen:
    push ax
    push bx
    push cx
    push dx
    mov dh, 11
    mov dl, 15
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, 0CEh
    mov al, ' '
    mov cx, 35
    int 10h
    mov dh, 11
    mov dl, 25
    call set_cursor
    mov si, pause_text1
    call print_string
    mov dh, 13
    mov dl, 15
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, 0CEh
    mov al, ' '
    mov cx, 35
    int 10h
    mov dh, 13
    mov dl, 16
    call set_cursor
    mov si, pause_text2
    call print_string
    pop dx
    pop cx
    pop bx
    pop ax
    ret
clear_pause_screen:
    push ax
    push bx
    push cx
    push dx
    mov dh, 11
    mov dl, 15
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_ROAD
    mov al, 0xB0
    mov cx, 35
    int 10h
    mov dh, 13
    mov dl, 15
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_ROAD
    mov al, 0xB0
    mov cx, 35
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
move_obstacle:
    push ax
    mov al, [obstacle_timer]
    inc al
    mov [obstacle_timer], al
    cmp al, OBSTACLE_SPEED
    jl .done
    mov byte [obstacle_timer], 0
    mov al, [obstacle_row]
    inc al
    cmp al, SCREEN_HEIGHT - 2
    jl .update_position
    mov byte [obstacle_row], 0
    call randomize_obstacle
    jmp .done
.update_position:
    mov [obstacle_row], al
.done:
    pop ax
    ret
move_coin:
    push ax
    mov al, [coin_timer]
    inc al
    mov [coin_timer], al
    cmp al, COIN_SPEED
    jl .done
    mov byte [coin_timer], 0
    cmp byte [coin_active], 0
    je .done
    mov al, [coin_row]
    inc al
    cmp al, SCREEN_HEIGHT
    jge .remove_coin
    mov ah, [player_row]
    sub ah, 1
    cmp al, ah
    jl .no_collision
    add ah, 3
    cmp al, ah
    jg .no_collision
    mov ah, [coin_col]
    mov al, [player_col]
    cmp ah, al
    jne .no_collision
    mov al, [fuel_level]
    add al, 2
    cmp al, MAX_FUEL
    jle .set_fuel
    mov al, MAX_FUEL
.set_fuel:
    mov [fuel_level], al
    inc byte [coin_count]
    mov byte [coin_active], 0
    jmp .done
.no_collision:
    mov al, [coin_row]
    inc al
    mov [coin_row], al
    jmp .done
.remove_coin:
    mov byte [coin_active], 0
.done:
    pop ax
    ret
try_spawn_coin:
    push ax
    push dx
    cmp byte [coin_active], 1
    je .done
    mov ah, 00h
    int 1Ah
    and dl, 0x1F
    cmp dl, COIN_SPAWN_CHANCE
    jg .done
    mov byte [coin_active], 1
    mov byte [coin_row], 0
    mov ax, dx
    shr ax, 8
    mov dx, 0
    mov bx, 3
    div bx
    cmp dl, 0
    je .lane1_coin
    cmp dl, 1
    je .lane2_coin
    mov byte [coin_col], LANE3_CENTER
    jmp .done
.lane1_coin:
    mov byte [coin_col], LANE1_CENTER
    jmp .done
.lane2_coin:
    mov byte [coin_col], LANE2_CENTER
.done:
    pop dx
    pop ax
    ret
draw_fuel_icon:
    push ax
    push bx
    push cx
    push dx
    cmp byte [fuel_icon_active], 0
    je .done
    mov dh, [fuel_icon_row]
    mov dl, [fuel_icon_col]
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_FUEL_ICON
    mov al, 0x0F          
    mov cx, 1
    int 10h
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
move_fuel_icon:
    push ax
    mov al, [fuel_icon_timer]
    inc al
    mov [fuel_icon_timer], al
    cmp al, FUEL_ICON_SPEED
    jl .done
    mov byte [fuel_icon_timer], 0
    cmp byte [fuel_icon_active], 0
    je .done
    mov al, [fuel_icon_row]
    inc al
    cmp al, SCREEN_HEIGHT
    jge .remove_fuel_icon
    mov ah, [player_row]
    sub ah, 1
    cmp al, ah
    jl .no_collision_fuel
    add ah, 3
    cmp al, ah
    jg .no_collision_fuel
    mov ah, [fuel_icon_col]
    mov al, [player_col]
    cmp ah, al
    jne .no_collision_fuel
    mov al, [fuel_level]
    add al, 3
    cmp al, MAX_FUEL
    jle .set_fuel_from_icon
    mov al, MAX_FUEL
.set_fuel_from_icon:
    mov [fuel_level], al
    mov byte [fuel_icon_active], 0
    jmp .done
.no_collision_fuel:
    mov al, [fuel_icon_row]
    inc al
    mov [fuel_icon_row], al
    jmp .done
.remove_fuel_icon:
    mov byte [fuel_icon_active], 0
.done:
    pop ax
    ret
try_spawn_fuel_icon:
    push ax
    push dx
    cmp byte [fuel_icon_active], 1
    je .done
    mov ah, 00h
    int 1Ah
    and dl, 0x1F
    cmp dl, FUEL_ICON_SPAWN_CHANCE
    jg .done
    mov byte [fuel_icon_active], 1
    mov byte [fuel_icon_row], 0
    mov ax, dx
    shr ax, 8
    mov dx, 0
    mov bx, 3
    div bx
    cmp dl, 0
    je .lane1_fuel
    cmp dl, 1
    je .lane2_fuel
    mov byte [fuel_icon_col], LANE3_CENTER
    jmp .done
.lane1_fuel:
    mov byte [fuel_icon_col], LANE1_CENTER
    jmp .done
.lane2_fuel:
    mov byte [fuel_icon_col], LANE2_CENTER
.done:
    pop dx
    pop ax
    ret
update_fuel:
    push ax
    mov al, [frame_counter]
    inc al
    mov [frame_counter], al
    cmp al, FUEL_DECREASE_RATE
    jl .done
    mov byte [frame_counter], 0
    mov al, [fuel_level]
    cmp al, 0
    je .done
    dec al
    mov [fuel_level], al
.done:
    pop ax
    ret
update_movement_cooldown:
    push ax
    mov al, [movement_cooldown]
    cmp al, 0
    je .done
    dec al
    mov [movement_cooldown], al
.done:
    pop ax
    ret
check_collision:
    push ax
    push bx
    push cx
    push dx
    mov al, [obstacle_row]
    mov bl, [player_row]
    sub al, bl          
    jns .positive_diff
    neg al              
.positive_diff:
    cmp al, COLLISION_DISTANCE
    jg .no_collision    
    mov al, [obstacle_col]
    mov bl, [player_col]
    cmp al, bl
    jne .no_collision   
    mov byte [collision_occurred], 1
.no_collision:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
check_lane_collision:
    push bx
    push cx
    push dx
    mov bl, al          
    mov al, [obstacle_col]
    cmp al, bl
    jne .lane_safe      
    mov al, [obstacle_row]
    mov cl, [player_row]
    sub al, cl          
    jns .positive_diff
    neg al              
.positive_diff:
    cmp al, COLLISION_DISTANCE + 2
    jg .lane_safe       
    mov al, 0
    jmp .done
.lane_safe:
    mov al, bl          
.done:
    pop dx
    pop cx
    pop bx
    ret
show_spark_effect:
    push ax
    push bx
    push cx
    push dx
    mov byte [spark_timer], SPARK_DURATION
    mov dh, [player_row]
    mov dl, [player_col]
    sub dh, 2
    sub dl, 3
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_SPARK
    mov al, '*'
    mov cx, 1
    int 10h
    add dl, 2
    call set_cursor
    int 10h
    add dl, 2
    call set_cursor
    int 10h
    add dh, 2
    sub dl, 4
    call set_cursor
    int 10h
    add dl, 4
    call set_cursor
    int 10h
    add dh, 2
    sub dl, 2
    call set_cursor
    int 10h
    add dl, 2
    call set_cursor
    int 10h
    add dl, 2
    call set_cursor
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_static_background:
    call draw_grass_areas
    call draw_borders
    call draw_footpaths
    call draw_hud_area
    ret
clear_road_area:
    push ax
    push bx
    push cx
    push dx
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_ROAD
    mov al, 0xB0
    mov dh, 0
.row_loop:
    mov dl, ROAD_START
    call set_cursor
    mov cx, ROAD_WIDTH
    int 10h
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .row_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_grass_areas:
    push ax
    push bx
    push cx
    push dx
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_GRASS
    mov al, 0xB1
    mov dh, 0
.row_loop:
    mov dl, GRASS_START
    call set_cursor
    mov cx, GRASS_WIDTH
    int 10h
    mov dl, GRASS_END_COL
    call set_cursor
    mov cx, HUD_START - GRASS_END_COL
    int 10h
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .row_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_borders:
    push ax
    push bx
    push cx
    push dx
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_BORDER
    mov al, 0xDB
    mov dh, 0
.row_loop:
    mov dl, BORDER1_COL
    call set_cursor
    mov cx, BORDER1_WIDTH
    int 10h
    mov dl, BORDER2_COL
    call set_cursor
    mov cx, BORDER2_WIDTH
    int 10h
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .row_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_footpaths:
    push ax
    push bx
    push cx
    push dx
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_FOOTPATH
    mov dh, 0
.row_loop:
    mov al, dh
    and al, 03h
    cmp al, 0
    je .pattern_red
    cmp al, 2
    je .pattern_red
    mov al, 0xDB
    jmp .draw_footpaths
.pattern_red:
    mov bl, COLOR_BORDER
    mov al, 0xDB
.draw_footpaths:
    push bx
    mov dl, FOOTPATH1_COL
    call set_cursor
    mov cx, FOOTPATH1_WIDTH
    int 10h
    pop bx
    mov dl, FOOTPATH2_COL
    call set_cursor
    mov cx, FOOTPATH2_WIDTH
    int 10h
    mov bl, COLOR_FOOTPATH
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .row_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_lane_dividers:
    push ax
    push bx
    push cx
    push dx
    mov dh, 0
.row_loop:
    mov al, dh
    add al, [divider_offset]
    and al, 03h
    cmp al, 3
    jge .skip_row
    mov dl, DIVIDER1_COL
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_DIVIDER
    mov al, 0xDB
    mov cx, 1
    int 10h
    mov dl, DIVIDER2_COL
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_DIVIDER
    mov al, 0xDB
    mov cx, 1
    int 10h
.skip_row:
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .row_loop
    mov al, [frame_counter]
    and al, 01h
    jnz .no_update
    mov al, [divider_offset]
    inc al
    and al, 03h
    mov [divider_offset], al
.no_update:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_hud_area:
    push ax
    push bx
    push cx
    push dx
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_HUD
    mov al, ' '
    mov dh, 0
.row_loop:
    mov dl, HUD_START
    call set_cursor
    mov cx, SCREEN_WIDTH - HUD_START
    int 10h
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .row_loop
    mov dh, 0
.border_loop:
    mov dl, HUD_START
    call set_cursor
    mov ah, 09h
    mov bl, 08h
    mov al, 0xB3
    mov cx, 1
    int 10h
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .border_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_hud_content:
    push ax
    push bx
    push cx
    push dx
    mov dh, 2
    mov dl, 66
    call set_cursor
    mov si, fuel_text
    call print_string_hud
    mov dh, 4
    mov dl, 66
    mov cl, [fuel_level]
    mov ch, 0
.fuel_bar_loop:
    cmp cx, 0
    je .empty_bars
    call set_cursor
    mov ah, 09h
    mov bh, 0
    cmp cx, 4
    jg .green
    cmp cx, 2
    jg .yellow
    mov bl, 0C0h
    jmp .draw_bar
.yellow:
    mov bl, 0E0h
    jmp .draw_bar
.green:
    mov bl, 0A0h
.draw_bar:
    mov al, 0xDB
    push cx
    mov cx, 1
    int 10h
    pop cx
    inc dl
    dec cx
    jmp .fuel_bar_loop
.empty_bars:
    mov cl, MAX_FUEL
    sub cl, [fuel_level]
    mov ch, 0
.empty_loop:
    cmp cx, 0
    je .draw_coins
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, 78h
    mov al, 0xB0
    push cx
    mov cx, 1
    int 10h
    pop cx
    inc dl
    dec cx
    jmp .empty_loop
.draw_coins:
    mov dh, 7
    mov dl, 66
    call set_cursor
    mov si, coins_text
    call print_string_hud
    mov dh, 9
    mov dl, 66
    call set_cursor
    mov al, [coin_count]
    mov ah, 0
    mov bl, 10
    div bl              
    push ax
    cmp al, 0
    je .ones_only
    add al, '0'
    mov ah, 0Eh
    mov bh, 0
    mov bl, 0Fh
    int 10h
.ones_only:
    pop ax
    mov al, ah          
    add al, '0'
    mov ah, 0Eh
    mov bh, 0
    mov bl, 0Fh
    int 10h
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_player_car:
    push ax
    push bx
    push cx
    push dx
    mov dh, [player_row]
    dec dh
    mov dl, [player_col]
    sub dl, 2
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, 00h
    mov al, 0xDB
    mov cx, 1
    int 10h
    mov dl, [player_col]
    add dl, 2
    call set_cursor
    mov ah, 09h
    mov al, 0xDB
    mov cx, 1
    int 10h
    mov dh, [player_row]
    mov dl, [player_col]
    sub dl, 2
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_PLAYER
    mov al, 0xDB
    mov cx, CAR_WIDTH
    int 10h
    mov dl, [player_col]
    sub dl, 1
    call set_cursor
    mov bl, COLOR_PLAYER3
    mov al, 0xDB
    mov cx, 3
    int 10h
    inc dh
    mov dl, [player_col]
    sub dl, 2
    call set_cursor
    mov bl, COLOR_PLAYER
    mov al, 0xDB
    mov cx, CAR_WIDTH
    int 10h
    inc dh
    mov dl, [player_col]
    sub dl, 2
    call set_cursor
    mov bl, COLOR_PLAYER2
    mov al, 0xDB
    mov cx, CAR_WIDTH
    int 10h
    mov dl, [player_col]
    call set_cursor
    mov bl, 00h
    mov al, 0xDB
    mov cx, 1
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_obstacle_car:
    push ax
    push bx
    push cx
    push dx
    mov dh, [obstacle_row]
    dec dh
    mov dl, [obstacle_col]
    sub dl, 2
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, 00h
    mov al, 0xDB
    mov cx, 1
    int 10h
    mov dl, [obstacle_col]
    add dl, 2
    call set_cursor
    mov ah, 09h
    mov al, 0xDB
    mov cx, 1
    int 10h
    mov dh, [obstacle_row]
    mov dl, [obstacle_col]
    sub dl, 2
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_OBSTACLE
    mov al, 0xDB
    mov cx, CAR_WIDTH
    int 10h
    mov dl, [obstacle_col]
    sub dl, 1
    call set_cursor
    mov bl, COLOR_OBST3
    mov al, 0xDB
    mov cx, 3
    int 10h
    inc dh
    mov dl, [obstacle_col]
    sub dl, 2
    call set_cursor
    mov bl, COLOR_OBSTACLE
    mov al, 0xDB
    mov cx, CAR_WIDTH
    int 10h
    inc dh
    mov dl, [obstacle_col]
    sub dl, 2
    call set_cursor
    mov bl, COLOR_OBST2
    mov al, 0xDB
    mov cx, CAR_WIDTH
    int 10h
    mov dl, [obstacle_col]
    call set_cursor
    mov bl, 00h
    mov al, 0xDB
    mov cx, 1
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_coin:
    push ax
    push bx
    push cx
    push dx
    cmp byte [coin_active], 0
    je .done
    mov dh, [coin_row]
    mov dl, [coin_col]
    dec dl
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_COIN
    mov al, '('
    mov cx, 1
    int 10h
    inc dl
    call set_cursor
    mov ah, 09h
    mov al, '$'
    mov cx, 1
    int 10h
    inc dl
    call set_cursor
    mov ah, 09h
    mov al, ')'
    mov cx, 1
    int 10h
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
set_cursor:
    push ax
    push bx
    mov ah, 02h
    mov bh, 0
    int 10h
    pop bx
    pop ax
    ret
print_string:
    push ax
    push bx
    push si
    mov ah, 0Eh
    mov bh, 0
    mov bl, 0CEh
.loop:
    lodsb
    cmp al, 0
    je .done
    int 10h
    jmp .loop
.done:
    pop si
    pop bx
    pop ax
    ret
print_string_hud:
    push ax
    push bx
    push si
    mov ah, 0Eh
    mov bh, 0
    mov bl, 0Fh          
.loop_hud:
    lodsb
    cmp al, 0
    je .done_hud
    int 10h
    jmp .loop_hud
.done_hud:
    pop si
    pop bx
    pop ax
    ret
delay:
    push ax
    push cx
    mov cx, 5
.outer:
    push cx
    mov cx, 0FFFFh
.inner:
    loop .inner
    pop cx
    loop .outer
    pop cx
    pop ax
    ret
randomize_obstacle:
    push ax
    push dx
    mov ah, 00h
    int 1Ah
    mov ax, dx
    mov dx, 0
    mov bx, 3
    div bx
    cmp dl, 0
    je .lane1
    cmp dl, 1
    je .lane2
    mov byte [obstacle_col], LANE3_CENTER
    jmp .done
.lane1:
    mov byte [obstacle_col], LANE1_CENTER
    jmp .done
.lane2:
    mov byte [obstacle_col], LANE2_CENTER
.done:
    pop dx
    pop ax
    ret
show_intro_and_get_player:
    push ax
    push bx
    push cx
    push dx
    push si
    mov ax, 0003h
    int 10h
    mov dh, 4
    mov dl, 28
    call set_cursor
    mov si, intro_title
    call print_string
    mov dh, 6
    mov dl, 30
    call set_cursor
    mov si, intro_dev
    call print_string
    mov dh, 10
    mov dl, 22
    call set_cursor
    mov si, press_any_key
    call print_string
    mov ah, 00h
    int 16h
    mov ax, 0003h
    int 10h
    mov dh, 6
    mov dl, 15
    call set_cursor
    mov si, name_prompt
    call print_string
    mov si, player_name
    call read_line
    mov dh, 8
    mov dl, 15
    call set_cursor
    mov si, roll_prompt
    call print_string
    mov si, player_roll
    call read_line
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
show_instructions_screen:
    push ax
    push bx
    push cx
    push dx
    push si
    mov ax, 0003h
    int 10h
    mov dh, 2
    mov dl, 30
    call set_cursor
    mov si, instr_title
    call print_string
    mov dh, 5
    mov dl, 5
    call set_cursor
    mov si, instr1
    call print_string
    mov dh, 7
    mov dl, 5
    call set_cursor
    mov si, instr2
    call print_string
    mov dh, 9
    mov dl, 5
    call set_cursor
    mov si, instr3
    call print_string
    mov dh, 11
    mov dl, 5
    call set_cursor
    mov si, instr4
    call print_string
    mov dh, 13
    mov dl, 5
    call set_cursor
    mov si, instr5
    call print_string
    mov dh, 18
    mov dl, 10
    call set_cursor
    mov si, instr_continue
    call print_string
    mov ah, 00h
    int 16h
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
read_line:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov di, si
    mov dx, input_buffer
    mov ah, 0Ah
    int 21h
    mov si, input_buffer + 2    
    mov cl, [input_buffer + 1]  
    mov ch, 0
    cmp cx, 0
    je .rl_done
.copy_loop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop .copy_loop
.rl_done:
    mov byte [di], 0
    mov ah, 0Eh
    mov bh, 0
    mov bl, 0Fh
    mov al, 13           
    int 10h
    mov al, 10           
    int 10h
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
show_game_over_screen:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dh, 8
.row_loop_end:
    mov dl, 18
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, 70h
    mov al, ' '
    mov cx, 44
    int 10h
    inc dh
    cmp dh, 16
    jl .row_loop_end
    mov dh, 9
    mov dl, 32
    call set_cursor
    mov si, game_over_title
    call print_string
    mov dh, 11
    mov dl, 20
    call set_cursor
    mov al, [end_reason]
    cmp al, 2
    je .use_quit_text
    cmp al, 3
    je .use_collision_text
    mov si, end_fuel_text
    jmp .print_reason
.use_quit_text:
    mov si, end_quit_text
    jmp .print_reason
.use_collision_text:
    mov si, end_collision_text
.print_reason:
    call print_string
    mov dh, 12
    mov dl, 20
    call set_cursor
    mov si, end_player_label
    call print_string
    mov si, player_name
    call print_string
    mov dh, 13
    mov dl, 20
    call set_cursor
    mov si, end_roll_label
    call print_string
    mov si, player_roll
    call print_string
    mov dh, 14
    mov dl, 20
    call set_cursor
    mov si, end_coin_label
    call print_string
    mov al, [coin_count]
    mov ah, 0
    mov bl, 10
    div bl              
    push ax
    cmp al, 0
    je .ones_only_coin
    add al, '0'
    mov ah, 0Eh
    mov bh, 0
    mov bl, 0Fh
    int 10h
.ones_only_coin:
    pop ax
    mov al, ah          
    add al, '0'
    mov ah, 0Eh
    mov bh, 0
    mov bl, 0Fh
    int 10h
    mov dh, 15
    mov dl, 19
    call set_cursor
    mov si, end_prompt
    call print_string
.wait_key_end:
    mov ah, 00h
    int 16h
    cmp al, 13          
    je .done_end
    cmp al, 27          
    je .done_end
    jmp .wait_key_end
.done_end:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
