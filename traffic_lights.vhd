--Sistem Lampu Lalu Lintas
--
--Kelompok A2 Perancangan Sistem Digital
--Anggota:
--* Haidar Hanif					1806148694
--* Josef Eric						1806148725
--* Muhammad Miftah Faridh		1806148782
--* Jidan Dhirayoga Gumbira	1806200116

LIBRARY IEEE;
--Library yang digunakan untuk menggunakan input, output, dan sinyal logika
--digital beserta fungsi-fungsi yang terkait
USE IEEE.STD_LOGIC_1164.ALL;
--Library yang digunakan untuk dapat melakukan operasi file pada sistem, yang
--akan digunakan untuk menyimpan log dari sistem
USE STD.TEXTIO.ALL;

ENTITY TRAFFIC_LIGHTS IS
	PORT(
		--Input clock dari sistem
		CLOCK		: IN STD_LOGIC := '0';
		
		--Input tombol yang digunakan untuk menunda sementara sistem dan membuat
		--lampu lalu lintas pada setiap jalan menjadi merah, agar pejalan kaki
		--dapat menyeberang
		BUTTON	: IN STD_LOGIC	:= '0';
		
		--Output yang digunakan untuk mengatur lampu yang menyala dari setiap
		--lampu lalu lintas pada setiap jalan, dengan urutan: merah, kuning, dan
		--hijau (contoh: jika TL_A = 001, maka lampu yang menyala adalah hijau),
		--dan dengan pembagian seperti berikut:
		--
		--         A
		--
		--         |
		--         |
		--         |
		-- C –––––– –––––– D
		--         |
		--         |
		--         |
		--
		--         B
		--
		TL_A		: OUT STD_LOGIC_VECTOR(0 TO 2);
		TL_B		: OUT STD_LOGIC_VECTOR(0 TO 2);
		TL_C		: OUT STD_LOGIC_VECTOR(0 TO 2);
		TL_D		: OUT STD_LOGIC_VECTOR(0 TO 2)
	);
END ENTITY TRAFFIC_LIGHTS;

ARCHITECTURE BEHAVIOR OF TRAFFIC_LIGHTS IS
	--Data yang akan digunakan untuk memanggil file logs.txt, yang akan digunakan
	--untuk menyimpan log dari sistem
	FILE LOGS			: TEXT;
	
	--Lima state yang akan digunakan untuk menentukan keadaan dari sistem, dengan
	--keterangan:
	--* CD_RED		: Keadaan ketika lampu lalu lintas pada jalan A dan B = hijau
	--					  dan lampu lalu lintas pada jalan C dan D = merah. State ini
	--					  berjalan selama 60 step
	--* CD_YELLOW	: Keadaan ketika lampu lalu lintas pada jalan A dan B = hijau
	--					  dan lampu lalu lintas pada jalan C dan D = kuning. State ini
	--					  berjalan selama 5 step
	--* AB_RED		: Keadaan ketika lampu lalu lintas pada jalan A dan B = merah
	--					  dan lampu lalu lintas pada jalan A dan B = hijau. State ini
	--					  berjalan selama 60 step
	--* AB_YELLOW	: Keadaan ketika lampu lalu lintas pada jalan A dan B = kuning
	--					  dan lampu lalu lintas pada jalan A dan B = hijau. State ini
	--					  berjalan selama 5 step
	--* CROSS		: Keadaan ketika lampu lalu lintas pada setiap jalan = merah,
	--					  agar pejalan kaki dapat menyeberang. State ini berjalan
	--					  selama 15 step
	TYPE STATE_TYPE IS (CD_RED, CD_YELLOW, AB_RED, AB_YELLOW, CROSS);
	
	--Sinyal yang digunakan untuk menentukan state yang berjalan pada saat ini
	--dan yang berjalan sebelumnya
	SIGNAL STATE		: STATE_TYPE					:= CD_RED;
	SIGNAL PREV_STATE	: STATE_TYPE					:= CD_RED;
	
	--Sinyal yang digunakan untuk memberikan lokasi dari file logs.txt
	SIGNAL FILE_LOGS	: STRING(1 TO 33)				:= "C:\Users\Jidan\Downloads\logs.txt";
	
	--Sinyal yang akan naik menjadi 1 ketika tombol pada perempatan ditekan, agar
	--pejalan kaki dapat menyeberang
	SIGNAL HALT			: STD_LOGIC						:= '0';
	
	--Sinyal yang digunakan untuk menentukan lama jalannya setiap state pada
	--sistem, yang dipisah untuk 4 state utama dan untuk state khusus ketika ada
	--penyeberang
	SIGNAL TIMER_TL	: INTEGER						:= 0;
	SIGNAL TIMER_X		: INTEGER						:= 0;
	
	--Sinyal yang digunakan untuk menentukan lampu yang menyala dari setiap lampu
	--lalu lintas, dengan urutan: merah, kuning, dan hijau untuk lampu lalu
	--lintas A-B dan merah, kuning, dan hijau untuk lampu lalu lintas C-D
	SIGNAL TL_ALL		: STD_LOGIC_VECTOR(0 TO 5)	:= "001100";
BEGIN
	--Process yang menentukan lampu yang menyala dari setiap lampu lalu lintas,
	--sesuai dengan state-nya
	TL_STATE: PROCESS(STATE)
	BEGIN
		--Case yang menentukan lampu yang menyala dari setiap lampu lalu lintas,
		--sesuai dengan state-nya
		CASE STATE IS
			WHEN CD_RED		=> TL_ALL <= "001100";
			WHEN CD_YELLOW	=> TL_ALL <= "001010";
			WHEN AB_RED		=> TL_ALL <= "100001";
			WHEN AB_YELLOW	=> TL_ALL <= "010001";
			WHEN CROSS		=> TL_ALL <= "100100";
		END CASE;
	END PROCESS TL_STATE;
	
	--Process yang menentukan alur state dari sistem, sesuai dengan waktu masing-
	--masing state dan apakah tombol penyeberangan ditekan atau tidak. Process
	--ini juga menentukan pembagian lampu yang menyala dari sinyal TL_ALL ke
	--semua lampu lalu lintas
	TL_PROCESS: PROCESS(CLOCK)
		--Variabel-variabel ini digunakan untuk mencatat log dari sistem ke file
		--log
		VARIABLE TITLE			: STRING(1 TO 21)	:= "Traffic Lights Report";
		VARIABLE HEADER		: STRING(1 TO 44)	:= "Time  Street A  Street B  Street C  Street D";
		
		VARIABLE STATUS		: STRING(1 TO 38)	:= "  GREEN     GREEN     RED       RED   ";
		VARIABLE STATUS_PREV	: STRING(1 TO 38)	:= "  GREEN     GREEN     RED       RED   ";
		
		VARIABLE STATUS_A		: STRING(1 TO 38)	:= "  GREEN     GREEN     RED       RED   ";
		VARIABLE STATUS_B		: STRING(1 TO 38)	:= "  GREEN     GREEN     YELLOW    YELLOW";
		VARIABLE STATUS_C		: STRING(1 TO 38)	:= "  RED       RED       GREEN     GREEN ";
		VARIABLE STATUS_D		: STRING(1 TO 38)	:= "  YELLOW    YELLOW    GREEN     GREEN ";
		VARIABLE STATUS_E		: STRING(1 TO 38)	:= "  RED       RED       RED       RED   ";
		
		--Variabel ini digunakan untuk mencatat berapa banyak entri pada log dari
		--sistem
		VARIABLE COUNT			: INTEGER := 1;
		
		--Variabel ini digunakan sebagai tempat penyimpanan sementara string yang
		--akan dimasukkan ke file log
		VARIABLE ROW			: LINE;
	BEGIN
		--If conditional yang menandakan bahwa setiap statement pada if
		--conditional hanya akan berlaku ketika clock naik dari 0 ke 1
		IF(RISING_EDGE(CLOCK)) THEN
			--Case yang menentukan alur state dari sistem berdasarkan apakah tombol
			--penyeberangan ditekan atau tidak
			CASE HALT IS
				WHEN '0' =>
					--Case yang menentukan alur state dari sistem ketika tombol
					--penyeberangan tidak ditekan
					CASE TIMER_TL IS
						--Bagian ini menentukan state awal dari sistem, yaitu state
						--CD_RED
						WHEN 0 =>
							PREV_STATE	<= STATE;
							STATE			<= CD_RED;
							TIMER_TL		<= TIMER_TL + 1;
							STATUS		:= STATUS_A;
							IF(COUNT = 1) THEN
								FILE_OPEN(LOGS, FILE_LOGS, WRITE_MODE);
								WRITE(ROW, TITLE);
								WRITELINE(LOGS, ROW);
								WRITELINE(LOGS, ROW);
								WRITE(ROW, HEADER);
								WRITELINE(LOGS, ROW);
							END IF;
							
						--Bagian ini menentukan perpindahan state sistem dari state
						--CD_RED, yang sudah berjalan selama 60 step, ke state
						--CD_YELLOW
						WHEN 60 =>
							PREV_STATE	<= STATE;
							STATE			<= CD_YELLOW;
							TIMER_TL		<= TIMER_TL + 1;
							STATUS		:= STATUS_B;
							
						--Bagian ini menentukan perpindahan state sistem dari state
						--CD_YELLOW, yang sudah berjalan selama 5 step, ke state
						--AB_RED
						WHEN 65 =>
							PREV_STATE	<= STATE;
							STATE			<= AB_RED;
							TIMER_TL		<= TIMER_TL + 1;
							STATUS		:= STATUS_C;
							
						--Bagian ini menentukan perpindahan state sistem dari state
						--AB_RED, yang sudah berjalan selama 60 step, ke state
						--AB_YELLOW
						WHEN 125 =>
							PREV_STATE	<= STATE;
							STATE			<= AB_YELLOW;
							TIMER_TL		<= TIMER_TL + 1;
							STATUS		:= STATUS_D;
							
						--Bagian ini menentukan perpindahan state sistem dari state
						--AB_YELLOW, yang sudah berjalan selama 5 step, ke state
						--CD_RED, dengan me-reset TIMER_TL
						WHEN 130 =>
							PREV_STATE	<= STATE;
							STATE			<= CD_RED;
							TIMER_TL		<= 1;
							STATUS		:= STATUS_A;
							
						--Bagian ini bertanggung jawab dalam melakukan increment pada
						--TIMER_TL, yang akan mempengaruhi alur state dari sistem
						--ketika tombol penyeberangan tidak ditekan
						WHEN OTHERS =>
							TIMER_TL		<= TIMER_TL + 1;
					END CASE;
				
				WHEN '1' =>
					--Case yang menentukan alur state dari sistem ketika tombol
					--penyeberangan ditekan
					CASE TIMER_X IS
						--Bagian ini menentukan state dari sistem ketika tombol
						--penyeberangan ditekan, yaitu state CROSS
						WHEN 0 =>
							PREV_STATE	<= STATE;
							STATE			<= CROSS;
							TIMER_X		<= TIMER_X + 1;
							STATUS_PREV	:= STATUS;
							STATUS		:= STATUS_E;
							
						--Bagian ini menentukan perpindahan state sistem dari state
						--CROSS, yang sudah berjalan selama 15 step, ke state
						--sebelumnya
						WHEN 15 =>
							IF(TIMER_TL = 60) THEN
								STATE		<= CD_YELLOW;
								STATUS 	:= STATUS_B;
							ELSIF(TIMER_TL = 65) THEN
								STATE		<= AB_RED;
								STATUS 	:= STATUS_C;
							ELSIF(TIMER_TL = 125) THEN
								STATE		<= AB_YELLOW;
								STATUS 	:= STATUS_D;
							ELSIF(TIMER_TL = 130) THEN
								STATE		<= CD_RED;
								STATUS 	:= STATUS_A;
							ELSE
								STATE		<= PREV_STATE;
								STATUS	:= STATUS_PREV;
							END IF;
							HALT			<= '0';
							TIMER_X		<= 0;
							TIMER_TL		<= TIMER_TL + 1;
							
						--Bagian ini bertanggung jawab dalam melakukan increment pada
						--TIMER_X, yang akan mempengaruhi alur state dari sistem
						--ketika tombol penyeberangan ditekan
						WHEN OTHERS =>
							TIMER_X		<= TIMER_X + 1;
					END CASE;
				
				WHEN OTHERS =>
					STATE <= STATE;
			END CASE;
			
			--If conditional yang akan menaikkan sinyal HALT menjadi 1 ketika
			--tombol penyeberangan ditekan
			IF(BUTTON = '1') THEN HALT <= '1';
			END IF;
			
			--Bagian ini akan memasukkan status dari sistem pada saat itu ke file
			--log
			WRITE(ROW, COUNT, RIGHT, 4);
			WRITE(ROW, STATUS);
			WRITELINE(LOGS, ROW);
			
			--Bagian ini akan mencatat berapa banyak entri pada log dari sistem
			COUNT	:= COUNT + 1;
			
			--Bagian yang bertanggung jawab dalam  menentukan pembagian lampu yang
			--menyala dari sinyal TL_ALL ke semua lampu lalu lintas
			TL_A	<= TL_ALL(0 TO 2);
			TL_B	<= TL_ALL(0 TO 2);
			TL_C	<= TL_ALL(3 TO 5);
			TL_D	<= TL_ALL(3 TO 5);
		END IF;
	END PROCESS TL_PROCESS;
END ARCHITECTURE BEHAVIOR;
