


'control program Picaxe 28X2
'© D Hall & J Chidley 2010
 'PICONE TURBO 
 
'used w7 w8 w9 w10 w11 w12 w13 w14 w15 w16 w17(b14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35)
'used	b36 37 40 41 42 43 44 45 47 48 50 7

#slot 1
b7=0
		settimer off
		settimer count 65535
symbol left_wall=44
symbol right_wall=46
symbol front_wall=25
symbol reset_frontwall=88

symbol right_straighten=275
symbol left_straighten=285'280

symbol left_straighten1= left_straighten+20
symbol right_straighten1= right_straighten+20
symbol left_straighten2= left_straighten+30'30'40
symbol right_straighten2= right_straighten+30'30'40
symbol left_straighten3= left_straighten+40'30'40
symbol right_straighten3= right_straighten+40'30'40

'symbol right_straightens=350
'symbol left_straightens=350
'symbol super_left_motor=600
'symbol super_right_motor=616

symbol fast_left_motor=500'600' 	800'700'600'500'           
symbol fast_right_motor=510'621'	828'723'619'510'       

symbol left_motor=305'340' sets left motor speed for straight line max 1023
symbol right_motor=312' 308          '349' sets right motor speed for straight line max 1023

symbol end_wall=640			'front wall trigger in dead end

symbol button_A = pinC.4		'Button A
symbol start_button = pinC.6
symbol middle_green_led = 6
symbol left_red_led = 7
symbol right_red_led = 4
symbol yellow_led = 0			
symbol green_led = 5

symbol sensor_leds = c.5		'IR leds
symbol l_sensor_led = 3		'l IR led
symbol r_sensor_led = 2		'r IR led
symbol motor_right = c.1
symbol motor_left = c.2
symbol relay = 1
symbol left_sensor = w7
symbol front_sensor = w8
symbol right_sensor = w9
symbol wall_config = b43
symbol last_wheel = bit16
symbol path_start=256
symbol cpu_full_speed=em64
symbol move=b13

		'0 gosub stopit
		'1 gosub reset_start
		'8 gosub left_diag
		'4 gosub right_diag
		'10 gosub l_straight_diag
		'6 gosub r_straight_diag
		'9 gosub left_90
		'5 gosub right_90
		'7 gosub r_out_diag
		'11 gosub l_out_diag
		'2 gosub straight_f
		'3 gosub straight_fs
'12 gosub super_fast
'

#no_data
'#no_table

table	0,(3,4,7,2,2,2,2,2,2,2,3,4,7,2,3,4,7,2,2,2,2,2,2,2,3,4,7,2,3,4,7,0)
 'outside run '  table	0,(3,4,7,2,2,2,2,2,2,2,2,2,2,2,2,3,4,7,2,2,2,2,2,2,2,2,2,2,2,2,3,4,7,2,2,2,2,2,2,2,2,2,2,2,2,3,4,7,2,2,2,2,2,2,2,2,2,2,2,2,3,0)

'table	0,(3,3,3,3,3,3,6,6,6,6,3,3,3,3,3,0)
'table	0,()
'table	0,()

'table	0,()
'table	0,()
'table	0,()

'table	0,()
'table	0,()
'table	0,()

'table	0,()
'table	0,()
'table	0,()

'table	0,()
'table	0,()
'table	0,()
'table	0,()

main:
		
		switch off relay				'output to relay
		switch off sensor_leds			'IR leds off
		adcsetup =3
		setfreq cpu_full_speed			'external resinator speed
		pwmout motor_right,255,0		'stop right motor
		pwmout motor_left,255,0			'stop left motor

		ptr=path_start
		if @ptr=0 then gosub load_route_from_table 'if no route load pre set route from table
b45=43
							'mouse start square requires added wheel counts to straight line count
		switch off middle_green_led		'middle green led on
		switch off left_red_led			'left red led on
		switch off right_red_led			'right red led on
		w11=right_motor-90
		
		w13=left_motor
		w15=right_motor	
		goto fast_moves'testing diagonals and fastmove

load_route_from_table:

		b50=0
		ptr=path_start
		do
			readtable b50,@ptr
			b50= b50+1
			SETFREQ M8	
			sertxd("p2 ptr=",#ptr," @ptr=",#@ptr,13,10)		
			SETFREQ cpu_full_speed
		loop until @ptrinc=0
		return	

deadend_straight:
		pwmduty motor_right,right_motor
		pwmduty motor_left,left_motor
		
deadend_loop:					
		switch on sensor_leds				'IR leds on
		readadc10  0,left_sensor				'reads left wall sensor
		readadc10  1,front_sensor				'read front wall sensor
		readadc10 2,right_sensor				'read right wall sensor
		switch off sensor_leds      			'IR leds off
		
		do while last_wheel=pinc.0			'wait for left wheel counter
		loop
		last_wheel=pinc.0		
		b47=b47+ 1
		
		if right_sensor<right_wall then
			b47=b48
		endif
	
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
	
		if wall_config<b44 then return endif			'has wall config changed		
		b44=wall_config		
		if b47=b48 then return endif
		
		if b45=0 then	'mouse is going into dead end use front wall reset
			if front_sensor>front_wall then	'if dead end travel to end wall 
			b47=0
				if front_sensor>end_wall then	return
				endif
			endif	
		endif						
				
		if left_sensor< left_wall then 		'straighten on left wall if available
				if right_sensor< right_wall then deadend_straight	
				if right_sensor< right_straighten then deadsteer_right	
			else
				if left_sensor> left_straighten then deadsteer_right
			endif
		
		pwmduty motor_left,w11		'slower speed for left motor to straighten mouse
		pwmduty motor_right,right_motor
		goto deadend_loop
		
deadsteer_right:
		pwmduty motor_right,w11	'slower speed for right motor to straighten mouse
		pwmduty motor_left,left_motor
		goto deadend_loop	 
			 

'diagonal and fast run moves

fast_moves: 'start here if mouse has decided to go into fast run mode				
reset_start:	'start here if mouse has been restarted and fast route is known				
pause 500
		
b48=49'58
		b47= 0
		timer = 0
		move=3
		w10=0
	'	b45=0	
		wall_config= 0
		pwmduty motor_right,right_motor
		pause 40
		pwmduty motor_left,left_motor
	
'gosub steer_straight
'b48=7
		'timer = 0
		move=3
		'w10=0
		'b45=0	
		b44=0
		'wall_config= 0
		gosub steer_straight
		ptr=path_start
		do until @ptr=6000						
			on @ptrinc gosub stopit,reset_start,straight_f,straight_fs,right_diag,right_90,r_straight_diag,r_out_diag,left_diag,left_90,l_straight_diag,l_out_diag
		loop
	
stopit: '0
			'b48=140
			'gosub	steer_straight
			'pwmduty motor_right,0
			'pwmduty motor_left,0
			
		run 0
			
left_diag: '8 	B 1,3,7,11   A 9,10,11
	
'pwmduty motor_right,0
'pwmduty motor_left,0	
'stop
	
	
	
		move=8	
		pwmduty motor_right,right_motor
		'pwmduty motor_left,left_motor
	
		'	timer=0
		'	do
		'		b47=timer 	
		'	loop until b47>=2
		
		
		
			
		pwmduty motor_left,0
		b48=35'34'33'29'28'  37       30'31'32'33'34'26'31'       48'49'32'35'37'38'
		b47=0		
		do
			last_wheel=pinc.3			
			do while last_wheel=pinc.3		'wait for right wheel counter to change
			loop
			b47=b47+ 1	
		loop until b47=b48			
		pwmduty motor_left,left_motor
		b44=0
		b47=0		
l_travel:	switch on sensor_leds			'IR leds on
		readadc10  0,left_sensor			'read left wall sensor
		switch off sensor_leds			'IR leds off
		left_sensor=left_sensor min 50
		if left_sensor < b44 or left_sensor=50 then	
			b48=43'45      '12'15'45
			b47=0
			do
				last_wheel=pinc.3			
				do while last_wheel=pinc.3		'wait for right wheel counter to change
				loop
				b47=b47+ 1	
			loop until b47=b48
			

			return		
		endif
		b44=left_sensor
		goto l_travel
		
right_diag: '4	B 1,3,7,11  A 5,6,7
	
	
	
	
	
	
		move=4				
	'	pwmduty motor_right,right_motor
		pwmduty motor_left,left_motor
	
	'		timer=0
	'		do
	'			b47=timer 	
	'		loop until b47>=1'2
		
		pwmduty motor_right,0
		b48=34'30'        31'31'30'     35        30'31'52'31
		timer=0
		do
			b47=timer 	
		loop until b47>=b48
		
		pwmduty motor_right,right_motor
		b44=0		
r_travel:	switch on sensor_leds			'IR leds on
		readadc10  2,right_sensor			'read right wall sensor
		switch off sensor_leds			'IR leds off
		right_sensor=right_sensor min 50	 
		if right_sensor<b44 or right_sensor=50 then					
			b48=43'54'58'56'             46'43'34'45'34
			timer=0
			do
				b47=timer 	
			loop until b47>=b48 
			
			return
		endif
		b44=right_sensor
		goto r_travel
		
		
		
		
		
		
		
		
				
l_straight_diag:'10 	B 6,8,9,	A 5,6,7

		move=10
		
		switch on sensor_leds
		readadc10 2,right_sensor
		switch off sensor_leds
		
		b48=0
		do
			last_wheel=pinc.3
			do while last_wheel=pinc.3		'wait for right wheel counter to change		
			loop
			b48=b48+1	
		loop until b48>=2'3'5

'-------------
		pwmduty motor_right,417'422'412'+100
		pwmduty motor_left,left_motor
		b48=0
		do
			last_wheel=pinc.3
			do while last_wheel=pinc.3		'wait for right wheel counter to change		
			loop
			b48=b48+1	
		loop until b48>=3'4'  6'10

'--------------		
		
		b48=0
		switch on r_sensor_led		
		readadc10  1,front_sensor		'read front wall sensor
		switch off r_sensor_led			'IR leds off
		
		if right_sensor>50 then 'wall present leading up to end post	
			front_sensor=front_sensor/2
		endif	
			
			
			if front_sensor>40 then '52    80'110'35 45
				pwmduty motor_left,70'75'50						
				switch on right_red_led
				do
					last_wheel=pinc.0
					do while last_wheel=pinc.0		'wait for left wheel counter to change		
					loop
					b48=b48+1	
				loop until b48>12	
				b48=0
				pwmduty motor_left,left_motor
							
				do
					last_wheel=pinc.0
					do while last_wheel=pinc.0		'wait for left wheel counter to change		
					loop
					b48=b48+1	
				loop until b48>6'2	
				b48=0
				pwmduty motor_right,20'50						
				do
					last_wheel=pinc.3
					do while last_wheel=pinc.3		'wait for right wheel counter to change		
					loop
					b48=b48+1	
				loop until b48>18'15'14'15

				pwmduty motor_right,right_motor
				pwmduty motor_left,left_motor
				b48=32'20'18
			endif
		
			do	
				last_wheel=pinc.0
					do while last_wheel=pinc.0		'wait for left wheel counter to change		
					loop
				b48=b48+1	
			
				if b48>18 then
					pwmduty motor_left,505
					pwmduty motor_right,right_motor			
				endif	
			
			loop until b48>32'20				
'------------------------------			
		pwmduty motor_left,left_motor	
	
		b47=0
		b48=0
		w11=20
		if right_sensor>50 then 'wall present leading up to end post	 	
		 	b47=1	
		endif
	
		do
			switch on sensor_leds
			readadc10 2,right_sensor
			switch off sensor_leds
			right_sensor=right_sensor min 20
			if right_sensor<w11 then
				b48=25'20'18'22'25'30'28 40			
			endif	
			
			if b47=1 then
				if right_sensor=20 then
					b48=25
				endif
			endif	
				
			w11=right_sensor	
			last_wheel=pinc.3
				do while last_wheel=pinc.3		'wait for right wheel counter to change		
				loop
			b48=b48+1	
		loop until b48>25
		b48=0
		do
			last_wheel=pinc.3
				do while last_wheel=pinc.3		'wait for right wheel counter to change		
				loop
			b48=b48+1	
		loop until b48=23'22
		
		return		
	
		
		
		
r_straight_diag:	'6	B 4,5,10	A 9,10,11



	'	pwmduty motor_right,right_motor
	'	endif
		move=6
		
		switch on sensor_leds
		readadc10 0,left_sensor
		switch off sensor_leds
		
		b48=0
		do
			last_wheel=pinc.0
			do while last_wheel=pinc.0		'wait for left wheel counter to change		
			loop
			b48=b48+1	
		loop until b48>=2'3'5

'-------------
		pwmduty motor_right,right_motor
		pwmduty motor_left,395'390
		b48=0
		do
			last_wheel=pinc.0
			do while last_wheel=pinc.0		'wait for left wheel counter to change		
			loop
			b48=b48+1	
		loop until b48>=3'4'6'   10
'pwmduty motor_right,0
'pwmduty motor_left,0	
'stop	
'--------------		
		
		b48=0
		switch on l_sensor_led		
		readadc10  1,front_sensor		'read front wall sensor
		switch off l_sensor_led			'IR leds off
			
if left_sensor>50 then '50'wall present leading up to end post	
	front_sensor=front_sensor/2
endif				
		
			if front_sensor>40 then ' 45     55'               60        80'110'35 45
				pwmduty motor_right,70'75'50						
				switch on left_red_led
				do
					last_wheel=pinc.3
					do while last_wheel=pinc.3		'wait for right wheel counter to change		
					loop
					b48=b48+1	
				loop until b48>12	
				b48=0
				pwmduty motor_right,right_motor
								
				do
					last_wheel=pinc.3
					do while last_wheel=pinc.3		'wait for right wheel counter to change		
					loop
					b48=b48+1	
				loop until b48>6'3	
				
				b48=0					
				pwmduty motor_left,45'60						
				do
					last_wheel=pinc.0
					do while last_wheel=pinc.0		'wait for left wheel counter to change		
					loop
					b48=b48+1	
				loop until b48>18'14'13'          14'15
				pwmduty motor_left,left_motor
				pwmduty motor_right,right_motor
				b48=32'30'25'20'18
			endif
		do	
			last_wheel=pinc.3
			do while last_wheel=pinc.3		'wait for right wheel counter to change		
			loop
			b48=b48+1
			if b48>18 then
				pwmduty motor_right,505'-------------------------------------------
				pwmduty motor_left,left_motor
			endif
			
			
			
			
				
		loop until b48>32'30'25'20				
			
			
'pause 8000		
'pwmduty motor_right,0
			pwmduty motor_right,right_motor	
'stop	

		b47=0
		b48=0
		w11=20
		if left_sensor>50 then 'wall present leading up to end post
		 	b47=1	
		endif
		
		do
			switch on sensor_leds
			readadc10 0,left_sensor
			switch off sensor_leds
			left_sensor=left_sensor min 18'20
			if left_sensor<w11 then
				b48=25           '20'18'22'25'30'28 40			
			endif					
			
			if b47=1 then
				if left_sensor=20 then
					b48=25
				endif
			endif
			
			
			
			
			w11=left_sensor	
			last_wheel=pinc.0
				do while last_wheel=pinc.0		'wait for left wheel counter to change		
				loop
			b48=b48+1	
		loop until b48>25
		b48=0
		do
			last_wheel=pinc.0
				do while last_wheel=pinc.0		'wait for left wheel counter to change		
				loop
			b48=b48+1	
		loop until b48=23'28               '25'23'22


'pwmduty motor_right,0
'pwmduty motor_left,0	
'stop			
return		
		
		
left_90:	'9	B 8,6		A 10,11


			
		b47=0		
		pwmduty motor_right,right_motor
		pwmduty motor_left,0
		'if move=11 then
		'	b48=70
		'else
		
		
		b48= 77'76'78'76'75'74'73'74'75'77
		'endif
		 move=9          	
		do
			last_wheel=pinc.3
			do while last_wheel=pinc.3		'wait for right wheel counter to change		
			loop
			b47=b47+ 1
		loop until b47=b48
		pwmduty motor_left,left_motor
		b48=45'44'               37
		b47=0
		do
			last_wheel=pinc.3
			do while last_wheel=pinc.3		'wait for left wheel counter to change		
			loop
			b47=b47+ 1
		loop until b47=b48

			return
		
		
right_90:	'5	B 4,10 	A 6,7



		move=5
		pwmduty motor_left,left_motor
		pwmduty motor_right,0
		b48=76'73'71'70'71'70              '71
		timer=0
		do
			b47=timer 	
		loop until b47>=b48
		pwmduty motor_right,right_motor
		b48=44'42'37
		timer=0
		do
			b47=timer 	
		loop until b47>=b48
		
'pause 4000		
		
'pwmduty motor_left,0	
'pwmduty motor_right,0



		return
		
		
r_out_diag: '7	B 5,4,10	A 1,2,3,4,8
		pwmduty motor_left,left_motor				
		pwmduty motor_right,right_motor
			
		b48=13'12                    '9'                 10'12'2'7'13'12
		timer=0
		do
				switch on sensor_leds
				readadc10  1,front_sensor				'read front wall sensor
				switch off sensor_leds		
				if front_sensor >35 then	'25		'1420 26 then
					switch on yellow_led
					b47=b48
				else
					b47=timer
				endif
		loop until b47>=b48
		pwmduty motor_right,0
		
		b48=33'32'32    35
'		if move=10 then
'			b48=31'31'34
'		endif	
		if move=5 then
			b48=32'31'30
		
		endif
		
			
		move=7
		timer=0
		do
			b47=timer 	
		loop until b47>=b48
			'b48=110	
		timer =0
		'b45=0
		b44=0
		'wall_config= 0
		w13=left_motor
		w15=right_motor

		
		if @ptr=0 then
			b48=40	'straight line count last move
		else
			b48=120	'straight line count normal
		endif



		gosub steer_straight		

		return
	
l_out_diag: '11	B 6,8,9	A 1,2,3,4,8
		
		pwmduty motor_right,right_motor	
		pwmduty motor_left,left_motor		
		b48=11'10'12'        9'10'8'10            '12            '2   7'11
		timer=0
		do
				switch on sensor_leds
				readadc10  1,front_sensor	'read front wall sensor
				switch off sensor_leds		
				if front_sensor >25 then	
					switch on yellow_led
					b47=b48
				else
					b47=timer
				endif
		loop until b47>=b48
		pwmduty motor_left,0
		
		b48=35'34      '37
	'	if move=6 then
	'		b48=34'40
	'	endif	
	'	if move=9 then
	'		b48=35'40'36'34
	'	endif
		move=11
		
		
		
		
		b47=0
		do
			last_wheel=pinc.3
			do while last_wheel=pinc.3	'wait for left wheel counter to change		
			loop
		b47=b47+ 1	
		loop until b47>=b48
		

		
			'b48=110
		timer =0
		'b45=0
		b44=0
		'wall_config= 0
		w13=left_motor
		w15=right_motor
		
		if @ptr=0 then
			b48=40	'straight line count last move
		else
			b48=120	'straight line count normal
		endif
		
		'b48=120	

		
		
		
		gosub steer_straight


		return
		
		
straight_fs: '3

'pause 4000
		move=20
		b48=35'45 '35                55
		timer = 0
		'b45=0			
		b44=0
		'wall_config= 0				
		gosub steer_straight
		
		move=3		
		if @ptr=0 then
			b48=10           '10	'straight line count last move
		else
			b48=75'65'75            90           '70	'straight line count normal
		endif
		timer =0
		'b45=0
		b44=0
		'wall_config= 0
		w13=left_motor
		w15=right_motor			
		gosub steer_straight
		return
		
		
straight_f:	'2
		move=2
	
		b48=111'114 115
		timer = 0
		'b45=0
		b44=0	
		'wall_config= 0			
		gosub steer_straight
		return
		
'super_fast: '12
'		move=12
'		b48=113
'		timer=0
'		b44=0
'		gosub steer_straight
'		return

steer_straight:		'straightening with only posts available
w16=0
w10=0
		pwmduty motor_left,w13
		pwmduty motor_right,w15
		
			if wall_config=0 then
				if front_sensor<20 then						
					switch on l_sensor_led	
					readadc10 1,front_sensor
					switch off l_sensor_led
'					
					if front_sensor >25 then
						w11=w15-200	min 200	
						pwmduty motor_right,w11
					endif
'			
					switch on r_sensor_led
					readadc10 1,front_sensor
					switch off r_sensor_led
'								
					if front_sensor >20 then
						w11=w13-200 min 200
						pwmduty motor_left,w11			
					endif
				endif
			endif
								
forward_loop:
			switch off green_led		
		switch on sensor_leds			'IR leds on
		readadc10  0,left_sensor 'read left wall sensor
		readadc10  2,right_sensor			'read right wall sensor
		readadc10  1,front_sensor	
		switch off sensor_leds			'IR leds off	
		
			if left_sensor> left_wall then
				wall_config= 1			'wall config value for current cell
			else
				wall_config= 0			'wall config value for current cell
			endif
		
			if right_sensor> right_wall then
				wall_config=wall_config+ 2	'wall config value for current cell
			endif		
		
		if move=2 then  'fast speeds
	
			if w13<fast_left_motor then
				w13=w13+3 max fast_left_motor'5'     10'14
			endif	
			if w15<fast_right_motor then
				w15=w15+3 max fast_right_motor'5'     10'14	
			endif	
			if w13>fast_left_motor then
				w13=w13-20 min fast_left_motor'5'     10'14
			endif	
			if w15>fast_right_motor then
				w15=w15-20 min fast_right_motor'5'     10'14	
			endif				
			
		else 'slow speeds			
			if w15<>right_motor then
				w15=w15-40 min right_motor			
			endif
			
			if w13<>left_motor then
				w13=w13-40 min left_motor			
			endif		
		endif	
		
'		if move=12 then 'super fast 
'			if w15<>super_right_motor then
'				w15=w15+3 max super_right_motor			
'			endif
'			if w13<>super_left_motor then
'				w13=w13+3 max super_left_motor			
'			endif	
'		endif
		
		pwmduty motor_right,w15
		pwmduty motor_left,w13
		
		b45=timer	
			if wall_config<b44 then	'wall config has changed
				if move < 20 then
					if move=7 or move=11 then	
						if b45>39 then
							b45=b48
						endif
					else
						if b45>10 then
							b45=b48
						endif
					endif
				endif
			endif	
		if b45>=b48 then	'end move	
			pwmduty motor_right,right_motor
			pwmduty motor_left,left_motor
			return	
		endif		
		b44=wall_config		

'straightening routines
			if move <>3 and b45 < 100 then
				switch on green_led
			endif

		if left_sensor< left_wall then 		'straighten on left wall if available
			if right_sensor< right_wall then steer_straight		'straighten on right wall if available
			if right_sensor< right_straighten then steer_right		
		else
			if left_sensor> left_straighten then steer_right
		endif
		
		
steer_left:		
		if right_sensor<w16 then
			w11=w13+30'11'5
		else
			w11=w13
		endif
			w11=w11-30'40'11
			
		if right_sensor>right_straighten1 then
			if move <>3 and b45 < 100 then
				switch on green_led
				w11=w11+60'11			
				if right_sensor>right_straighten2 then	'medium correcton
					w11=w11-30'20'15'10            '40
					if right_sensor>right_straighten3 then	'medium correcton
						w11=w11-40'5'20 15'10            '40			
					endif			
				endif
			endif		
		endif
		pwmduty motor_left,w11	'power to motors
		pwmduty motor_right,w15	
		w16=right_sensor	
		goto forward_loop


steer_right:		
		if left_sensor<w10 then
			w11=w15+30'11'15
		else
			w11=w15
		endif
			w11=w11-30'40'11
	
		if left_sensor>left_straighten1 then	'medium correction
			if move <>3 and b45 < 100 then
				switch on green_led
				w11=w11+60'40 11
				if left_sensor>left_straighten2 then	'hight correction
					w11=w11-30'20'15'15'10'40
					if left_sensor>left_straighten3 then	'hight correction
						w11=w11-40'5'20'15'10'40
					endif	
				endif	
			endif	
		endif	
				
		pwmduty motor_right,w11	'power to motors
		pwmduty motor_left,w13
		w10=left_sensor				
		goto forward_loop





















