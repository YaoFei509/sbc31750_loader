\\
\\                       _oo0oo_
\\                      o8888888o
\\                      88" . "88
\\                      (| -_- |)
\\                      0\  =  /0
\\                    ___/`---'\___
\\                  .' \\|     |\\ '.
\\                 / \\|||  :  |||// \
\\                / _||||| -:- |||||- \
\\               |   | \\\  -  /// |   |
\\               | \_|  ''\---/''  |_/ |
\\               \  .-\__  '-'  ___/-. /
\\             ___'. .'  /--.--\  `. .'___
\\          ."" '<  `.___\_<|>_/___.' >' "".
\\         | | :  `- \`.;`\ _ /`;.`/ - ` : | |
\\         \  \ `_.   \_ __\ /__ _/   .-` /  /
\\     =====`-.____`.___ \_____/___.-`___.-'=====
\\                       `=---='
\\
\\
\\     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
\\
\\               佛祖保佑         永无BUG
\\
\\     SBC31750 单板机简易加载器，接收Intel HEX格式目标码
\\
\\                     姚飞 feiyao@me.com	
\\

	
        \**************** Memory Map on Reset **************************\
        \								\
        \								\
        \       0000--------------------------------------------	\
        \                Reset routine & Function move			\
        \       0020--------------------------------------------	\
        \                      Interupt Vectors				\
        \       0040 - - - - - - - - - - - - - - - - - - - - - -	\
        \                         continued				\
        \       0080--------------------------------------------	\
        \                 Interupt return storage area			\
        \       00b0--------------------------------------------	\
        \								\
        \                      Interrupt routines			\
        \								\
        \       0100--------------------------------------------	\
        \								\
	\		Standard Input and Output routines		\
	\								\
        \       0400--------------------------------------------	\
        \								\
        \                     Main monitor program			\
        \								\
        \       0900--------------------------------------------	\
        \                Reserved for parser heap & stack		\
        \       0b00--------------------------------------------	\
        \                   Stack Area (Top = monstk)			\
        \       0c00--------------------------------------------	\
        \                   Transient function area			\
        \       1000--------------------------------------------	\
        \								\
        \								\
        \                          User RAM				\
        \								\
        \								\
        \       ffff--------------------------------------------	\
        \								\
        \								\
        \***************************************************************\


radix	hex
MA31750

\******************************* Equates table ********************************\

USARTD1 equ     0500
USARTC1 equ     0501
USARTD2 equ     0520
USARTC2 equ     0521
RD      equ     8000			\read offset for xio's
link	equ	0080			\interrupt link area
PStkLo	equ	fa00			\bottom of parser stack
PStkHi	equ	faff			\top of parser stack
PrsHeap	equ	f900
MonStk	equ	fc00			\monitor stack	


\************************ Monitor ROM reset sequence **************************\

org 0000

bit_sav	equ	6000

rom_mov	st	r0,  bit_sav		\save the bit return code
	xorr	r14, r14		\clear r14
	jc	f,   rst_mov		\No offset - we are running from ROM!!	

\****************** Interrupt linkage and service pointers ********************\

org 0020

        data    link+00 0040    	\power down, lp=link, sp=0040
        data    link+03 0043
        data    link+06 0046
        data    link+09 0049
        data    link+0c 004c
        data    link+2d 006d
        data    link+0f 004f
        data    link+12 0052
        data    link+15 0055
        data    link+18 0058
        data    link+1b 005b
        data    link+1e 005e
        data    link+21 0061
        data    link+24 0064
        data    link+27 0067
        data    link+2a 006a


\*************** New service machine status for each interrupt ****************\

org 0040

        data    0000 0000 ipwrd         \mk, sw=0000, ic=start of i\r routine
        data    0000 0000 imcerr
        data    0000 0000 iint02
        data    0000 0000 iflpof
        data    0000 0000 ifxpof
        data    0000 0000 iflpuf
        data    0000 0000 itimea
        data    0000 0000 iint08
        data    0000 0000 itimeb
        data    0000 0000 iint10
        data    0000 0000 iint11
        data    0000 0000 iioi1
        data    0000 0000 iint13
        data    0000 0000 iioi2
        data    0000 0000 iint15
        data    0000 0000               \mk=0, sw=0 for bex instructions
        data    bexr bexr bexr bexr bexr bexr bexr bexr
        data    bexr bexr bexr bexr bexr bexr bexr bexr


\************************** Interupt vectors ***************************\

org 	00b0

ipwrd   lst     link
imcerr  pshm    r12, r12		\system fault has occurred.
        lim     r12, mfault	,r14	\tell the user.
        sjs     r15, tprint	,r14
        rcfr	r12			\read and clear fault.
        popm    r12, r12		\restore damage
	enbl				\re-enable interrupts
        lst     link+03			\(r0 is dummy variable)
iint02  lst     link+06
iflpof  lst     link+09
ifxpof  lst     link+0c
bexr    lst     link+2d			\for all bex instructions
iflpuf  lst     link+0e
itimea  lst     link+12
iint08  lst     link+15
itimeb  lst     link+18
iint10  lst     link+1b
iint11  lst     link+1e
iioi1   lst     link+21
iint13  lst     link+24
iioi2   pshm    r12, r12		\save r12 status
        lim     r12, mintrp	,r14
        sjs     r15, tprint	,r14
        popm    r12, r12
        enbl
        lst     link+27			\return to sender!
iint15  lst     link+2a


org 0100

\*******************************************************************\
\ STDIO - these routines implement standard I/O functions for the   \
\         GSDB board (INCHx, OUTCHx, WORDRDx, WORDWRx .... etc)	    \
\*******************************************************************\

rst_mov	xio	r6,  8410
	andm	r6,  400c
	bez	no_bpu
	mpen
	lim	r6,  0100
bpu_wt	soj	r6,  bpu_wt	,r14
no_bpu	xorr	r6,  r6			\source address=0000
	lr	r4,  r14		\destination addr=offset addr (0000)
	lr	r13,  r14
	lim     r5,  0100		\r5=length of ivet (256 words)
	xio	r0,  esur		\enable start-up-rom ready for move
	mov	r4,  r6			\move the code
	
	xorr	r6,  r6			\move code
	lim 	r4,  f800
	lim 	r5,  0500
	mov	r4,  r6
	lim	r14, f800
	lr	r13, r14
	xio	r0,  dsur		\disable start-up-rom after move
	jc      f,   setup	,r14    \jump to parser setup routines


offset2	equ	0020
current	data	0000			\current address pointer


crlf	pshm    r11, r12		\prints a CR & LF (newline) to port1
	lim	r12, 0a0d		\setup r12 = 0d0a
	br	prt0
chprt2	pshm    r11, r12		\print the 2 chars in r12 to port1
prt2	lim	r11, offset2		\setup r11 to use port 2 
	br	oput
chprt   pshm    r11, r12		\print the 2 chars in r12 to port1
prt0	xorr	r11, r11		\setup r11 to use port 0 
oput	slc	r12, 0008		\rotate ms-byte to ls-byte position
	sjs	r15, Xmt	,r14
	srl	r12, 0008
	sjs	r15, Xmt	,r14
        popm    r11, r12
        urs     r15

atoh    andm	r12, 00ff               \mask off top byte
        cbl	r12, lim09      ,r14    \is it in the range 30 to 39
        bez	ascok                   \yes just convert straight to hex
     	rbr	10,  r12		\otherwise make upper case
	cbl	r12, limaf      ,r14    \now is it in the range 'A' to 'F'
        bnz	badhex                  \no flag an invalid input
        sisp	r12, 0007               \if ok, subtract 37H to get a hex nybble
ascok   sim	r12, 0030
        br	endah                   \return the converted number in r12
badhex  lisn	r12, 0001               \flag bad hex char with ffff
endah   urs	r15                     \return to calling routine

lim09   data	0030 0039               \data for comparison ('0' to '9')
limaf   data	0041 0046               \data for comparison ('A' to 'F')


tprint2	pshm	r10, r12
	lim	r11, offset2		\use usart2
	br	tpr	
tprint  pshm    r10, r12
	xorr	r11, r11		\use usart1
tpr	lr      r10, r12                \put pointer into r10
nxttab  l       r12, 0000	,r10	\load next data from table
        cim     r12, 0100
        blt     endprt                  \if whole wrd <0100H, ie msb=0 then end
        slc     r12, 0008               \move msb to lsb, preserve order
        sjs     r15, Xmt	,r14    \print char to term.
        srl     r12, 0008
        bez     endprt                  \is lsb is zero then end
        sjs     r15, Xmt	,r14    \...otherwise print char to term.
        aisp    r10, 0001               \inc text pointer
        br      nxttab
endprt  popm    r10, r12
        urs     r15

byterd	pshm 	r0,  r1
	sjs	r15, inch2,	r14     \read first char
	sjs	r15, atoh,	r14	\convert to hex
	lr	r0,  r12		\move partial result
	sll	r0,  4			\shift
	sjs	r15, inch2,	r14	\read 2ns char
	sjs	r15, atoh,	r14	\convert to hex
	orr	r12, r0			\combine 
	popm 	r0,  r1
	urs	r15

inch2	pshm	r11, r11
	lim	r11, offset2		\offset for USART2 in r11
	br	in
inch1	pshm	r11, r11
	xorr	r11, r11		\no offset needed for USART1
in	sjs	r15, Rcv	,r14	\input the character
	popm	r11, r11
	urs	r15


outch2	pshm	r11, r12
	lim	r11, offset2		\offset for USART2 in r11
	br	out
outch1  pshm	r11, r12
	xorr	r11, r11		\no offset for USART1
out	sjs	r15, Xmt	,r14	\output the character
	popm	r11, r12
	urs	r15


Xmt	pshm	r10, r12
GetStat	xio	r10, USARTC1+RD	,r11	\read control word from usart
	tbr	13,  r10
	bez	GetStat			\if not ok to transmit then loop
	lim	r10, 0030		\else wait a short time
wt_xmt	soj	r10, wt_xmt	,r14	
	andm	r12, 00ff		\only LSB can be transmitted
	xio	r12, USARTD1	,r11	\write r12 LSB to usart
	popm	r10, r12
	urs	r15


Rcv	xio	r12, USARTC1+RD	,r11	\read control word from usart
	tbr	14,  r12
	bez	Rcv			\if nothing recieved then loop
	xio	r12, USARTD1+RD	,r11	\read from usart into r12 LSB
	andm	r12, 00ff		\only LSB is used by usart
	urs	r15

					\Init two USARTs 8251 
setcom	pshm	r0,  r0
	xorr	r0,  r0
        xio	r0,  USARTC1		\write 3 pass, 8251 so slowly	
        xio	r0,  USARTC2
        xio	r0,  USARTC1
        xio	r0,  USARTC2
        xio	r0,  USARTC1
        xio	r0,  USARTC2            \reset usart's
        sbr	9,   r0			\r0 = 0040
        xio	r0,  USARTC1
        xio	r0,  USARTC2
        lim	r0,  00CE               \  Usart1&2 baudrate = clock \ 16
        xio	r0,  USARTC1            \           2 stop bits
        xio	r0,  USARTC2            \           no parity & 8 bit chars
        lim	r0,  0027               \command instruction:- RTSN low
        xio	r0,  USARTC1            \                      Tx & Rx enable
        xio	r0,  USARTC2            \                      DTRN low
	popm	r0,  r0
        urs	r15


\******************  Start of main parser/control routine  ********************\

org	0200

setup	lim	r15, MonStk	,r14	\setup the stack
	sjs	r15, setcom	,r14

	sjs	r15, crlf	,r14
	sjs	r15, dobann	,r14	\print the banner
main	sjs	r15, dlhex	,r14	
	br	main


dobann  pshm    r10, r12
        lim     r12, ban	,r14	\r11 points to address of banner
	sjs	r15, tprint	,r14
	sjs	r15, crlf	,r14
        popm    r10, r12
	urs	r15


\*************************** Main Title With Graphics *************************\
ban	text	Yao Fei MIL-STD-1750A SBC Console V2.0\n\r
	text	cp *.hex  /dev/ttyS1  \n\r
	text    Wait HEX file on USART2    \0\0


\******************************************************************************\
\*   Yao Fei     Download Intel HEX file 			              *\
\******************************************************************************\
dlhex	pshm	r6,  r12
        xorr	r7,  r7 		\clear the fail flag (r7)
        lim     r12, mloadh 	,r13
        sjs     r15, tprint     ,r14    \print the Loading message

hex_in 	xorr    r8,  r8                 \clear my line checksum
        sjs     r15, inch2      ,r14
        cim     r12, 003a               \':'
        bez     hokread
	
hchkend cisp    r12, 0003               \if input was <ctrl>C then end
        bez     heof
        br      hex_in			\otherwise keep looking

hokread sjs     r15, byterd      ,r14	\get the byte count
	lr	r10, r12		\r10 == byte count
	srl	r10, 1			\r10/2 == word count    
	lr 	r8,  r12		\cs = data + 0
	lisn	r7,  0001		\set fail flag
	sjs	r15, byterd	 ,r14	\read start address, 1st byte
        lr      r11, r12                \r11 == start address . half
	sll	r11, 8			\shift to hi-byte
	ar 	r8,  r12                \cs =cs add start address
	sjs	r15, byterd,	 ,r14
	ar 	r8,  r12                \cs = cs add data
	ar	r11, r12		\r11 == start address

	srl	r11, 1			\byte address to word address

	sjs	r15, byterd	 ,r14	\read data class  , should be 00
	ar 	r8,  r12                \cs = cs add data
	cim  	r12, 0			\should be 0
	bez	nextbt			\00 for data
	cim	r12, 1			\01 for end    :00000001ff
	bnz 	hex_in
	sjs	r15, byterd	 ,r14   \ read last byte
	ar	r8,  r12
	andm	r8, 00ff
	bez	heof
	br	hex_in

nextbt  sjs	r15, byterd	 ,r14
	lr	r9,  r12		\keep in r9
	sll 	r9,  8			\1st byte, shift
	ar 	r8,  r12                \cs = cs add data
	sjs	r15, byterd,	 ,r14
	ar	r8,  r12		\cs = cs add data
	ar 	r12, r9
	st	r12, 0000,	 ,r11   \store it at right address
	aisp	r11, 1			\p++
	soj	r10, nextbt	 ,r13
	sjs	r15, byterd	 ,r14   \read checksum
	ar	r8,  r12
        andm	r8,  00ff
	bnz     hsumerr			\if not equal then ERROR!!
	br      hex_in			\otherwise, carry on

hsumerr lim     r12, mcherr     ,r13
        sjs     r15, tprint     ,r14    \print error mesg
        sjs     r15, crlf       ,r14
        br      exithexld

heof    lim	r12, mipfin	,r13    \pointer to ip finished message
        cisn	r7,  0001               \is the fail flag ffff
	bez	hdo_prn                 \yes, ip was ok

        lim     r12, mipfail    ,r13    \otherwise ip failed
hdo_prn sjs     r15, tprint     ,r14    \print complete mesg
        sjs     r15, crlf       ,r14
	jc	f,  0
	
exithexld popm	r6,  r12
        urs     r15

\*********************  Start of Text message data area  **********************\

even

mabort	text	    ** Aborted ** \r\n
	data	0700
mintrp	text	\r\n   ** Interrupt on IOI2 **\r\n
	data	0700
mfault	text	\n\n\r   ** SYSTEM FAULT !! **    Status word -->
	data	2007 0000
mcherr  text	\r\n\r\n   ** Checksum error! Aborted ** \r\n
	data	0700
mloadh	text	\r\n\r\n   Loading HEX file...\0\0\0\0
mok	text	OK\r\n\0\0
	data	0000 0000
mfile	text	\r\n\r\n   File : \0\0\0
mipfin	text	, Load complete - No errors\r\n\r\n\0\0
mipfail	text	** Load Failed ! ** \r\n\r\n
	data	0700

