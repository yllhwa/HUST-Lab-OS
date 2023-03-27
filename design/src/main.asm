%include	"pm.inc"
%include    "macro.inc"

PageDirBase0	equ	200000h	; 页目录 0 开始地址:	2M
PageTblBase0	equ	201000h	; 页表 0 开始地址:		2M +  4K
PageDirBase1	equ	210000h	; 页目录 1 开始地址:	2M + 64K
PageTblBase1	equ	211000h	; 页表 1 开始地址:		2M + 64K + 4K
PageDirBase2    equ 220000h ; 页目录 2 开始地址:	2M + 128K
PageTblBase2    equ 221000h ; 页表 2 开始地址:		2M + 128K + 4K
PageDirBase3    equ 230000h ; 页目录 3 开始地址:	2M + 192K
PageTblBase3    equ 231000h ; 页表 3 开始地址:		2M + 192K + 4K

org	0100h
	jmp	LABEL_BEGIN

; IDT
[SECTION .idt]
ALIGN	32
[BITS	32]
LABEL_IDT:
; 门                          目标选择子,            偏移, DCount, 属性
%rep 32
				Gate	SelectorCode32, SpuriousHandler,      0, DA_386IGate
%endrep
.020h:			Gate	SelectorCode32,    ClockHandler,      0, DA_386IGate
%rep 95
				Gate	SelectorCode32, SpuriousHandler,      0, DA_386IGate
%endrep
.080h:			Gate	SelectorCode32,  UserIntHandler,      0, DA_386IGate

IdtLen		equ	$ - LABEL_IDT	; IDT 长度
IdtPtr		dw	IdtLen - 1		; IDT 段界限
			dd	0				; IDT 基地址, 待设置
; END of [SECTION .idt]

; GDT
[SECTION .gdt]
;                                  段基址,            段界限,  属性
LABEL_GDT:			Descriptor	       0,                 0, 0								; 空描述符
LABEL_DESC_NORMAL:	Descriptor	       0,            0ffffh, DA_DRW							; Normal 描述符
LABEL_DESC_FLAT_C:	Descriptor         0,           0fffffh, DA_CR | DA_32 | DA_LIMIT_4K	; 0 ~ 4G
LABEL_DESC_FLAT_RW:	Descriptor         0,           0fffffh, DA_DRW | DA_LIMIT_4K			; 0 ~ 4G
LABEL_DESC_CODE32:	Descriptor	       0,  SegCode32Len - 1, DA_CR | DA_32					; 非一致代码段, 32 位, 基址待设置
LABEL_DESC_CODE16:	Descriptor	       0,            0ffffh, DA_C							; 非一致代码段, 16 位, 基址待设置
LABEL_DESC_DATA:	Descriptor	       0,		DataLen - 1, DA_DRW							; 数据段, 基址待设置
LABEL_DESC_STACK:	Descriptor	       0,        TopOfStack, DA_DRWA | DA_32				; 堆栈段, 32 位, 基址待设置
LABEL_DESC_VIDEO:	Descriptor	 0B8000h,            0ffffh, DA_DRW + DA_DPL3							; 显存首地址

LABEL_DESC_LDT0:	Descriptor	       0,       LDTLen0 - 1, DA_LDT							; LDT0, 基址待设置
LABEL_DESC_TSS0:	Descriptor	       0,       TSSLen0 - 1, DA_386TSS						; TSS0, 基址待设置
LABEL_DESC_LDT1:	Descriptor	       0,       LDTLen1 - 1, DA_LDT							; LDT1, 基址待设置
LABEL_DESC_TSS1:	Descriptor	       0,       TSSLen1 - 1, DA_386TSS						; TSS1, 基址待设置
LABEL_DESC_LDT2:	Descriptor	       0,       LDTLen2 - 1, DA_LDT							; LDT2, 基址待设置
LABEL_DESC_TSS2:	Descriptor	       0,       TSSLen2 - 1, DA_386TSS						; TSS2, 基址待设置
LABEL_DESC_LDT3:	Descriptor	       0,       LDTLen3 - 1, DA_LDT							; LDT3, 基址待设置
LABEL_DESC_TSS3:	Descriptor	       0,       TSSLen3 - 1, DA_386TSS						; TSS3, 基址待设置

GdtLen		equ	$ - LABEL_GDT	; GDT 长度
GdtPtr		dw	GdtLen - 1		; GDT 界限
			dd	0				; GDT 基地址, 待设置

; GDT 选择子
SelectorNormal		equ	LABEL_DESC_NORMAL	- LABEL_GDT
SelectorFlatC		equ	LABEL_DESC_FLAT_C	- LABEL_GDT
SelectorFlatRW		equ	LABEL_DESC_FLAT_RW	- LABEL_GDT
SelectorCode32		equ	LABEL_DESC_CODE32	- LABEL_GDT
SelectorCode16		equ	LABEL_DESC_CODE16	- LABEL_GDT
SelectorData		equ	LABEL_DESC_DATA		- LABEL_GDT
SelectorStack		equ	LABEL_DESC_STACK	- LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT

SelectorLDT0		equ	LABEL_DESC_LDT0		- LABEL_GDT				; LDT0 的选择子
SelectorTSS0		equ	LABEL_DESC_TSS0		- LABEL_GDT				; TSS0 的选择子
SelectorLDT1		equ	LABEL_DESC_LDT1		- LABEL_GDT				; LDT1 的选择子
SelectorTSS1		equ	LABEL_DESC_TSS1		- LABEL_GDT				; TSS0 的选择子
SelectorLDT2		equ	LABEL_DESC_LDT2		- LABEL_GDT				; LDT2 的选择子
SelectorTSS2		equ	LABEL_DESC_TSS2		- LABEL_GDT				; TSS0 的选择子
SelectorLDT3		equ	LABEL_DESC_LDT3		- LABEL_GDT				; LDT3 的选择子
SelectorTSS3		equ	LABEL_DESC_TSS3		- LABEL_GDT				; TSS0 的选择子
; END of [SECTION .gdt]

; 数据段
[SECTION .data1]
ALIGN	32
[BITS	32]
LABEL_DATA:
; 实模式下使用这些符号
; 字符串
_szPMMessage:		db	"In Protect Mode now. ^-^",0Ah, 0Ah, 0 ; 进入保护模式后显示此字符串
_szMemChkTitle:		db	"BaseAddrL BaseAddrH LengthLow LengthHigh   Type", 0Ah, 0
_szRAMSize			db	"RAM size:", 0
_szReturn			db	0Ah, 0
; 变量
_wSPValueInRealMode	dw	0
_dwMCRNumber:		dd	0					; Memory Check Result Number
_dwDispPos:			dd	(80 * 2 + 0) * 2	; 屏幕第 2 行, 第 0 列。
_dwMemSize:			dd	0
_ARDStruct:									; Address Range Descriptor Structure
	_dwBaseAddrLow:		dd	0
	_dwBaseAddrHigh:	dd	0
	_dwLengthLow:		dd	0
	_dwLengthHigh:		dd	0
	_dwType:			dd	0
_PageTableNumber	dd	0
_SavedIDTR:			dd	0					; 用于保存 IDTR
					dd	0
_SavedIMREG:		db	0					; 中断屏蔽寄存器值

_MemChkBuf:	times	256	db	0				; Memory Check Result Buffer

%define timeTimes   50	; 切换太快看不清楚

_TaskPriority:		dd	16*timeTimes, 10*timeTimes, 8*timeTimes, 6*timeTimes			; 任务优先级
_TaskTicks:			dd	0, 0, 0, 0			; 任务时间片

_dwCurrentTask		dd	0

; 保护模式下使用这些符号
szPMMessage		equ	_szPMMessage	- $$
szMemChkTitle	equ	_szMemChkTitle	- $$
szRAMSize		equ	_szRAMSize		- $$
szReturn		equ	_szReturn		- $$
dwDispPos		equ	_dwDispPos		- $$
dwMemSize		equ	_dwMemSize		- $$
dwMCRNumber		equ	_dwMCRNumber	- $$
ARDStruct		equ	_ARDStruct		- $$
	dwBaseAddrLow	equ	_dwBaseAddrLow	- $$
	dwBaseAddrHigh	equ	_dwBaseAddrHigh	- $$
	dwLengthLow		equ	_dwLengthLow	- $$
	dwLengthHigh	equ	_dwLengthHigh	- $$
	dwType			equ	_dwType			- $$
MemChkBuf		equ	_MemChkBuf		- $$
SavedIDTR		equ	_SavedIDTR		- $$
SavedIMREG		equ	_SavedIMREG		- $$
PageTableNumber	equ	_PageTableNumber	- $$

TaskPriority	equ	_TaskPriority	- $$
TaskTicks		equ	_TaskTicks		- $$
dwCurrentTask	equ _dwCurrentTask	- $$

DataLen			equ	$ - LABEL_DATA
; END of [SECTION .data1]

; 全局堆栈段
[SECTION .gs]
ALIGN	32
[BITS	32]
LABEL_STACK:
	times 512 db 0
TopOfStack	equ	$ - LABEL_STACK - 1
; END of [SECTION .gs]

; 0Fh->白字, 0Ch->红字
DefineAllStuff 0, "VERY", 0Ch
DefineAllStuff 1, "LOVE", 0Fh
DefineAllStuff 2, "HUST", 0Ch
DefineAllStuff 3, "MRSU", 0Fh

; 16 位代码段, 程序的入口和出口.
[SECTION .s16]
[BITS	16]
; 程序入口
LABEL_BEGIN:
	mov		ax, cs
	mov		ds, ax
	mov		es, ax
	mov		ss, ax
	mov		sp, 0100h

	mov		[LABEL_GO_BACK_TO_REAL + 3], ax	; 设置跳回实模式的基址
	mov		[_wSPValueInRealMode], sp		; 保存实模式下的 sp 寄存器

	; 使用 15 号中断得到内存信息
	mov		ebx, 0
	mov		di, _MemChkBuf
.loop:
	mov		eax, 0E820h
	mov		ecx, 20
	mov		edx, 0534D4150h
	int		15h
	jc		LABEL_MEM_CHK_FAIL
	add		di, 20
	inc		dword [_dwMCRNumber]
	cmp		ebx, 0
	jne		.loop
	jmp		LABEL_MEM_CHK_OK
LABEL_MEM_CHK_FAIL:
	mov		dword [_dwMCRNumber], 0
LABEL_MEM_CHK_OK:

	; 使用宏 InitDescriptorBase 初始化描述符的基址
	; 当前 DS = ES = SS = CS, 宏 InitDescriptorBase 见 "pm.inc"
	InitDescriptorBase LABEL_SEG_CODE16,	LABEL_DESC_CODE16			; 初始化 16 位代码段描述符
	InitDescriptorBase LABEL_SEG_CODE32,	LABEL_DESC_CODE32			; 初始化 32 位代码段描述符
	InitDescriptorBase LABEL_DATA,			LABEL_DESC_DATA				; 初始化数据段描述符
	InitDescriptorBase LABEL_STACK, 		LABEL_DESC_STACK			; 初始化堆栈段描述符

	InitDescriptorBase LABEL_LDT0,			LABEL_DESC_LDT0				; 初始化 LDT0 描述符
	InitDescriptorBase LABEL_T0_DATA,		LABEL_DESC_TASK0_DATA		; 初始化 LDT0 中 DATA 的描述符
	InitDescriptorBase LABEL_T0_CODE,		LABEL_DESC_TASK0_CODE		; 初始化 LDT0 中 CODE 的描述符
	InitDescriptorBase LABEL_T0_STACK0,		LABEL_DESC_TASK0_STACK0		; 初始化 LDT0 中 STACK0 的描述符
	InitDescriptorBase LABEL_T0_STACK3,		LABEL_DESC_TASK0_STACK3		; 初始化 LDT0 中 STACK3 的描述符
	InitDescriptorBase LABEL_TSS0,			LABEL_DESC_TSS0				; 初始化 TSS0 描述符

	InitDescriptorBase LABEL_LDT1,			LABEL_DESC_LDT1				; 初始化 LDT1 描述符
	InitDescriptorBase LABEL_T1_DATA, 		LABEL_DESC_TASK1_DATA		; 初始化 LDT1 中 DATA 的描述符
	InitDescriptorBase LABEL_T1_CODE,		LABEL_DESC_TASK1_CODE		; 初始化 LDT1 中 CODE 的描述符
	InitDescriptorBase LABEL_T1_STACK0,		LABEL_DESC_TASK1_STACK0		; 初始化 LDT1 中 STACK0 的描述符
	InitDescriptorBase LABEL_T1_STACK3,		LABEL_DESC_TASK1_STACK3		; 初始化 LDT1 中 STACK3 的描述符
	InitDescriptorBase LABEL_TSS1,			LABEL_DESC_TSS1				; 初始化 TSS1 描述符

	InitDescriptorBase LABEL_LDT2,			LABEL_DESC_LDT2				; 初始化 LDT2 描述符
	InitDescriptorBase LABEL_T2_DATA,		LABEL_DESC_TASK2_DATA		; 初始化 LDT2 中 DATA 的描述符
	InitDescriptorBase LABEL_T2_CODE,		LABEL_DESC_TASK2_CODE		; 初始化 LDT2 中 CODE 的描述符
	InitDescriptorBase LABEL_T2_STACK0,		LABEL_DESC_TASK2_STACK0		; 初始化 LDT2 中 STACK0 的描述符
	InitDescriptorBase LABEL_T2_STACK3,		LABEL_DESC_TASK2_STACK3		; 初始化 LDT2 中 STACK3 的描述符
	InitDescriptorBase LABEL_TSS2,			LABEL_DESC_TSS2				; 初始化 TSS2 描述符

	InitDescriptorBase LABEL_LDT3,			LABEL_DESC_LDT3				; 初始化 LDT3 描述符
	InitDescriptorBase LABEL_T3_DATA,		LABEL_DESC_TASK3_DATA		; 初始化 LDT3 中 DATA 的描述符
	InitDescriptorBase LABEL_T3_CODE,		LABEL_DESC_TASK3_CODE		; 初始化 LDT3 中 CODE 的描述符
	InitDescriptorBase LABEL_T3_STACK0,		LABEL_DESC_TASK3_STACK0		; 初始化 LDT3 中 STACK0 的描述符
	InitDescriptorBase LABEL_T3_STACK3,		LABEL_DESC_TASK3_STACK3		; 初始化 LDT3 中 STACK3 的描述符
	InitDescriptorBase LABEL_TSS3,			LABEL_DESC_TSS3				; 初始化 TSS3 描述符

	; 为加载 GDTR 作准备
	xor		eax, eax
	mov		ax, ds
	shl		eax, 4
	add		eax, LABEL_GDT				; eax <- gdt 基地址
	mov		dword [GdtPtr + 2], eax		; [GdtPtr + 2] <- gdt 基地址

	; 为加载 IDTR 作准备
	xor		eax, eax
	mov		ax, ds
	shl		eax, 4
	add		eax, LABEL_IDT				; eax <- idt 基地址
	mov		dword [IdtPtr + 2], eax		; [IdtPtr + 2] <- idt 基地址

	sidt	[_SavedIDTR]				; 保存 IDTR

	in		al, 21h						; ┳ 保存中断屏蔽寄存器(IMREG)值
	mov		[_SavedIMREG], al			; ┛

	lgdt	[GdtPtr]					; 加载 GDTR

	cli									; 关中断

	lidt	[IdtPtr]					; 加载 IDTR

	in		al, 92h						; ┓
	or		al, 00000010b				; ┣ 打开地址线 A20
	out		92h, al						; ┛

	mov		eax, cr0					; ┓
	or		eax, 1						; ┣ 准备切换到保护模式
	mov		cr0, eax					; ┛

	jmp		dword SelectorCode32:0		; 真正进入保护模式

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 从保护模式跳回到实模式就到了这里, 程序出口
LABEL_REAL_ENTRY:		
	mov		ax, cs
	mov		ds, ax
	mov		es, ax
	mov		ss, ax

	mov		sp, [_wSPValueInRealMode]	; 恢复 sp 寄存器

	lidt	[_SavedIDTR]				; 恢复 IDTR 的原值

	mov		al, [_SavedIMREG]			; ┳ 恢复中断屏蔽寄存器 IMREG 的原值
	out		21h, al						; ┛

	in		al, 92h						; ┓
	and		al, 11111101b				; ┣ 关闭 A20 地址线
	out		92h, al						; ┛

	sti									; 开中断

	mov		ax, 4c00h					; ┳ 回到 DOS
	int		21h							; ┛
; END of [SECTION .s16]

; 32 位代码段, 由实模式跳入.
[SECTION .s32]
[BITS	32]

LABEL_SEG_CODE32:
	mov		ax, SelectorData
	mov		ds, ax				; DS <- 数据段选择子
	mov		es, ax				; ES <- 数据段选择子
	mov		ax, SelectorVideo
	mov		gs, ax				; GS <- 视频段选择子
	mov		ax, SelectorStack
	mov		ss, ax				; SS <-堆栈段选择子
	mov		esp, TopOfStack		; ESP <- 栈顶指针

	call	Init8253A			; 设置定时芯片
	call	Init8259A			; 初始化中断

	call	ClearScreen			; 清屏

	push	szPMMessage			; ┓
	call	DispStr				; ┣ 输出信息
	add		esp, 4				; ┛

	push	szMemChkTitle		; ┓
	call	DispStr				; ┣ 显示内存信息
	add		esp, 4				; ┃
	call	DispMemSize			; ┛

	; 根据内存大小计算应初始化多少 PDE 以及多少页表
	xor		edx, edx
	mov		eax, [dwMemSize]
	mov		ebx, 400000h			; 400000h = 4M = 4096 * 1024, 一个页表对应的内存大小
	div		ebx
	mov		ecx, eax				; 此时 ecx 为页表的个数，也即 PDE 应该的个数
	test	edx, edx
	jz		.no_remainder
	inc		ecx						; 如果余数不为 0 就需增加一个页表
.no_remainder:
	mov		[PageTableNumber], ecx	; 暂存页表个数

	call	SetupPaging0		; 初始化任务 0 的页表
	call	SetupPaging1		; 初始化任务 1 的页表
	call	SetupPaging2		; 初始化任务 2 的页表
	call	SetupPaging3		; 初始化任务 3 的页表

	sti							; 打开中断

	mov		ax, SelectorTSS0	; ┳ 加载 TSS
	ltr		ax					; ┛

	mov		ax, SelectorLDT0	; ┳ 加载 LDT
	lldt	ax					; ┛

	mov		eax, PageDirBase0	; ┳ 加载 CR3
	mov		cr3, eax			; ┛

	mov		eax, cr0			; ┓
	or		eax, 80000000h		; ┣ 打开分页
	mov		cr0, eax			; ┃
	jmp		short .1			; ┛
.1:
	nop

	; 使用 retf 进行任务切换, 切换至任务 0
	; push	SelectorTask0Stack0	; SS
	; push	TopOfTask0Stack0	; ESP
	; push	SelectorTask0Code	; CS
	; push	0					; EIP
	; retf

	; 修改ds为任务0的数据段
	mov		eax, SelectorTask0Data
	mov		ds, eax

	; 使用 iretd 进行任务切换, 切换至任务 0
	push	SelectorTask0Stack3	; SS
	push	TopOfTask0Stack3	; ESP
	pushfd						; EFLAGS
	pop		eax					; ┓
	or		eax, 0x200			; ┣ 将 EFLAGS 中的 IF 位置 1, 即开启中断
	push	eax					; ┛
	push	SelectorTask0Code	; CS
	push	0					; EIP
	iretd

	call	SetRealmode8259A	; 恢复 8259A 以顺利返回实模式, 未执行
	jmp		SelectorCode16:0	; 返回实模式, 未执行

; ClearScreen ------------------------------------------------------------------
ClearScreen:
	push	eax
	push	ebx
	push	ecx

	mov		ah, 00000000b			; 0000: 黑底    0000: 黑字
	mov		al, 0
	mov		ebx, 0
	mov		ecx, 4000
.1:
	mov		[gs:ebx], ax
	add		ebx, 2
	loop 	.1

	pop		ecx
	pop		ebx
	pop		eax

	ret
; END of ClearScreen -----------------------------------------------------------

; Init8259A --------------------------------------------------------------------
Init8259A:
	mov		al, 011h
	out		020h, al	; 主8259, ICW1.
	call	io_delay

	out		0A0h, al	; 从8259, ICW1.
	call	io_delay

	mov		al, 020h	; IRQ0 对应中断向量 0x20
	out		021h, al	; 主8259, ICW2.
	call	io_delay

	mov		al, 028h	; IRQ8 对应中断向量 0x28
	out		0A1h, al	; 从8259, ICW2.
	call	io_delay

	mov		al, 004h	; IR2 对应从8259
	out		021h, al	; 主8259, ICW3.
	call	io_delay

	mov		al, 002h	; 对应主8259的 IR2
	out		0A1h, al	; 从8259, ICW3.
	call	io_delay

	mov		al, 001h
	out		021h, al	; 主8259, ICW4.
	call	io_delay

	out		0A1h, al	; 从8259, ICW4.
	call	io_delay

	mov		al, 11111110b	; 仅仅开启定时器中断
	; mov		al, 11111111b	; 屏蔽主8259所有中断
	out		021h, al	; 主8259, OCW1.
	call	io_delay

	mov		al, 11111111b	; 屏蔽从8259所有中断
	out		0A1h, al	; 从8259, OCW1.
	call	io_delay

	ret
; END of Init8259A -------------------------------------------------------------

; SetRealmode8259A -------------------------------------------------------------
SetRealmode8259A:
	mov		ax, SelectorData
	mov		fs, ax

	mov		al, 017h
	out		020h, al	; 主8259, ICW1.
	call	io_delay

	mov		al, 008h	; IRQ0 对应中断向量 0x8
	out		021h, al	; 主8259, ICW2.
	call	io_delay

	mov		al, 001h
	out		021h, al	; 主8259, ICW4.
	call	io_delay

	mov		al, [fs:SavedIMREG]	; ┓恢复中断屏蔽寄存器 IMREG 的原值
	out		021h, al			; ┛
	call	io_delay

	ret
; END of SetRealmode8259A ------------------------------------------------------

; Init8253A --------------------------------------------------------------------
Init8253A:
	mov		al, 00110110b		; 通道 0 的 CONTROL 字节
	out		043h, al			; 设置 8253A 芯片, 2 字节计数值, 模式 3, 二进制计数
	call	io_delay

	mov		ax, 23863			; 频率 50 Hz, 设置 COUNT 为 1193180 / 50 = 23863
	out		040h, al			; 将 COUNT 的低位写入通道 0
	call	io_delay

	mov		al, ah
	out		040h, al			; 将 COUNT 的高位写入通道 0
	call	io_delay

	ret
; END of Init8253A -------------------------------------------------------------

; io_delay ---------------------------------------------------------------------
io_delay:
	nop
	nop
	nop
	nop
	ret
; END of io_delay --------------------------------------------------------------

; int handler ------------------------------------------------------------------
_ClockHandler:
ClockHandler	equ	_ClockHandler - $$
	push	ds
	pushad

	mov		eax, SelectorData
	mov		ds, ax

	mov		al, 0x20
	out		0x20, al

	; 保护当前执行的进程编号
	mov     edx, dword [dwCurrentTask]

	; 判断TaskTicks是否全为0, 如果是, 则重置
	xor 	ecx, ecx
.all_zero_test_loop:
	; 注意TaskTicks为dd, 4字节
	cmp		dword [TaskTicks + ecx * 4], 0
	jne		.not_all_zero
	inc		ecx
	cmp		ecx, 4
	jne		.all_zero_test_loop
	xor    ecx, ecx
.all_zero:
	; 从TaskPriority复制到TaskTicks
	mov		ebx, dword [TaskPriority + ecx * 4]
	mov		dword [TaskTicks + ecx * 4], ebx
	inc		ecx
	cmp		ecx, 4
	jne		.all_zero
	xor     eax, eax
	xor     ecx, ecx
	jmp 	.priority_loop
.not_all_zero:
	; 判断当前的TaskTicks[MaxPriorityTask]是否为0，是的话重新调度
	mov     ebx, dword [dwCurrentTask]
	cmp     dword [TaskTicks + ebx * 4], 0
	jne     .current_not_zero
	xor     eax, eax
	xor     ecx, ecx
.priority_loop:
    cmp     eax, dword [TaskTicks + ecx * 4]
	jge     .priority_loop_end
	mov     eax, dword [TaskTicks + ecx * 4]
	mov     ebx, ecx ; ebx = 优先级最高的任务号
.priority_loop_end:
	inc		ecx
	cmp		ecx, 4
	jne		.priority_loop
	mov		dword [dwCurrentTask], ebx
.current_not_zero:
	mov 	ebx, dword [dwCurrentTask]
	; TaskTicks[MaxPriorityTask]--
	dec		dword [TaskTicks + ebx * 4]
	; 如果编号没有变化，直接返回
	cmp		ebx, edx
	je		.exit
	cmp		ebx, 0
	je		.1
	cmp		ebx, 1
	je		.2
	cmp		ebx, 2
	je		.3
	cmp		ebx, 3
	je		.4
	jmp		.exit
.1:
	SwitchTask	0
.2:
	SwitchTask	1
.3:
	SwitchTask	2
.4:
	SwitchTask	3
.exit:
	popad
	pop		ds
	iretd

_UserIntHandler:
UserIntHandler	equ	_UserIntHandler - $$
	mov		ah, 0Ch							; 0000: 黑底    1100: 红字
	mov		al, 'i'
	mov		[gs:((80 * 0 + 70) * 2)], ax	; 屏幕第 0 行, 第 70 列。
	iretd

_SpuriousHandler:
SpuriousHandler	equ	_SpuriousHandler - $$
	mov		ah, 0Ch							; 0000: 黑底    1100: 红字
	mov		al, '!'
	mov		[gs:((80 * 0 + 75) * 2)], ax	; 屏幕第 0 行, 第 75 列。
	iretd
; END of int handler -----------------------------------------------------------

DefineSetupPaging 0
DefineSetupPaging 1
DefineSetupPaging 2
DefineSetupPaging 3

; DispMemSize ------------------------------------------------------------------
DispMemSize:
	push	esi
	push	edi
	push	ecx

	mov		esi, MemChkBuf
	mov		ecx, [dwMCRNumber]		;for(int i = 0; i < [MCRNumber]; i++) // 每次得到一个ARDS(Address Range Descriptor Structure)结构
.loop:								;{
	mov		edx, 5					;	for(int j = 0; j < 5; j++)	// 每次得到一个ARDS中的成员，共5个成员
	mov		edi, ARDStruct			;	{
.1:									;		// 依次显示：BaseAddrLow，BaseAddrHigh，LengthLow，LengthHigh，Type
	push	dword [esi]				;
	call	DispInt					;		DispInt(MemChkBuf[j * 4]); // 显示一个成员
	pop		eax						;
	stosd							;		ARDStruct[j * 4] = MemChkBuf[j * 4];
	add		esi, 4					;
	dec		edx						;
	cmp		edx, 0					;
	jnz		.1						;	}
	call	DispReturn				;	printf("\n");
	cmp		dword [dwType], 1		;	if(Type == AddressRangeMemory) // AddressRangeMemory : 1, AddressRangeReserved : 2
	jne		.2						;	{
	mov		eax, [dwBaseAddrLow]	;
	add		eax, [dwLengthLow]		;
	cmp		eax, [dwMemSize]		;		if(BaseAddrLow + LengthLow > MemSize)
	jb		.2						;
	mov		[dwMemSize], eax		;			MemSize = BaseAddrLow + LengthLow;
.2:									;	}
	loop	.loop					;}
									;
	call	DispReturn				;printf("\n");
	push	szRAMSize				;
	call	DispStr					;printf("RAM size:");
	add		esp, 4					;
									;
	push	dword [dwMemSize]		;
	call	DispInt					;DispInt(MemSize);
	add		esp, 4					;

	pop		ecx
	pop		edi
	pop		esi
	ret
; End of DispMemSize -----------------------------------------------------------

%include	"lib.inc"	; 库函数

SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]


; 16 位代码段, 由 32 位代码段跳入, 跳出后到实模式.
[SECTION .s16code]
ALIGN	32
[BITS	16]
LABEL_SEG_CODE16:
	; 跳回实模式:
	mov		ax, SelectorNormal
	mov		ds, ax
	mov		es, ax
	mov		fs, ax
	mov		gs, ax
	mov		ss, ax

	mov		eax, cr0
	; and		al, 11111110b	; 仅切换到实模式
	and		eax, 7ffffffeh		; 切换到实模式并关闭分页
	mov		cr0, eax

LABEL_GO_BACK_TO_REAL:
	jmp		0:LABEL_REAL_ENTRY	; 段地址会在程序开始处被设置成正确的值

Code16Len	equ	$ - LABEL_SEG_CODE16
; END of [SECTION .s16code]