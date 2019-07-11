#############################################
#
# OBS: O jogo começa pausado!
#
# Controles:
# 	A - move peça para a esquerda
# 	D - move peça para a direita
#	W - rotaciona a peça
# 	S - move peça para baixo
# 	P - pausa o jogo
#
#############################################

.include "macros2.s"

.data

num_vezes_que_o_RARS_travou: .dword 28

board: .space 200

# BBGGGRRR
color: .byte 0, 0xff, 0xc0, 0x7, 0xc6, 0x3f, 0xf8, 0x38, 0x1f, 0
.align 3

# Rotações manuais de 90 graus no sentido horário
piece:  .half 0x71, 0x113, 0x47,0x644
	.half 0xf, 0x1111, 0xf, 0x1111
	.half 0x74, 0x311, 0x17, 0x446
	.half 0x33, 0x33, 0x33, 0x33
	.half 0x36, 0x462, 0x36, 0x462
	.half 0x27, 0x232, 0x72, 0x131
	.half 0x63, 0x264, 0x63, 0x264
	.half 0xffff, 0xffff, 0xffff, 0xffff # bloco 4x4

pause: .word 1
delay: .word 500
next:  .word 0
pontos:.word 0
rotation: .word 0
cheats: .word 0

.include "logo.s"
.include "menu.s"

# Strings
pontosStr: .string "Pontuacao: "
newpieceStr: .string "Nova peca: "


.text
M_SetEcall(exceptionHandling)	# Macro de SetEcall
j main

.include "musica_fundo.s"

main: j no_menu
# Desenha menu
		li t0 0xff000000
		li t1 0xff012c00
		la t2 menu
		addi t2 t2 8 # pula dimensoes da imagem
menu_loop: 	bge t0 t1 menu_done
		lw t3 0(t2)
		sw t3 0(t0)
		addi t0 t0 4
		addi t2 t2 4
		j menu_loop
menu_done:	call musiquinha
no_menu:

# Desenha a logo
		li t0 0xff000000
		li t1 0xff012c00
		la t2 logo
		addi t2 t2 8 # pula dimensoes da imagem
logo_loop: 	bge t0 t1 logo_done
		lw t3 0(t2)
		sw t3 0(t0)
		addi t0 t0 4
		addi t2 t2 4
		j logo_loop
logo_done:	

		la a0 pontosStr
		li a1 130
		li a2 50
		li a3 0xff
		li a7 104
		li a4 0 # ??
		ecall
				
		li a0 0
		li a1 220
		li a2 50
		li a3 0xff
		li a7 101
		li a4 0
		ecall
		
		la a0 newpieceStr
		li a1 130
		li a2 100
		li a3 0xff
		li a7 104
		li a4 0
		ecall

		call new_piece
		call new_piece
		
		# Create right-border
		li t0 0xFF000078
		li t1 0xFF012C00
		li t2 0xff
border_loop:	bge t0 t1 main_loop
		sb t2 0(t0)
		sb t2 1(t0)
		addi t0 t0 320
		j border_loop
	
main_loop:	#bgt s10 s9 main_done

		# Get input ready flag
		li t0 0xff200000
		lb t0 0(t0)
		andi t0 t0 1
		beq t0 x0 ri_done
		
		# Read input
		li t0 0xff200004
		lb t0 0(t0)
		li t1 0x70 # p
		beq t0 t1 ri_pause
		
		# Also pause the game (needed here to unpause sometimes)
		la t2 pause
		lw t3 0(t2)
		bne t3 x0 main_loop
		
		li t1 0x61 # a
		beq t0 t1 ri_left
		li t1 0x64 # d
		beq t0 t1 ri_right
		li t1 0x73
		beq t0 t1 ri_down # s
		li t1 0x77
		beq t0 t1 ri_rotate # w
		j ri_done
ri_left:	addi s11 s11 -1
		mv a2 s11 # Check collision
		mv a1 s10
		mv a0 s8
		call check_collision
		beq a0 x0 ri_done # No collision
		addi s11 s11 1 # Back movement
		j ri_done
ri_right:	addi s11 s11 1
		mv a2 s11 # Check collision
		mv a1 s10
		mv a0 s8
		call check_collision
		beq a0 x0 ri_done # No collision
		addi s11 s11 -1 # Back movement
		j ri_done
ri_down:	li a0 0
ri_down_loop:  bne a0 x0 ri_down_done
		addi s10 s10 1
		mv a2 s11 # Check collision
		mv a1 s10
		mv a0 s8
		call check_collision
		j ri_down_loop
ri_down_done:	addi s10 s10 -1
		j ri_done
ri_rotate:	la t1 rotation
		lw t0 0(t1)
		addi t0 t0 1
		andi t0 t0 3 # t0 % 4
		sw t0 0(t1)
		
		# Check collision
		mv a1 s10
		mv a2 s11
		mv a0 s8
		call check_collision
		beq a0 x0 ri_done # No collision
		
		# There's a collision, go back
		la t1 rotation
		lw t0 0(t1)
		addi t0 t0 -1
		andi t0 t0 3 # t0 % 4
		sw t0 0(t1)
		j ri_done
ri_pause:	la t0 pause
		lw t1 0(t0)
		xori t1 t1 1
		sw t1 0(t0)
		j main_loop
ri_done:
		# Draw piece
		li a3 0
		mv a0 s8
		mv a2 s10
		mv a1 s11
		call draw_piece
		
		# Pause the game
		la t2 pause
		lw t3 0(t2)
		bne t3 x0 main_loop
		
		# Wait {delay}ms
		li a7 32
		la t0 delay
		lw a0 0(t0)
		li t4 200
		div t4 a0 t4
		sub a0 a0 t4
		sw a0 0(t0)
		ecall
		
		# Erase piece
		mv a0 s8
		li a3 1
		mv a2 s10
		mv a1 s11
		call draw_piece
		
		# y++, check collision, go back to loop
		addi s10 s10 1
			
		# Check collision
		mv a1 s10
		mv a2 s11
		mv a0 s8
		call check_collision
		beq a0 x0 main_loop # No collision
		
		#
		# Handle Collision!
		#
		addi s10 s10 -1
		
		# Draw piece
		li a3 0
		mv a0 s8
		mv a2 s10
		mv a1 s11
		call draw_piece
		
		# Emplace piece on the board
		mv a0 s8
		mv a1 s10
		mv a2 s11
		li a7 0
		call emplace_piece
		
		# Check if line is full
		li s5 0
main_cl:	call check_lines
		beq a7 x0 main_cl_done
		slli s5 s5 1
		addi s5 s5 1
		j main_cl
main_cl_done:	la t0 pontos
		lw t1 0(t0)
		add s5 s5 t1
		sw s5 0(t0)
		
		mv a0 t1
		li a1 220
		li a2 50
		li a3 0x00
		li a7 101
		li a4 0 # ??
		ecall
		
		la a0 pontos
		lw a0 0(a0)
		li a1 220
		li a2 50
		li a3 0xff
		li a7 101
		li a4 0
		ecall
		
		call new_piece
		
		# If new piece already collides, end game
		# Check collision
		mv a1 s10
		mv a2 s11
		mv a0 s8
		call check_collision
		beq a0 x0 main_loop # No collision
	
main_done:	j exit

# Desenha a peça com índice a0 na posição (a2, a1) da matriz
# Talvez esteja trocado e seja posição (a1, a2), mas depois eu confiro isso
# depois = nunca
# Se a3 = 0, desenha a peça normalmente, se não, desenha pixeis pretos por cima da peça
# Stack: [0: index bitmask a2 a1 ra :20]
draw_piece:	
		# Store return address on the stack
		addi sp sp -4
		sw ra 0(sp)
		
		# Store a2 and a1 on the stack
		addi sp sp -8
		sw a2 0(sp)
		sw a1 4(sp)

		la t0 piece
		slli t1 a0 3 # piece index
		add t0 t0 t1 # t0 = piece[a0*8]
		la t2 rotation
		lw t2 0(t2)
		add t2 t2 t2
		add t0 t0 t2 # t0 = piece[a0*8] + rotation_offset
		addi sp sp -4
		lhu t0 0(t0) # load current piece bitmask from data memory
		sh t0 0(sp) # store current piece bitmask in stack
		
		addi a0 a0 2 # a0 = color index
		beq a3 x0 drp_dc2b # don't change color to black
		li a0 0
drp_dc2b: 
		
		addi sp sp -4
		sw x0 0(sp) # store current index
drp_check:	lhu t0 4(sp) # load current piece bitmask
		andi t1 t0 1
		beq t1 x0 drp_update # Don't draw piece
		
		#
		# Draw piece
		#
		lw a1 0(sp) # load current index
		li t0 4     
		andi a2 a1 3 # get x position (a2 = a1%4)
		srli a1 a1 2 # get y position (a1 = a1/4)
		
		# Offset by original (a2, a1)
		lw t0 8(sp)
		lw t1 12(sp)
		add a1 a1 t0
		add a2 a2 t1
		call draw_block	
		
		# Update bitmask
drp_update:	lhu  t1 4(sp) # load current piece bitmask
		srli t1 t1 1  # shift
		sh   t1 4(sp) # store
 		
 		# Update index
		lw t0 0(sp) # load current index
		addi t0 t0 1
		sw t0 0(sp)
	
		beq t1 x0 drp_done
		j drp_check
drp_done:	addi sp sp 20
		lw ra -4(sp) # Load return address
		ret


#
# DRAW_BLOCK
#

# Desenha bloco no bitmap display com a cor definida por a0,
# na posição (a2, a1) da matriz do jogo
# Os blocos tem tamanho 12x12
draw_block:		
			# Coloca cor em t6
			la   t6 color
			add  t6 t6 a0
			lbu  t6 0(t6)
			
			# Normaliza as posições matriz => display
			li t0 12
			mul a1 a1 t0
			mul a2 a2 t0
			
			addi a3 a1 12 # a3 = max y
			addi a4 a2 12 # a4 = max x
			
drb_row:		bge a1 a3 drb_done 

			# t0 = posição de (a2, a1) na memória
			li t0 0xff000000
			li t1 320
			mul t1 t1 a1 # t1 = a1*width
			add t0 t0 t1 # t0 += a1*width
			add t0 t0 a2 # t0 += a2

			mv a5 a2 # a5 vai de a2 a a4
drb_col:		bge a5 a4 drb_row_inc
			
			# Desenha um pixel na localização correta, se tudo der certo
			sb t6 0(t0)
			beq t6 x0 drb_drawdone
			addi t1 a3 -1
			beq a1 t1 drb_drawline
			addi t1 a4 -1
			beq a5 t1 drb_drawline
			j drb_drawdone
drb_drawline:		li t1 0x9 #0x9B
			sb t1 0(t0)
drb_drawdone:
	
			addi a5 a5 1
			addi t0 t0 1
			j drb_col
		
drb_row_inc:		addi a1 a1 1
			j drb_row
			
drb_done:		ret

#
# NEW_PIECE
#
# s10 = y, s11 = x
# s9  = max_y
# s8  = piece index
# Stack: [ra]
new_piece:		
			addi sp sp -4
			sw ra 0(sp)
			
			# Erase piece (new piece)
		 	li a0 7
 			li a3 1
			li a2 7
			li a1 19
			call draw_piece

			# Generate random integer in [0, a1]
			li a7 42
			li a0 0
			li a1 6
			ecall
			# a0 = índice da próxima peça
			
			la t0 cheats
			lw t0 0(t0)
			beq t0 x0 np_nocheat
np_cheat:		mv a0 t0
np_nocheat:
		
			li s10 0 # piece y
			li s11 2 # piece x
			
			la t0 next
			lw s8 0(t0) # Modelo da nova peça
			sw a0 0(t0) # Atualiza próxima peça
			
			# Draw piece (new piece)
			li a3 0
			li a2 7
			li a1 19
			call draw_piece
			
			addi sp sp 4
			lw ra -4(sp)
			ret

# Checks if piece a0 at (a2, a1) collides or not
# Returns 1 or 0 on a0
# Stack: [counter bitmask ra]
check_collision:				
			addi sp sp -4
			sw ra 0(sp)

			# Loads piece bitmask onto t6
			la t0 piece
			slli t1 a0 3 # piece index
			add t0 t0 t1 # t0 = piece[a0*8]
			la t2 rotation
			lw t2 0(t2)
			add t2 t2 t2
			add t0 t0 t2 # t0 = piece[a0*8] + rotation_offset
			lhu t6 0(t0) # load current piece bitmask from data memory
			
			addi sp sp -4 # store bitmask
			sw t6 0(sp)
			
			li t1 -1 # store counter
			addi sp sp -4
			sw t1 0(sp)
			
cc_loop:		lw t1 0(sp)
			lw t6 4(sp)
			beq t6 x0 cc_done
			andi t0 t6 1
			srli t6 t6 1
			addi t1 t1 1
			sw t1 0(sp)
			sw t6 4(sp)
			beq t0 x0 cc_loop
			
			# Get block position
			andi t2 t1 3 # x
			srli t3 t1 2 # y
			add t2 t2 a2
			add t3 t3 a1
			
			# Border collision checks
			li t4 10
			bge t2 t4 cc_does_collide
			blt t2 x0 cc_does_collide
			li t4 20
			bge t3 t4 cc_does_collide
			
			# Ultimate collision-with-other-blocks checker
			li a7 1
			call emplace_piece
			bne a7 x0 cc_does_collide
			
			j cc_loop
			
cc_does_collide:	li a7 31 # Efeito sonoro
			li a0 60
	  		li a1 600
  			li a2 121
 			li a3 50
 		 	ecall

			li a0 1
			j cc_ret
cc_done:		li a0 0
cc_ret:			addi sp sp 12
			lw ra -4(sp)
			ret

# Emplaces piece on the board for later collision checking
# Position (a2, a1), index a0
# REPURPOSED TO CHECK COLLISIONS BETWEEN PIECES
# a7 = 0 => emplace, a7 = 1 => check for collisions
# Returns result on a7
emplace_piece:		
			la t5 board
		
			# Load bitmask onto t6
			la t0 piece
		 	slli t1 a0 3 # piece index
	 		add t0 t0 t1 # t0 = piece[a0*8]
			la t2 rotation
			lw t2 0(t2)
			add t2 t2 t2
			add t0 t0 t2 # t0 = piece[a0*8] + rotation_offset
			lhu t6 0(t0) # t6 = bitmask
			
			li t0 -1 # counter
emp_loop:		beq t6 x0 emp_done
			addi t0 t0 1
			andi t1 t6 1
			srli t6 t6 1
			beq t1 x0 emp_loop # Nothing to be done
			
			# mask is set at this position
			srli t2 t0 2 # t2 = t0/4
			add  t4 a1 t2
			li   t3 10
			mul  a3 t4 t3 # a3 = board[a1+block_offset][0]
			
			andi t2 t0 3 # t2 = t0%4
			add  a3 a3 t2 # a3 = board[a1+block_offest][block_offset]
			add  a3 a3 a2 # a3 = board[a1+block_offset][a2+block_offset]
			
			add a3 a3 t5
			
			bne a7 x0 emp_check

			# Store
			sb t1 0(a3)
			j emp_loop
			
emp_check:		# Check
			lb t1 0(a3)
			bne t1 x0 emp_ret_collision
			j emp_loop
emp_ret_collision:	li a7 1
			ret
emp_done:		li a7 0	
			ret
			

# Verifica se ha uma linha inteira preenchida
# Retorna o resultado em a7
# Stack: [y x ra]
check_lines:		
			addi sp sp -4
			sw ra 0(sp)
			
			addi sp sp -8 # usado depois para armazenar (y, x)
			
			li a7 0
			la t6 board # posicao na matriz
			li t0 0 # y
			li t2 20 # max y
			li t3 10 # max x
cl_outer:		bge t0 t2 cl_done_no
			mv t1 x0 # x
			li t4 1 # mask
			
cl_inner:		bge t1 t3 cl_outer_aft

			lb t5 0(t6)
			and t4 t4 t5
			
			addi t1 t1 1
			addi t6 t6 1
			j cl_inner

cl_outer_aft:		bne t4 x0 cl_yes
			addi t0 t0 1
			j cl_outer

cl_yes:			# Elimina linha
			sw t0 0(sp) # store y
			sw x0 4(sp) # store x
			
cl_yes_loop:		lw a1 0(sp) # y
			lw a2 4(sp) # x
			li t0 10
			bge a2 t0 cl_done_yes
			
			la t2 board
			mul t1 t0 a1 # t1 = a1*10
			add t1 t1 a2 # t1 = a1*10 + a2
			add t2 t2 t1 # t2 = board[a1*10 + a2]
			sb x0 0(t2)
			
			addi a2 a2 1
			sw a2 4(sp)
			
			addi a2 a2 -1
			li a0 0
			call draw_block
			j cl_yes_loop			
		
cl_done_yes: 		li a7 1
			j cl_done		
cl_done_no:		li a7 0
cl_done:		addi sp sp 12
			lw ra -4(sp)
			ret


exit:			li a7 4
			la a0 pontosStr
			ecall
			li a7 1
			la a0 pontos
			lw a0 0(a0)
			ecall

			li a7 10
			ecall

.include "SYSTEMv13.s"
