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
PUZZLE_CNT              = 0xffff2008
# Add any MMIO that you need here (see the Spimbot Documentation)

TSHLD = 5

CTR_LEFT = 14
CTR_TOP = 7

L_LEFT = 2
L_TOP = 20

R_LEFT = 29
R_TOP = 5

### Puzzle
GRIDSIZE = 16
signal:      	   .word 0
has_puzzle:        .word 0
puzzle_cnt:  .word 1
finishing:   .word 0
anchor: 		   .word -1
oppo_puzzle:       .word 0:3
puzzle:      .half 0:2000             
heap:        .half 0:2000
location:    .byte 0:1700
minibot:	 .word 0:30
atk_flag:    .word 0
test_loc:    .word 0

silo_built:  .word 0

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

		la $t0, puzzle
		sw $t0, REQUEST_PUZZLE
		
		j center_main
		
		main_dispatch:
		

        lw $t0, TIMER
        bgt $t0, 8700000, finish
		lw $t0, signal
		beq $t0, 1 mission_solve6
		beq $t0, 0 mission_move_main

	finish:
        li $t0, 1
        sw $t0, finishing
        lw $t0, BOT_X
        lw $t1, BOT_Y
        
        lw $t0, signal
        blt $t0, 2, ftl_skip
        	bne $t0, 2, ftl_skip2
        	jal transfer_l2m
        	j ftl_skip
        	ftl_skip2:
        	jal transfer_r2m
        ftl_skip:
		li $a0 14
		li $a1 13
		jal move_main
        top_left:
			li $s4 10
			sw $s4 VELOCITY

			li $s3 1
            li $t4 225
			sw $t4 ANGLE
			sw $s3 ANGLE_CONTROL
			
            li $a0 130
			jal stop_timer
			
            li $t4 135
            sw $t4 ANGLE
            sw $s3 ANGLE_CONTROL
			sw $s4 VELOCITY

            li $a0 16
            jal stop_timer
			

            li $t4 40
            sw $t4 ANGLE
            sw $s3 ANGLE_CONTROL
			sw $s4 VELOCITY


            li $a0 55
            jal stop_timer
			
			li $t4 95
			sw $t4 ANGLE
			sw $s3 ANGLE_CONTROL
			sw $s4 VELOCITY

			li $a0 110
			jal stop_timer
			
			li $t4 325
			sw $t4 ANGLE
			sw $s3 ANGLE_CONTROL
			sw $s4 VELOCITY

			li $a0 90
			jal stop_timer
			
			li $t4 43
            sw $t4 ANGLE
            sw $s3 ANGLE_CONTROL
            sw $s4 VELOCITY

            li $a0 275
            jal stop_timer
			

			li $t4 0
            sw $t4 ANGLE
            sw $s3 ANGLE_CONTROL
            sw $s4 VELOCITY

            li $a0 20
            jal stop_timer
			
			li $t4 230
            sw $t4 ANGLE
            sw $s3 ANGLE_CONTROL
            sw $s4 VELOCITY

            li $a0 70
            jal stop_timer

			li $t4 260
            sw $t4 ANGLE
            sw $s3 ANGLE_CONTROL
            sw $s4 VELOCITY

            li $a0 100
            jal stop_timer

			li $t4 30
			sw $t4 ANGLE
			sw $s3 ANGLE_CONTROL
			sw $s4 VELOCITY


        j top_left
        bottom_right:
            li $s6 0
        	li $s8 0
            li $s7 0
        	fbr_get_loop:
        		beq $s6, 10, fbr_out
        		jal fin_left_target
        		move $a0 $s8
                move $a1 $s7
        		jal move_main
        		addi $s6 $s6 1
        	j fbr_get_loop
        	fbr_out:
        j bottom_right
	j finish

    fin_left_target:
        la $t9 location
        sw $t9 GET_KERNEL_LOCATIONS($0)
        #ensure safety
        li $t5 13 #right bound
        li $t6 20 #bottom bound
        bge $s7 $t6 skipv0resetfl
        li $s7 0
        skipv0resetfl:
        bge $s8 $t5 skipv1resetfl
        li $s8 0
        skipv1resetfl:
        li $t6 40
        addi $t9 $t9 4
        mt_outerfl:
        bge $s7 20 mt_outer_exitfl
            mt_innerfl:
            bge $s8 13 mt_inner_exitfl
                mul $t8 $t6 $s7
                add $t8 $t8 $s8
                add $t8 $t8 $t9
                lb $t8 0($t8)
                blt $t8, TSHLD mt_next_locfl
                jr $ra
                mt_next_locfl:
            addi $s8 $s8 1
            j mt_innerfl
            mt_inner_exitfl:

            li $s8 0
        addi $s7 $s7 1
        j mt_outerfl
        mt_outer_exitfl:
        li $s7 0
        jr $ra

    # right_target:
    #     la $t9 location
    #     sw $t9 GET_KERNEL_LOCATIONS($0)
    #     #ensure safety
    #     li $t5 37 #right bound
    #     li $t6 17
    #     bge $s7 $t6 skipv0reset
    #     li $s7 R_TOP
    #     skipv0reset2:
    #     bge $s8 $t5 skipv1reset
    #     li $s8 R_LEFT
    #     skipv1reset2:
    #     li $t6 40
    #     addi $t9 $t9 4
    #     mt_outer2:
    #     bge $s7 17 mt_outer_exit2
    #         mt_inner2:
    #         bge $s8 37 mt_inner_exit2
    #             mul $t8 $t6 $s7
    #             add $t8 $t8 $s8
    #             add $t8 $t8 $t9
    #             lb $t8 0($t8)
    #             blt $t8, TSHLD mt_next_loc2
    #             jr $ra
    #             mt_next_loc2:
    #         addi $s8 $s8 1
    #         j mt_inner2
    #         mt_inner_exit2:

    #         li $s8 R_LEFT
    #     addi $s7 $s7 1
    #     j mt_outer2
    #     mt_outer_exit2:
    #     li $s7 R_TOP
    #     jr $ra

	mission_solve6:
		lw $t0, TIMER
		addi $t0 $t0 10
		sw $t0, TIMER

		la $t0, minibot
		sw $t0, GET_MINIBOT
		lw $t0, minibot
		bne $t0, $0, main_dispatch

		
		la $t0, oppo_puzzle
		sw $t0, PUZZLE_CNT
		lw $t0 4($t0)    ##oppo_puzzle
		bgt $t0, 3, need_solve

		jal get_oppo_silo
		lw $t0, atk_flag
		beq $t0, 1, need_solve	
	    j main_dispatch	


		need_solve:
        lw $s0, puzzle_cnt
        puzzle_loop:
            beq $s0 $0 out_puzzle_loop ## when solved 4 puzzles go collect
            la $t1 has_puzzle
        	la $a0 puzzle
            la $a1 heap
            li $a2 0
            li $a3 0
            while:
                lw $t2 0($t1)
                bne $0 $t2 start_solving
            j while
            start_solving:
            jal slow_solve_dominosa
			la $a0 puzzle
			sw $a0 REQUEST_PUZZLE
            la $a1 heap
            sw $a1 SUBMIT_SOLUTION
			sw $0  has_puzzle
	    addi $s0 $s0 -1
        j puzzle_loop
		out_puzzle_loop:
		li $t0 1
		sw $t0, SPAWN_MINIBOT
		
		jal get_oppo_silo
		lw $t0, atk_flag
		
		beq $t0, 0, non_atk
		la $t0, minibot
        sw $t0, GET_MINIBOT
        lw $t1, minibot
		beq $t1, 0, non_atk
            lw $t0, 4($t0)
			sw $t0, SELECT_ID
			lw $t0, test_loc
			sw $t0, SET_TARGET

		non_atk:
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
	li $t9 100
	add $t8 $t8 $t9
	sw $t8, TIMER

	
    get_more:
	lw $t0, anchor
	beq $t0, 0, middle_get
	beq $t0, 1, middle_get1
	beq $t0, 2, left_get
	beq $t0, 3, right_get
middle_get:
	li $s6 0
	li $s8 CTR_LEFT
    li $s7 CTR_TOP
	middle_get_loop:
		beq $s6, 10, middle_out
		jal main_target
		bne $s8, CTR_LEFT, valid_t
        bne $s7, CTR_TOP, valid_t
		j middle_out
		valid_t:
		move $a0 $s8
        move $a1 $s7
		jal move_main
		addi $s6 $s6 1
	j middle_get_loop
	middle_out:
	jal transfer_m2l
	li $t0, 2
	sw $t0, anchor
	j get_out

middle_get1:
    li $s6 0
	li $s8 CTR_LEFT
    li $s7 CTR_TOP
    middle_get_loop1:
        beq $s6, 10, middle_out1
        jal main_target

		bne $s8, CTR_LEFT, valid_t1
        bne $s7, CTR_TOP, valid_t1
		j middle_out1
		valid_t1:
        move $a0 $s8
        move $a1 $s7
        jal move_main
        addi $s6 $s6 1
    j middle_get_loop1
    middle_out1:

    jal transfer_m2r
    li $t0, 3
    sw $t0, anchor
    j get_out

left_get:
	li $s8 L_LEFT
	li $s7 L_TOP
	li $s6 0
	left_get_loop:
		beq $s6, 10, left_out
		jal left_target
		bne $s8, L_LEFT, valid_t2
        bne $s7, L_TOP, valid_t2
		j left_out
		valid_t2:
		move $a0 $s8
		move $a1 $s7
		jal move_main
		addi $s6 $s6 1
    j left_get_loop
    left_out:
    jal transfer_l2m
    li $t0, 1
    sw $t0, anchor
    j get_out

right_get:
    li $s8 R_LEFT
    li $s7 R_TOP
    li $s6 0
    right_get_loop:
        beq $s6, 10, right_out
        jal right_target
		bne $s8, R_LEFT, valid_t3
        bne $s7, R_TOP, valid_t3
		j right_out
		valid_t3:
        move $a0 $s8
        move $a1 $s7
        jal move_main
        addi $s6 $s6 1
    j right_get_loop
    right_out:
    jal transfer_r2m
    li $t0, 0
    sw $t0, anchor
    j get_out

get_out:
    lw $t8 signal
    bne $t8, 0, main_dispatch
    j get_more


	


#test_field:
	# lw $t8, TIMER
	# li $t9 10000
	# add $t8 $t8 $t9
	# sw $t8, TIMER
	#your code
        # lw $t0, puzzle_cnt
        # beq $t0, 4, enter_move_again
#        sub $sp, $sp, 4
#       sw $ra, 0($sp)
#       li $t0, 1
#       sw $t0, SPAWN_MINIBOT
#       sw $t0, SPAWN_MINIBOT
#       sw $t0, SPAWN_MINIBOT
#       
#       li $t0, 0x1a06
#       sw $t0, SELECT_IDLE
#       sw $t0, SET_TARGET
#       li $a0, 56
#        jal stop_timer
#       li $t0, 0x1a06  ## build silo at (6,26)
#        sw $t0, BUILD_SILO
#       li $t8, 1
#       sw $t8, silo_built
#       lw $ra, 0($sp)
#       addi $sp, $sp, 4
#       jr $ra
#
#   main_mbot: ## spawn 2 bots and move to silo
#		li $t0 1
#		sw $t0, SPAWN_MINIBOT
#		sw $t0, SPAWN_MINIBOT
		# sw $t0, SPAWN_MINIBOT
		# sw $t0, SPAWN_MINIBOT
#       li $t0, 0x00001a06
#       sw $t0, SELECT_IDLE
#       sw $t0, SET_TARGET
#       jr $ra

	# 	enter_move_again:
    #     jal get_next_location

    #     move_again:
	# 	la $a1 test_loc
	# 	jal move_minibot
	# 	la $a0 400
	# 	jal stop_timer
		
    #     sw $t0, SELECT_IDLE
	# 	li $t0, 0x1a06
	# 	sw $t0, SET_TARGET

	# 	la $a0 500
	# 	jal stop_timer
    #     lw $t5, signal
    #     bne $t5, 2, main_dispatch
	# 	j move_again


	# j test_field	

get_oppo_silo:
	la $t0 location
	sw $t0, GET_MAP
	
	li $t1 0
	li $t4 3
	li $t5 2
	oppo_oloop:
	beq $t1, 1600, oppo_oout
		add $t3 $t0 $t1	
		lbu $t3 0($t3)
		bne $t1, 1180, test_bk
			li $v0 1
			move $a0 $t3
			syscall
		test_bk:
		beq $t3 $t4 storeturn
        beq $t3 $t5 storeturn
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
	sll $t5 $t5 $t6
	or $t4 $t4 $t5
	sw $t4, test_loc
    jr $ra






#get_next_location:
		la $t9 location
		sw $t9 GET_KERNEL_LOCATIONS($0)
		la $t4 test_loc
		add $t9 4
		li $t5 0 # find 10
		loopp:
		bge $t5 10 loop_over
			
			 lw $t6, TIMER
			 div $t8, $t6, 15
			 div $t9, $t6, 13
			 mul $t9, $t9, 13
			 sub $t7, $t6, $t9
		     mul $t8, $t8, 15
			 sub $t6 $t6 $t8
			
			li $a1 40
			addi $t7 $t7 20
			addi $t6 $t6 2

			la $t9 location
			addi $t9 $t9 4
			loc_outer:
			bge $t6 34 loc_outer_exit
				loc_inner:
				bge $t7 17 loc_inner_exit
					mul $t8 $a1 $t6
					add $t8 $t8 $t7
					add $t8 $t8 $t9
					lb $t8 0($t8)
					bgt $t8 3 loc_outer_exit
				addi $t7 1
				j loc_inner
				loc_inner_exit:
				li $t7 20
			addi $t6 1
			j loc_outer
			loc_outer_exit:
			

		ble $t8 3 gnls
			sll $t8 $t6 8
			or $t8 $t7 $t8 ###reversed
			sw $t8 0($t4)

			add $t4 4
			add $t5 1
		gnls:
		j loopp
		loop_over:
		jr $ra

move_main:
    addi $sp $sp -20
	sw $ra 0($sp)
    sw $s0 4($sp)
    sw $s1 8($sp)
	sw $a0 12($sp)
	sw $a1 16($sp)


#    la $t0, minibot
#    sw $t0, GET_MINIBOT
#    lw $t1, minibot
#    bne $t1, $zero, label
#
#    label:
#    jal move_minibot
#
#	lw $a0 12($sp)
#	lw $a1 16($sp)

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

        ble $s0 $0 yxleft
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
        ble $s0 $0 yxleft
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
		addi $sp $sp 20
		jr $ra

main_target:
        la $t9 location
        sw $t9 GET_KERNEL_LOCATIONS($0)

		#ensure safety
		li $t5 26
		li $t6 33
		bgt $s7 $t6 skipv0reset
		li $s7 CTR_TOP
		skipv0reset:
		bgt $s8 $t5 skipv1reset
		li $s8 CTR_LEFT
		skipv1reset:
        li $t6 40
        addi $t9 $t9 4
        mt_outer:
        bge $s7 33 mt_outer_exit
            mt_inner:
            bge $s8 26 mt_inner_exit
                mul $t8 $t6 $s7
                add $t8 $t8 $s8
                add $t8 $t8 $t9
                lb $t8 0($t8)
                blt $t8, TSHLD, mt_next_loc
				
                jr $ra
                mt_next_loc:
            addi $s8 $s8 1
            j mt_inner
            mt_inner_exit:

            li $s8 CTR_LEFT
        addi $s7 $s7 1
        j mt_outer
        mt_outer_exit:
        li $s7 CTR_TOP
		jr $ra
		

left_target:
        la $t9 location
        sw $t9 GET_KERNEL_LOCATIONS($0)
        #ensure safety
        li $t5 11 #right bound
        li $t6 34
        bge $s7 $t6 skipv0reset1
        li $s7 L_TOP
        skipv0reset1:
        bge $s8 $t5 skipv1reset1
        li $s8 L_LEFT
        skipv1reset1:
        li $t6 40
        addi $t9 $t9 4
        mt_outer1:
        bge $s7 34 mt_outer_exit1
            mt_inner1:
            bge $s8 11 mt_inner_exit1
                mul $t8 $t6 $s7
                add $t8 $t8 $s8
                add $t8 $t8 $t9
                lb $t8 0($t8)
                blt $t8, TSHLD mt_next_loc1
                jr $ra
                mt_next_loc1:
            addi $s8 $s8 1
            j mt_inner1
            mt_inner_exit1:

            li $s8 L_LEFT
        addi $s7 $s7 1
        j mt_outer1
        mt_outer_exit1:
        li $s7 L_TOP
        jr $ra

right_target:
        la $t9 location
        sw $t9 GET_KERNEL_LOCATIONS($0)
        #ensure safety
        li $t5 37 #right bound
        li $t6 17
        bge $s7 $t6 skipv0reset2
        li $s7 R_TOP
        skipv0reset2:
        bge $s8 $t5 skipv1reset2
        li $s8 R_LEFT
        skipv1reset2:
        li $t6 40
        addi $t9 $t9 4
        mt_outer2:
        bge $s7 17 mt_outer_exit2
            mt_inner2:
            bge $s8 37 mt_inner_exit2
                mul $t8 $t6 $s7
                add $t8 $t8 $s8
                add $t8 $t8 $t9
                lb $t8 0($t8)
                blt $t8, TSHLD mt_next_loc2
                jr $ra
                mt_next_loc2:
            addi $s8 $s8 1
            j mt_inner2
            mt_inner_exit2:

            li $s8 R_LEFT
        addi $s7 $s7 1
        j mt_outer2
        mt_outer_exit2:
        li $s7 R_TOP
        jr $ra

transfer_m2l:
    addi $sp $sp -4
    sw $ra 0($sp)
    li $a0 15
    li $a1 28
    jal move_main
    li $t0 180
    sw $t0, ANGLE
    li $t0 1
    sw $t0, ANGLE_CONTROL
    li $t0 10
    sw $t0, VELOCITY
    li $a0 56
    jal stop_timer
    lw $ra 0($sp)
    addi $sp $sp 4
    jr $ra

transfer_l2m:
    addi $sp $sp -4
    sw $ra 0($sp)
    li $a0 7
    li $a1 28
    jal move_main
    li $t0 0
    sw $t0, ANGLE
    li $t0 1
    sw $t0, ANGLE_CONTROL
    li $t0 10
    sw $t0, VELOCITY
    li $a0 56
    jal stop_timer
    lw $ra 0($sp)
    addi $sp $sp 4
    jr $ra

transfer_m2r:
    addi $sp $sp -4
    sw $ra 0($sp)
    li $a0 25
    li $a1 12
    jal move_main
    li $t0 0
    sw $t0, ANGLE
    li $t0 1
    sw $t0, ANGLE_CONTROL
    li $t0 10
    sw $t0, VELOCITY
    li $a0 56
    jal stop_timer
    lw $ra 0($sp)
    addi $sp $sp 4
    jr $ra

transfer_r2m:
    addi $sp $sp -4
    sw $ra 0($sp)
    li $a0 33
    li $a1 12
    jal move_main
    li $t0 180
    sw $t0, ANGLE
    li $t0 1
    sw $t0, ANGLE_CONTROL
    li $t0 10
    sw $t0, VELOCITY
    li $a0 56
    jal stop_timer
    lw $ra 0($sp)
    addi $sp $sp 4
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
		li $v0 350
		blt $a0 $v0 bnk_conti
		li $a0 45
		bnk_conti:
		lw $v0, TIMER
		div, $k0, $v0, 20
        mul $k0, $k0, 20
        sub $v0 $v0 $k0
		addi $v0 $v0 -10
		add $a0 $a0 $v0

		sw $a0 ANGLE($0)
		sw $a0 BNK_AGL($0)
		li $a0 1
		sw $a0 ANGLE_CONTROL($0)
		li $a0 10
		sw $a0 VELOCITY($0)
		li $v0 30
		bnk_wait:
		beq $a0 $v0 bnk_out
		addi $a0 $a0 1
		j bnk_wait
		bnk_out:
        lw $a0, finishing
        bne $a0, $zero, bnk_skip
        sw $zero, VELOCITY
        bnk_skip:

		
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
#sw $0, VELOCITY
		lw $a0, signal
		addi $a0 $a0 1
		bgt $a0, 1, timer_skip
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
