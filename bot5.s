.data
# syscall constants
PRINT_STRING            = 4
PRINT_CHAR              = 11
PRINT_INT               = 1

# memory-mapped I/O
VELOCITY                = 0xffff0010
ANGLE                   = 0xffff0014
ANGLE_CONTROL           = 0xffff0018

BOT_X                   = 0xffff0020
BOT_Y                   = 0xffff0024

TIMER                   = 0xffff001c

REQUEST_PUZZLE          = 0xffff00d0  ## Puzzle
SUBMIT_SOLUTION         = 0xffff00d4  ## Puzzle

BONK_INT_MASK           = 0x1000
BONK_ACK                = 0xffff0060

TIMER_INT_MASK          = 0x8000      
TIMER_ACK               = 0xffff006c 

REQUEST_PUZZLE_INT_MASK = 0x800       ## Puzzle
REQUEST_PUZZLE_ACK      = 0xffff00d8  ## Puzzle

PICKUP                  = 0xffff00f4

SPAWN_MINIBOT           = 0xffff00dc
BUILD_SILO              = 0xffff2000
SELECT_IDLE             = 0xffff00e4
SET_TARGET				= 0xffff00e8
GET_KERNEL_LOCATIONS    = 0xffff200c
SELECT_ID 				= 0xffff2004
GET_MINIBOT				= 0xffff2014
GET_MAP                 = 0xffff00f0
# Add any MMIO that you need here (see the Spimbot Documentation)


CTR_LEFT = 15
CTR_TOP = 7

### Puzzle
GRIDSIZE = 16
signal:      	   .word 0
has_puzzle:        .word 0                         
anchor: 		   .word 0
puzzle:      .half 0:2000             
heap:        .half 0:2000
location:    .byte 0:1700
minibot:	 .word 0:30
atk_flag:    .word 0
test_loc:    .word 0:10


#### Puzzle
BNK_AGL: .word 45
three: .float 3.0
five: .float 5.0
PI: .float 3.141592
F180: .float 180.0



.text
main:
# Construct interrupt mask
	    li      $t4, 0
        or      $t4, $t4, REQUEST_PUZZLE_INT_MASK # puzzle interrupt bit
        or      $t4, $t4, TIMER_INT_MASK	  # timer interrupt bit
        or      $t4, $t4, BONK_INT_MASK	  # timer interrupt bit
        or      $t4, $t4, 1                       # global enable
	    mtc0    $t4, $12

#Fill in your code here

		
		j center_main
		main_dispatch:
		lw $t0, signal
		beq $t0, 0 mission_solve6
		beq $t0, 1 mission_move_main
		beq $t0, 2 test_field
		mission_solve6:
		lw $t0, TIMER
		addi $t0 $t0 20000
		sw $t0, TIMER
		addi $sp $sp -4
		sw $s0 0($sp)
        li $s0 10
        puzzle_loop:
            beq $s0 $0 out_puzzle_loop ## when solved 4 puzzles go collect
            la $t1 has_puzzle
            sw $0  0($t1)
            la $a0 puzzle
            la $t0 REQUEST_PUZZLE
            sw $a0 0($t0)
            la $a1 heap
            li $a2 0
            li $a3 0
            while:
                lw $t2 0($t1)
                bne $0 $t2 start_solving
            j while
            start_solving:
            jal slow_solve_dominosa
            la $a1 heap
            sw $a1 SUBMIT_SOLUTION
	    addi $s0 $s0 -1
        j puzzle_loop
		out_puzzle_loop:

		j main_dispatch


		center_main:
		## moves the bot to the center of the map
    
	     lw $t0 BOT_X($0)
		 blt $t0 160 upper_start
		 li $t1 225
		 j start_end
		 upper_start:
		 li $t1 45
		 start_end:
		 sw $t1 ANGLE($0)
		 li $t1 1
		 sw $t1 ANGLE_CONTROL($0)
   	 li $a0 20
   	 li $a1 20
   	 jal dist
   	 li $t0 10
   	 sw $t0 VELOCITY($0)
     move $a0 $v0
	 li $t8 8
	 mul $a0 $a0 $t8
     jal stop_timer ## move to 20 18?
	 j main_dispatch

	mission_move_main:
	lw $t8, TIMER
	li $t9 1000000
	add $t8 $t8 $t9
	sw $t8, TIMER

	li $v0 CTR_LEFT
	li $v1 CTR_TOP
    get_more:
	jal main_target
	move $a0 $v1
	move $a1 $v0
	jal move_main
	lw $t8 signal
	bne $t8, 1, main_dispatch
	j get_more


	test_field:
	#your code
        jal get_next_location
        
        li $t0, 1
        sw $t0, SPAWN_MINIBOT
        sw $t0, SPAWN_MINIBOT
        sw $t0, SPAWN_MINIBOT
        
        li $t0, 0x1a06
        sw $t0, SELECT_IDLE
        sw $t0, SET_TARGET
        li $a0, 500
        jal stop_timer
        li $t0, 0x1a06  ## build silo at (6,26)
        sw $t0, BUILD_SILO

		li $t0 1
		sw $t0, SPAWN_MINIBOT
		sw $t0, SPAWN_MINIBOT
		sw $t0, SPAWN_MINIBOT
		sw $t0, SPAWN_MINIBOT

		move_again:
		li $a0 1
		la $a1 test_loc
		jal move_minibot
		la $a0 500
		jal stop_timer
		j move_again
        li $t0, 1
        sw $t0, SPAWN_MINIBOT
        jal assign_minibot
	j test_field	

move_minibot: ## move $a0 bots to $a0 different locations stored in $a1
    sub $sp, $sp, 4
    sw $ra, 0($sp)
    la $t0, minibot
    sw $t0, GET_MINIBOT
    lw $t1, 0($t0) # number of minibots
	#bgt $a0, $t1, mv_mbot_out
    addi $t2, $t0, 4 # minibots*
    li $t0, 0
    mv_mbot:
    bge $t0, $t1, mv_mbot_out
        li $t3, 4
        mul $t3, $t3, $t0
        add $t3, $t3, $a1
        lw $t4, 0($t3)
#        sll $t4, $t4, 8
#        lbu $t5, 0($t3) # loc
        lw $t6, 0($t2) # bot id
        sw $t6, SELECT_ID
        sw $t4, SET_TARGET
        addi $t0, $t0, 1
        addi $t2, $t2, 8
    j mv_mbot
    mv_mbot_out:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


get_oppo_silo:
	la $t0 location
	sw $t0, GET_MAP
	
	li $t1 0
	li $t4 3
	oppo_oloop:
	bge $t1, 1600, oppo_ooout
		add $t3 $t0 $t1	
		lbu $t3 0($t1)
		beq $t3 $t4 storeturn
		
	addi $t1 $t1 1
	j oppo_oloop
	oppo_oout:	
	li $t4 0
	sw $t4, atk_flag
	jr $ra
	storeturn:
	li $t4 1
	sw $t4, atk_flag
	li $t4 40
	div $t5 $t1 $t4 #y
   	mul $t4 $t4 $t5 
	sub $t4 $t1 $t4 #x
	li $t6 8
	sll $t4 $t4 $t6
	or $t4 $t4 $t5
	sw $t4, test_loc



assign_minibot:
		jal get_next_location
		addi $sp $sp -4
		sw $ra 0($sp)
		la $t0 minibot
		sw $t0 GET_MINIBOT($0)
		lw $t0 minibot($0)
		li $t1 0
		li $t4 8
		la $t2 minibot
		addi $t2 $t2 4
		addi $t0 $t0 -1
		li $v0 0
		li $v1 0
		assign_loop:
		ble $t0 $t1 assign_loop_out
			mul $t3 $t1 $t4
			add $t5 $t3 $t2
			lw $t5 0($t5) #ID
			sw $t5 SELECT_ID($0)
			jal get_next_location
			sll $t8 $v0 8
			or $t8 $t8 $v1
			sw $t8 SET_TARGET($0)
		addi $t1 $t1 1
		j assign_loop
		assign_loop_out:
		lw $ra 0($sp)
		addi $sp $sp 4
		jr $ra



encode_five_locations:
	addi $sp $sp -16
	sw $ra 0($sp)
	sw $s0 4($sp)
	sw $s1 8($sp)
	sw $s2 12($sp)
	la $t9 location
	sw $t9, GET_KERNEL_LOCATIONS
	li $s0 5
	encode_loop:
	beq $s0 $0 encode_loc_out
		#use same logic as get_next_location to get x y
		
		#use similar logic as move main to encode path
	addi $s0 $s0 -1
	j encode_loop
	encode_loc_out:








get_next_location:
		la $t9 location
		sw $t9 GET_KERNEL_LOCATIONS($0)
		la $t4 test_loc
		add $t9 4
		li $t5 0 # find 10
		loopp:
		bge $t5 10 loop_over
			
			lw $t6, TIMER
			div $t8, $t6, 36
			div $t7, $t8, 36
			mul $t9, $t7, 36
			sub $t7, $t8, $t9
		    mul $t8, $t8, 36
			sub $t6 $t6 $t8

			li $a1 40

			la $t9 location
			loc_outer:
			bge $t6 40 loc_outer_exit
				loc_inner:
				bge $t7 40 loc_inner_exit
					mul $t8 $a1 $t6
					add $t8 $t8 $t7
					add $t8 $t8 $t9
					lb $t8 0($t8)
					bgt $t8 3 loc_outer_exit
				addi $t7 1
				j loc_inner
				loc_inner_exit:
				li $t7 0
			addi $t6 1
			j loc_outer
			loc_outer_exit:
		blt $t8 3 gnls
			mul $t8 $t7 256
			or $t8 $t6 $t8
			sw $t8 0($t4)
				move $a0 $t7
				li $v0 1
				syscall
				li $v0 4
				li $a0 0
				syscall

				move $a0 $t6
				li $v0 1
				syscall
				
				li $v0 4
				li $a0 0
				syscall

			add $t4 4
			add $t5 1
		gnls:
		j loopp
		loop_over:
		jr $ra



move_main:
addi $sp $sp -12
	sw $ra 0($sp)
        sw $s0 4($sp)
        sw $s1 8($sp)
	lw $t0 BOT_X #x
	lw $t1 BOT_Y #y
	li $t8 8
#	div $t0 $t0 $t8
#	div $t1 $t1 $t8
	mul $a0 $a0 $t8
	mul $a1 $a1 $t8
	
	slti $t2 $t0 160 #x < 160
	slti $t3 $t1 160 #y < 160
	not $t4 $t2
	not $t5 $t3
	

	sub $s0 $a0 $t0
	sub $s1 $a1 $t1
	

	ble $s0 $0 x_offset_neg

x_offset_pos:
	ble $s1 $0 xpyn
	xpyp:
		ble $t3 $t2 xy_move		
		j yx_move
	xpyn:
		ble $t5 $t2 xy_move
		j yx_move
x_offset_neg:
	ble $s1 $0 xnyn 
	xnyp:
		ble $t5 $t2 yx_move
		j xy_move
	xnyn:
		ble $t3 $t2 yx_move
		j xy_move

xy_move:
	move $a0 $s0
	abs $a0 $a0
	ble $s0 $0 xleft
	xright:
		li $t8 0
		sw $t8 ANGLE
		li $t8 1
		sw $t8 ANGLE_CONTROL
		li $t8 10
		sw $t8 VELOCITY
		jal stop_timer
		
		ble $s1 $0 xyup
		j xydown
	xleft:
		li $t8 180
		sw $t8 ANGLE
		li $t8 1
		sw $t8 ANGLE_CONTROL
		li $t8 10
		sw $t8 VELOCITY
		jal stop_timer
		ble $s1 $0 xyup
		j xydown
        xyup:
            li $t8 270
            sw $t8 ANGLE
            li $t8 1
            sw $t8 ANGLE_CONTROL
            li $t8 10
            sw $t8 VELOCITY
			move $a0 $s1
			neg $a0 $a0
            jal stop_timer
            j move_end
        xydown:
            li $t8 90
            sw $t8 ANGLE
            li $t8 1
            sw $t8 ANGLE_CONTROL
            li $t8 10
            sw $t8 VELOCITY
			move $a0 $s1
            jal stop_timer
			j move_end
	
yx_move:
	ble $s1 $0 yup
	ydown:
        li $t8 90
        sw $t8 ANGLE
        li $t8 1
        sw $t8 ANGLE_CONTROL
        li $t8 10
        sw $t8 VELOCITY
		move $a0 $s1
        jal stop_timer

        ble $s1 $0 yxleft
        j yxright
    yup:
        li $t8 270
        sw $t8 ANGLE
        li $t8 1
        sw $t8 ANGLE_CONTROL
        li $t8 10
        sw $t8 VELOCITY
		move $a0 $s1
		neg $a0 $a0
        jal stop_timer
        ble $s1 $0 yxleft
        j yxright
        yxleft:
            li $t8 180
            sw $t8 ANGLE
            li $t8 1
            sw $t8 ANGLE_CONTROL
            li $t8 10
            sw $t8 VELOCITY
            move $a0 $s0
            neg $a0 $a0
            jal stop_timer
            j move_end
        yxright:
            li $t8 0
            sw $t8 ANGLE
            li $t8 1
            sw $t8 ANGLE_CONTROL
            li $t8 10
            sw $t8 VELOCITY
            move $a0 $s0
			jal stop_timer
			j move_end
	move_end:
		lw $ra 0($sp)
		lw $s0 4($sp)
		lw $s1 8($sp)
		addi $sp $sp 12
		jr $ra

main_target:
        la $t9 location
        sw $t9 GET_KERNEL_LOCATIONS($0)

		#ensure safety
		li $t5 CTR_LEFT
		li $t6 CTR_TOP
		bge $v0 $t6 skipv0reset
		li $v0 CTR_TOP
		skipv0reset:
		bge $v1 $t5 skipv1reset
		li $v1 CTR_LEFT
		skipv1reset:


        li $t6 40
        addi $t9 $t9 4
        mt_outer:
        bge $v0 33 mt_outer_exit
            mt_inner:
            bge $v1 26 mt_inner_exit
                mul $t8 $t6 $v0
                add $t8 $t8 $v1
                add $t8 $t8 $t9
                lb $t8 0($t8)
                blt $t8 4 mt_next_loc
				move $a0 $v0
				move $s0 $v0

                jr $ra
                mt_next_loc:
            addi $v1 $v1 1
            j mt_inner
            mt_inner_exit:

            li $v1 CTR_LEFT
        addi $v0 $v0 1
        j mt_outer
        mt_outer_exit:
        li $v0 CTR_TOP

###print result
		jr $ra


dist:
	mul $a0, $a0, $a0 # x^2
	mul $a1, $a1, $a1 # y^2
	add $v0, $a0, $a1 # x^2 + y^2
	mtc1 $v0, $f0
	cvt.s.w $f0, $f0 # float(x^2 + y^2)
	sqrt.s $f0, $f0 # sqrt(x^2 + y^2)
	cvt.w.s $f0, $f0 # int(sqrt(...))
	mfc1 $v0, $f0
	jr $ra


.globl sb_arctan
sb_arctan:
li $v0, 0 # angle = 0;
abs $t0, $a0 # get absolute values
abs $t1, $a1
ble $t1, $t0, no_TURN_90
## if (abs(y) > abs(x)) { rotate 90 degrees }
move $t0, $a1 # int temp = y;
neg $a1, $a0 # y = -x;
move $a0, $t0 # x = temp;
li $v0, 90 # angle = 90;
no_TURN_90:
bgez $a0, pos_x # skip if (x >= 0)
## if (x < 0)
add $v0, $v0, 180 # angle += 180;
pos_x:
mtc1 $a0, $f0
mtc1 $a1, $f1
cvt.s.w $f0, $f0 # convert from ints to floats
cvt.s.w $f1, $f1
div.s $f0, $f1, $f0 # float v = (float) y / (float) x;
mul.s $f1, $f0, $f0 # v^^2
mul.s $f2, $f1, $f0 # v^^3
l.s $f3, three # load 3.0
div.s $f3, $f2, $f3 # v^^3/3
sub.s $f6, $f0, $f3 # v - v^^3/3
mul.s $f4, $f1, $f2 # v^^5
l.s $f5, five # load 5.0
div.s $f5, $f4, $f5 # v^^5/5
add.s $f6, $f6, $f5 # value = v - v^^3/3 + v^^5/5
l.s $f8, PI # load PI
div.s $f6, $f6, $f8 # value / PI
l.s $f7, F180 # load 180.0
mul.s $f6, $f6, $f7 # 180.0 * value / PI
cvt.w.s $f6, $f6 # convert "delta" back to integer
mfc1 $t0, $f6
add $v0, $v0, $t0 # angle += delta
jr $ra






# The contents of this file are not graded, it exists purely as a reference solution that you can use


# #define MAX_GRIDSIZE 16
# #define MAX_MAXDOTS 15

# /*** begin of the solution to the puzzle ***/

# // encode each domino as an int
# int encode_domino(unsigned char dots1, unsigned char dots2, int max_dots) {
#     return dots1 < dots2 ? dots1 * max_dots + dots2 + 1 : dots2 * max_dots + dots1 + 1;
# }
encode_domino:
        bge     $a0, $a1, encode_domino_greater_row

        mul     $v0, $a0, $a2           # col * max_dots
        add     $v0, $v0, $a1           # col * max_dots + row
        add     $v0, $v0, 1             # col * max_dots + row + 1
        j       encode_domino_end
encode_domino_greater_row:
        mul     $v0, $a1, $a2           # row * max_dots
        add     $v0, $v0, $a0           # row * max_dots + col
        add     $v0, $v0, 1             # col * max_dots + row + 1
encode_domino_end:
        jr      $ra

# -------------------------------------------------------------------------
next:
        # $a0 = row
        # $a1 = col
        # $a2 = num_cols
        # $v0 = next_row
        # $v1 = next_col

        #     int next_row = ((col == num_cols - 1) ? row + 1 : row);
        move    $v0, $a0
        sub     $t0, $a2, 1
        bne     $a1, $t0, next_col
        add     $v0, $v0, 1
next_col:
        #     int next_col = (col + 1) % num_cols;
        add     $t1, $a1, 1
        rem     $v1, $t1, $a2

        jr      $ra




# // main solve function, recurse using backtrack
# // puzzle is the puzzle question struct
# // solution is an array that the function will fill the answer in
# // row, col are the current location
# // dominos_used is a helper array of booleans (represented by a char)
# //   that shows which dominos have been used at this stage of the search
# //   use encode_domino() for indexing
# int solve(dominosa_question* puzzle, 
#           unsigned char* solution,
#           int row,
#           int col) {
#
#     int num_rows = puzzle->num_rows;
#     int num_cols = puzzle->num_cols;
#     int max_dots = puzzle->max_dots;
#     int next_row = ((col == num_cols - 1) ? row + 1 : row);
#     int next_col = (col + 1) % num_cols;
#     unsigned char* dominos_used = puzzle->dominos_used;
#
#     if (row >= num_rows || col >= num_cols) { return 1; }
#     if (solution[row * num_cols + col] != 0) { 
#         return solve(puzzle, solution, next_row, next_col); 
#     }
#
#     unsigned char curr_dots = puzzle->board[row * num_cols + col];
#
#     if (row < num_rows - 1 && solution[(row + 1) * num_cols + col] == 0) {
#         int domino_code = encode_domino(curr_dots,
#                                         puzzle->board[(row + 1) * num_cols + col],
#                                         max_dots);
#
#         if (dominos_used[domino_code] == 0) {
#             dominos_used[domino_code] = 1;
#             solution[row * num_cols + col] = domino_code;
#             solution[(row + 1) * num_cols + col] = domino_code;
#             if (solve(puzzle, solution, next_row, next_col)) {
#                 return 1;
#             }
#             dominos_used[domino_code] = 0;
#             solution[row * num_cols + col] = 0;
#             solution[(row + 1) * num_cols + col] = 0;
#         }
#     }
#     if (col < num_cols - 1 && solution[row * num_cols + (col + 1)] == 0) {
#         int domino_code = encode_domino(curr_dots,
#                                         puzzle->board[row * num_cols + (col + 1)],
#                                         max_dots);
#         if (dominos_used[domino_code] == 0) {
#             dominos_used[domino_code] = 1;
#             solution[row * num_cols + col] = domino_code;
#             solution[row * num_cols + (col + 1)] = domino_code;
#             if (solve(puzzle, solution, next_row, next_col)) {
#                 return 1;
#             }
#             dominos_used[domino_code] = 0;
#             solution[row * num_cols + col] = 0;
#             solution[row * num_cols + (col + 1)] = 0;
#         }
#     }
#     return 0;
# }
solve:
        sub     $sp, $sp, 80
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)
        sw      $s7, 32($sp)
        
        move    $s0, $a0                # puzzle
        move    $s1, $a1                # solution
        move    $s2, $a2                # row
        move    $s3, $a3                # col

#     int num_rows = puzzle->num_rows;
#     int num_cols = puzzle->num_cols;
#     int max_dots = puzzle->max_dots;
#     unsigned char* dominos_used = puzzle->dominos_used;
        lw      $s4, 0($s0)             # puzzle->num_rows
        lw      $s5, 4($s0)             # puzzle->num_cols
        lw      $s6, 8($s0)             # puzzle->max_dots
        la      $s7, 268($s0)           # puzzle->dominos_used

# Compute:
# - next_row (Done below)
# - next_col (Done below)
        mul     $t0, $s2, $s5
        add     $t0, $t0, $s3           # row * num_cols + col
        add     $t1, $s2, 1
        mul     $t1, $t1, $s5
        add     $t1, $t1, $s3           # (row + 1) * num_cols + col
        mul     $t2, $s2, $s5
        add     $t2, $t2, $s3
        add     $t2, $t2, 1             # row * num_cols + (col + 1)

        la      $t3, 12($s0)            # puzzle->board
        add     $t4, $t3, $t0
        lbu     $t9, 0($t4)
        sw      $t9, 44($sp)            # puzzle->board[row * num_cols + col]
        add     $t4, $t3, $t1
        lbu     $t9, 0($t4)
        sw      $t9, 48($sp)            # puzzle->board[(row + 1) * num_cols + col]
        add     $t4, $t3, $t2
        lbu     $t9, 0($t4)
        sw      $t9, 52($sp)            # puzzle->board[row * num_cols + (col + 1)]

        # solution addresses
        add     $t9, $s1, $t0
        sw      $t9, 56($sp)            # &solution[row * num_cols + col]
        add     $t9, $a1, $t1
        sw      $t9, 60($sp)            # &solution[(row + 1) * num_cols + col]
        add     $t9, $a1, $t2
        sw      $t9, 64($sp)            # &solution[row * num_cols + (col + 1)]


        #     int next_row = ((col == num_cols - 1) ? row + 1 : row);
        #     int next_col = (col + 1) % num_cols;
        move    $a0, $s2
        move    $a1, $s3
        move    $a2, $s5
        jal     next
        sw      $v0, 36($sp)
        sw      $v1, 40($sp)


#     if (row >= num_rows || col >= num_cols) { return 1; }
        sge     $t0, $s2, $s4
        sge     $t1, $s3, $s5
        or      $t0, $t0, $t1
        beq     $t0, 0, solve_not_base

        li      $v0, 1
        j       solve_end
solve_not_base:

#     if (solution[row * num_cols + col] != 0) { 
#         return solve(puzzle, solution, next_row, next_col); 
#     }
        lw      $t0, 56($sp)
        lb      $t0, 0($t0)
        beq     $t0, 0, solve_not_solved

        move    $a0, $s0
        move    $a1, $s1
        move    $a2, $v0
        move    $a3, $v1
        jal     solve
        j       solve_end

solve_not_solved:
#     unsigned char curr_dots = puzzle->board[row * num_cols + col];
        lw      $t9, 44($sp)            # puzzle->board[row * num_cols + col]

#     if (row < num_rows - 1 && solution[(row + 1) * num_cols + col] == 0) {
        sub     $t5, $s4, 1
        bge     $s2, $t5, end_vert

        lw      $t0, 60($sp)
        lbu     $t8, 0($t0)             # solution[(row + 1) * num_cols + col]
        bne     $t8, 0, end_vert 

#         int domino_code = encode_domino(curr_dots,
#                                         puzzle->board[(row + 1) * num_cols + col],
#                                         max_dots);
        move    $a0, $t9
        lw      $a1, 48($sp)
        move    $a2, $s6
        jal     encode_domino
        sw      $v0, 68($sp)

#         if (dominos_used[domino_code] == 0) {
        add     $t0, $s7, $v0
        lbu     $t1, 0($t0)
        bne     $t1, 0, end_vert

#             dominos_used[domino_code] = 1;
        li      $t1, 1
        sb      $t1, 0($t0)

#             solution[row * num_cols + col] = domino_code;
#             solution[(row + 1) * num_cols + col] = domino_code;
        lw      $t0, 56($sp)
        sb      $v0, 0($t0)
        lw      $t0, 60($sp)
        sb      $v0, 0($t0)

        
#             if (solve(puzzle, solution, next_row, next_col)) {
#                 return 1;
#             }
        move    $a0, $s0
        move    $a1, $s1
        lw      $a2, 36($sp)
        lw      $a3, 40($sp)
        jal     solve
        beq     $v0, 0, end_vert_if
        
        li      $v0, 1
        j       solve_end
end_vert_if:

#             dominos_used[domino_code] = 0;
        lw      $v0, 68($sp)            # domino_code
        add     $t0, $v0, $s7
        sb      $zero, 0($t0)
        
#             solution[row * num_cols + col] = 0;
        lw      $t0, 56($sp)
        sb      $zero, 0($t0)
#             solution[(row + 1) * num_cols + col] = 0;
        lw      $t0, 60($sp)
        sb      $zero, 0($t0)
#         }
#     }

end_vert:

#     if (col < num_cols - 1 && solution[row * num_cols + (col + 1)] == 0) {
        sub     $t5, $s5, 1
        bge     $s3, $t5, ret_0
        lw      $t0, 64($sp)
        lbu     $t1, 0($t0)             # solution[row * num_cols + (col + 1)]
        bne     $t1, 0, ret_0

#         int domino_code = encode_domino(curr_dots,
#                                         puzzle->board[row * num_cols + (col + 1)],
#                                         max_dots);
        lw      $a0, 44($sp)            # puzzle->board[row * num_cols + col]
        lw      $a1, 52($sp)
        move    $a2, $s6
        jal     encode_domino
        sw      $v0, 68($sp)

#         if (dominos_used[domino_code] == 0) {
        add     $t0, $s7, $v0
        lbu     $t1, 0($t0)
        bne     $t1, 0, ret_0
        
#             dominos_used[domino_code] = 1;
        li      $t1, 1
        sb      $t1, 0($t0)

#             solution[row * num_cols + col] = domino_code;
        lw      $t0, 56($sp)
        sb      $v0, 0($t0)
#             solution[row * num_cols + (col + 1)] = domino_code;
        lw      $t0, 64($sp)
        sb      $v0, 0($t0)
#             if (solve(puzzle, solution, next_row, next_col)) {
#                 return 1;
#             }
        move    $a0, $s0
        move    $a1, $s1
        lw      $a2, 36($sp)
        lw      $a3, 40($sp)
        jal     solve
        beq     $v0, 0, end_horz_if
        
        li      $v0, 1
        j       solve_end
end_horz_if:



#             dominos_used[domino_code] = 0;
        lw      $v0, 68($sp) # domino_code
        add     $t0, $s7, $v0 
        sb      $zero, 0($t0)
        
#             solution[row * num_cols + col] = 0;
        lw      $t0, 56($sp)
        sb      $zero, 0($t0)
#             solution[row * num_cols + (col + 1)] = 0;
        lw      $t0, 64($sp)
        sb      $zero, 0($t0)
#         }
#     }
#     return 0;
# }
ret_0:
        li      $v0, 0

solve_end:
        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        lw      $s4, 20($sp)
        lw      $s5, 24($sp)
        lw      $s6, 28($sp)
        lw      $s7, 32($sp)
        add     $sp, $sp, 80
        jr      $ra



# // zero out an array with given number of elements
# void zero(int num_elements, unsigned char* array) {
#     for (int i = 0; i < num_elements; i++) {
#         array[i] = 0;
#     }
# }
zero:
        li      $t0, 0          # i = 0
zero_loop:
        bge     $t0, $a0, zero_end_loop
        add     $t1, $a1, $t0
        sb      $zero, 0($t1)
        add     $t0, $t0, 1
        j       zero_loop
zero_end_loop:
        jr      $ra




# // the slow solve entry function,
# // solution will appear in solution array
# // return value shows if the dominosa is solved or not
# int slow_solve_dominosa(dominosa_question* puzzle, unsigned char* solution) {
#     zero(puzzle->num_rows * puzzle->num_cols, solution);
#     zero(MAX_MAXDOTS * MAX_MAXDOTS, dominos_used);
#     return solve(puzzle, solution, 0, 0);
# }
# // end of solution
# /*** end of the solution to the puzzle ***/
slow_solve_dominosa:
        sub     $sp, $sp, 16
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)

        move    $s0, $a0
        move    $s1, $a1



#     zero(puzzle->num_rows * puzzle->num_cols, solution);
        lw      $t0, 0($s0)
        lw      $t1, 4($s0)
        mul     $a0, $t0, $t1
        jal     zero

#     zero(MAX_MAXDOTS * MAX_MAXDOTS + 1, dominos_used);
        li      $a0, 226
        la      $a1, 268($s0)
        jal     zero

#     return solve(puzzle, solution, 0, 0);
        move    $a0, $s0
        move    $a1, $s1
        li      $a2, 0
        li      $a3, 0
        jal     solve

        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        add     $sp, $sp, 16

        jr      $ra



#####
check_speed:
repeat:
la $t0 VELOCITY
lw $t0 0($t0)
beq $t0 $0 checked
li $t1 0
li $t2 1000
	wait_cs:
	beq $t1 $t2 for_out
	addi $t1 $t1 1
	j wait_cs
for_out:
j repeat
checked:
jr $ra
pick:
la $t0 PICKUP
sw $t0 0($t0)
jr $ra


stop_timer:

beq $a0 $0 stop_out

li $t0 1000
mul $a0 $a0 $t0
li $t0 6
div $a0 $a0 $t0
li $t0 0
waitback:
bge $t0 $a0 stop_out
addi $t0 $t0 1
sw $t0 PICKUP($0)
j waitback
stop_out:
la $t0 VELOCITY
sw $0 0($t0)
jr $ra

####
up:
addi $sp $sp -4
sw $ra 0($sp)
jal check_speed
li $t1 0
or $t1 $t1 ANGLE
li $t2 270
sw $t2 0($t1)
li $t1 0 
or $t1 $t1 ANGLE_CONTROL
li $t2 1 ##abs
sw $t2 0($t1)
la $t1 VELOCITY
li $t2 10
sw $t2 0($t1)
lw $ra 0($sp)
addi $sp $sp 4

jr $ra

down:
addi $sp $sp -4
sw $ra 0($sp)
jal check_speed
la $t1 ANGLE
li $t2 90
sw $t2 0($t1)
la	$t1 ANGLE_CONTROL
li $t2 1 ##abs
sw $t2 0($t1)
la $t1 VELOCITY
li $t2 10
sw $t2 0($t1)
lw $ra 0($sp)
addi $sp $sp 4
jr $ra

left:
addi $sp $sp -4
sw $ra 0($sp)
jal check_speed
la $t1 ANGLE
li $t2 180
sw $t2 0($t1)
la $t1 ANGLE_CONTROL
li $t2 1 ##abs
sw $t2 0($t1)
la $t1 VELOCITY
li $t2 10
sw $t2 0($t1)
lw $ra 0($sp)
addi $sp $sp 4
jr $ra

right:
addi $sp $sp -4
sw $ra 0($sp)
jal check_speed
la $t1 ANGLE
li $t2 0
sw $t2 0($t1)
la $t1 ANGLE_CONTROL
li $t2 1 ##abs
sw $t2 0($t1)
la $t1 VELOCITY
li $t2 10
sw $t2 0($t1)
lw $ra 0($sp)
addi $sp $sp 4
jr $ra
























infinite:
        j       infinite              # Don't remov this! If this is removed, then your code will not be graded!!

.kdata
chunkIH:    .space 8  #TODO: Decrease this
non_intrpt_str:    .asciiz "Non-interrupt exception\n"
unhandled_str:    .asciiz "Unhandled interrupt type\n"
.ktext 0x80000180
interrupt_handler:
.set noat
        move      $k1, $at              # Save $at
.set at
        la      $k0, chunkIH
        sw      $a0, 0($k0)             # Get some free registers
        sw      $v0, 4($k0)             # by storing them to a global variable

        mfc0    $k0, $13                # Get Cause register
        srl     $a0, $k0, 2
        and     $a0, $a0, 0xf           # ExcCode field
        bne     $a0, 0, non_intrpt

interrupt_dispatch:                     # Interrupt:
		sw $0, VELOCITY
        mfc0    $k0, $13                # Get Cause register, again
        beq     $k0, 0, done            # handled all outstanding interrupts

        and     $a0, $k0, BONK_INT_MASK # is there a bonk interrupt?
        bne     $a0, 0, bonk_interrupt

        and     $a0, $k0, TIMER_INT_MASK # is there a timer interrupt?
        bne     $a0, 0, timer_interrupt

        and 	$a0, $k0, REQUEST_PUZZLE_INT_MASK
        bne 	$a0, 0, request_puzzle_interrupt

        li      $v0, PRINT_STRING       # Unhandled interrupt types
        la      $a0, unhandled_str
        syscall
        j       done

bonk_interrupt:
        
		lw $a0 BNK_AGL($0)
		addi $a0 $a0 90
		li $v0 340
		ble $a0 $v0 bnk_conti
		li $a0 45
		bnk_conti:
		sw $a0 ANGLE($0)
		sw $a0 BNK_AGL($0)
		li $a0 1
		sw $a0 ANGLE_CONTROL($0)
		li $a0 10
		sw $a0 VELOCITY($0)
		li $v0 400
		bnk_wait:
		beq $a0 $v0 bnk_out
		addi $a0 $a0 1
		j bnk_wait
		bnk_out:
		
#Fill in your code here
		
# li $a0 180
#       sw $a0 ANGLE
#       sw $zero ANGLE_CONTROL ## turn around
#       li $a0 10
#        sw $a0 VELOCITY
#        li $a0 1000
#        li $k0 0
#        wait4k:
#        beq $k0 $a0 out4k
#        addi $k0 $k0 1
#        j wait4k
#        out4k:
#        sw $0 VELOCITY
#        li $a0 1
#        sw $a0 BONK_ACK
		sw $0, BONK_ACK
        j       interrupt_dispatch      # see if other interrupts are waiting

request_puzzle_interrupt:
        sw      $0, REQUEST_PUZZLE_ACK
		
#Fill in your code here
		li $k0 1
        la $a0 has_puzzle
        sw $k0 0($a0)

        j	interrupt_dispatch

timer_interrupt:
		sw      $0, TIMER_ACK
#Fill in your code here
		
		lw $a0, signal
		addi $a0 $a0 1
		beq $a0, 3, timer_skip
		sw $a0, signal
		j	interrupt_dispatch
		timer_skip:
		li $a0 0
		sw $a0, signal
        j   interrupt_dispatch
non_intrpt:                             # was some non-interrupt
        li      $v0, PRINT_STRING
        la      $a0, non_intrpt_str
        syscall                         # print out an error message
# fall through to done

done:
        la      $k0, chunkIH
        lw      $a0, 0($k0)             # Restore saved registers
        lw      $v0, 4($k0)

.set noat
        move    $at, $k1                # Restore $at
.set at
        eret
