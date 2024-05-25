

'control program Picaxe 28X2
'© D Hall & J Chidley 2009
 'PICONE TURBO 

'used b0 1 4 6 7 8 9 10 11 12 13 39 43 44 45 46 47 48 52 53 54 55
'used w7 w8 w9 w10 w12 w13 w14 w15 (b14 15 16 17 18 19 20 21 24 25 26 27 28 29 30 31)

#slot 0

symbol maze_center=$88'88' f1 a0  'b4 5x5    $87=Center for 16X16 maze

symbol left_wall=44'440 and target 0 to test right wall  'sets left wall detection 
symbol right_wall=50'46			'56sets right wall detection 
symbol front_wall=39'40'         40'35'             30'26			'sets front wall detection 
symbol reset_frontwall=86'60'50'74'40 86		'resets wheel counter if deadend is found 


symbol left_straighten=285'250		'value of left sensor if no straightening required
symbol right_straighten=270'275'247		'value of right sensor if no straightening required

symbol left_straighten1= left_straighten+20
symbol right_straighten1= right_straighten+20
symbol left_straighten2= left_straighten+30
symbol right_straighten2= right_straighten+30
symbol left_straighten3= left_straighten+40
symbol right_straighten3= right_straighten+40

symbol straight_before_right=12'12'    9'8'         9'10'11'15	'sets distance of short straight before right turn 
symbol angle_right=73'74'73'71'72'71'70'71'68'66'67 65 69			'sets amount of right turn 
symbol straight_after_right=63'61'60'48    '48'57     '56'54'5248'49'48'50	'sets distance of short straight after right turn (lower number to travel further)

symbol straight_before_left=13'12'    9'8'           9'10'11'15	'sets distance of short straight before left turn 
symbol angle_left=73'71'          72'73'74'73'           72'71'76'72 70			'sets amount of left turn 
symbol straight_after_left=70'77'75'73'72'70'70    '78    '77'73'72'6670		'sets distance of short straight after left turn (lower number to travel further)

symbol straight_turnround=15'65		'distance travelled into deadend before turn round 
symbol angle_turnround=63'or 64'          66'67'66            '67'69'68'67'65'63'79		'sets amount of turn round 
symbol end_wall=600'550 400			'front wall trigger in dead end


symbol left_motor=251'323'         370'450'390'		'sets left motor speed for straight line max 1023
symbol right_motor=255'259'254'333'          386'466'405'		'sets right motor speed for straight line max 1023
symbol slowleft_motor=251'280'
symbol slowright_motor=255'259'254'285'
symbol relay_turn=150				'slower speed for turn on spot


symbol button_A = pinC.4		'Button A
symbol start_button = pinC.6
symbol middle_green_led = 6
symbol left_red_led = 7
symbol right_red_led = 4
symbol yellow_led = 0			
symbol green_led = 5
symbol sensor = b7                  'sensor reading from pic28
symbol sensor_leds = c.5		'IR leds
symbol l_sensor_led = 3		'left forward pointing IR led
symbol r_sensor_led = 2		'right forward pointing IR led
symbol motor_right = c.1
symbol motor_left = c.2
symbol relay = 1
symbol left_sensor = w7	'value of left sensor reading
symbol front_sensor = w8	'value of front sensor reading
symbol right_sensor = w9	'value of right sensor reading
symbol wall_config = b43	'current cell wall config 0-7
symbol last_wheel = bit16
symbol maze_start=$F0

'PicOne maze solver symbols

symbol map_walls = b0           'this is overlaid by the folwing 8 sysbols
symbol w_north = bit5           '1 if wall to north
symbol w_south = bit7           '1 if wall to south
symbol w_west = bit4            '1 it wall to west
symbol w_east = bit6            '1 if wall to east
symbol w_visited = bit2         '1 if mouse has visited this square
symbol w_done = bit3            'used in maze solver
symbol w_direc1 = bit0          'bit 0 of solved direction
symbol w_direc2 = bit1          'bit 1 of solved direction

symbol map_walls2 = b1          'this is overlaid by the folwing 8 sysbols
symbol w_north2 = bit13         '1 if wall to north
symbol w_south2 = bit15         '1 if wall to south
symbol w_west2 = bit12          '1 it wall to west
symbol w_east2 = bit14          '1 if wall to east
symbol w_visited2 = bit10       '1 if mouse has visited this square
symbol w_done2 = bit11          'used in maze solver
symbol w_direc12 = bit8         'bit 0 of solved direction
symbol w_direc22 = bit9         'bit 1 of solved direction

symbol solvit = bit8            'run the solver
symbol clear_the_maze = bit9    'Used in maze solver

symbol backup_b0 = 239          'memory locations to save data
symbol backup_b1 = 126
symbol start_count = 238

symbol maze_pos = b10           'used by maze solver
symbol list1 = b11              'address of list1 entry
symbol list2 = b12              'address of list2 entry
symbol Target = b4              'address of target for maze solver

symbol pos = b13                'position of mouse in maze
symbol direc = b9               'direction of mouse in maze 0=north 1=east 2=south 3=west

symbol temp = b52
symbol temp2 = b6

symbol Path_start=256
symbol cpu_full_speed=em64

symbol w_timer =w10
settimer 65221

'b32=45	'straightening values


#no_data
#no_table
	
main:
		switch off r_sensor_led
		switch off l_sensor_led
		switch off relay						'output to relay
		switch off sensor_leds			'IR leds off
		adcsetup =3
		setfreq cpu_full_speed			'external resinator speed
		pwmout motor_right,255,0		'stop right motor
		pwmout motor_left,255,0			'stop left motor
		gosub maze_setup				'setup maze
		ptr=0
		b45=30
							'mouse start square requires added wheel counts to straight line count
		switch on middle_green_led		'middle green led on
		switch on left_red_led			'left red led on
		switch on right_red_led			'right red led on

		gosub check_path
		
		ptr=path_start
		@ptr=3
		setfreq k250			'adjust processor speed 
		
the_stat_button:
		
		do while start_button=1			'wait for start button 
			
			If button_A = 0 Then 		'If other button pressed output maze
				GoSub List_maze
			end if
			if temp=maze_center or @ptr=0 then gosub led_thing_3
		loop
		
		setfreq cpu_full_speed
		switch off middle_green_led		'middle green led off
		
		
		temp2=0
		do while start_button=0			'wait for start button to be released
			let temp2=temp2+1 max 255
			pause 50
			if temp2=255 then gosub led_thing
		loop
		
		if temp2=255 then
			ptr=path_start
			@ptr=0
			setfreq m1
			goto the_stat_button
		endif

		setfreq cpu_full_speed
		ptr=path_start
		if @ptr=0 then run 1 endif
		
		if temp=maze_center then goto end_of_run 'do fast run

		ptr=0
		
		front_sensor=0		
		switch off left_red_led			'left red led off
		switch off right_red_led		'right red led off
		pause 5000					'time to remove hand from mouse
	
		settimer off
		settimer count 65535
		timer=0
	
		
if w_visited=1 then
b39=1
gosub fill_maze
endif
		
		
		
		'wall_config=4	'ensures left and right forward look sensors are not active on first loop

		w15=slowright_motor
		w13=slowleft_motor
		
steer_straight:
		
		'w13=w13+w15/2
		'w15=w13+15						
				
		pwmduty motor_right,w15	'power to motors
		pwmduty motor_left,w13

	
	if wall_config = 0 then 'straightening with only end posts available
		if front_sensor<20 then
		'switch on green_led
			switch on l_sensor_led   
			readadc10 1,front_sensor
			switch off l_sensor_led
			
			'	last_wheel=pinc.0
			'		do while last_wheel=pinc.0		'wait for right wheel counter
			''		@ptr=@ptr and 247			'Clear maze working bit
			''		ptrl=ptrl+1
			''''		loop
			'		b45=b45 + 1					'add one to straight line counter		
	'							
			
			
				if front_sensor >25 then'34
					w12=w15-100 min 200		'slows down right motor value
					pwmduty motor_right,w12	
				endif
				
	
	
			switch on r_sensor_led
			readadc10 1,front_sensor
			switch off r_sensor_led
			

			
			
			
			
				if front_sensor >20 then'20
					w12=w13-100 min 200		'slows down left motor value
					pwmduty motor_left,w12					
				endif
	endif			
	'switch off green_led	
			
	'	
	endif	
	
	 			'	last_wheel=pinc.0
				'	do while last_wheel=pinc.0		'wait for right wheel counter
				'	@ptr=@ptr and 247			'Clear maze working bit
				'	ptrl=ptrl+1
				'	loop
				'	b45=b45 + 1					'add one to straight line counter		
								'
forward_loop:
'if wall_config <> 0 then
'switch off green_led
'endif

		'if b38>115 then	end_move		'end of current move
			
		switch on sensor_leds			'IR leds on
		readadc10  0,left_sensor			'read left wall sensor
		readadc10  1,front_sensor			'read front wall sensor
		readadc10  2,right_sensor			'read right wall sensor
		switch off sensor_leds			'IR leds off

		
		last_wheel=pinc.0
		do while last_wheel=pinc.0		'wait for right wheel counter
			@ptr=@ptr and 247			'Clear maze working bit
			ptrl=ptrl+1
		loop
		b38=timer+b45
		
		if left_sensor> left_wall then
			wall_config= 1			'wall config value for current cell
			switch on left_red_led 
		else
			switch off left_red_led
			wall_config= 0			'wall config value for current cell
		endif
		
		if right_sensor> right_wall then
			switch on right_red_led
			wall_config=wall_config+ 2	'wall config value for current cell
		else
			switch off right_red_led
		endif
		

'		if front_sensor> front_wall then
'			switch on middle_green_led		'middle green led on if wall is detected
'			wall_config=wall_config+ 4		'wall config walue for current cell
'		else
'			switch off middle_green_led
'		endif
	
					
		if front_sensor> reset_frontwall then 	'front wall detected end of current move
			if b38>50 then '60
			switch on sensor_leds			'IR leds on
			readadc10 1,front_sensor			'read front wall sensor
			
			if front_sensor> reset_frontwall then			
				readadc10 1,front_sensor			'read front wall sensor			
				switch off sensor_leds			'IR leds off
				switch on yellow_led
				if front_sensor> reset_frontwall then end_move                            'double check front sensor for timing gate interference					
			endif
			endif
		endif	
		if wall_config<b44 then 			'has wall config changed
			if b38>30 then'50		
				timer=0
				b45= 92			'use change in wall config to correct straight line wheel counter			
				b44= 0				'resets wall config for previous cell	
			endif
		'else
			
		endif
		b44=wall_config
		if b38>111 then	end_move	'115end of current move	  
		
		if wall_config=3 or front_sensor< front_wall then		
		
'		if b45<82 then	'92			

			if w15<right_motor then		'speed up mouse no turn ahead
				w15=w15+10 max right_motor
			endif
			if w13<left_motor then
				w13=w13+10 max left_motor	
			endif
		else
			if w15>slowright_motor then			'slow down mouse possible turn ahead
				w15=w15-15 min slowright_motor
			endif
			if w13>slowleft_motor then
				w13=w13-15 min slowleft_motor
			endif
		endif

		'w13=slowleft_motor
		'w15=slowright_motor
'	
		if left_sensor< left_wall then 		'straighten on left wall if available
			if right_sensor< right_wall then steer_straight		'straighten on right wall if available
			if right_sensor< right_straighten then steer_right		
		else
			if left_sensor> left_straighten then steer_right
		endif
		
		
steer_left:		
		if right_sensor<w16 then
			w12=w13+30'11'15'7'5'3
		else
			w12=w13
		endif
	
		w12=w12-30'40'20'11
'		if left_sensor>left_wall then
'			if left_sensor < left_straighten then	
'				w12=w12+20
'			endif
'		endif
		
	'if b45<80 or b45>100 then
	if wall_config=3 then	
		if right_sensor>right_straighten1 then
			w12=w12-20'30'20			
			if right_sensor>right_straighten2 then	'medium correcton
				w12=w12-30'20'40
				if right_sensor>right_straighten3 then	'medium correcton
					w12=w12-40'10'20'40	
				endif	
			endif
		endif		
	endif	
		pwmduty motor_left,w12	'power to motors
		pwmduty motor_right,w15	
		
		w16=right_sensor	
		goto forward_loop


steer_right:

		if left_sensor<w17 then
			w12=w15+30'11'15'9'7'5'3
		else
			w12=w15
		endif
		
		w12=w12-30'40'20'11
'		if right_sensor>right_wall then
'			if right_sensor<right_straighten then
'				w12=w12+20
'			endif
'		endif	
		
		if wall_config=3 then
'	if b45<80 or b45>100 then
		if left_sensor>left_straighten1 then	'medium correction
			w12=w12-20'30'20
			if left_sensor>left_straighten2 then	'hight correction
			w12=w12-30'20'40
				if left_sensor>left_straighten3 then	'hight correction
					w12=w12-40'10'20'40
				endif		
			endif		
		endif	
	endif			
		pwmduty motor_right,w12	'power to motors
		pwmduty motor_left,w13
			
		w17=left_sensor
		goto forward_loop

end_move:	
		settimer 65221
		if start_button = 0 then			'stop if start button pressed
			pwmduty motor_right,0		'stop right motor
			pwmduty motor_left,0			'stop left motor						
			gosub save_maze 
			goto main
		endif	
		
		gosub direction_check				'end of cell check for next move
		b44= 0						'resets wall config for previous cell
		'wall_config= 4 'ensures left and right forward look sensors are not active on first loop										
		
		
		settimer off
		settimer count 65535
		timer=0
		
		
		goto steer_straight


straight:
		b36=0
		return 'reset and back to forward loop
		
right_turn:	
		b48=straight_before_right-w_timer min 7'5'0'if wheels have stopped some wheel counts will be lost
		if b48>3 then			'only do straight before turn if for 2 or more counts
			gosub left_wheel_counter
		endif		
	
		if b46=2 then
			timer=0
			do
				b47=timer 	
			loop until b47=4'3
		endif
	
		pwmduty motor_right,0
		
			if b48<4 then		'if wheels have stopped turn less sharp
			b48= angle_right-8
			else
			b48= angle_right
			endif
		
		gosub left_wheel_counter

		b45= straight_after_right
		b36=1
		return

left_turn:	
		
	'	b36=0
		b48=straight_before_left-w_timer min 7'5'0'if wheels have stopped some wheel counts will be lost
		 if b48>3 then			'only do straight before turn if for 2 or more counts
			gosub left_wheel_counter
		endif

		if b46=3 then
			timer=0
			do
				b47=timer 	
			loop until b47=3
		endif
		
		pwmduty motor_left,0
		
			if b48<4 then		'if wheels have stopped turn less sharp
			b48= angle_left-8
			else
			b48= angle_left
			endif
		
		b45= straight_after_left
		gosub right_wheel_counter
		
		return									

turn_round:
		'b36=0
	
		b45=0
		b48= straight_turnround
		b47= 0
		w12=slowright_motor-70
		gosub deadend_straight	
		
		pwmduty motor_right,0			'stop both motors before turnround
		pause 20						'adjusted to ensure mouse stops without twist
		pwmduty motor_left,0

		
		if solvit=1 then
			GoSub solve_maze
            	solvit = 0
            endif
        
            switch on relay					'switch relay on
		pwmduty motor_right,relay_turn			'right_motor
		pwmduty motor_left,relay_turn			'left_motor
		b48= angle_turnround
		
		gosub right_wheel_counter			'count turnround
		
		pwmduty motor_right,0
		pause 40						'adjusted to ensure mouse stops without twist
		pwmduty motor_left,0
		switch off relay					'switch relay off
		pause 100
		
		if	target=maze_center then
			gosub check_path
			if temp=maze_center then 
				if pos=0xE0 then goto end_of_run			
				let target=maze_start
				gosub clear_maze_bits
				GoSub solve_maze
	            	solvit = 0        	
 			else
 				pause 100
			endif
		else
		pause 100
		endif
			'at this point program can goto fast_moves
		b45= 95'92'93'80'93'80'30 92	'after deadend requires added wheel counts to straight line count
		b48=48'42'    62 distance out dead end
		b47= 0
		w12=slowright_motor-90'70
		b44=0
		gosub deadend_straight		
		'b44=0
		
		return		

deadend_straight:					'straightening on walls entering and leaving a deadend
		pwmduty motor_right,350
		pwmduty motor_left,350
		
deadend_loop:					
		switch on sensor_leds				'IR leds on
		readadc10  0,left_sensor				'reads left wall sensor
		readadc10  1,front_sensor				'read front wall sensor
		readadc10 2,right_sensor				'read right wall sensor
		switch off sensor_leds      			'IR leds off
		
		do while last_wheel=pinc.0			'wait for left wheel counter
			@ptr=@ptr and 247
			ptrl=ptrl+1
		loop
		last_wheel=pinc.0
		
		b47=b47+ 1
		
			
		if left_sensor> left_wall then
			wall_config= 1			'wall config value for current cell
			switch on left_red_led 
		else
			wall_config= 0			'wall config value for current cell
			switch off left_red_led		'no left wall left red led off
		endif
		
		if right_sensor> right_wall then
			switch on right_red_led
			wall_config=wall_config+ 2	'wall config value for current cell
		else
			switch off right_red_led	'no right wall right red led off
		endif
	
	
		if wall_config<b44 then 'return			'has wall config changed
'			pwmduty motor_right,0
'			pause 40						'adjusted to ensure mouse stops without twist
'			pwmduty motor_left,0
'			stop		
		endif
		
		b44=wall_config
	
			
		if b47=>b48 then 
'			pwmduty motor_right,0
'			pause 40						'adjusted to ensure mouse stops without twist
'			pwmduty motor_left,0
'			stop
		
		return
		endif
		
		if b45=0 then	'mouse is going into dead end use front wall reset
			if front_sensor>front_wall then	'if dead end travel to end wall 
			b47=0
				if front_sensor>end_wall then	return
				endif
			endif	
		endif			
		
		'100'80	
				
straighten:		if left_sensor< left_wall then 		'straighten on left wall if available
				if right_sensor< right_wall then deadend_straight	
				if right_sensor< right_straighten then deadsteer_right	
			else
				if left_sensor> left_straighten then deadsteer_right
			endif
		
		pwmduty motor_left,w12		'slower speed for left motor to straighten mouse
		pwmduty motor_right,slowright_motor
		goto deadend_loop
		
deadsteer_right:
		pwmduty motor_right,w12	'slower speed for right motor to straighten mouse
		pwmduty motor_left,slowleft_motor
		goto deadend_loop	 
			 
left_wheel_counter:						'count left wheel counter to the value of b8

		b47=0		
		do
			last_wheel=pinc.0
			
			do while last_wheel=pinc.0		'wait for left wheel counter to change
				@ptr=@ptr and 247
				ptrl=ptrl+1
			loop
			
			b47=b47+ 1
			
		loop until b47=b48		
		return

right_wheel_counter:						'count right wheel counter to the value of b8

		b47=0		
		do
			last_wheel=pinc.3
			
			do while last_wheel=pinc.3		'wait for right wheel counter to change
				@ptr=@ptr and 247
				ptrl=ptrl+1
			loop
			
			b47=b47+ 1
			
		loop until b47=b48		
		return

direction_check:	
		switch off middle_green_led
		if front_sensor> front_wall then
			switch on middle_green_led		'middle green led on if wall is detected
			wall_config=wall_config+ 4		'wall config walue for current cell
	'	else
	'		
		endif
		
		pwmduty motor_right,0			'stop right motor untill next move is decided
		pause 20						'adjusted to ensure mouse stops with no twist
		pwmduty motor_left,0				'stop left motor untill next move is decided 

		sensor=wall_config
		
		timer=0		
		gosub check_cell
		b46=b8
		w_timer=timer>>3	'value for amount of time spent solving maze 
		if w_timer>9 then
			w_timer =8
		endif
		b45=w_timer
		
		pwmduty motor_right,slowright_motor
		pause 35						'ajusted to ensure mouse starts with no twist
		pwmduty motor_left,slowleft_motor
		'wall_config=0
		'b44=0		 
		
		on b8 gosub turn_round,straight,right_turn,left_turn
		b44=0
		return



Maze_setup:						'Setup maze for new run
        
        
        if	button_a = 0 then
        	GoSub clear_maze        	'if button pressed then reset the maze map
		gosub save_maze
        else
        	gosub restore_maze
        	GoSub clear_maze_bits   	'Rest the maze for solving
        end if
        
        switch on yellow_led
        
        Target = maze_center 			'first run to the center
        pos = maze_start - 16 'start in bottom left square (mouse always starts with a forward move so asume start one square forward)
        direc = 0                   	'facing north
        solvit = 0
                
        GoSub solve_maze                	'solve the maze
        
        
        switch off yellow_led             	'mouse ready to go when yellow led is off
        
        return
        
        
check_cell:                               	'check if direction required for PIC28 called when pin 6 is High


         	
    	If pos = Target Then    		'if at target swap to go back to start/center
         		get pos,map_walls
         		gosub write_the_mazemap
         		gosub clear_maze_bits
         		
         		solvit = 1
         		gosub save_maze
         		
         		
         		
         	if Target = maze_center Then
                        Target = maze_start
                        switch on green_led
gosub fill_maze			
				get pos,map_walls
				gosub write_the_mazemap
				'gosub solve_maze
				'solvit=0
				clear_the_maze=1
			    	
         	
         	Else	
             	Target = maze_center
             	switch off green_led
       		b39=b39+1
            	if b39 = 1 then 'number of visits to center before final run
           		gosub fill_maze
             	endif          	
	   	End If
         	gosub solve_maze
	endif
        
        get pos, map_walls     		'get the maze map info for the position of the mouse

        If w_visited = 0 Then   		'if already been here dont store the walls again
                solvit = 1
        else
        	if solvit = 1 then
        		if sensor=0 or sensor=1 or sensor=2 or sensor=4 then
        			GoSub solve_maze
                  	solvit = 0
                  	clear_the_maze = 1
                  	get pos, map_walls
                  endif  	
        	endif
        
        End If      
        
        Do
                Select Case sensor
                        Case 3
                                b8 = 1      'if walls both sides and no front wall always go forward
                        Case 5
                                b8 = 2	  
                        Case 6
                                b8 = 3
                        Case 7
                                b8 = 0
                        Else
                                    b8=map_walls & %00000011
                                select case direc  'convert to wall map bits depending on the direction of the mouse
                                        Case 0
                                                lookup b8,(1,2,0,3),b8 'mouse facing north
                                        Case 1
                                                lookup b8,(3,1,2,0),b8 'mouse facing east
                                        Case 2
                                                lookup b8,(0,3,1,2),b8  'mouse facing south
                                        Case 3
                                                lookup b8,(2,0,3,1),b8 'mouse facing west
                                endselect
                                
                                If solvit = 1 Then
                                        Select Case b8
                                                
                                                Case 0
                                                        b8 = 100
                                                Case 1
                                                        If sensor = 4 Then
                                                                b8 = 100
                                                        End If
                                                Case 2
                                                        If sensor = 2 Then
                                                                b8 = 100
                                                        End If
                                                Case 3
                                                        If sensor = 1 Then
                                                                b8 = 100
                                                        End If
                                        endselect
                                End If
                endselect
                                
                If b8 = 100 Then
                		If w_visited = 0 Then
                        	GoSub write_the_mazemap
                        endif
                        GoSub solve_maze
                        solvit = 0
                        clear_the_maze = 1
                        get pos, map_walls
                        
                End If

        Loop Until b8 < 100       
        
        If w_visited = 0 Then
                GoSub write_the_mazemap
                solvit=1
        End If
    
        get pos, map_walls

        On b8 GoSub go_round, go_forward, go_right, go_left
        
        switch off yellow_led
Return

go_left:                                'Mouse turning left
        dec direc
        If direc = 255 Then
                direc = 3
        End If
        GoTo go_forward
Return

go_right:                               'Mouse turning right
        inc direc
        If direc = 4 Then
                direc = 0
        End If
        GoTo go_forward
Return

go_round:                               'Mouse to do a U turn
        direc = direc + 2
        If direc > 3 Then
                direc = direc - 4
        End If
        GoTo go_forward
Return

go_forward:                             'mouse moving forward (Also move forward after a turn)

        Select Case direc
        Case 0
                pos = pos - 16 	'move north
        Case 1
                inc pos         	'move east
        Case 2
                pos = pos + 16 	'move south
        Case 3
                dec pos         	'move west
        endselect
        
Return


write_the_mazemap:			'Add new walls to the maze map

                select case direc   'convert to wall map bits depending on the direction of the mouse
                				'Also sets viseted bit for this square
                Case 0
                        lookup sensor,(4,20,68,84,36,52,100,116),b53 	'mouse facing north
                Case 1
                        lookup sensor,(4,36,132,164,68,100,196,228),b53 	'mouse facing east
                Case 2
                        lookup sensor,(4,68,20,84,132,196,148,212),b53   'mouse facing south
                Case 3
                        lookup sensor,(4,132,36,164,20,148,52,180),b53 	'mouse facing west
                endselect
                

                map_walls = map_walls | b53

                put pos,map_walls

Return


solve_maze:                             	'Solve the maze

        clear_the_maze=1
        
        poke backup_b0, map_walls       	'save varibals
        poke backup_b1, map_walls2
        
        switch on yellow_led
        list1=$50           			'initalize list1 address
        list2=$C0           			'initalize list2 address
        poke list1, Target      		'add maze center to list 1
        poke $51,target         		'terminate list1
        get Target, map_walls2
        w_done2 = 1
        put target,map_walls2
        
        Do
                Do
                        peek list1, maze_pos 'get next pos from list1
                        inc list1
                        
                        get maze_pos, map_walls2 'get wall map
                        

                        If w_north2 = 0 Then
                                                 'add_north
                                temp = maze_pos - 16
                                get temp, map_walls
                                
                                If w_done = 0 And w_south = 0 Then
                                        w_direc1 = 0
                                        map_walls=map_walls|%00001010
                                        put temp,map_walls
                                        If temp = pos Then GoTo End_maze
                                        poke list2, temp 'add to list2
                                        inc list2
                                End If
                        End If
                        
                        If w_south2 = 0 Then
                                                  'add_south
                                temp = maze_pos + 16
                                get temp, map_walls
                                
                                If w_done = 0 And w_north = 0 Then
                                        w_done = 1
                                        map_walls=map_walls&%11111100
                                        put temp,map_walls
                                        If temp = pos Then GoTo End_maze
                                        poke list2, temp 'add to list2
                                        inc list2
                                                
                                End If
                        End If
                        
                        If w_east2 = 0 Then
                                                   'add_east
                                temp = maze_pos + 1
                                get temp, map_walls
                                If w_done = 0 And w_west = 0 Then
                                        map_walls=map_walls|%00001011
                                        put temp,map_walls
                                        If temp = pos Then GoTo End_maze
                                        poke list2, temp 'add to list2
                                        inc list2
                                End If
                        End If
                        
                        If w_west2 = 0 Then
                                                    'add_west
                                temp = maze_pos - 1
                                get temp, map_walls
                                If w_done = 0 And w_east = 0 Then
                                        w_direc2 = 0
                                        map_walls=map_walls|%00001001
                                        put temp,map_walls
                                        If temp = pos Then GoTo End_maze
                                        poke list2, temp 'add to list2
                                        inc list2
                                End If
                        End If
                        
                Loop Until maze_pos = Target
        
                poke list2, Target              'terminate list 2
                
                if      list1<$C0 then  		'Swap and reset the lists
                        list1=$C0
                        list2=$50
                 Else
                        list1=$50
                        list2=$C0
                End If

                peek list1, maze_pos 		'get next pos from list1
                
        Loop Until maze_pos = Target

        							'the maze is solved
End_maze:

        get pos, map_walls
        If w_done = 0 Then GoTo maze_unsolvable
        
        peek backup_b0, map_walls 			'restore bit variables
        peek backup_b1, map_walls2
        switch off yellow_led

Return


clear_maze_bits:                        		'clear done bits in map

        toggle green_led
        
        For temp = 0 To 255
                get temp, map_walls

                w_done = 0
                put temp,map_walls
          
        Next
        
        toggle green_led
        
        clear_the_maze = 0

Return


save_maze:                       			'save maze to eeprom
     	gosub led_thing
      gosub led_thing
	gosub led_thing
	gosub led_thing
    
      For temp = 0 To 255
              get temp, map_walls
              write temp,map_walls
      Next

Return


restore_maze:                     			'restore maze from eeprom

	setfreq m8
       
     	gosub led_thing_2
      gosub led_thing_2
	gosub led_thing_2
	gosub led_thing_2

	setfreq cpu_full_speed

      For temp = 0 To 255
              read temp, map_walls
              put temp,map_walls
      Next

Return


Fill_maze:                       			'Block all unviseted paths

'        For b6 = 0 To 255
 '               get b6, map_walls
  '              If w_visited = 0 Then
   '                     w_north = 1
    '                    w_south = 1
     '                   w_east	= 1
      '                  w_west	= 1
       '                 put b6,map_walls
 '               End If
'        Next
 '       

'Return

        		For temp = 0 To 255
                	get temp, map_walls
           		If w_visited = 0 Then
               		temp2=temp-16             'North
               		get temp2, map_walls2
               		if w_visited2 = 1 Then                     
                  		w_north = w_south2
               		else
                 			w_north = 1
               		End if                                    
               		
               		temp2=temp+1               'East
               		get temp2, map_walls2
               		if w_visited2 = 1 Then
                 			w_east = w_west2
               		else
                			w_east = 1
               		End if                        
               		
               		temp2=temp+16             'south
               		get temp2, map_walls2
               		if w_visited2 = 1 Then
                 			w_south = w_north2
               		else
                 			w_south = 1
               		End if
                                                
               		temp2=temp-1                'west
               		get temp2, map_walls2
               		if w_visited2 = 1 Then
               			  w_west = w_east2
               		else
                			 w_west = 1
               		End if
                        put temp,map_walls
            	End If
        	Next
		Return







clear_maze:							'Reset to a blank maze

	setfreq M8
	gosub led_thing
	gosub led_thing
	setfreq cpu_full_speed

        switch on green_led
        switch on yellow_led

        for temp=$01 to $0E                     'clear the top line
                put temp,$20
        Next
        
        for temp=$F2 to $FE                     'clear the bottom line
                put temp,$80
        Next
        
        for b53=$10 to $E0 step $10      		'clear left side
                put b53,$10
                for temp=$01 to $0E
                        b0 = temp + b53 		'clear center maze
                        put b0,$00
                Next
                inc b0
                put b0,$40            		'clear right side
        Next
        
        put $00,$30                   		'clear maze corners
        put $0F,$60
        put $F0,$D4
        put $FF,$C0
        put $F1,$90
        
'put $b5,$40
'put $b6,$10
        
        clear_the_maze = 0
        
        switch off green_led
        switch off yellow_led
        
Return


check_path:'different new gosub

	temp=maze_start-16 	'pos

	get temp,map_walls
	
	do until temp = maze_center or W_VISITED=0
	      b8=map_walls & %00000011
	      lookup B8,(240,1,16,255),b53
	      let temp=temp+b53
	      
	      get temp,map_walls
	loop


return


calc_maze_path: 'different new gosub

	temp=maze_start-16 	'pos
	b54=1 			'last move
	temp2=0			'direc
	ptr=path_start
	
	do  until temp = maze_center
	
		get temp,map_walls
	      map_walls=map_walls & %00000011
	   
	      select case temp2  'convert to wall map bits depending on the direction of the mouse
	              Case 0
	                      lookup map_walls,(1,2,0,3),b8 'mouse facing north
	              Case 1
	                      lookup map_walls,(3,1,2,0),b8 'mouse facing east
	              Case 2
	                      lookup map_walls,(0,3,1,2),b8 'mouse facing south
	              Case 3
	                      lookup map_walls,(2,0,3,1),b8 'mouse facing west
	      endselect
	      
	      let b55=0
	      
	      if 	  b54=3 and b8=3 then let b55=9 
	      else if b54=3 and b8=2 then let b55=10
	      else if b54=3 and b8=1 then let b55=11
	      
	      else if b54=2 and b8=3 then let b55=6
	      else if b54=2 and b8=2 then let b55=5
	      else if b54=2 and b8=1 then let b55=7 
	      
	      else if b54=1 and b8=3 then let b55=8
	      else if b54=1 and b8=2 then let b55=4
	      else if b54=1 and b8=1 then let b55=3 
	      endif
	      
	      
	      b54=b8
		lookup map_walls,(240,1,16,255),b53 '-16,+1,+16,-1
		temp=temp+b53
		temp2=map_walls
		
		@ptrinc=b55
		
	loop
	
	lookup b54,(3,3,7,11),@ptrinc 'setup last move
	
	@ptr=0	'Terminate list with 0
	
	b54=0
	do until ptr<path_start		'set long strates to 2 with 3 on the end		
	
		if @ptr=3 then
			if b54=3 then let @ptr=2 
			else if b54=2 or b54=12 then let @ptr=12
			endif
		endif

		b54=@ptr
		ptr=ptr-1		
	loop

	
	ptr=path_start
	SETFREQ M8
	do until @ptr=0				
		sertxd("ptr=",#ptr," @ptr=",#@ptrinc,13,10)		
	loop
	SETFREQ cpu_full_speed
	

return


List_maze:                  				'list maze to debug window

    setfreq M8

    sertxd(" ",13,10)
    
    For temp = 0 To 240 Step 16
        
        b8 = temp + 15
        
        For temp2 = temp To b8
            get temp2, map_walls
            b53 = temp2 - 16
            get b53, map_walls2
            If w_north = 1 Or w_south2 = 1 Then
                sertxd ("+-")
            Else
                sertxd ("+ ")
            End If
        Next
        
        sertxd("+",13,10)
        
        map_walls2 = 0
        b8 = temp + 15
        
        For temp2 = temp To b8
            get temp2, map_walls
            
            If w_west = 1 Or w_east2 = 1 Then
                sertxd ("|")
            Else
                sertxd (" ")
            End If
            
		if w_done=1 then
	            b53=map_walls & %00000011
      	      lookup b53,("^",">","v","<"),b53
      	else
      		b53=" "
      	endif
      	
            sertxd (b53)
            map_walls2 = map_walls
        Next
        sertxd("|",13,10)
        
    Next
    sertxd("+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+",13,10)
    
    SETFREQ cpu_full_speed

Return


end_of_run:  'different new gosub

	gosub calc_maze_path
		     			pwmduty motor_left,200
					pause 500
					pwmduty motor_left,0	
				'	stop
	run 1					'Do fast run


       
maze_unsolvable:

'gosub save_maze
zzz:
	setfreq m2
	
	gosub led_thing

	
	If button_A=0 then
		gosub list_maze
	endif
'goto zzz	
goto maze_unsolvable


LED_thing:

      switch on yellow_led
	switch on green_led
	pause 1000
'	switch off green_led
'	switch off yellow_led
'	pause 75
'	switch off yellow_led
'	switch on right_red_led
'	pause 50
'	switch off right_red_led
'	switch on middle_green_led
'	pause 75
'	switch off middle_green_led
'	switch on left_red_led
'	pause 100
'	switch off left_red_led
'	switch on middle_green_led
'	pause 75
'	switch off middle_green_led
'	switch on right_red_led
'	pause 50
'	switch off right_red_led
'	switch on yellow_led
'	pause 75
	
	return
 
End


led_thing_2:

'      switch off middle_green_led
'	switch on green_led
'	pause 100
'	switch off left_red_led
'	switch on yellow_led
'	pause 100
'	switch off green_led
'	switch on right_red_led
'	pause 100
'	switch off yellow_led
'	switch on middle_green_led
'	pause 100
'	switch off right_red_led
'	switch on left_red_led
'	pause 100
	
	return



led_thing_3: 'different new gosub

'      switch off middle_green_led
'	switch on green_led
'
'	switch off left_red_led
'	switch on yellow_led
'
'	switch off green_led
'	switch on right_red_led
'
'	switch off yellow_led
'	switch on middle_green_led
'
'	switch off right_red_led
'	switch on left_red_led

	
	return



