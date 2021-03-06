(*
 * Copyright (c) 2010-2012,
 *  Jinseong Jeon <jsjeon@cs.umd.edu>
 *  Kris Micinski <micinski@cs.umd.edu>
 *  Jeff Foster   <jfoster@cs.umd.edu>
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. The names of the contributors may not be used to endorse or promote
 * products derived from this software without specific prior written
 * permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *)

(***********************************************************************)
(* Instr                                                               *)
(* reference: dalvik/libdex/OpCode.h                                   *)
(***********************************************************************)

module U = Util

module I32 = Int32
module I64 = Int64

module IM = Map.Make (I32)

module L = List
module B = Buffer

(***********************************************************************)
(* Basic Types/Elements                                                *)
(***********************************************************************)

type offset = int32

type instr  = opcode * operand list

and operand =
  | OPR_CONST    of int64
  | OPR_REGISTER of int
  | OPR_INDEX    of int
  | OPR_OFFSET   of offset

and opcode  =
  | OP_NOP                        (* 0x00 *)

  | OP_MOVE                       (* 0x01 *)
  | OP_MOVE_FROM16                (* 0x02 *)
  | OP_MOVE_16                    (* 0x03 *)
  | OP_MOVE_WIDE                  (* 0x04 *)
  | OP_MOVE_WIDE_FROM16           (* 0x05 *)
  | OP_MOVE_WIDE_16               (* 0x06 *)
  | OP_MOVE_OBJECT                (* 0x07 *)
  | OP_MOVE_OBJECT_FROM16         (* 0x08 *)
  | OP_MOVE_OBJECT_16             (* 0x09 *)

  | OP_MOVE_RESULT                (* 0x0a *)
  | OP_MOVE_RESULT_WIDE           (* 0x0b *)
  | OP_MOVE_RESULT_OBJECT         (* 0x0c *)
  | OP_MOVE_EXCEPTION             (* 0x0d *)

  | OP_RETURN_VOID                (* 0x0e *)
  | OP_RETURN                     (* 0x0f *)
  | OP_RETURN_WIDE                (* 0x10 *)
  | OP_RETURN_OBJECT              (* 0x11 *)

  | OP_CONST_4                    (* 0x12 *)
  | OP_CONST_16                   (* 0x13 *)
  | OP_CONST                      (* 0x14 *)
  | OP_CONST_HIGH16               (* 0x15 *)
  | OP_CONST_WIDE_16              (* 0x16 *)
  | OP_CONST_WIDE_32              (* 0x17 *)
  | OP_CONST_WIDE                 (* 0x18 *)
  | OP_CONST_WIDE_HIGH16          (* 0x19 *)
  | OP_CONST_STRING               (* 0x1a *)
  | OP_CONST_STRING_JUMBO         (* 0x1b *)
  | OP_CONST_CLASS                (* 0x1c *)

  | OP_MONITOR_ENTER              (* 0x1d *)
  | OP_MONITOR_EXIT               (* 0x1e *)

  | OP_CHECK_CAST                 (* 0x1f *)
  | OP_INSTANCE_OF                (* 0x20 *)

  | OP_ARRAY_LENGTH               (* 0x21 *)

  | OP_NEW_INSTANCE               (* 0x22 *)
  | OP_NEW_ARRAY                  (* 0x23 *)

  | OP_FILLED_NEW_ARRAY           (* 0x24 *)
  | OP_FILLED_NEW_ARRAY_RANGE     (* 0x25 *)
  | OP_FILL_ARRAY_DATA            (* 0x26 *)
    
  | OP_THROW                      (* 0x27 *)
  | OP_GOTO                       (* 0x28 *)
  | OP_GOTO_16                    (* 0x29 *)
  | OP_GOTO_32                    (* 0x2a *)
  | OP_PACKED_SWITCH              (* 0x2b *)
  | OP_SPARSE_SWITCH              (* 0x2c *)
    
  | OP_CMPL_FLOAT                 (* 0x2d *)
  | OP_CMPG_FLOAT                 (* 0x2e *)
  | OP_CMPL_DOUBLE                (* 0x2f *)
  | OP_CMPG_DOUBLE                (* 0x30 *)
  | OP_CMP_LONG                   (* 0x31 *)

  | OP_IF_EQ                      (* 0x32 *)
  | OP_IF_NE                      (* 0x33 *)
  | OP_IF_LT                      (* 0x34 *)
  | OP_IF_GE                      (* 0x35 *)
  | OP_IF_GT                      (* 0x36 *)
  | OP_IF_LE                      (* 0x37 *)
  | OP_IF_EQZ                     (* 0x38 *)
  | OP_IF_NEZ                     (* 0x39 *)
  | OP_IF_LTZ                     (* 0x3a *)
  | OP_IF_GEZ                     (* 0x3b *)
  | OP_IF_GTZ                     (* 0x3c *)
  | OP_IF_LEZ                     (* 0x3d *)
(*
  | OP_UNUSED_3E                  (* 0x3e *)
  | OP_UNUSED_3F                  (* 0x3f *)
  | OP_UNUSED_40                  (* 0x40 *)
  | OP_UNUSED_41                  (* 0x41 *)
  | OP_UNUSED_42                  (* 0x42 *)
  | OP_UNUSED_43                  (* 0x43 *)
*)
  | OP_AGET                       (* 0x44 *)
  | OP_AGET_WIDE                  (* 0x45 *)
  | OP_AGET_OBJECT                (* 0x46 *)
  | OP_AGET_BOOLEAN               (* 0x47 *)
  | OP_AGET_BYTE                  (* 0x48 *)
  | OP_AGET_CHAR                  (* 0x49 *)
  | OP_AGET_SHORT                 (* 0x4a *)
  | OP_APUT                       (* 0x4b *)
  | OP_APUT_WIDE                  (* 0x4c *)
  | OP_APUT_OBJECT                (* 0x4d *)
  | OP_APUT_BOOLEAN               (* 0x4e *)
  | OP_APUT_BYTE                  (* 0x4f *)
  | OP_APUT_CHAR                  (* 0x50 *)
  | OP_APUT_SHORT                 (* 0x51 *)

  | OP_IGET                       (* 0x52 *)
  | OP_IGET_WIDE                  (* 0x53 *)
  | OP_IGET_OBJECT                (* 0x54 *)
  | OP_IGET_BOOLEAN               (* 0x55 *)
  | OP_IGET_BYTE                  (* 0x56 *)
  | OP_IGET_CHAR                  (* 0x57 *)
  | OP_IGET_SHORT                 (* 0x58 *)
  | OP_IPUT                       (* 0x59 *)
  | OP_IPUT_WIDE                  (* 0x5a *)
  | OP_IPUT_OBJECT                (* 0x5b *)
  | OP_IPUT_BOOLEAN               (* 0x5c *)
  | OP_IPUT_BYTE                  (* 0x5d *)
  | OP_IPUT_CHAR                  (* 0x5e *)
  | OP_IPUT_SHORT                 (* 0x5f *)

  | OP_SGET                       (* 0x60 *)
  | OP_SGET_WIDE                  (* 0x61 *)
  | OP_SGET_OBJECT                (* 0x62 *)
  | OP_SGET_BOOLEAN               (* 0x63 *)
  | OP_SGET_BYTE                  (* 0x64 *)
  | OP_SGET_CHAR                  (* 0x65 *)
  | OP_SGET_SHORT                 (* 0x66 *)
  | OP_SPUT                       (* 0x67 *)
  | OP_SPUT_WIDE                  (* 0x68 *)
  | OP_SPUT_OBJECT                (* 0x69 *)
  | OP_SPUT_BOOLEAN               (* 0x6a *)
  | OP_SPUT_BYTE                  (* 0x6b *)
  | OP_SPUT_CHAR                  (* 0x6c *)
  | OP_SPUT_SHORT                 (* 0x6d *)

  | OP_INVOKE_VIRTUAL             (* 0x6e *)
  | OP_INVOKE_SUPER               (* 0x6f *)
  | OP_INVOKE_DIRECT              (* 0x70 *)
  | OP_INVOKE_STATIC              (* 0x71 *)
  | OP_INVOKE_INTERFACE           (* 0x72 *)
(*
  | OP_UNUSED_73                  (* 0x73 *)
*)    
  | OP_INVOKE_VIRTUAL_RANGE       (* 0x74 *)
  | OP_INVOKE_SUPER_RANGE         (* 0x75 *)
  | OP_INVOKE_DIRECT_RANGE        (* 0x76 *)
  | OP_INVOKE_STATIC_RANGE        (* 0x77 *)
  | OP_INVOKE_INTERFACE_RANGE     (* 0x78 *)
(*
  | OP_UNUSED_79                  (* 0x79 *)
  | OP_UNUSED_7A                  (* 0x7a *)
*)
  | OP_NEG_INT                    (* 0x7b *)
  | OP_NOT_INT                    (* 0x7c *)
  | OP_NEG_LONG                   (* 0x7d *)
  | OP_NOT_LONG                   (* 0x7e *)
  | OP_NEG_FLOAT                  (* 0x7f *)
  | OP_NEG_DOUBLE                 (* 0x80 *)
  | OP_INT_TO_LONG                (* 0x81 *)
  | OP_INT_TO_FLOAT               (* 0x82 *)
  | OP_INT_TO_DOUBLE              (* 0x83 *)
  | OP_LONG_TO_INT                (* 0x84 *)
  | OP_LONG_TO_FLOAT              (* 0x85 *)
  | OP_LONG_TO_DOUBLE             (* 0x86 *)
  | OP_FLOAT_TO_INT               (* 0x87 *)
  | OP_FLOAT_TO_LONG              (* 0x88 *)
  | OP_FLOAT_TO_DOUBLE            (* 0x89 *)
  | OP_DOUBLE_TO_INT              (* 0x8a *)
  | OP_DOUBLE_TO_LONG             (* 0x8b *)
  | OP_DOUBLE_TO_FLOAT            (* 0x8c *)
  | OP_INT_TO_BYTE                (* 0x8d *)
  | OP_INT_TO_CHAR                (* 0x8e *)
  | OP_INT_TO_SHORT               (* 0x8f *)

  | OP_ADD_INT                    (* 0x90 *)
  | OP_SUB_INT                    (* 0x91 *)
  | OP_MUL_INT                    (* 0x92 *)
  | OP_DIV_INT                    (* 0x93 *)
  | OP_REM_INT                    (* 0x94 *)
  | OP_AND_INT                    (* 0x95 *)
  | OP_OR_INT                     (* 0x96 *)
  | OP_XOR_INT                    (* 0x97 *)
  | OP_SHL_INT                    (* 0x98 *)
  | OP_SHR_INT                    (* 0x99 *)
  | OP_USHR_INT                   (* 0x9a *)

  | OP_ADD_LONG                   (* 0x9b *)
  | OP_SUB_LONG                   (* 0x9c *)
  | OP_MUL_LONG                   (* 0x9d *)
  | OP_DIV_LONG                   (* 0x9e *)
  | OP_REM_LONG                   (* 0x9f *)
  | OP_AND_LONG                   (* 0xa0 *)
  | OP_OR_LONG                    (* 0xa1 *)
  | OP_XOR_LONG                   (* 0xa2 *)
  | OP_SHL_LONG                   (* 0xa3 *)
  | OP_SHR_LONG                   (* 0xa4 *)
  | OP_USHR_LONG                  (* 0xa5 *)

  | OP_ADD_FLOAT                  (* 0xa6 *)
  | OP_SUB_FLOAT                  (* 0xa7 *)
  | OP_MUL_FLOAT                  (* 0xa8 *)
  | OP_DIV_FLOAT                  (* 0xa9 *)
  | OP_REM_FLOAT                  (* 0xaa *)
  | OP_ADD_DOUBLE                 (* 0xab *)
  | OP_SUB_DOUBLE                 (* 0xac *)
  | OP_MUL_DOUBLE                 (* 0xad *)
  | OP_DIV_DOUBLE                 (* 0xae *)
  | OP_REM_DOUBLE                 (* 0xaf *)

  | OP_ADD_INT_2ADDR              (* 0xb0 *)
  | OP_SUB_INT_2ADDR              (* 0xb1 *)
  | OP_MUL_INT_2ADDR              (* 0xb2 *)
  | OP_DIV_INT_2ADDR              (* 0xb3 *)
  | OP_REM_INT_2ADDR              (* 0xb4 *)
  | OP_AND_INT_2ADDR              (* 0xb5 *)
  | OP_OR_INT_2ADDR               (* 0xb6 *)
  | OP_XOR_INT_2ADDR              (* 0xb7 *)
  | OP_SHL_INT_2ADDR              (* 0xb8 *)
  | OP_SHR_INT_2ADDR              (* 0xb9 *)
  | OP_USHR_INT_2ADDR             (* 0xba *)

  | OP_ADD_LONG_2ADDR             (* 0xbb *)
  | OP_SUB_LONG_2ADDR             (* 0xbc *)
  | OP_MUL_LONG_2ADDR             (* 0xbd *)
  | OP_DIV_LONG_2ADDR             (* 0xbe *)
  | OP_REM_LONG_2ADDR             (* 0xbf *)
  | OP_AND_LONG_2ADDR             (* 0xc0 *)
  | OP_OR_LONG_2ADDR              (* 0xc1 *)
  | OP_XOR_LONG_2ADDR             (* 0xc2 *)
  | OP_SHL_LONG_2ADDR             (* 0xc3 *)
  | OP_SHR_LONG_2ADDR             (* 0xc4 *)
  | OP_USHR_LONG_2ADDR            (* 0xc5 *)

  | OP_ADD_FLOAT_2ADDR            (* 0xc6 *)
  | OP_SUB_FLOAT_2ADDR            (* 0xc7 *)
  | OP_MUL_FLOAT_2ADDR            (* 0xc8 *)
  | OP_DIV_FLOAT_2ADDR            (* 0xc9 *)
  | OP_REM_FLOAT_2ADDR            (* 0xca *)
  | OP_ADD_DOUBLE_2ADDR           (* 0xcb *)
  | OP_SUB_DOUBLE_2ADDR           (* 0xcc *)
  | OP_MUL_DOUBLE_2ADDR           (* 0xcd *)
  | OP_DIV_DOUBLE_2ADDR           (* 0xce *)
  | OP_REM_DOUBLE_2ADDR           (* 0xcf *)

  | OP_ADD_INT_LIT16              (* 0xd0 *)
  | OP_RSUB_INT                   (* 0xd1 *) (* no _LIT16 suffix for this *)
  | OP_MUL_INT_LIT16              (* 0xd2 *)
  | OP_DIV_INT_LIT16              (* 0xd3 *)
  | OP_REM_INT_LIT16              (* 0xd4 *)
  | OP_AND_INT_LIT16              (* 0xd5 *)
  | OP_OR_INT_LIT16               (* 0xd6 *)
  | OP_XOR_INT_LIT16              (* 0xd7 *)

  | OP_ADD_INT_LIT8               (* 0xd8 *)
  | OP_RSUB_INT_LIT8              (* 0xd9 *)
  | OP_MUL_INT_LIT8               (* 0xda *)
  | OP_DIV_INT_LIT8               (* 0xdb *)
  | OP_REM_INT_LIT8               (* 0xdc *)
  | OP_AND_INT_LIT8               (* 0xdd *)
  | OP_OR_INT_LIT8                (* 0xde *)
  | OP_XOR_INT_LIT8               (* 0xdf *)
  | OP_SHL_INT_LIT8               (* 0xe0 *)
  | OP_SHR_INT_LIT8               (* 0xe1 *)
  | OP_USHR_INT_LIT8              (* 0xe2 *)
(*
  | OP_UNUSED_E3                  (* 0xe3 *)
  | OP_UNUSED_E4                  (* 0xe4 *)
  | OP_UNUSED_E5                  (* 0xe5 *)
  | OP_UNUSED_E6                  (* 0xe6 *)
  | OP_UNUSED_E7                  (* 0xe7 *)
  | OP_UNUSED_E8                  (* 0xe8 *)
  | OP_UNUSED_E9                  (* 0xe9 *)
  | OP_UNUSED_EA                  (* 0xea *)
  | OP_UNUSED_EB                  (* 0xeb *)

    (*
     * The "breakpoint" instruction is special, in that it should never
     * be seen by anything but the debug interpreter.  During debugging
     * it takes the place of an arbitrary opcode, which means operations
     * like "tell me the opcode width so I can find the next instruction"
     * aren't possible.  (This is correctable, but probably not useful.)
     *)

  | OP_BREAKPOINT                 (* 0xec *)

    (* optimizer output -- these are never generated by "dx" *)

  | OP_THROW_VERIFICATION_ERROR   (* 0xed *)
  | OP_EXECUTE_INLINE             (* 0xee *)
  | OP_EXECUTE_INLINE_RANGE       (* 0xef *)

  | OP_INVOKE_DIRECT_EMPTY        (* 0xf0 *)
  | OP_UNUSED_F1                  (* 0xf1 *) (* OP_INVOKE_DIRECT_EMPTY_RANGE? *)
  | OP_IGET_QUICK                 (* 0xf2 *)
  | OP_IGET_WIDE_QUICK            (* 0xf3 *)
  | OP_IGET_OBJECT_QUICK          (* 0xf4 *)
  | OP_IPUT_QUICK                 (* 0xf5 *)
  | OP_IPUT_WIDE_QUICK            (* 0xf6 *)
  | OP_IPUT_OBJECT_QUICK          (* 0xf7 *)

  | OP_INVOKE_VIRTUAL_QUICK       (* 0xf8 *)
  | OP_INVOKE_VIRTUAL_QUICK_RANGE (* 0xf9 *)
  | OP_INVOKE_SUPER_QUICK         (* 0xfa *)
  | OP_INVOKE_SUPER_QUICK_RANGE   (* 0xfb *)
  | OP_UNUSED_FC                  (* 0xfc *) (* OP_INVOKE_DIRECT_QUICK? *)
  | OP_UNUSED_FD                  (* 0xfd *) (* OP_INVOKE_DIRECT_QUICK_RANGE? *)
  | OP_UNUSED_FE                  (* 0xfe *) (* OP_INVOKE_INTERFACE_QUICK? *)
  | OP_UNUSED_FF                  (* 0xff *) (* OP_INVOKE_INTERFACE_QUICK_RANGE *)
*)

(***********************************************************************)
(* Utilities                                                           *)
(***********************************************************************)

let to_i32 = I32.of_int
let of_i32 = I32.to_int

let to_i64 = I64.of_int
let of_i64 = I64.to_int

(* instr_to_string : instr -> string *)
let rec instr_to_string (op, opr) =
  let buf = B.create 80 in
  B.add_string buf (op_to_string op);
  B.add_char buf ' ';
  let per_opr opr' =
    B.add_string buf (opr_to_string opr');
    B.add_char buf ' '
  in
  L.iter per_opr opr;
  B.contents buf

(* opr_to_string : operand -> string *)
and opr_to_string = function
  | OPR_CONST    cs -> I64.to_string cs
  | OPR_REGISTER rg -> "v"^(string_of_int rg)
  | OPR_INDEX    ix -> Printf.sprintf "@%X" ix (* dexdump format *)
  | OPR_OFFSET  off -> Printf.sprintf "0x%08X" (of_i32 off)

(* op_to_string : opcode -> string *)
and op_to_string = function
  | OP_NOP                        -> "nop"

  | OP_MOVE                       -> "move"
  | OP_MOVE_FROM16                -> "move/from16"
  | OP_MOVE_16                    -> "move/16"
  | OP_MOVE_WIDE                  -> "move-wide"
  | OP_MOVE_WIDE_FROM16           -> "move-wide/from16"
  | OP_MOVE_WIDE_16               -> "move-wide/16"
  | OP_MOVE_OBJECT                -> "move-object"
  | OP_MOVE_OBJECT_FROM16         -> "move-object/from16"
  | OP_MOVE_OBJECT_16             -> "move-object/16"

  | OP_MOVE_RESULT                -> "move-result"
  | OP_MOVE_RESULT_WIDE           -> "move-result-wide"
  | OP_MOVE_RESULT_OBJECT         -> "move-result-object"
  | OP_MOVE_EXCEPTION             -> "move-exception"

  | OP_RETURN_VOID                -> "return-void"
  | OP_RETURN                     -> "return"
  | OP_RETURN_WIDE                -> "return-wide"
  | OP_RETURN_OBJECT              -> "return-object"

  | OP_CONST_4                    -> "const/4"
  | OP_CONST_16                   -> "const/16"
  | OP_CONST                      -> "const"
  | OP_CONST_HIGH16               -> "const/high16"
  | OP_CONST_WIDE_16              -> "const-wide/16"
  | OP_CONST_WIDE_32              -> "const-wide/32"
  | OP_CONST_WIDE                 -> "const-wide"
  | OP_CONST_WIDE_HIGH16          -> "const-wide/high16"
  | OP_CONST_STRING               -> "const-string"
  | OP_CONST_STRING_JUMBO         -> "const-string/jumbo"
  | OP_CONST_CLASS                -> "const-class"

  | OP_MONITOR_ENTER              -> "monitor-enter"
  | OP_MONITOR_EXIT               -> "monitor-exit"

  | OP_CHECK_CAST                 -> "check-cast"
  | OP_INSTANCE_OF                -> "instance-of"

  | OP_ARRAY_LENGTH               -> "array-length"

  | OP_NEW_INSTANCE               -> "new-instance"
  | OP_NEW_ARRAY                  -> "new-array"

  | OP_FILLED_NEW_ARRAY           -> "filled-new-array"
  | OP_FILLED_NEW_ARRAY_RANGE     -> "filled-new-array/range"
  | OP_FILL_ARRAY_DATA            -> "fill-array-data"
    
  | OP_THROW                      -> "throw"
  | OP_GOTO                       -> "goto"
  | OP_GOTO_16                    -> "goto/16"
  | OP_GOTO_32                    -> "goto/32"
  | OP_PACKED_SWITCH              -> "packed-switch"
  | OP_SPARSE_SWITCH              -> "sparse-switch"
    
  | OP_CMPL_FLOAT                 -> "cmpl-float"
  | OP_CMPG_FLOAT                 -> "cmpg-float"
  | OP_CMPL_DOUBLE                -> "cmpl-double"
  | OP_CMPG_DOUBLE                -> "cmpg-double"
  | OP_CMP_LONG                   -> "cmp-long"

  | OP_IF_EQ                      -> "if-eq"
  | OP_IF_NE                      -> "if-ne"
  | OP_IF_LT                      -> "if-lt"
  | OP_IF_GE                      -> "if-ge"
  | OP_IF_GT                      -> "if-gt"
  | OP_IF_LE                      -> "if-le"
  | OP_IF_EQZ                     -> "if-eqz"
  | OP_IF_NEZ                     -> "if-nez"
  | OP_IF_LTZ                     -> "if-ltz"
  | OP_IF_GEZ                     -> "if-gez"
  | OP_IF_GTZ                     -> "if-gtz"
  | OP_IF_LEZ                     -> "if-lez"

  | OP_AGET                       -> "aget"
  | OP_AGET_WIDE                  -> "aget-wide"
  | OP_AGET_OBJECT                -> "aget-object"
  | OP_AGET_BOOLEAN               -> "aget-boolean"
  | OP_AGET_BYTE                  -> "aget-byte"
  | OP_AGET_CHAR                  -> "aget-char"
  | OP_AGET_SHORT                 -> "aget-short"
  | OP_APUT                       -> "aput"
  | OP_APUT_WIDE                  -> "aput-wide"
  | OP_APUT_OBJECT                -> "aput-object"
  | OP_APUT_BOOLEAN               -> "aput-boolean"
  | OP_APUT_BYTE                  -> "aput-byte"
  | OP_APUT_CHAR                  -> "aput-char"
  | OP_APUT_SHORT                 -> "aput-short"

  | OP_IGET                       -> "iget"
  | OP_IGET_WIDE                  -> "iget-wide"
  | OP_IGET_OBJECT                -> "iget-object"
  | OP_IGET_BOOLEAN               -> "iget-boolean"
  | OP_IGET_BYTE                  -> "iget-byte"
  | OP_IGET_CHAR                  -> "iget-char"
  | OP_IGET_SHORT                 -> "iget-short"
  | OP_IPUT                       -> "iput"
  | OP_IPUT_WIDE                  -> "iput-wide"
  | OP_IPUT_OBJECT                -> "iput-object"
  | OP_IPUT_BOOLEAN               -> "iput-boolean"
  | OP_IPUT_BYTE                  -> "iput-byte"
  | OP_IPUT_CHAR                  -> "iput-char"
  | OP_IPUT_SHORT                 -> "iput-short"

  | OP_SGET                       -> "sget"
  | OP_SGET_WIDE                  -> "sget-wide"
  | OP_SGET_OBJECT                -> "sget-object"
  | OP_SGET_BOOLEAN               -> "sget-boolean"
  | OP_SGET_BYTE                  -> "sget-byte"
  | OP_SGET_CHAR                  -> "sget-char"
  | OP_SGET_SHORT                 -> "sget-short"
  | OP_SPUT                       -> "sput"
  | OP_SPUT_WIDE                  -> "sput-wide"
  | OP_SPUT_OBJECT                -> "sput-object"
  | OP_SPUT_BOOLEAN               -> "sput-boolean"
  | OP_SPUT_BYTE                  -> "sput-byte"
  | OP_SPUT_CHAR                  -> "sput-char"
  | OP_SPUT_SHORT                 -> "sput-short"

  | OP_INVOKE_VIRTUAL             -> "invoke-virtual"
  | OP_INVOKE_SUPER               -> "invoke-super"
  | OP_INVOKE_DIRECT              -> "invoke-direct"
  | OP_INVOKE_STATIC              -> "invoke-static"
  | OP_INVOKE_INTERFACE           -> "invoke-interface"
    
  | OP_INVOKE_VIRTUAL_RANGE       -> "invoke-virtual/range"
  | OP_INVOKE_SUPER_RANGE         -> "invoke-super/range"
  | OP_INVOKE_DIRECT_RANGE        -> "invoke-direct/range"
  | OP_INVOKE_STATIC_RANGE        -> "invoke-static/range"
  | OP_INVOKE_INTERFACE_RANGE     -> "invoke-interface/range"

  | OP_NEG_INT                    -> "neg-int"
  | OP_NOT_INT                    -> "not-int"
  | OP_NEG_LONG                   -> "neg-long"
  | OP_NOT_LONG                   -> "not-long"
  | OP_NEG_FLOAT                  -> "neg-float"
  | OP_NEG_DOUBLE                 -> "neg-double"
  | OP_INT_TO_LONG                -> "int-to-long"
  | OP_INT_TO_FLOAT               -> "int-to-float"
  | OP_INT_TO_DOUBLE              -> "int-to-double"
  | OP_LONG_TO_INT                -> "long-to-int"
  | OP_LONG_TO_FLOAT              -> "long-to-float"
  | OP_LONG_TO_DOUBLE             -> "long-to-double"
  | OP_FLOAT_TO_INT               -> "float-to-int"
  | OP_FLOAT_TO_LONG              -> "float-to-long"
  | OP_FLOAT_TO_DOUBLE            -> "float-to-double"
  | OP_DOUBLE_TO_INT              -> "double-to-int"
  | OP_DOUBLE_TO_LONG             -> "double-to-long"
  | OP_DOUBLE_TO_FLOAT            -> "double-to-float"
  | OP_INT_TO_BYTE                -> "int-to-byte"
  | OP_INT_TO_CHAR                -> "int-to-char"
  | OP_INT_TO_SHORT               -> "int-to-short"

  | OP_ADD_INT                    -> "add-int"
  | OP_SUB_INT                    -> "sub-int"
  | OP_MUL_INT                    -> "mul-int"
  | OP_DIV_INT                    -> "div-int"
  | OP_REM_INT                    -> "rem-int"
  | OP_AND_INT                    -> "and-int"
  | OP_OR_INT                     -> "or-int"
  | OP_XOR_INT                    -> "xor-int"
  | OP_SHL_INT                    -> "shl-int"
  | OP_SHR_INT                    -> "shr-int"
  | OP_USHR_INT                   -> "ushr-int"

  | OP_ADD_LONG                   -> "add-long"
  | OP_SUB_LONG                   -> "sub-long"
  | OP_MUL_LONG                   -> "mul-long"
  | OP_DIV_LONG                   -> "div-long"
  | OP_REM_LONG                   -> "rem-long"
  | OP_AND_LONG                   -> "and-long"
  | OP_OR_LONG                    -> "or-long"
  | OP_XOR_LONG                   -> "xor-long"
  | OP_SHL_LONG                   -> "shl-long"
  | OP_SHR_LONG                   -> "shr-long"
  | OP_USHR_LONG                  -> "ushr-long"

  | OP_ADD_FLOAT                  -> "add-float"
  | OP_SUB_FLOAT                  -> "sub-float"
  | OP_MUL_FLOAT                  -> "mul-float"
  | OP_DIV_FLOAT                  -> "div-float"
  | OP_REM_FLOAT                  -> "rem-float"
  | OP_ADD_DOUBLE                 -> "add-double"
  | OP_SUB_DOUBLE                 -> "sub-double"
  | OP_MUL_DOUBLE                 -> "mul-double"
  | OP_DIV_DOUBLE                 -> "div-double"
  | OP_REM_DOUBLE                 -> "rem-double"

  | OP_ADD_INT_2ADDR              -> "add-int/2addr"
  | OP_SUB_INT_2ADDR              -> "sub-int/2addr"
  | OP_MUL_INT_2ADDR              -> "mul-int/2addr"
  | OP_DIV_INT_2ADDR              -> "div-int/2addr"
  | OP_REM_INT_2ADDR              -> "rem-int/2addr"
  | OP_AND_INT_2ADDR              -> "and-int/2addr"
  | OP_OR_INT_2ADDR               -> "or-int/2addr"
  | OP_XOR_INT_2ADDR              -> "xor-int/2addr"
  | OP_SHL_INT_2ADDR              -> "shl-int/2addr"
  | OP_SHR_INT_2ADDR              -> "shr-int/2addr"
  | OP_USHR_INT_2ADDR             -> "ushr-int/2addr"

  | OP_ADD_LONG_2ADDR             -> "add-long/2addr"
  | OP_SUB_LONG_2ADDR             -> "sub-long/2addr"
  | OP_MUL_LONG_2ADDR             -> "mul-long/2addr"
  | OP_DIV_LONG_2ADDR             -> "div-long/2addr"
  | OP_REM_LONG_2ADDR             -> "rem-long/2addr"
  | OP_AND_LONG_2ADDR             -> "and-long/2addr"
  | OP_OR_LONG_2ADDR              -> "or-long/2addr"
  | OP_XOR_LONG_2ADDR             -> "xor-long/2addr"
  | OP_SHL_LONG_2ADDR             -> "shl-long/2addr"
  | OP_SHR_LONG_2ADDR             -> "shr-long/2addr"
  | OP_USHR_LONG_2ADDR            -> "ushr-long/2addr"

  | OP_ADD_FLOAT_2ADDR            -> "add-float/2addr"
  | OP_SUB_FLOAT_2ADDR            -> "sub-float/2addr"
  | OP_MUL_FLOAT_2ADDR            -> "mul-float/2addr"
  | OP_DIV_FLOAT_2ADDR            -> "div-float/2addr"
  | OP_REM_FLOAT_2ADDR            -> "rem-float/2addr"
  | OP_ADD_DOUBLE_2ADDR           -> "add-double/2addr"
  | OP_SUB_DOUBLE_2ADDR           -> "sub-double/2addr"
  | OP_MUL_DOUBLE_2ADDR           -> "mul-double/2addr"
  | OP_DIV_DOUBLE_2ADDR           -> "div-double/2addr"
  | OP_REM_DOUBLE_2ADDR           -> "rem-double/2addr"

  | OP_ADD_INT_LIT16              -> "add-int/lit16"
  | OP_RSUB_INT                   -> "rsub-int"
  | OP_MUL_INT_LIT16              -> "mul-int/lit16"
  | OP_DIV_INT_LIT16              -> "div-int/lit16"
  | OP_REM_INT_LIT16              -> "rem-int/lit16"
  | OP_AND_INT_LIT16              -> "and-int/lit16"
  | OP_OR_INT_LIT16               -> "or-int/lit16"
  | OP_XOR_INT_LIT16              -> "xor-int/lit16"

  | OP_ADD_INT_LIT8               -> "add-int/lit8"
  | OP_RSUB_INT_LIT8              -> "rsub-int/lit8"
  | OP_MUL_INT_LIT8               -> "mul-int/lit8"
  | OP_DIV_INT_LIT8               -> "div-int/lit8"
  | OP_REM_INT_LIT8               -> "rem-int/lit8"
  | OP_AND_INT_LIT8               -> "and-int/lit8"
  | OP_OR_INT_LIT8                -> "or-int/lit8"
  | OP_XOR_INT_LIT8               -> "xor-int/lit8"
  | OP_SHL_INT_LIT8               -> "shl-int/lit8"
  | OP_SHR_INT_LIT8               -> "shr-int/lit8"
  | OP_USHR_INT_LIT8              -> "ushr-int/lit8"

(* hx_to_op_and_size : int -> opcode * int *)
let hx_to_op_and_size (hx: int) : opcode * int =
  match hx with
  | 0x00 -> OP_NOP, 2

  | 0x01 -> OP_MOVE, 2
  | 0x02 -> OP_MOVE_FROM16, 4
  | 0x03 -> OP_MOVE_16, 6
  | 0x04 -> OP_MOVE_WIDE, 2
  | 0x05 -> OP_MOVE_WIDE_FROM16, 4
  | 0x06 -> OP_MOVE_WIDE_16, 6
  | 0x07 -> OP_MOVE_OBJECT, 2
  | 0x08 -> OP_MOVE_OBJECT_FROM16, 4
  | 0x09 -> OP_MOVE_OBJECT_16, 6

  | 0x0a -> OP_MOVE_RESULT, 2
  | 0x0b -> OP_MOVE_RESULT_WIDE, 2
  | 0x0c -> OP_MOVE_RESULT_OBJECT, 2
  | 0x0d -> OP_MOVE_EXCEPTION, 2

  | 0x0e -> OP_RETURN_VOID, 2
  | 0x0f -> OP_RETURN, 2
  | 0x10 -> OP_RETURN_WIDE, 2
  | 0x11 -> OP_RETURN_OBJECT, 2

  | 0x12 -> OP_CONST_4, 2
  | 0x13 -> OP_CONST_16, 4
  | 0x14 -> OP_CONST, 6
  | 0x15 -> OP_CONST_HIGH16, 4
  | 0x16 -> OP_CONST_WIDE_16, 4
  | 0x17 -> OP_CONST_WIDE_32, 6
  | 0x18 -> OP_CONST_WIDE, 10
  | 0x19 -> OP_CONST_WIDE_HIGH16, 4
  | 0x1a -> OP_CONST_STRING, 4
  | 0x1b -> OP_CONST_STRING_JUMBO, 6
  | 0x1c -> OP_CONST_CLASS, 4

  | 0x1d -> OP_MONITOR_ENTER, 2
  | 0x1e -> OP_MONITOR_EXIT, 2

  | 0x1f -> OP_CHECK_CAST, 4
  | 0x20 -> OP_INSTANCE_OF, 4

  | 0x21 -> OP_ARRAY_LENGTH, 2

  | 0x22 -> OP_NEW_INSTANCE, 4
  | 0x23 -> OP_NEW_ARRAY, 4

  | 0x24 -> OP_FILLED_NEW_ARRAY, 6
  | 0x25 -> OP_FILLED_NEW_ARRAY_RANGE, 6
  | 0x26 -> OP_FILL_ARRAY_DATA, 6
    
  | 0x27 -> OP_THROW, 2
  | 0x28 -> OP_GOTO, 2
  | 0x29 -> OP_GOTO_16, 4
  | 0x2a -> OP_GOTO_32, 6
  | 0x2b -> OP_PACKED_SWITCH, 6
  | 0x2c -> OP_SPARSE_SWITCH, 6
    
  | 0x2d -> OP_CMPL_FLOAT, 4
  | 0x2e -> OP_CMPG_FLOAT, 4
  | 0x2f -> OP_CMPL_DOUBLE, 4
  | 0x30 -> OP_CMPG_DOUBLE, 4
  | 0x31 -> OP_CMP_LONG, 4

  | 0x32 -> OP_IF_EQ, 4
  | 0x33 -> OP_IF_NE, 4
  | 0x34 -> OP_IF_LT, 4
  | 0x35 -> OP_IF_GE, 4
  | 0x36 -> OP_IF_GT, 4
  | 0x37 -> OP_IF_LE, 4
  | 0x38 -> OP_IF_EQZ, 4
  | 0x39 -> OP_IF_NEZ, 4
  | 0x3a -> OP_IF_LTZ, 4
  | 0x3b -> OP_IF_GEZ, 4
  | 0x3c -> OP_IF_GTZ, 4
  | 0x3d -> OP_IF_LEZ, 4

  | 0x44 -> OP_AGET, 4
  | 0x45 -> OP_AGET_WIDE, 4
  | 0x46 -> OP_AGET_OBJECT, 4
  | 0x47 -> OP_AGET_BOOLEAN, 4
  | 0x48 -> OP_AGET_BYTE, 4
  | 0x49 -> OP_AGET_CHAR, 4
  | 0x4a -> OP_AGET_SHORT, 4
  | 0x4b -> OP_APUT, 4
  | 0x4c -> OP_APUT_WIDE, 4
  | 0x4d -> OP_APUT_OBJECT, 4
  | 0x4e -> OP_APUT_BOOLEAN, 4
  | 0x4f -> OP_APUT_BYTE, 4
  | 0x50 -> OP_APUT_CHAR, 4
  | 0x51 -> OP_APUT_SHORT, 4

  | 0x52 -> OP_IGET, 4
  | 0x53 -> OP_IGET_WIDE, 4
  | 0x54 -> OP_IGET_OBJECT, 4
  | 0x55 -> OP_IGET_BOOLEAN, 4
  | 0x56 -> OP_IGET_BYTE, 4
  | 0x57 -> OP_IGET_CHAR, 4
  | 0x58 -> OP_IGET_SHORT, 4
  | 0x59 -> OP_IPUT, 4
  | 0x5a -> OP_IPUT_WIDE, 4
  | 0x5b -> OP_IPUT_OBJECT, 4
  | 0x5c -> OP_IPUT_BOOLEAN, 4
  | 0x5d -> OP_IPUT_BYTE, 4
  | 0x5e -> OP_IPUT_CHAR, 4
  | 0x5f -> OP_IPUT_SHORT, 4

  | 0x60 -> OP_SGET, 4
  | 0x61 -> OP_SGET_WIDE, 4
  | 0x62 -> OP_SGET_OBJECT, 4
  | 0x63 -> OP_SGET_BOOLEAN, 4
  | 0x64 -> OP_SGET_BYTE, 4
  | 0x65 -> OP_SGET_CHAR, 4
  | 0x66 -> OP_SGET_SHORT, 4
  | 0x67 -> OP_SPUT, 4
  | 0x68 -> OP_SPUT_WIDE, 4
  | 0x69 -> OP_SPUT_OBJECT, 4
  | 0x6a -> OP_SPUT_BOOLEAN, 4
  | 0x6b -> OP_SPUT_BYTE, 4
  | 0x6c -> OP_SPUT_CHAR, 4
  | 0x6d -> OP_SPUT_SHORT, 4

  | 0x6e -> OP_INVOKE_VIRTUAL, 6
  | 0x6f -> OP_INVOKE_SUPER, 6
  | 0x70 -> OP_INVOKE_DIRECT, 6
  | 0x71 -> OP_INVOKE_STATIC, 6
  | 0x72 -> OP_INVOKE_INTERFACE, 6
    
  | 0x74 -> OP_INVOKE_VIRTUAL_RANGE, 6
  | 0x75 -> OP_INVOKE_SUPER_RANGE, 6
  | 0x76 -> OP_INVOKE_DIRECT_RANGE, 6
  | 0x77 -> OP_INVOKE_STATIC_RANGE, 6
  | 0x78 -> OP_INVOKE_INTERFACE_RANGE, 6

  | 0x7b -> OP_NEG_INT, 2
  | 0x7c -> OP_NOT_INT, 2
  | 0x7d -> OP_NEG_LONG, 2
  | 0x7e -> OP_NOT_LONG, 2
  | 0x7f -> OP_NEG_FLOAT, 2
  | 0x80 -> OP_NEG_DOUBLE, 2
  | 0x81 -> OP_INT_TO_LONG, 2
  | 0x82 -> OP_INT_TO_FLOAT, 2
  | 0x83 -> OP_INT_TO_DOUBLE, 2
  | 0x84 -> OP_LONG_TO_INT, 2
  | 0x85 -> OP_LONG_TO_FLOAT, 2
  | 0x86 -> OP_LONG_TO_DOUBLE, 2
  | 0x87 -> OP_FLOAT_TO_INT, 2
  | 0x88 -> OP_FLOAT_TO_LONG, 2
  | 0x89 -> OP_FLOAT_TO_DOUBLE, 2
  | 0x8a -> OP_DOUBLE_TO_INT, 2
  | 0x8b -> OP_DOUBLE_TO_LONG, 2
  | 0x8c -> OP_DOUBLE_TO_FLOAT, 2
  | 0x8d -> OP_INT_TO_BYTE, 2
  | 0x8e -> OP_INT_TO_CHAR, 2
  | 0x8f -> OP_INT_TO_SHORT, 2

  | 0x90 -> OP_ADD_INT, 4
  | 0x91 -> OP_SUB_INT, 4
  | 0x92 -> OP_MUL_INT, 4
  | 0x93 -> OP_DIV_INT, 4
  | 0x94 -> OP_REM_INT, 4
  | 0x95 -> OP_AND_INT, 4
  | 0x96 -> OP_OR_INT, 4
  | 0x97 -> OP_XOR_INT, 4
  | 0x98 -> OP_SHL_INT, 4
  | 0x99 -> OP_SHR_INT, 4
  | 0x9a -> OP_USHR_INT, 4

  | 0x9b -> OP_ADD_LONG, 4
  | 0x9c -> OP_SUB_LONG, 4
  | 0x9d -> OP_MUL_LONG, 4
  | 0x9e -> OP_DIV_LONG, 4
  | 0x9f -> OP_REM_LONG, 4
  | 0xa0 -> OP_AND_LONG, 4
  | 0xa1 -> OP_OR_LONG, 4
  | 0xa2 -> OP_XOR_LONG, 4
  | 0xa3 -> OP_SHL_LONG, 4
  | 0xa4 -> OP_SHR_LONG, 4
  | 0xa5 -> OP_USHR_LONG, 4

  | 0xa6 -> OP_ADD_FLOAT, 4
  | 0xa7 -> OP_SUB_FLOAT, 4
  | 0xa8 -> OP_MUL_FLOAT, 4
  | 0xa9 -> OP_DIV_FLOAT, 4
  | 0xaa -> OP_REM_FLOAT, 4
  | 0xab -> OP_ADD_DOUBLE, 4
  | 0xac -> OP_SUB_DOUBLE, 4
  | 0xad -> OP_MUL_DOUBLE, 4
  | 0xae -> OP_DIV_DOUBLE, 4
  | 0xaf -> OP_REM_DOUBLE, 4

  | 0xb0 -> OP_ADD_INT_2ADDR, 2
  | 0xb1 -> OP_SUB_INT_2ADDR, 2
  | 0xb2 -> OP_MUL_INT_2ADDR, 2
  | 0xb3 -> OP_DIV_INT_2ADDR, 2
  | 0xb4 -> OP_REM_INT_2ADDR, 2
  | 0xb5 -> OP_AND_INT_2ADDR, 2
  | 0xb6 -> OP_OR_INT_2ADDR, 2
  | 0xb7 -> OP_XOR_INT_2ADDR, 2
  | 0xb8 -> OP_SHL_INT_2ADDR, 2
  | 0xb9 -> OP_SHR_INT_2ADDR, 2
  | 0xba -> OP_USHR_INT_2ADDR, 2

  | 0xbb -> OP_ADD_LONG_2ADDR, 2
  | 0xbc -> OP_SUB_LONG_2ADDR, 2
  | 0xbd -> OP_MUL_LONG_2ADDR, 2
  | 0xbe -> OP_DIV_LONG_2ADDR, 2
  | 0xbf -> OP_REM_LONG_2ADDR, 2
  | 0xc0 -> OP_AND_LONG_2ADDR, 2
  | 0xc1 -> OP_OR_LONG_2ADDR, 2
  | 0xc2 -> OP_XOR_LONG_2ADDR, 2
  | 0xc3 -> OP_SHL_LONG_2ADDR, 2
  | 0xc4 -> OP_SHR_LONG_2ADDR, 2
  | 0xc5 -> OP_USHR_LONG_2ADDR, 2

  | 0xc6 -> OP_ADD_FLOAT_2ADDR, 2
  | 0xc7 -> OP_SUB_FLOAT_2ADDR, 2
  | 0xc8 -> OP_MUL_FLOAT_2ADDR, 2
  | 0xc9 -> OP_DIV_FLOAT_2ADDR, 2
  | 0xca -> OP_REM_FLOAT_2ADDR, 2
  | 0xcb -> OP_ADD_DOUBLE_2ADDR, 2
  | 0xcc -> OP_SUB_DOUBLE_2ADDR, 2
  | 0xcd -> OP_MUL_DOUBLE_2ADDR, 2
  | 0xce -> OP_DIV_DOUBLE_2ADDR, 2
  | 0xcf -> OP_REM_DOUBLE_2ADDR, 2

  | 0xd0 -> OP_ADD_INT_LIT16, 4
  | 0xd1 -> OP_RSUB_INT, 4
  | 0xd2 -> OP_MUL_INT_LIT16, 4
  | 0xd3 -> OP_DIV_INT_LIT16, 4
  | 0xd4 -> OP_REM_INT_LIT16, 4
  | 0xd5 -> OP_AND_INT_LIT16, 4
  | 0xd6 -> OP_OR_INT_LIT16, 4
  | 0xd7 -> OP_XOR_INT_LIT16, 4

  | 0xd8 -> OP_ADD_INT_LIT8, 4
  | 0xd9 -> OP_RSUB_INT_LIT8, 4
  | 0xda -> OP_MUL_INT_LIT8, 4
  | 0xdb -> OP_DIV_INT_LIT8, 4
  | 0xdc -> OP_REM_INT_LIT8, 4
  | 0xdd -> OP_AND_INT_LIT8, 4
  | 0xde -> OP_OR_INT_LIT8, 4
  | 0xdf -> OP_XOR_INT_LIT8, 4
  | 0xe0 -> OP_SHL_INT_LIT8, 4
  | 0xe1 -> OP_SHR_INT_LIT8, 4
  | 0xe2 -> OP_USHR_INT_LIT8, 4

  |    _ -> OP_NOP, 0

(* hx_to_op : int -> opcode *)
let hx_to_op (hx: int) : opcode =
  fst (hx_to_op_and_size hx)

(* op_to_hx_and_size : opcode -> int * int *)
let op_to_hx_and_size (op: opcode) : int * int =
  match op with
  | OP_NOP -> 0x00, 2

  | OP_MOVE               -> 0x01, 2
  | OP_MOVE_FROM16        -> 0x02, 4
  | OP_MOVE_16            -> 0x03, 6
  | OP_MOVE_WIDE          -> 0x04, 2
  | OP_MOVE_WIDE_FROM16   -> 0x05, 4
  | OP_MOVE_WIDE_16       -> 0x06, 6
  | OP_MOVE_OBJECT        -> 0x07, 2
  | OP_MOVE_OBJECT_FROM16 -> 0x08, 4
  | OP_MOVE_OBJECT_16     -> 0x09, 6

  | OP_MOVE_RESULT        -> 0x0a, 2
  | OP_MOVE_RESULT_WIDE   -> 0x0b, 2
  | OP_MOVE_RESULT_OBJECT -> 0x0c, 2
  | OP_MOVE_EXCEPTION     -> 0x0d, 2

  | OP_RETURN_VOID   -> 0x0e, 2
  | OP_RETURN        -> 0x0f, 2
  | OP_RETURN_WIDE   -> 0x10, 2
  | OP_RETURN_OBJECT -> 0x11, 2

  | OP_CONST_4            -> 0x12, 2
  | OP_CONST_16           -> 0x13, 4
  | OP_CONST              -> 0x14, 6
  | OP_CONST_HIGH16       -> 0x15, 4
  | OP_CONST_WIDE_16      -> 0x16, 4
  | OP_CONST_WIDE_32      -> 0x17, 6
  | OP_CONST_WIDE         -> 0x18, 10
  | OP_CONST_WIDE_HIGH16  -> 0x19, 4
  | OP_CONST_STRING       -> 0x1a, 4
  | OP_CONST_STRING_JUMBO -> 0x1b, 6
  | OP_CONST_CLASS        -> 0x1c, 4

  | OP_MONITOR_ENTER -> 0x1d, 2
  | OP_MONITOR_EXIT  -> 0x1e, 2

  | OP_CHECK_CAST  -> 0x1f, 4
  | OP_INSTANCE_OF -> 0x20, 4

  | OP_ARRAY_LENGTH -> 0x21, 2

  | OP_NEW_INSTANCE -> 0x22, 4
  | OP_NEW_ARRAY -> 0x23, 4

  | OP_FILLED_NEW_ARRAY       -> 0x24, 6
  | OP_FILLED_NEW_ARRAY_RANGE -> 0x25, 6
  | OP_FILL_ARRAY_DATA        -> 0x26, 6
    
  | OP_THROW -> 0x27, 2
  | OP_GOTO  -> 0x28, 2
  | OP_GOTO_16 -> 0x29, 4
  | OP_GOTO_32 -> 0x2a, 6
  | OP_PACKED_SWITCH -> 0x2b, 6
  | OP_SPARSE_SWITCH -> 0x2c, 6
    
  | OP_CMPL_FLOAT  -> 0x2d, 4
  | OP_CMPG_FLOAT  -> 0x2e, 4
  | OP_CMPL_DOUBLE -> 0x2f, 4
  | OP_CMPG_DOUBLE -> 0x30, 4
  | OP_CMP_LONG    -> 0x31, 4

  | OP_IF_EQ  -> 0x32, 4
  | OP_IF_NE  -> 0x33, 4
  | OP_IF_LT  -> 0x34, 4
  | OP_IF_GE  -> 0x35, 4
  | OP_IF_GT  -> 0x36, 4
  | OP_IF_LE  -> 0x37, 4
  | OP_IF_EQZ -> 0x38, 4
  | OP_IF_NEZ -> 0x39, 4
  | OP_IF_LTZ -> 0x3a, 4
  | OP_IF_GEZ -> 0x3b, 4
  | OP_IF_GTZ -> 0x3c, 4
  | OP_IF_LEZ -> 0x3d, 4

  | OP_AGET         -> 0x44, 4
  | OP_AGET_WIDE    -> 0x45, 4
  | OP_AGET_OBJECT  -> 0x46, 4
  | OP_AGET_BOOLEAN -> 0x47, 4
  | OP_AGET_BYTE    -> 0x48, 4
  | OP_AGET_CHAR    -> 0x49, 4
  | OP_AGET_SHORT   -> 0x4a, 4
  | OP_APUT         -> 0x4b, 4
  | OP_APUT_WIDE    -> 0x4c, 4
  | OP_APUT_OBJECT  -> 0x4d, 4
  | OP_APUT_BOOLEAN -> 0x4e, 4
  | OP_APUT_BYTE    -> 0x4f, 4
  | OP_APUT_CHAR    -> 0x50, 4
  | OP_APUT_SHORT   -> 0x51, 4

  | OP_IGET         -> 0x52, 4
  | OP_IGET_WIDE    -> 0x53, 4
  | OP_IGET_OBJECT  -> 0x54, 4
  | OP_IGET_BOOLEAN -> 0x55, 4
  | OP_IGET_BYTE    -> 0x56, 4
  | OP_IGET_CHAR    -> 0x57, 4
  | OP_IGET_SHORT   -> 0x58, 4
  | OP_IPUT         -> 0x59, 4
  | OP_IPUT_WIDE    -> 0x5a, 4
  | OP_IPUT_OBJECT  -> 0x5b, 4
  | OP_IPUT_BOOLEAN -> 0x5c, 4
  | OP_IPUT_BYTE    -> 0x5d, 4
  | OP_IPUT_CHAR    -> 0x5e, 4
  | OP_IPUT_SHORT   -> 0x5f, 4

  | OP_SGET         -> 0x60, 4
  | OP_SGET_WIDE    -> 0x61, 4
  | OP_SGET_OBJECT  -> 0x62, 4
  | OP_SGET_BOOLEAN -> 0x63, 4
  | OP_SGET_BYTE    -> 0x64, 4
  | OP_SGET_CHAR    -> 0x65, 4
  | OP_SGET_SHORT   -> 0x66, 4
  | OP_SPUT         -> 0x67, 4
  | OP_SPUT_WIDE    -> 0x68, 4
  | OP_SPUT_OBJECT  -> 0x69, 4
  | OP_SPUT_BOOLEAN -> 0x6a, 4
  | OP_SPUT_BYTE    -> 0x6b, 4
  | OP_SPUT_CHAR    -> 0x6c, 4
  | OP_SPUT_SHORT   -> 0x6d, 4

  | OP_INVOKE_VIRTUAL   -> 0x6e, 6
  | OP_INVOKE_SUPER     -> 0x6f, 6
  | OP_INVOKE_DIRECT    -> 0x70, 6
  | OP_INVOKE_STATIC    -> 0x71, 6
  | OP_INVOKE_INTERFACE -> 0x72, 6
    
  | OP_INVOKE_VIRTUAL_RANGE   -> 0x74, 6
  | OP_INVOKE_SUPER_RANGE     -> 0x75, 6
  | OP_INVOKE_DIRECT_RANGE    -> 0x76, 6
  | OP_INVOKE_STATIC_RANGE    -> 0x77, 6
  | OP_INVOKE_INTERFACE_RANGE -> 0x78, 6

  | OP_NEG_INT         -> 0x7b, 2
  | OP_NOT_INT         -> 0x7c, 2
  | OP_NEG_LONG        -> 0x7d, 2
  | OP_NOT_LONG        -> 0x7e, 2
  | OP_NEG_FLOAT       -> 0x7f, 2
  | OP_NEG_DOUBLE      -> 0x80, 2
  | OP_INT_TO_LONG     -> 0x81, 2
  | OP_INT_TO_FLOAT    -> 0x82, 2
  | OP_INT_TO_DOUBLE   -> 0x83, 2
  | OP_LONG_TO_INT     -> 0x84, 2
  | OP_LONG_TO_FLOAT   -> 0x85, 2
  | OP_LONG_TO_DOUBLE  -> 0x86, 2
  | OP_FLOAT_TO_INT    -> 0x87, 2
  | OP_FLOAT_TO_LONG   -> 0x88, 2
  | OP_FLOAT_TO_DOUBLE -> 0x89, 2
  | OP_DOUBLE_TO_INT   -> 0x8a, 2
  | OP_DOUBLE_TO_LONG  -> 0x8b, 2
  | OP_DOUBLE_TO_FLOAT -> 0x8c, 2
  | OP_INT_TO_BYTE     -> 0x8d, 2
  | OP_INT_TO_CHAR     -> 0x8e, 2
  | OP_INT_TO_SHORT    -> 0x8f, 2

  | OP_ADD_INT  -> 0x90, 4
  | OP_SUB_INT  -> 0x91, 4
  | OP_MUL_INT  -> 0x92, 4
  | OP_DIV_INT  -> 0x93, 4
  | OP_REM_INT  -> 0x94, 4
  | OP_AND_INT  -> 0x95, 4
  | OP_OR_INT   -> 0x96, 4
  | OP_XOR_INT  -> 0x97, 4
  | OP_SHL_INT  -> 0x98, 4
  | OP_SHR_INT  -> 0x99, 4
  | OP_USHR_INT -> 0x9a, 4

  | OP_ADD_LONG  -> 0x9b, 4
  | OP_SUB_LONG  -> 0x9c, 4
  | OP_MUL_LONG  -> 0x9d, 4
  | OP_DIV_LONG  -> 0x9e, 4
  | OP_REM_LONG  -> 0x9f, 4
  | OP_AND_LONG  -> 0xa0, 4
  | OP_OR_LONG   -> 0xa1, 4
  | OP_XOR_LONG  -> 0xa2, 4
  | OP_SHL_LONG  -> 0xa3, 4
  | OP_SHR_LONG  -> 0xa4, 4
  | OP_USHR_LONG -> 0xa5, 4

  | OP_ADD_FLOAT  -> 0xa6, 4
  | OP_SUB_FLOAT  -> 0xa7, 4
  | OP_MUL_FLOAT  -> 0xa8, 4
  | OP_DIV_FLOAT  -> 0xa9, 4
  | OP_REM_FLOAT  -> 0xaa, 4
  | OP_ADD_DOUBLE -> 0xab, 4
  | OP_SUB_DOUBLE -> 0xac, 4
  | OP_MUL_DOUBLE -> 0xad, 4
  | OP_DIV_DOUBLE -> 0xae, 4
  | OP_REM_DOUBLE -> 0xaf, 4

  | OP_ADD_INT_2ADDR  -> 0xb0, 2
  | OP_SUB_INT_2ADDR  -> 0xb1, 2
  | OP_MUL_INT_2ADDR  -> 0xb2, 2
  | OP_DIV_INT_2ADDR  -> 0xb3, 2
  | OP_REM_INT_2ADDR  -> 0xb4, 2
  | OP_AND_INT_2ADDR  -> 0xb5, 2
  | OP_OR_INT_2ADDR   -> 0xb6, 2
  | OP_XOR_INT_2ADDR  -> 0xb7, 2
  | OP_SHL_INT_2ADDR  -> 0xb8, 2
  | OP_SHR_INT_2ADDR  -> 0xb9, 2
  | OP_USHR_INT_2ADDR -> 0xba, 2

  | OP_ADD_LONG_2ADDR  -> 0xbb, 2
  | OP_SUB_LONG_2ADDR  -> 0xbc, 2
  | OP_MUL_LONG_2ADDR  -> 0xbd, 2
  | OP_DIV_LONG_2ADDR  -> 0xbe, 2
  | OP_REM_LONG_2ADDR  -> 0xbf, 2
  | OP_AND_LONG_2ADDR  -> 0xc0, 2
  | OP_OR_LONG_2ADDR   -> 0xc1, 2
  | OP_XOR_LONG_2ADDR  -> 0xc2, 2
  | OP_SHL_LONG_2ADDR  -> 0xc3, 2
  | OP_SHR_LONG_2ADDR  -> 0xc4, 2
  | OP_USHR_LONG_2ADDR -> 0xc5, 2

  | OP_ADD_FLOAT_2ADDR  -> 0xc6, 2
  | OP_SUB_FLOAT_2ADDR  -> 0xc7, 2
  | OP_MUL_FLOAT_2ADDR  -> 0xc8, 2
  | OP_DIV_FLOAT_2ADDR  -> 0xc9, 2
  | OP_REM_FLOAT_2ADDR  -> 0xca, 2
  | OP_ADD_DOUBLE_2ADDR -> 0xcb, 2
  | OP_SUB_DOUBLE_2ADDR -> 0xcc, 2
  | OP_MUL_DOUBLE_2ADDR -> 0xcd, 2
  | OP_DIV_DOUBLE_2ADDR -> 0xce, 2
  | OP_REM_DOUBLE_2ADDR -> 0xcf, 2

  | OP_ADD_INT_LIT16 -> 0xd0, 4
  | OP_RSUB_INT      -> 0xd1, 4
  | OP_MUL_INT_LIT16 -> 0xd2, 4
  | OP_DIV_INT_LIT16 -> 0xd3, 4
  | OP_REM_INT_LIT16 -> 0xd4, 4
  | OP_AND_INT_LIT16 -> 0xd5, 4
  | OP_OR_INT_LIT16  -> 0xd6, 4
  | OP_XOR_INT_LIT16 -> 0xd7, 4

  | OP_ADD_INT_LIT8  -> 0xd8, 4
  | OP_RSUB_INT_LIT8 -> 0xd9, 4
  | OP_MUL_INT_LIT8  -> 0xda, 4
  | OP_DIV_INT_LIT8  -> 0xdb, 4
  | OP_REM_INT_LIT8  -> 0xdc, 4
  | OP_AND_INT_LIT8  -> 0xdd, 4
  | OP_OR_INT_LIT8   -> 0xde, 4
  | OP_XOR_INT_LIT8  -> 0xdf, 4
  | OP_SHL_INT_LIT8  -> 0xe0, 4
  | OP_SHR_INT_LIT8  -> 0xe1, 4
  | OP_USHR_INT_LIT8 -> 0xe2, 4

(* op_to_hx: opcode -> int *)
let op_to_hx (op: opcode) : int =
  fst (op_to_hx_and_size op)

type link_sort =
  | STRING_IDS
  | TYPE_IDS
  | FIELD_IDS
  | METHOD_IDS
  | OFFSET
  | NOT_LINK

(* access_link : opcode -> link_sort *)
let access_link (op: opcode) : link_sort =
  let hx = op_to_hx op in
  if L.mem hx [0x1a; 0x1b] then STRING_IDS
  else if L.mem hx [0x1c; 0x1f; 0x20]
  || 0x22 <= hx && hx <= 0x25 then TYPE_IDS
  else if 0x52 <= hx && hx <= 0x6d then FIELD_IDS
  else if 0x6e <= hx && hx <= 0x78 && hx <> 0x73 then METHOD_IDS
  else if 0x26 <= hx && hx <= 0x2c && hx <> 0x27
  || 0x32 <= hx && hx <= 0x3d then OFFSET
  else NOT_LINK

(* low_reg : opcode -> int *)
let low_reg (op: opcode) : int =
  match op with
  | OP_INVOKE_VIRTUAL -> 16
  | _ -> -1 (* TODO: not yet *)

(* get_argv : instr -> operand list *)
let get_argv (ins: instr) : operand list =
  let op, opr = ins in
  match access_link op with
  | METHOD_IDS ->
  (
    let argv = L.rev (L.tl (L.rev opr))
    and hx = op_to_hx op in
    if 0x6e <= hx && hx <= 0x72 then argv (* normal *)
    else if 0x74 <= hx && hx <= 0x78 then (* range *)
      let (OPR_REGISTER fst_arg)::(OPR_REGISTER last_arg)::[] = argv in
      L.map (fun i -> OPR_REGISTER i) (U.range fst_arg last_arg [])
    else []
  )
  | _ -> []

(***********************************************************************)
(* Parsing                                                             *)
(***********************************************************************)

(* make_instr : opcode -> int list -> instr *)
let make_instr (op: opcode) (args: int list) : instr =
  let to_sign4  x = if (x land 0x8)    <> 0 then x - 0x10    else x
  and to_sign8  x = if (x land 0x80)   <> 0 then x - 0x100   else x
  and to_sign16 x = if (x land 0x8000) <> 0 then x - 0x10000 else x
  in
  let opr4 i = (i land 0x0f), (i lsr 4)
  and opr16u l h = (h lsl  8) lor l in
  let opr16  l h = to_sign16 (opr16u l h)
  and opr32  l h = (h lsl 16) lor l
  and opr32u l h = I64.logor (I64.shift_left (to_i64 h) 16) (to_i64 l)
  in
  let f_10x () = []
  and f_12x () =
    let ba::[] = args in
    let a,b = opr4 ba in [OPR_REGISTER a; OPR_REGISTER b]
  and f_11n () =
    let ba::[] = args in
    let a,b = opr4 ba in [OPR_REGISTER a; OPR_CONST (to_i64 (to_sign4 b))]
  and f_11x () =
    let aa::[] = args in [OPR_REGISTER aa]
  and f_10t () =
    let aa::[] = args in [OPR_OFFSET (to_i32 (to_sign8 aa))]
  and f_20t () =
    let _::al::ah::[] = args in
    let a = opr16 al ah in [OPR_OFFSET (to_i32 a)]
  and f_22x () =
    let aa::bl::bh::[] = args in
    let b = opr16 bl bh in [OPR_REGISTER aa; OPR_REGISTER b]
  and f_21t () =
    let aa::bl::bh::[] = args in
    let b = opr16 bl bh in [OPR_REGISTER aa; OPR_OFFSET (to_i32 b)]
  and f_21s () =
    let aa::bl::bh::[] = args in
    let b = opr16 bl bh in [OPR_REGISTER aa; OPR_CONST (to_i64 b)]
  and f_21h () =
    let aa::bl::bh::[] = args in
    let b = opr16 bl bh in [OPR_REGISTER aa; OPR_CONST (to_i64 b)]
  and f_21c () =
    let aa::bl::bh::[] = args in
    let b = opr16u bl bh in [OPR_REGISTER aa; OPR_INDEX b]
  and f_23x () =
    let aa::bb::cc::[] = args in
    [OPR_REGISTER aa; OPR_REGISTER bb; OPR_REGISTER cc]
  and f_22b () =
    let aa::bb::cc::[] = args in
    [OPR_REGISTER aa; OPR_REGISTER bb; OPR_CONST (to_i64 cc)]
  and f_22t () =
    let ba::cl::ch::[] = args in
    let a,b = opr4 ba and c = opr16 cl ch in
    [OPR_REGISTER a; OPR_REGISTER b; OPR_OFFSET (to_i32 c)]
  and f_22s () =
    let ba::cl::ch::[] = args in
    let a,b = opr4 ba and c = opr16 cl ch in
    [OPR_REGISTER a; OPR_REGISTER b; OPR_CONST (to_i64 c)]
  and f_22c () =
    let ba::cl::ch::[] = args in
    let a,b = opr4 ba and c = opr16u cl ch in
    [OPR_REGISTER a; OPR_REGISTER b; OPR_INDEX c]
  and f_30t () =
    let _::all::alh::ahl::ahh::[] = args in
    let al = opr16u all alh and ah = opr16u ahl ahh in
    let a = opr32 al ah in [OPR_OFFSET (to_i32 a)]
  and f_32x () =
    let _::al::ah::bl::bh::[] = args in
    let a = opr16 al ah and b = opr16 bl bh in
    [OPR_REGISTER a; OPR_REGISTER b]
  and f_31i () =
    let aa::bll::blh::bhl::bhh::[] = args in
    let bl = opr16u bll blh and bh = opr16u bhl bhh in
    let b = opr32u bl bh in [OPR_REGISTER aa; OPR_CONST b]
  and f_31t () =
    let aa::bll::blh::bhl::bhh::[] = args in
    let bl = opr16u bll blh and bh = opr16u bhl bhh in
    let b = opr32 bl bh in [OPR_REGISTER aa; OPR_OFFSET (to_i32 b)]
  and f_31c () =
    let aa::bll::blh::bhl::bhh::[] = args in
    let bl = opr16u bll blh and bh = opr16u bhl bhh in
    let b = opr32 bl bh in [OPR_REGISTER aa; OPR_INDEX b]
  and f_35c () =
    let ba::cl::ch::ed::gf::[] = args in
    let a,b = opr4 ba and   c = opr16u cl ch
    and d,e = opr4 ed and f,g = opr4 gf in
    let iC = OPR_INDEX c    and vD = OPR_REGISTER d
    and vE = OPR_REGISTER e and vF = OPR_REGISTER f
    and vG = OPR_REGISTER g and vA = OPR_REGISTER a in
    (
      match b with
      | 0 -> [iC]
      | 1 -> [vD; iC]
      | 2 -> [vD; vE; iC]
      | 3 -> [vD; vE; vF; iC]
      | 4 -> [vD; vE; vF; vG; iC]
      | 5 -> [vD; vE; vF; vG; vA; iC]
      | _ -> []
    )
  and f_3rc () =
    let aa::bl::bh::cl::ch::[] = args in
    let b = opr16u bl bh and c = opr16 cl ch in
    let n = c + aa - 1 in [OPR_REGISTER c; OPR_REGISTER n; OPR_INDEX b]
  and f_51l () =
    let aa::b1l::b1h::b2l::b2h::b3l::b3h::b4l::b4h::[] = args in
    let b1 = opr16u b1l b1h and b2 = opr16u b2l b2h
    and b3 = opr16u b3l b3h and b4 = opr16u b4l b4h in
    let b12 = opr32u b1 b2 and b34 = opr32u b3 b4 in
    let b = I64.logor (I64.shift_left b34 32) b12 in
    [OPR_REGISTER aa; OPR_CONST b]
  in
  op, match op with 
  | OP_NOP
  | OP_RETURN_VOID             -> f_10x ()

  | OP_MOVE
  | OP_MOVE_WIDE
  | OP_MOVE_OBJECT

  | OP_ARRAY_LENGTH

  | OP_NEG_INT
  | OP_NOT_INT
  | OP_NEG_LONG
  | OP_NOT_LONG
  | OP_NEG_FLOAT
  | OP_NEG_DOUBLE
  | OP_INT_TO_LONG
  | OP_INT_TO_FLOAT
  | OP_INT_TO_DOUBLE
  | OP_LONG_TO_INT
  | OP_LONG_TO_FLOAT
  | OP_LONG_TO_DOUBLE
  | OP_FLOAT_TO_INT
  | OP_FLOAT_TO_LONG
  | OP_FLOAT_TO_DOUBLE
  | OP_DOUBLE_TO_INT
  | OP_DOUBLE_TO_LONG
  | OP_DOUBLE_TO_FLOAT
  | OP_INT_TO_BYTE
  | OP_INT_TO_CHAR
  | OP_INT_TO_SHORT

  | OP_ADD_INT_2ADDR
  | OP_SUB_INT_2ADDR
  | OP_MUL_INT_2ADDR
  | OP_DIV_INT_2ADDR
  | OP_REM_INT_2ADDR
  | OP_AND_INT_2ADDR
  | OP_OR_INT_2ADDR
  | OP_XOR_INT_2ADDR
  | OP_SHL_INT_2ADDR
  | OP_SHR_INT_2ADDR
  | OP_USHR_INT_2ADDR

  | OP_ADD_LONG_2ADDR
  | OP_SUB_LONG_2ADDR
  | OP_MUL_LONG_2ADDR
  | OP_DIV_LONG_2ADDR
  | OP_REM_LONG_2ADDR
  | OP_AND_LONG_2ADDR
  | OP_OR_LONG_2ADDR
  | OP_XOR_LONG_2ADDR
  | OP_SHL_LONG_2ADDR
  | OP_SHR_LONG_2ADDR
  | OP_USHR_LONG_2ADDR

  | OP_ADD_FLOAT_2ADDR
  | OP_SUB_FLOAT_2ADDR
  | OP_MUL_FLOAT_2ADDR
  | OP_DIV_FLOAT_2ADDR
  | OP_REM_FLOAT_2ADDR
  | OP_ADD_DOUBLE_2ADDR
  | OP_SUB_DOUBLE_2ADDR
  | OP_MUL_DOUBLE_2ADDR
  | OP_DIV_DOUBLE_2ADDR
  | OP_REM_DOUBLE_2ADDR        -> f_12x ()

  | OP_CONST_4                 -> f_11n ()

  | OP_MOVE_RESULT
  | OP_MOVE_RESULT_WIDE
  | OP_MOVE_RESULT_OBJECT
  | OP_MOVE_EXCEPTION

  | OP_RETURN
  | OP_RETURN_WIDE
  | OP_RETURN_OBJECT

  | OP_MONITOR_ENTER
  | OP_MONITOR_EXIT

  | OP_THROW                   -> f_11x ()

  | OP_MOVE_FROM16
  | OP_MOVE_WIDE_FROM16
  | OP_MOVE_OBJECT_FROM16      -> f_22x ()

  | OP_IF_EQZ
  | OP_IF_NEZ
  | OP_IF_LTZ
  | OP_IF_GEZ
  | OP_IF_GTZ
  | OP_IF_LEZ                  -> f_21t ()

  | OP_CONST_16
  | OP_CONST_WIDE_16
  | OP_CONST_HIGH16            -> f_21s ()

  | OP_CONST_WIDE_HIGH16       -> f_21h ()

  | OP_CONST_STRING
  | OP_CONST_CLASS

  | OP_CHECK_CAST

  | OP_NEW_INSTANCE

  | OP_SGET
  | OP_SGET_WIDE
  | OP_SGET_OBJECT
  | OP_SGET_BOOLEAN
  | OP_SGET_BYTE
  | OP_SGET_CHAR
  | OP_SGET_SHORT
  | OP_SPUT
  | OP_SPUT_WIDE
  | OP_SPUT_OBJECT
  | OP_SPUT_BOOLEAN
  | OP_SPUT_BYTE
  | OP_SPUT_CHAR
  | OP_SPUT_SHORT              -> f_21c ()

  | OP_CMPL_FLOAT
  | OP_CMPG_FLOAT
  | OP_CMPL_DOUBLE
  | OP_CMPG_DOUBLE
  | OP_CMP_LONG

  | OP_AGET
  | OP_AGET_WIDE
  | OP_AGET_OBJECT
  | OP_AGET_BOOLEAN
  | OP_AGET_BYTE
  | OP_AGET_CHAR
  | OP_AGET_SHORT
  | OP_APUT
  | OP_APUT_WIDE
  | OP_APUT_OBJECT
  | OP_APUT_BOOLEAN
  | OP_APUT_BYTE
  | OP_APUT_CHAR
  | OP_APUT_SHORT

  | OP_ADD_INT
  | OP_SUB_INT
  | OP_MUL_INT
  | OP_DIV_INT
  | OP_REM_INT
  | OP_AND_INT
  | OP_OR_INT
  | OP_XOR_INT
  | OP_SHL_INT
  | OP_SHR_INT
  | OP_USHR_INT

  | OP_ADD_LONG
  | OP_SUB_LONG
  | OP_MUL_LONG
  | OP_DIV_LONG
  | OP_REM_LONG
  | OP_AND_LONG
  | OP_OR_LONG
  | OP_XOR_LONG
  | OP_SHL_LONG
  | OP_SHR_LONG
  | OP_USHR_LONG

  | OP_ADD_FLOAT
  | OP_SUB_FLOAT
  | OP_MUL_FLOAT
  | OP_DIV_FLOAT
  | OP_REM_FLOAT
  | OP_ADD_DOUBLE
  | OP_SUB_DOUBLE
  | OP_MUL_DOUBLE
  | OP_DIV_DOUBLE
  | OP_REM_DOUBLE              -> f_23x ()

  | OP_ADD_INT_LIT8
  | OP_RSUB_INT_LIT8
  | OP_MUL_INT_LIT8
  | OP_DIV_INT_LIT8
  | OP_REM_INT_LIT8
  | OP_AND_INT_LIT8
  | OP_OR_INT_LIT8
  | OP_XOR_INT_LIT8
  | OP_SHL_INT_LIT8
  | OP_SHR_INT_LIT8
  | OP_USHR_INT_LIT8           -> f_22b ()

  | OP_IF_EQ
  | OP_IF_NE
  | OP_IF_LT
  | OP_IF_GE
  | OP_IF_GT
  | OP_IF_LE                   -> f_22t ()

  | OP_ADD_INT_LIT16
  | OP_RSUB_INT
  | OP_MUL_INT_LIT16
  | OP_DIV_INT_LIT16
  | OP_REM_INT_LIT16
  | OP_AND_INT_LIT16
  | OP_OR_INT_LIT16
  | OP_XOR_INT_LIT16           -> f_22s ()

  | OP_INSTANCE_OF

  | OP_NEW_ARRAY

  | OP_IGET
  | OP_IGET_WIDE
  | OP_IGET_OBJECT
  | OP_IGET_BOOLEAN
  | OP_IGET_BYTE
  | OP_IGET_CHAR
  | OP_IGET_SHORT
  | OP_IPUT
  | OP_IPUT_WIDE
  | OP_IPUT_OBJECT
  | OP_IPUT_BOOLEAN
  | OP_IPUT_BYTE
  | OP_IPUT_CHAR
  | OP_IPUT_SHORT              -> f_22c ()

  | OP_MOVE_16
  | OP_MOVE_WIDE_16
  | OP_MOVE_OBJECT_16          -> f_32x ()

  | OP_CONST
  | OP_CONST_WIDE_32           -> f_31i ()

  | OP_FILL_ARRAY_DATA

  | OP_PACKED_SWITCH
  | OP_SPARSE_SWITCH           -> f_31t ()

  | OP_CONST_STRING_JUMBO      -> f_31c ()

  | OP_FILLED_NEW_ARRAY

  | OP_INVOKE_VIRTUAL
  | OP_INVOKE_SUPER
  | OP_INVOKE_DIRECT
  | OP_INVOKE_STATIC
  | OP_INVOKE_INTERFACE        -> f_35c ()

  | OP_FILLED_NEW_ARRAY_RANGE

  | OP_INVOKE_VIRTUAL_RANGE
  | OP_INVOKE_SUPER_RANGE
  | OP_INVOKE_DIRECT_RANGE
  | OP_INVOKE_STATIC_RANGE
  | OP_INVOKE_INTERFACE_RANGE  -> f_3rc ()

  | OP_GOTO                    -> f_10t ()
  | OP_GOTO_16                 -> f_20t ()
  | OP_GOTO_32                 -> f_30t ()

  | OP_CONST_WIDE              -> f_51l ()

(***********************************************************************)
(* Dumping                                                             *)
(***********************************************************************)

let (@@) l1 l2 = L.rev_append (L.rev l1) l2

(* instr_to_bytes : int -> instr -> char list *)
let instr_to_bytes (base: int) (ins: instr) : char list =
  let rel off = ((of_i32 off) - base) / 2
  in
  let rec w8 i = char_of_int i
  and w16 i =
    let i = i land 0x0000ffff in
    let l = i land 0x000000ff and h = i lsr  8 in
    w8 l :: w8 h :: []
  and w32 i =
    let l = i land 0x0000ffff and h = i lsr 16 in
    w16 l @@ w16 h
  and w32u i =
    let l = I64.logand i (I64.of_string "0x0000ffff")
    and h = I64.shift_right_logical i 16 in
    w16 (of_i64 l) @@ w16 (of_i64 h)
  and w64 i =
    let l = I64.logand i (I64.of_string "0xffffffff")
    and h = I64.shift_right_logical i 32 in
    w32u l @@ w32u h
  in
  let or_ing l = w16 (L.fold_left (lor) 0 l)
  in
  let get4  i = i land 0x000f
  and get8  i = i land 0x00ff
  and get16 i = i land 0xffff
  in
  let op, _ = op_to_hx_and_size (fst ins)
  in
  let f_10x () = w16 op
  and f_12x opr = let vA::vB::[] = opr in
    match vA, vB with OPR_REGISTER a, OPR_REGISTER b ->
    or_ing [(get4 b) lsl 12; (get4 a) lsl 8; op]
  and f_11n opr = let vA::cB::[] = opr in
    match vA, cB with OPR_REGISTER a, OPR_CONST b ->
    or_ing [(get4 (of_i64 b)) lsl 12; (get4 a) lsl 8; op]
  and f_11x opr = let vAA::[] = opr in
    match vAA with OPR_REGISTER aa ->
    or_ing [(get8 aa) lsl 8; op]
  and f_10t opr = let oAA::[] = opr in
    match oAA with OPR_OFFSET a ->
    let off = rel a in
    let uff = if off < 0 then off lor 0x80 else off in
    or_ing [(get8 uff) lsl 8; op]
  and f_20t opr = let oAA::[] = opr in
    match oAA with OPR_OFFSET a ->
    w16 op @@ w16 (rel a)
  and f_22x opr = let vAA::vB4::[] = opr in
    match vAA, vB4 with OPR_REGISTER a, OPR_REGISTER b ->
    or_ing [(get8 a) lsl 8; op] @@ w16 b
  and f_21t opr = let vAA::oB4::[] = opr in
    match vAA, oB4 with OPR_REGISTER a, OPR_OFFSET b ->
    or_ing [(get8 a) lsl 8; op] @@ w16 (rel b)
  and f_21s opr = let vAA::cB4::[] = opr in
    match vAA, cB4 with OPR_REGISTER a, OPR_CONST b ->
    or_ing [(get8 a) lsl 8; op] @@ w16 (of_i64 b)
  and f_21h opr = let vAA::cB4::[] = opr in
    match vAA, cB4 with OPR_REGISTER a, OPR_CONST b ->
    or_ing [(get8 a) lsl 8; op] @@ w16 (of_i64 b)
  and f_21c opr = let vAA::iB4::[] = opr in
    match vAA, iB4 with OPR_REGISTER a, OPR_INDEX b ->
    or_ing [(get8 a) lsl 8; op] @@ w16 b
  and f_23x opr = let vAA::vBB::vCC::[] = opr in
    match vAA, vBB, vCC with OPR_REGISTER a, OPR_REGISTER b, OPR_REGISTER c ->
    or_ing [(get8 a) lsl 8; op] @@ or_ing [(get8 c) lsl 8; get8 b]
  and f_22b opr = let vAA::vBB::cCC::[] = opr in
    match vAA, vBB, cCC with OPR_REGISTER a, OPR_REGISTER b, OPR_CONST c ->
    or_ing [(get8 a) lsl 8; op] @@ or_ing [(get8 (of_i64 c)) lsl 8; get8 b]
  and f_22t opr = let vA::vB::oC4::[] = opr in
    match vA, vB, oC4 with OPR_REGISTER a, OPR_REGISTER b, OPR_OFFSET c ->
    or_ing [(get4 b) lsl 12; (get4 a) lsl 8; op] @@ w16 (rel c)
  and f_22s opr = let vA::vB::cC4::[] = opr in
    match vA, vB, cC4 with OPR_REGISTER a, OPR_REGISTER b, OPR_CONST c ->
    or_ing [(get4 b) lsl 12; (get4 a) lsl 8; op] @@ w16 (of_i64 c)
  and f_22c opr = let vA::vB::iC4::[] = opr in
    match vA, vB, iC4 with OPR_REGISTER a, OPR_REGISTER b, OPR_INDEX c ->
    or_ing [(get4 b) lsl 12; (get4 a) lsl 8; op] @@ w16 c
  and f_30t opr = let oA8::[] = opr in
    match oA8 with OPR_OFFSET a ->
    w16 op @@ w32 (rel a)
  and f_32x opr = let vA4::vB4::[] = opr in
    match vA4, vB4 with OPR_REGISTER a, OPR_REGISTER b ->
    w16 op @@ w16 a @@ w16 b
  and f_31i opr = let vAA::cB8::[] = opr in
    match vAA, cB8 with OPR_REGISTER a, OPR_CONST b ->
    or_ing [(get8 a) lsl 8; op] @@ w32u b
  and f_31t opr = let vAA::oB8::[] = opr in
    match vAA, oB8 with OPR_REGISTER a, OPR_OFFSET b ->
    or_ing [(get8 a) lsl 8; op] @@ w32 (rel b)
  and f_31c opr = let vAA::iB8::[] = opr in
    match vAA, iB8 with OPR_REGISTER a, OPR_INDEX b ->
    or_ing [(get8 a) lsl 8; op] @@ w32 b
  and f_35c opr =
    let b = (L.length opr) - 1 in
    let gr i = match L.nth opr i with OPR_REGISTER r -> r in
    let d, e, f, g, a = match b with
    | 0 -> 0, 0, 0, 0, 0
    | 1 -> gr 0, 0, 0, 0, 0
    | 2 -> gr 0, gr 1, 0, 0, 0
    | 3 -> gr 0, gr 1, gr 2, 0, 0
    | 4 -> gr 0, gr 1, gr 2, gr 3, 0
    | 5 -> gr 0, gr 1, gr 2, gr 3, gr 4
    and c4 = match L.nth opr b with OPR_INDEX c -> c in
    or_ing [(get4 b) lsl 12; (get4 a) lsl 8; op] @@ w16 c4 @@
    or_ing [(get4 g) lsl 12; (get4 f) lsl 8; (get4 e) lsl 4; get4 d]
  and f_3rc opr = let vAA::vNN::iB4::[] = opr in
    match vAA, vNN, iB4 with OPR_REGISTER c, OPR_REGISTER n, OPR_INDEX b ->
    or_ing [(get8 (n + 1 - c)) lsl 8; op] @@ w16 b @@ w16 c
  and f_51l opr = let vAA::cB16::[] = opr in
    match vAA, cB16 with OPR_REGISTER a, OPR_CONST b ->
    or_ing [(get8 a) lsl 8; op] @@ w64 b
  in
  let op, opr = ins in
  match op with
  | OP_NOP
  | OP_RETURN_VOID             -> f_10x ()

  | OP_MOVE
  | OP_MOVE_WIDE
  | OP_MOVE_OBJECT

  | OP_ARRAY_LENGTH

  | OP_NEG_INT
  | OP_NOT_INT
  | OP_NEG_LONG
  | OP_NOT_LONG
  | OP_NEG_FLOAT
  | OP_NEG_DOUBLE
  | OP_INT_TO_LONG
  | OP_INT_TO_FLOAT
  | OP_INT_TO_DOUBLE
  | OP_LONG_TO_INT
  | OP_LONG_TO_FLOAT
  | OP_LONG_TO_DOUBLE
  | OP_FLOAT_TO_INT
  | OP_FLOAT_TO_LONG
  | OP_FLOAT_TO_DOUBLE
  | OP_DOUBLE_TO_INT
  | OP_DOUBLE_TO_LONG
  | OP_DOUBLE_TO_FLOAT
  | OP_INT_TO_BYTE
  | OP_INT_TO_CHAR
  | OP_INT_TO_SHORT

  | OP_ADD_INT_2ADDR
  | OP_SUB_INT_2ADDR
  | OP_MUL_INT_2ADDR
  | OP_DIV_INT_2ADDR
  | OP_REM_INT_2ADDR
  | OP_AND_INT_2ADDR
  | OP_OR_INT_2ADDR
  | OP_XOR_INT_2ADDR
  | OP_SHL_INT_2ADDR
  | OP_SHR_INT_2ADDR
  | OP_USHR_INT_2ADDR

  | OP_ADD_LONG_2ADDR
  | OP_SUB_LONG_2ADDR
  | OP_MUL_LONG_2ADDR
  | OP_DIV_LONG_2ADDR
  | OP_REM_LONG_2ADDR
  | OP_AND_LONG_2ADDR
  | OP_OR_LONG_2ADDR
  | OP_XOR_LONG_2ADDR
  | OP_SHL_LONG_2ADDR
  | OP_SHR_LONG_2ADDR
  | OP_USHR_LONG_2ADDR

  | OP_ADD_FLOAT_2ADDR
  | OP_SUB_FLOAT_2ADDR
  | OP_MUL_FLOAT_2ADDR
  | OP_DIV_FLOAT_2ADDR
  | OP_REM_FLOAT_2ADDR
  | OP_ADD_DOUBLE_2ADDR
  | OP_SUB_DOUBLE_2ADDR
  | OP_MUL_DOUBLE_2ADDR
  | OP_DIV_DOUBLE_2ADDR
  | OP_REM_DOUBLE_2ADDR        -> f_12x opr

  | OP_CONST_4                 -> f_11n opr

  | OP_MOVE_RESULT
  | OP_MOVE_RESULT_WIDE
  | OP_MOVE_RESULT_OBJECT
  | OP_MOVE_EXCEPTION

  | OP_RETURN
  | OP_RETURN_WIDE
  | OP_RETURN_OBJECT

  | OP_MONITOR_ENTER
  | OP_MONITOR_EXIT

  | OP_THROW                   -> f_11x opr

  | OP_MOVE_FROM16
  | OP_MOVE_WIDE_FROM16
  | OP_MOVE_OBJECT_FROM16      -> f_22x opr

  | OP_IF_EQZ
  | OP_IF_NEZ
  | OP_IF_LTZ
  | OP_IF_GEZ
  | OP_IF_GTZ
  | OP_IF_LEZ                  -> f_21t opr

  | OP_CONST_16
  | OP_CONST_WIDE_16
  | OP_CONST_HIGH16            -> f_21s opr

  | OP_CONST_WIDE_HIGH16       -> f_21h opr

  | OP_CONST_STRING
  | OP_CONST_CLASS

  | OP_CHECK_CAST

  | OP_NEW_INSTANCE

  | OP_SGET
  | OP_SGET_WIDE
  | OP_SGET_OBJECT
  | OP_SGET_BOOLEAN
  | OP_SGET_BYTE
  | OP_SGET_CHAR
  | OP_SGET_SHORT
  | OP_SPUT
  | OP_SPUT_WIDE
  | OP_SPUT_OBJECT
  | OP_SPUT_BOOLEAN
  | OP_SPUT_BYTE
  | OP_SPUT_CHAR
  | OP_SPUT_SHORT              -> f_21c opr

  | OP_CMPL_FLOAT
  | OP_CMPG_FLOAT
  | OP_CMPL_DOUBLE
  | OP_CMPG_DOUBLE
  | OP_CMP_LONG

  | OP_AGET
  | OP_AGET_WIDE
  | OP_AGET_OBJECT
  | OP_AGET_BOOLEAN
  | OP_AGET_BYTE
  | OP_AGET_CHAR
  | OP_AGET_SHORT
  | OP_APUT
  | OP_APUT_WIDE
  | OP_APUT_OBJECT
  | OP_APUT_BOOLEAN
  | OP_APUT_BYTE
  | OP_APUT_CHAR
  | OP_APUT_SHORT

  | OP_ADD_INT
  | OP_SUB_INT
  | OP_MUL_INT
  | OP_DIV_INT
  | OP_REM_INT
  | OP_AND_INT
  | OP_OR_INT
  | OP_XOR_INT
  | OP_SHL_INT
  | OP_SHR_INT
  | OP_USHR_INT

  | OP_ADD_LONG
  | OP_SUB_LONG
  | OP_MUL_LONG
  | OP_DIV_LONG
  | OP_REM_LONG
  | OP_AND_LONG
  | OP_OR_LONG
  | OP_XOR_LONG
  | OP_SHL_LONG
  | OP_SHR_LONG
  | OP_USHR_LONG

  | OP_ADD_FLOAT
  | OP_SUB_FLOAT
  | OP_MUL_FLOAT
  | OP_DIV_FLOAT
  | OP_REM_FLOAT
  | OP_ADD_DOUBLE
  | OP_SUB_DOUBLE
  | OP_MUL_DOUBLE
  | OP_DIV_DOUBLE
  | OP_REM_DOUBLE              -> f_23x opr

  | OP_ADD_INT_LIT8
  | OP_RSUB_INT_LIT8
  | OP_MUL_INT_LIT8
  | OP_DIV_INT_LIT8
  | OP_REM_INT_LIT8
  | OP_AND_INT_LIT8
  | OP_OR_INT_LIT8
  | OP_XOR_INT_LIT8
  | OP_SHL_INT_LIT8
  | OP_SHR_INT_LIT8
  | OP_USHR_INT_LIT8           -> f_22b opr

  | OP_IF_EQ
  | OP_IF_NE
  | OP_IF_LT
  | OP_IF_GE
  | OP_IF_GT
  | OP_IF_LE                   -> f_22t opr

  | OP_ADD_INT_LIT16
  | OP_RSUB_INT
  | OP_MUL_INT_LIT16
  | OP_DIV_INT_LIT16
  | OP_REM_INT_LIT16
  | OP_AND_INT_LIT16
  | OP_OR_INT_LIT16
  | OP_XOR_INT_LIT16           -> f_22s opr

  | OP_INSTANCE_OF

  | OP_NEW_ARRAY

  | OP_IGET
  | OP_IGET_WIDE
  | OP_IGET_OBJECT
  | OP_IGET_BOOLEAN
  | OP_IGET_BYTE
  | OP_IGET_CHAR
  | OP_IGET_SHORT
  | OP_IPUT
  | OP_IPUT_WIDE
  | OP_IPUT_OBJECT
  | OP_IPUT_BOOLEAN
  | OP_IPUT_BYTE
  | OP_IPUT_CHAR
  | OP_IPUT_SHORT              -> f_22c opr

  | OP_MOVE_16
  | OP_MOVE_WIDE_16
  | OP_MOVE_OBJECT_16          -> f_32x opr

  | OP_CONST
  | OP_CONST_WIDE_32           -> f_31i opr

  | OP_FILL_ARRAY_DATA

  | OP_PACKED_SWITCH
  | OP_SPARSE_SWITCH           -> f_31t opr

  | OP_CONST_STRING_JUMBO      -> f_31c opr

  | OP_FILLED_NEW_ARRAY

  | OP_INVOKE_VIRTUAL
  | OP_INVOKE_SUPER
  | OP_INVOKE_DIRECT
  | OP_INVOKE_STATIC
  | OP_INVOKE_INTERFACE        -> f_35c opr

  | OP_FILLED_NEW_ARRAY_RANGE

  | OP_INVOKE_VIRTUAL_RANGE
  | OP_INVOKE_SUPER_RANGE
  | OP_INVOKE_DIRECT_RANGE
  | OP_INVOKE_STATIC_RANGE
  | OP_INVOKE_INTERFACE_RANGE  -> f_3rc opr

  | OP_GOTO                    -> f_10t opr
  | OP_GOTO_16                 -> f_20t opr
  | OP_GOTO_32                 -> f_30t opr

  | OP_CONST_WIDE              -> f_51l opr

(***********************************************************************)
(* New instruction                                                     *)
(***********************************************************************)

(* new_const : int -> int -> instr *)
let new_const (r: int) (const: int) : instr =
  let op =
    if const < 0xf then OP_CONST_4 
    else if const < 0xffff then OP_CONST_16
    else OP_CONST
  and opr = [OPR_REGISTER r; OPR_CONST (to_i64 const)] in op, opr

(* wrap REGISTER except for the last thing (type, method, field) *)
let refer_last (hx: int) (args: int list) : instr =
  let rec ex_last = function
    | []   -> []
    | [i]  -> [OPR_INDEX i]
    | h::t -> (OPR_REGISTER h)::(ex_last t)
  in
  let op = hx_to_op hx
  and opr = ex_last args in op, opr

(* MOVE from a register to a register *)
let mv_reg_to_reg (hx: int) (dst: int) (src: int) : instr =
  let op = hx_to_op hx
  and opr = [OPR_REGISTER dst; OPR_REGISTER src] in op, opr

(* MOVE a thing referred by id to a register *)
let mv_id_to_reg (hx: int) (r: int) (i: int) : instr =
  refer_last hx [r; i]

(* new_const_id : int -> int -> int -> instr *)
let new_const_id (hx: int) (r: int) (i: int) : instr =
  mv_id_to_reg hx r i

(* new_move : int -> int -> int -> instr *)
let new_move (hx: int) (dst: int) (src: int) : instr =
  mv_reg_to_reg hx dst src

(* new_obj : int -> int -> instr *)
let new_obj (dst: int) (typ: int) : instr =
  let hx = op_to_hx OP_NEW_INSTANCE in
  mv_id_to_reg hx dst typ

(* new_arr : int -> int -> int -> instr *)
let new_arr (dst: int) (sz: int) (typ: int) : instr =
  let hx = op_to_hx OP_NEW_ARRAY in
  refer_last hx [dst; sz; typ]

(* new_arr_op : int -> int list -> instr *)
let new_arr_op (hx: int) (argv: int list) : instr =
  let op = hx_to_op hx
  and opr = L.map (fun i -> OPR_REGISTER i) argv in op, opr

(* new_stt_fld : int -> int -> int -> instr *)
let new_stt_fld (hx: int) (r: int) (i: int) : instr =
  mv_id_to_reg hx r i

(* new_invoke : int -> int list -> instr *)
let new_invoke (hx: int) (args: int list) : instr =
  refer_last hx args

(* new_move_result : int -> int -> instr *)
let new_move_result (hx: int) (r: int) : instr =
  let op = hx_to_op hx
  and opr = [OPR_REGISTER r] in op, opr

(* new_return : int -> int option -> instr *)
let new_return (hx: int) (r: int option) : instr =
  let op = hx_to_op hx
  and opr = match r with Some i -> [OPR_REGISTER i] | _ -> [] in op, opr

(* rv : instr *)
let rv = new_return 0x0e None

