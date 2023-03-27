; ------------------------------------------------------------------------
; 初始化段描述符
; usage: InitDescriptorBase LABEL, LABEL_DESC
; ------------------------------------------------------------------------
%macro InitDescriptorBase 2
	xor		eax, eax
	mov		ax, ds
	shl		eax, 4
	add		eax, %1
	mov		word [%2 + 2], ax
	shr		eax, 16
	mov		byte [%2 + 4], al
	mov		byte [%2 + 7], ah
%endmacro

; ------------------------------------------------------------------------
; 定义LDT
; usage: DefineLDT 任务号
; ------------------------------------------------------------------------
%macro DefineLDT 1
; 任务 0 的 LDT
[SECTION .ldt%1]
ALIGN	32
LABEL_LDT%1:
;                                          段基址,            段界限,  属性
LABEL_DESC_TASK%1_DATA:		Descriptor	       0, Task%1DataLen - 1, DA_DRWA + DA_DPL3				 		; 数据段, 32位, 基址待设置
LABEL_DESC_TASK%1_CODE:		Descriptor	       0, Task%1CodeLen - 1, DA_C + DA_32 + DA_DPL3				; 代码段, 32位, 基址待设置
LABEL_DESC_TASK%1_STACK0:	Descriptor	       0, TopOfTask%1Stack0, DA_DRWA + DA_32			 	; 堆栈段, 32位，ring0, 基址待设置
LABEL_DESC_TASK%1_STACK3:	Descriptor	       0, TopOfTask%1Stack3, DA_DRWA + DA_32 + DA_DPL3	; 堆栈段, 32位，ring3, 基址待设置

LDTLen%1	equ	$ - LABEL_LDT%1		; LDT 的大小

; LDT 选择子
SelectorTask%1Data		equ LABEL_DESC_TASK%1_DATA	- LABEL_LDT%1 + SA_TIL + SA_RPL3				; 数据段选择子
SelectorTask%1Code		equ LABEL_DESC_TASK%1_CODE	- LABEL_LDT%1 + SA_TIL + SA_RPL3				; 代码段选择子
SelectorTask%1Stack0		equ	LABEL_DESC_TASK%1_STACK0	- LABEL_LDT%1 + SA_TIL				; ring0 堆栈段选择子
SelectorTask%1Stack3		equ	LABEL_DESC_TASK%1_STACK3	- LABEL_LDT%1 + SA_TIL + SA_RPL3 	; ring3 堆栈段选择子
; END of [SECTION .ldt0]
%endmacro


; ------------------------------------------------------------------------
; 定义TSS
; usage: DefineTSS 任务号
; ------------------------------------------------------------------------
%macro DefineTSS 1
; 任务 0 的 TSS
[SECTION .tss%1]
ALIGN	32
[BITS	32]
LABEL_TSS%1:
		DD	0               	; Back
		DD	TopOfTask%1Stack0	; 0 级堆栈
		DD	SelectorTask%1Stack0; 
		DD	0					; 1 级堆栈
		DD	0					; 
		DD	0					; 2 级堆栈
		DD	0					;
		DD	PageDirBase%1		; CR3
		DD	0 					; EIP
		DD	0x200				; EFLAGS
		DD	0					; EAX
		DD	0					; ECX
		DD	0					; EDX
		DD	0					; EBX
		DD	TopOfTask%1Stack0	; ESP
		DD	0					; EBP
		DD	0					; ESI
		DD	0					; EDI
		DD	0					; ES
		DD	SelectorTask%1Code	; CS
		DD	SelectorTask%1Stack0; SS
		DD	SelectorTask%1Data	; DS
		DD	0					; FS
		DD	SelectorVideo		; GS
		DD	SelectorLDT%1		; LDT
		DW	0					; 调试陷阱标志
		DW	$ - LABEL_TSS%1 + 2	; I/O位图基址
		DB	0ffh				; I/O位图结束标志
TSSLen%1		equ	$ - LABEL_TSS%1	; TSS0 的大小
; END of [SECTION .tss0]
%endmacro


; ------------------------------------------------------------------------
; 定义数据段
; usage: DefineDATA 任务号, 任务输出内容
; ------------------------------------------------------------------------
%macro DefineDATA 2
; 任务 0 的数据段
[SECTION .t%1data]
ALIGN	32
[BITS	32]
LABEL_T%1_DATA:
_szTask%1Message:	db	%2, 0
szTask%1Message	equ _szTask%1Message - $$
Task%1DataLen	equ	$ - LABEL_T%1_DATA
; END of [SECTION .t0data]
%endmacro

; ------------------------------------------------------------------------
; 定义核心堆栈段
; usage: DefineStack0 任务号
; ------------------------------------------------------------------------
%macro DefineStack0 1
; 任务 0 的核心堆栈
[SECTION .t%1s0]
ALIGN	32
[BITS	32]
LABEL_T%1_STACK0:
	times 512 db 0
TopOfTask%1Stack0	equ	$ - LABEL_T%1_STACK0 - 1
; END of [SECTION .t0s0]
%endmacro


; ------------------------------------------------------------------------
; 定义用户堆栈段
; usage: DefineStack3 任务号
; ------------------------------------------------------------------------
%macro DefineStack3 1
; 任务 0 的用户堆栈
[SECTION .t%1s3]
ALIGN	32
[BITS	32]
LABEL_T%1_STACK3:
	times 512 db 0
TopOfTask%1Stack3	equ	$ - LABEL_T%1_STACK3 - 1
; END of [SECTION .t0s3]
%endmacro


; ------------------------------------------------------------------------
; 定义代码段
; usage: DefineCode 任务号, 输出颜色
; ------------------------------------------------------------------------
%macro DefineCode 2
; 任务 0 的代码段
[SECTION .t%1c32]
ALIGN	32
[BITS	32]
LABEL_T%1_CODE:
	; 遍历输出szTask0Message
	xor 	ecx, ecx
	mov 	ah, %2
.outputLoop:
	mov 	al, [szTask%1Message + ecx]
	mov 	[gs:((80 * 20 + ecx) * 2)], ax
	inc 	ecx
	; 判断是否到达字符串末尾
	cmp 	al, 0
	jne 	.outputLoop
	jmp		LABEL_T%1_CODE

Task%1CodeLen	equ	$ - LABEL_T%1_CODE
; END of [SECTION .t0c32]
%endmacro


; ------------------------------------------------------------------------
; 定义一个进程的所有内容
; usage: DefineAllStuff 任务号, 任务输出内容, 输出颜色
; ------------------------------------------------------------------------
%macro DefineAllStuff 3
    DefineLDT	%1
    DefineTSS	%1
    DefineDATA	%1, %2
    DefineStack0	%1
    DefineStack3	%1
	DefineCode %1, %3
%endmacro

; ------------------------------------------------------------------------
; 定义初始化页表函数
; usage: DefineSetupPaging 任务号
; ------------------------------------------------------------------------
%macro DefineSetupPaging 1
; SetupPaging1 -----------------------------------------------------------------
SetupPaging%1:
	; 初始化页目录
	mov		ax, SelectorFlatRW
	mov		es, ax
	mov		edi, PageDirBase%1		; 此段首地址为 PageDirBase1
	xor		eax, eax
	mov		eax, PageTblBase%1 | PG_P  | PG_USU | PG_RWW
	mov		ecx, [PageTableNumber]
.1:
	stosd
	add		eax, 4096				; 为了简化, 所有页表在内存中是连续的.
	loop	.1

	; 再初始化所有页表
	mov		eax, [PageTableNumber]	; 页表个数
	mov		ebx, 1024				; 每个页表 1024 个 PTE
	mul		ebx
	mov		ecx, eax				; PTE个数 = 页表个数 * 1024
	mov		edi, PageTblBase%1		; 此段首地址为 PageTblBase1
	xor		eax, eax
	mov		eax, PG_P  | PG_USU | PG_RWW
.2:
	stosd
	add		eax, 4096				; 每一页指向 4K 的空间
	loop	.2

	ret
; End of SetupPaging1 ----------------------------------------------------------
%endmacro

; ------------------------------------------------------------------------
; 切换任务
; usage: SwitchTask 任务号
; ------------------------------------------------------------------------

%macro SwitchTask 1
	mov		ax, SelectorLDT%1	; ┳ 加载 LDT
	lldt	ax					; ┛

	mov		eax, PageDirBase%1	; ┳ 加载 CR3
	mov		cr3, eax			; ┛

	; 加载ds
	mov		eax, SelectorTask%1Data
	mov		ds, eax

	; 使用 iretd 进行任务切换, 切换至任务 0
	push	SelectorTask%1Stack3	; SS
	push	TopOfTask%1Stack3	; ESP
	pushfd						; EFLAGS
	pop		eax					; ┓
	or		eax, 0x200			; ┣ 将 EFLAGS 中的 IF 位置 1, 即开启中断
	push	eax					; ┛
	push	SelectorTask%1Code	; CS
	push	0					; EIP
	iretd
%endmacro


; ------------------------------------------------------------------------
; 定义bochs magic breakpoint
; usage: debugger
; ------------------------------------------------------------------------
%define debugger xchg bx, bx