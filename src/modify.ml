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
(* Modify                                                              *)
(***********************************************************************)

module St = Stats
module DA = DynArray

module U = Util

module I  = Instr
module D  = Dex
module J  = Java
module JL = Java.Lang
module A  = Android

module V  = Visitor
module Cf = Ctrlflow

module IM = I.IM
module IS = Set.Make(Int32)

module I32 = Int32

module L  = List
module H  = Hashtbl
module S  = String
module RE = Str

(***********************************************************************)
(* Basic Types/Elements                                                *)
(***********************************************************************)

(* hash size *)
let h_sz = 29

type maps = {
  cmap : (int, int) H.t;
  fmap : (int, int) H.t;
  mmap : (int, int) H.t;
}

type class_replacement_option = 
  | Replace_Full_Class     of string * string
  | Replace_Only_Methods   of string * string * string list
  | Replace_Except_Methods of string * string * string list

(* opcodes *)
let rtrn_obj = I.op_to_hx I.OP_RETURN_OBJECT
let cons_str = I.op_to_hx I.OP_CONST_STRING
let mv_r_obj = I.op_to_hx I.OP_MOVE_RESULT_OBJECT
let aget_obj = I.op_to_hx I.OP_AGET_OBJECT
let sget_obj = I.op_to_hx I.OP_SGET_OBJECT
let call_vrt = I.op_to_hx I.OP_INVOKE_VIRTUAL
let call_stt = I.op_to_hx I.OP_INVOKE_STATIC
let call_sup = I.op_to_hx I.OP_INVOKE_SUPER
let call_dir = I.op_to_hx I.OP_INVOKE_DIRECT

(***********************************************************************)
(* Utilities                                                           *)
(***********************************************************************)

let print_fit (dx: D.dex) (fid, fit) : unit =
  let f_str = Log.of_i (D.of_idx fid)
  and c_str = Log.of_i (D.of_idx fit.D.f_class_id)
  and fname = D.get_str dx fit.D.f_name_id
  and ty = D.get_ty_str dx fit.D.f_type_id in
  Log.v ("    fid "^f_str^": [cid: "^c_str^", "^fname^" : "^ty^"]")

let print_mit (dx: D.dex) (mid, mit) : unit =
  let argv = D.get_argv dx mit
  and m_str = Log.of_i (D.of_idx mid)
  and c_str = Log.of_i (D.of_idx mit.D.m_class_id)
  and mname = D.get_str dx mit.D.m_name_id in
  let a_str = S.concat " " (L.map (D.get_ty_str dx) argv) in
  Log.v ("    mid "^m_str^": [cid: "^c_str^", "^mname^" : "^a_str^"]")

let print_map (map: (int, int) H.t) : unit =
  let each s d acc =
    acc^"("^(Log.of_i s)^" -> "^(Log.of_i d)^") "
  in
  Log.v ("map: "^(H.fold each map ""))

let rlink = ref 0
(* seed_addr : int -> unit *)
let seed_addr (seed: int) : unit =
  rlink := seed

(* get_fresh_addr : unit -> D.link *)
let get_fresh_addr () : D.link =
  incr rlink; D.to_off !rlink

let get_last (l: 'a list) : 'a =
  L.hd (L.rev l)

(* try matching regular expression *)
let regexp_folder target acc re =
  acc || RE.string_match re target 0

(* retreive human-readable type notation *)
let get_ty_str (dx: D.dex) (tid: D.link) : string =
  J.of_type_descr (D.get_ty_str dx tid)

(* wipe off final modifier *)
let wipe_off_final (access_flag: int) : int =
  (* any {!Dex.acc_kind}s are fine *)
  let final_flag = D.to_acc_flag D.ACC_FOR_CLASSES [D.ACC_FINAL] in
  access_flag land (lnot final_flag)

(***********************************************************************)
(* Dex modification                                                    *)
(***********************************************************************)

(* find or make new STRING_DATA *)
let find_or_new_str (dx: D.dex) (str: string) : D.link =
  let sid = D.find_str dx str in
  if sid <> D.no_idx then sid else
  (
    let sid' = D.to_idx (DA.length dx.D.d_string_ids)
    and off = get_fresh_addr () in
    D.insrt_str dx off str;
    DA.add dx.D.d_string_ids off;
    sid'
  )

(* wrapper for above function *)
let new_str (dx: D.dex) (str: string) : D.link =
  find_or_new_str dx str

let str_sub_cnt = ref 0

(* replace_str : D.dex -> string -> string -> bool *)
let replace_str (dx: D.dex) (prv: string) (nex: string) : bool =
  let sid = D.find_str dx prv in
  if sid = D.no_idx then (new_str dx nex; false)
  else (* exists; overwrite the old one *)
  (
    incr str_sub_cnt;
    let off = DA.get dx.D.d_string_ids (D.of_idx sid) in
    D.insrt_str dx off nex; true
  )

(* report_str_repl_cnt : unit -> unit *)
let report_str_repl_cnt () : unit =
  Log.i ("# of string replacement(s): "^(Log.of_i !str_sub_cnt))

(* find or make new type_id *)
let find_or_new_ty_str (dx: D.dex) (str: string) : D.link =
  let tid = D.find_ty_str dx str in
  if tid <> D.no_idx then tid else
  (
    let sid = find_or_new_str dx str
    and tid' = D.to_idx (DA.length dx.D.d_type_ids) in
    DA.add dx.D.d_type_ids sid;
    tid'
  )

(* wrapper for above function *)
let new_ty (dx: D.dex) (str: string) : D.link =
  find_or_new_ty_str dx str

let is_lib (cname: string) : bool =
  J.is_library cname || A.is_library cname

(* new_class : D.dex -> ?string -> string -> J.access_flag list -> D.link *)
let new_class (dx: D.dex) ?(super=Java.Lang.obj) (cname: string)
  (flags: D.access_flag list) : D.link =
  let cname = J.to_java_ty cname
  and super = J.to_java_ty super in
  let cid = find_or_new_ty_str dx cname
  and sid = D.get_cid dx super in
  if not (is_lib cname) then
  (
    let cdef = {
      D.c_class_id    = cid;
      D.c_access_flag = D.to_acc_flag D.ACC_FOR_CLASSES flags;
      D.superclass    = sid;
      D.interfaces    = D.no_off;
      D.source_file   = D.no_idx;
      D.annotations   = D.no_off;
      D.class_data    = D.no_off;
      D.static_values = D.no_off;
    } in
    DA.add dx.D.d_class_defs cdef
  );
  cid

(* make_class_overridable : D.dex -> D.link -> unit *)
let make_class_overridable (dx: D.dex) (cid: D.link) : unit =
  let cdef = D.get_cdef dx cid in
  cdef.D.c_access_flag <- wipe_off_final cdef.D.c_access_flag

(* find or make new TYPE_LIST *)
let find_or_new_ty_lst (dx: D.dex) (tl: D.link list) : D.link =
  if tl = [] then D.no_off else
  let found = ref false
  and off = ref D.no_off in
  let iter (k: I.offset) (it: D.data_item) : unit =
    match it with
    | D.TYPE_LIST tl' when not !found && D.ty_lst_comp dx tl tl' = 0 ->
      ( found := true; off := (D.Off k) )
    | _ -> ()
  in
  IM.iter iter dx.D.d_data;
  if !found then !off else
  (
    off := get_fresh_addr ();
    D.insrt_ty_lst dx !off tl;
    !off
  )

(* find or make new TYPE_LIST for given interface *)
let find_or_new_itf (dx: D.dex) (iid: D.link) prv : D.link =
  let org = D.get_ty_lst dx prv in
  if L.mem iid org then prv else
    find_or_new_ty_lst dx (iid :: org)

(* append interface TYPE_LIST to class definition *)
let append_itf (dx: D.dex) (cid: D.link) (itf_id: D.link) : unit =
  let itf_attacher (cdef: D.class_def_item) : unit =
    if cdef.D.c_class_id = cid then
      cdef.D.interfaces <- find_or_new_itf dx itf_id cdef.D.interfaces
  in
  DA.iter itf_attacher dx.D.d_class_defs

(* add_interface : D.dex -> D.link -> string -> unit *)
let add_interface (dx: D.dex) (cid: D.link) (interface: string) : unit =
  let icid = D.get_cid dx interface in
  if icid = D.no_idx then
    raise (D.Wrong_dex ("no such interface exists: "^interface))
  else
    append_itf dx cid icid

(* find or make new CLASS_DATA *)
let find_or_new_cdata (dx: D.dex) (cid: D.link) : D.class_data_item =
  try let _, cdat = D.get_cdata dx cid in cdat
  with D.Wrong_dex _ -> (* no such offset by D.get_data_item *)
    let cdat = {
      D.static_fields   = [];
      D.instance_fields = [];
      D.direct_methods  = [];
      D.virtual_methods = [];
    }
    and off = get_fresh_addr ()
    and cdef = D.get_cdef dx cid in
    cdef.D.class_data <- off;
    D.insrt_data dx off (D.CLASS_DATA cdat);
    cdat

(* field definition exists? *)
let fld_exists (dx: D.dex) (cid: D.link) (fname: string) : D.link =
  try
    let fid, _ = D.get_the_fld dx cid fname in
    if D.own_the_fld dx cid fid then fid else D.no_idx
  with D.Wrong_dex _ -> D.no_idx

(* new_field : D.dex -> D.link -> string
  -> J.access_flag list -> string -> D.link *)
let new_field (dx: D.dex) (cid: D.link) (fname: string)
  (flags: D.access_flag list) (ty: string) : D.link =
  let ty = J.to_type_descr ty in
  let old = fld_exists dx cid fname in
  if old <> D.no_idx then old else
  (
    let fid = D.to_idx (DA.length dx.D.d_field_ids)
    and fit = {
      D.f_class_id = cid;
      D.f_type_id  = find_or_new_ty_str dx ty;
      D.f_name_id  = find_or_new_str    dx fname;
    } in
    DA.add dx.D.d_field_ids fit;
    if not (is_lib (D.get_ty_str dx cid)) then
    (
      let cdat = find_or_new_cdata dx cid
      and efld = {
        D.field_idx     = fid;
        D.f_access_flag = D.to_acc_flag D.ACC_FOR_FIELDS flags;
      } in
      if L.mem D.ACC_STATIC flags then
        cdat.D.static_fields   <- efld :: cdat.D.static_fields
      else
        cdat.D.instance_fields <- efld :: cdat.D.instance_fields
    );
    fid
  )

(* find or make new proto_id_item *)
let find_or_new_proto (dx: D.dex) (rety: string) (args: string list) : D.link =
  let shty = J.to_shorty_descr (rety :: args)
  and rety = J.to_type_descr rety
  and args = L.map J.to_type_descr args in
  let tl = L.map (find_or_new_ty_str dx) args in
  let finder (pit: D.proto_id_item) : bool =
    (D.get_str dx pit.D.shorty = shty) &&
    (D.get_ty_str dx pit.D.return_type = rety) &&
    let tl' = D.get_ty_lst dx pit.D.parameter_off in
    (D.ty_lst_comp dx tl tl' = 0)
  in
  try D.to_idx (DA.index_of finder dx.D.d_proto_ids)
  with Not_found ->
    let pid = D.to_idx (DA.length dx.D.d_proto_ids) in
    let pit = {
      D.shorty        = find_or_new_str    dx shty;
      D.return_type   = find_or_new_ty_str dx rety;
      D.parameter_off = find_or_new_ty_lst dx tl;
    } in
    DA.add dx.D.d_proto_ids pit;
    pid

(* method signature exists? *)
let mtd_sig_exists (dx: D.dex) (cid: D.link) (mname: string) : D.link =
  try
    let mid, _ = D.get_the_mtd dx cid mname in
    if D.own_the_mtd dx cid mid then mid else D.no_idx
  with D.Wrong_dex _ -> D.no_idx

(* method implementation exists? *)
let mtd_body_exists (dx: D.dex) (cid: D.link) (mname: string) : D.link =
  let mid = mtd_sig_exists dx cid mname in
  if mid = D.no_idx then mid else
  try let _, _ = D.get_citm dx cid mid in mid
  with D.Wrong_dex _ -> D.no_idx

(* new_method : D.dex -> D.link -> string
  -> J.access_flag list -> string -> string list -> D.link *)
let new_method (dx: D.dex) (cid: D.link) (mname: string)
  (flags: D.access_flag list) (rety: string) (argv: string list) : D.link =
  let flags = if mname = J.init then D.ACC_CONSTRUCTOR::flags else flags in
  let old = mtd_body_exists dx cid mname in
  if old <> D.no_idx then old else
  (
    let old = mtd_sig_exists dx cid mname in
    let mid =
      if old <> D.no_idx then old else
      (
        let nid = D.to_idx (DA.length dx.D.d_method_ids)
        and mit = {
          D.m_class_id = cid;
          D.m_proto_id = find_or_new_proto dx rety argv;
          D.m_name_id  = find_or_new_str dx mname;
        } in
        DA.add dx.D.d_method_ids mit;
        nid
      )
    in
    if not (is_lib (D.get_ty_str dx cid)) then
    (
      let cdat = find_or_new_cdata dx cid
      and emtd = {
        D.method_idx    = mid;
        D.m_access_flag = D.to_acc_flag D.ACC_FOR_METHODS flags;
        D.code_off      = get_fresh_addr ();
      } in
      (
        if L.mem D.ACC_STATIC flags || L.mem D.ACC_CONSTRUCTOR flags then
          cdat.D.direct_methods  <- emtd :: cdat.D.direct_methods
        else
          cdat.D.virtual_methods <- emtd :: cdat.D.virtual_methods
      );
      (* take into accounts "this" or not *)
      let argc = L.length argv + (if L.mem D.ACC_STATIC flags then 0 else 1)
      and citm = D.empty_citm () in
      citm.D.registers_size <- argc;
      citm.D.ins_size       <- argc;
      D.insrt_citm dx emtd.D.code_off citm
    );
    mid
  )

(* make_method_overridable : D.dex -> D.link -> D.link -> unit *)
let make_method_overridable (dx: D.dex) (cid: D.link) (mid: D.link) : unit =
  let emtd = D.get_emtd dx cid mid in
  emtd.D.m_access_flag <- wipe_off_final emtd.D.m_access_flag

(* instruction inserting point *)
type cursor = int

(* previous instruction *)
let prev cur : cursor = cur - 1

(* next instruction *)
let next cur : cursor = cur + 1

(* get the cursor of the first instruction *)
let get_fst_cursor () : cursor = 0

(* get the cursor of the second instruction *)
let get_snd_cursor () : cursor = next (get_fst_cursor ())

(* get the cursor of the last instruction *)
let get_last_cursor (dx: D.dex) (citm: D.code_item) : cursor =
  let cfg  = St.time "cfg"  (Cf.make_cfg dx) citm in
  let pdom = St.time "pdom"  Cf.pdoms cfg in
  let off  = St.time "pdom" (Cf.get_last_ins cfg) pdom in
  DA.index_of (fun e -> e = off) citm.D.insns

(* get_fst_ins : D.dex -> D.code_item -> I.instr *)
let get_fst_ins (dx: D.dex) (citm: D.code_item) : I.instr =
  let fst_off = DA.get citm.D.insns (get_fst_cursor ()) in
  D.get_ins dx fst_off

let next_off off : D.link =
  D.to_off ((D.of_off off) + 1)

let ins_size (ins: I.instr) : int =
  let op, _ = ins in
  let _, sz = I.op_to_hx_and_size op in sz

let incr_insns_size (citm: D.code_item) (ins: I.instr) : unit =
  let sz = ins_size ins in
  citm.D.insns_size <- citm.D.insns_size + sz

let decr_insns_size (citm: D.code_item) (ins: I.instr) : unit =
  let sz = ins_size ins in
  citm.D.insns_size <- citm.D.insns_size - sz

(* insrt_ins : D.dex -> D.code_item -> cursor -> I.instr -> cursor *)
let insrt_ins (dx: D.dex) (citm: D.code_item) cur (ins: I.instr) : cursor =
  let off = get_fresh_addr () in
  D.insrt_ins dx off ins;
  DA.insert citm.D.insns cur off;
  incr_insns_size citm ins;
  cur + 1

(* rm_ins : D.dex -> D.code_item -> cursor -> cursor *)
let rm_ins (dx: D.dex) (citm: D.code_item) cur : cursor =
  let off = DA.get citm.D.insns cur in
  let ins = D.get_ins dx off in
  D.rm_data dx off;
  DA.delete citm.D.insns cur;
  decr_insns_size citm ins;
  cur

(* insert_insns : D.dex -> D.code_item -> cursor -> I.instr list -> cursor *)
let insrt_insns (dx: D.dex) (citm: D.code_item) cur (insns: I.instr list) =
  L.fold_left (insrt_ins dx citm) cur insns

(* insrt_insns_before_start : D.dex -> D.code_item -> I.instr list -> cursor *)
let insrt_insns_before_start dx (citm: D.code_item) (insns: I.instr list) =
  if citm.D.tries_size = 0 then
    insrt_insns dx citm (get_fst_cursor ()) insns
  else (* not to change base addr for try-catch *)
    let hd::tl  = insns
    and fst_off = DA.get citm.D.insns 0 in
    let fst_ins = D.get_ins dx fst_off
    and snd_off = next_off fst_off in
    (* shift the first ins *)
    D.insrt_ins dx snd_off fst_ins;
    DA.insert citm.D.insns (get_snd_cursor ()) snd_off;
    (* overwrite the first ins with new one *)
    D.insrt_ins dx fst_off hd;
    incr_insns_size citm hd;
    (* insert the remaining instructions from the second position *)
    insrt_insns dx citm (get_snd_cursor ()) tl

(* insrt_insns_after_start : D.dex -> D.code_item -> I.instr list -> cursor *)
let insrt_insns_after_start dx (citm: D.code_item) (insns: I.instr list) =
  insrt_insns dx citm (get_snd_cursor ()) insns

(* insrt_insns_before_end : D.dex -> D.code_item -> I.instr list -> cursor *)
let insrt_insns_before_end dx (citm: D.code_item) (insns: I.instr list) =
  insrt_insns dx citm (get_last_cursor dx citm) insns

(* insrt_insns_after_end : D.dex -> D.code_item -> I.instr list -> cursor *)
let insrt_insns_after_end dx (citm: D.code_item) (insns: I.instr list) =
  insrt_insns dx citm (next (get_last_cursor dx citm)) insns

(* insrt_return_void : D.dex -> D.link -> string -> unit *)
let insrt_return_void dx (cid: D.link) (mname: string) : unit =
  let mid, _ = D.get_the_mtd dx cid mname in
  let _,citm = D.get_citm dx cid mid in
  ignore (insrt_insns_after_end dx citm [I.rv])

(* update_reg_usage : D.dex -> D.code_item -> unit *)
let update_reg_usage dx (citm: D.code_item) : unit =
  let old_this = D.calc_this citm in
  (* update register usage and outs size *)
  let ins_folder (regs, outs) (off: D.link) =
    if not (D.is_ins dx off) then (regs, outs) else
    let op, opr = D.get_ins dx off in
    let a_sort = I.access_link op in
    let opr_folder_regs acc opr =
      match opr with
      | I.OPR_REGISTER n -> IS.add (I32.of_int n) acc
      | _ -> acc
    and opr_folder_outs acc opr =
      match opr, a_sort with
      | I.OPR_REGISTER n, I.METHOD_IDS -> IS.add (I32.of_int n) acc
      | _, _ -> acc
    in
    L.fold_left opr_folder_regs regs opr,
    L.fold_left opr_folder_outs outs opr
  in
  let regs, outs = DA.fold_left ins_folder (IS.empty, IS.empty) citm.D.insns in
  citm.D.registers_size <- max (IS.cardinal regs) citm.D.registers_size;
  citm.D.outs_size      <- max (IS.cardinal outs) citm.D.outs_size;
  (* this pointer may be altered; update old usage *)
  let new_this = D.calc_this citm in
  let ins_iter (off: D.link) =
    if D.is_ins dx off then
    (
      let op, opr = D.get_ins dx off in
      match I.access_link op with
      | I.METHOD_IDS
        when op <> I.OP_INVOKE_STATIC && op <> I.OP_INVOKE_STATIC_RANGE ->
      (
        let opr_alter opr =
          match opr with
          | I.OPR_REGISTER n when n = old_this -> I.OPR_REGISTER new_this
          | _ -> opr
        in
        D.insrt_ins dx off (op, L.map opr_alter opr)
      )
      | _ -> ()
    )
  in
  if old_this <> new_this then DA.iter ins_iter citm.D.insns

(* implements : D.dex -> D.link -> D.link -> string -> bool *)
let implements (dx: D.dex) (cid: D.link) (itf: D.link) (mname: string) : bool =
  let mid = mtd_body_exists dx cid mname in
  if mid <> D.no_idx then true else
  ( (* absence of the target method *)
    let _, mit = D.get_the_mtd dx itf mname in
    let rety = get_ty_str dx (D.get_rety dx mit)
    and argv = L.map (get_ty_str dx) (D.get_argv dx mit) in
    let _ = new_method dx cid mname D.pub rety argv in
    false
  )

(* override : D.dex -> D.link -> string -> bool *)
let override (dx: D.dex) (cid: D.link) (mname: string) : bool =
  let mid = mtd_body_exists dx cid mname in
  if mid <> D.no_idx then true else
  ( (* absence of the target method *)
    let _, mit = D.get_the_mtd dx cid mname in
    (* TODO: even superclass may not have the method *)
    let rety = get_ty_str dx (D.get_rety dx mit)
    and argv = L.map (get_ty_str dx) (D.get_argv dx mit) in
    let mid' = new_method dx cid mname D.pub rety argv in
    let _, citm = D.get_citm dx cid mid' in
    let this = D.calc_this citm
    and sid = D.get_supermethod dx cid mid' in
    if sid = D.no_idx then
      raise (D.Wrong_dex ("not overridable method: "^mname));
    let sp = I.new_invoke
      (if mname = J.init then call_dir else call_sup)
      (U.range this (this + citm.D.ins_size - 1) [D.of_idx sid])
    in
    let _ = insrt_insns_before_start dx citm [sp] in
    citm.D.outs_size <- max 1 citm.D.ins_size;
    false
  )

(***********************************************************************)
(* Substitution                                                        *)
(***********************************************************************)

let sub_cnt = ref 0

(* in order not to touch library classes *)
let skip_cur_cls = ref false

(* int to int *)
let i2i map i : int =
  if !skip_cur_cls then i else
  try
    let res = H.find map i in
    if res <> i then ( incr sub_cnt; res )
    else raise (D.NOT_YET (string_of_int i))
  with Not_found -> i

(* link to link *)
let l2l map l : D.link =
  D.to_idx (i2i map (D.of_idx l))

(* make class replacement map *)
let make_cmap maps xid yid : unit =
  H.add maps.cmap (D.of_idx xid) (D.of_idx yid)

(* make field replacement map *)
let make_fmap maps (dx: D.dex) xl yl : unit =
  let each (s, s_fit) =
    let s_name = D.get_str dx s_fit.D.f_name_id
    and s_type = l2l maps.cmap s_fit.D.f_type_id in
    let finder (_, d_fit) : bool =
      let d_name = D.get_str dx d_fit.D.f_name_id
      and d_type = l2l maps.cmap d_fit.D.f_type_id in
      s_name = d_name && D.ty_comp dx s_type d_type = 0
    in
    try
      let d, _ = L.find finder yl in
      H.add maps.fmap (D.of_idx s) (D.of_idx d)
    with Not_found -> ()
  in
  L.iter each xl

(* make method replacement map *)
let make_mmap maps (dx: D.dex) xl yl cro : unit =
  let each (s, s_mit) =
    let s_name = D.get_str dx s_mit.D.m_name_id
    and s_argv = L.map (l2l maps.cmap) (D.get_argv dx s_mit)
    and s_rety = l2l maps.cmap (D.get_rety dx s_mit) in
    (* if it's in ads packages, do not check method name *)
    let cname = D.get_ty_str dx s_mit.D.m_class_id in
    let t =
      match cro with
      | Replace_Full_Class           _ -> true
      | Replace_Only_Methods   (_,_,l) ->      L.exists (fun x -> x = s_name) l
      | Replace_Except_Methods (_,_,l) -> not (L.exists (fun x -> x = s_name) l)
    in
    if not t then () else
      let finder (_, d_mit) : bool =
        let d_name = D.get_str dx d_mit.D.m_name_id
        and d_argv = L.map (l2l maps.cmap) (D.get_argv dx d_mit)
        and d_rety = l2l maps.cmap (D.get_rety dx d_mit) in
        (* TODO: configurable: only sig comp. vs. name match too *)
        s_name = d_name &&
        D.ty_lst_comp_relaxed dx (s_rety::s_argv) (d_rety::d_argv) = 0
      and s_id = D.of_idx s in
      try
        let d, _ = L.find finder yl in
        H.add maps.mmap s_id (D.of_idx d)
      with Not_found ->
      (
        Log.w ("W: unimplemented: "^cname^"."^s_name);
        (* to raise an exception if a certain method isn't in a proxy *)
        H.add maps.mmap s_id s_id
      )
  in
  L.iter each xl

let found_unimplemented_method (dx: D.dex) (istr: string) : unit =
  let mid = D.to_idx (int_of_string istr) in
  let cid = D.get_cid_from_mid dx mid in
  let cname = D.get_ty_str dx cid
  and mname = D.get_mtd_name dx mid in
  raise (D.NOT_YET (cname^"."^mname))

(* opr to opr *)
let opr2opr map opr : I.operand =
  D.idx2opr (l2l map (D.opr2idx opr))

let update_ty_lst dx map off : unit =
  if off <> D.no_off then
    let org = D.get_ty_lst dx off in
    D.insrt_ty_lst dx off (L.map (l2l map) org)

(* index is always placed at the end of args list *)
let update_last map opr : I.operand list =
  let rev = L.rev opr in
  let idx :: rest = rev in
  L.rev ((opr2opr map idx) :: rest)

(* class or its superclasses are one of targets? *)
let target_in_hierarchy (dx: D.dex) map (cid: D.link) : bool =
  let undefined_in_map cid' = l2l map cid' <> cid in
  D.in_hierarchy dx undefined_in_map cid

class replacer (dx: D.dex) maps =
object (self)
  inherit V.iterator dx

  method v_fit (fit: D.field_id_item) : unit =
    fit.D.f_type_id <- l2l maps.cmap fit.D.f_type_id

  method v_mit (mit: D.method_id_item) : unit =
    let cname = D.get_ty_str dx mit.D.m_class_id in
    if target_in_hierarchy dx maps.cmap mit.D.m_class_id
    then
    (
      let pit = D.get_pit dx mit in
      pit.D.return_type <- l2l maps.cmap pit.D.return_type;
      update_ty_lst dx maps.cmap pit.D.parameter_off
    )

  val mutable cur_cid = D.no_idx
  method v_cdef (cdef: D.class_def_item) : unit =
    cur_cid <- cdef.D.c_class_id;
    let cid = D.of_idx cur_cid in
    let is_target k v b = b || cid = k || cid = v in
    skip_cur_cls := H.fold is_target maps.cmap false;
    cdef.D.superclass <- l2l maps.cmap cdef.D.superclass;
    update_ty_lst dx maps.cmap cdef.D.interfaces

  method r_eval ev : D.encoded_value =
    match ev with
    | D.VALUE_TYPE   i -> D.VALUE_TYPE   (i2i maps.cmap i)
    | D.VALUE_FIELD  i -> D.VALUE_FIELD  (i2i maps.fmap i)
    | D.VALUE_METHOD i -> D.VALUE_METHOD (i2i maps.mmap i)
    | D.VALUE_ENUM   i -> D.VALUE_ENUM   (i2i maps.fmap i)
    | D.VALUE_ARRAY  l -> D.VALUE_ARRAY  (L.map self#r_eval l)
    | D.VALUE_ANNOTATION an -> self#v_anno an; ev
    | _ -> ev

  method v_anno (an: D.encoded_annotation) : unit =
    let subst_elt (e: D.annotation_element) =
      e.D.value <- self#r_eval e.D.value
    in
    an.D.an_type_idx <- l2l maps.cmap an.D.an_type_idx;
    L.iter subst_elt an.D.elements

  method v_ins (ins: D.link) : unit =
    try
      let op, opr = D.get_ins dx ins in
      let prv = !sub_cnt in
      let opr' =
        match I.access_link op with
        | I.TYPE_IDS   -> update_last maps.cmap opr
        | I.FIELD_IDS  -> update_last maps.fmap opr
        | I.METHOD_IDS -> update_last maps.mmap opr
        | _ -> opr
      in
      if !sub_cnt <> prv then D.insrt_ins dx ins (op, opr')
    with
    | D.Wrong_match _ -> ()
    | D.NOT_YET  istr -> () (* found_unimplemented_method dx istr *)

  method v_hdl (hdl: D.encoded_catch_handler) : unit =
    let iter pair : unit =
      pair.D.ch_type_idx <- l2l maps.cmap pair.D.ch_type_idx
    in
    L.iter iter hdl.D.e_handlers

  method v_dbg (dbg: D.debug_info_item) : unit =
    let update_idx (m_ins, opr) =
      m_ins, match m_ins with
      | D.DBG_START_LOCAL ->
        let r::n::t::[] = opr in r::n::(opr2opr maps.cmap t)::[]
      | D.DBG_START_LOCAL_EXTENDED ->
        let r::n::t::s::[] = opr in r::n::(opr2opr maps.cmap t)::s::[]
      | _ -> opr
    in
    dbg.D.state_machine <- L.map update_idx dbg.D.state_machine
end

(* subst_cls_helper : dx -> class_replacement_option list -> unit *)
let subst_cls_helper (dx: D.dex) (crs: class_replacement_option list) =
  let maps = {
    cmap = H.create h_sz;
    fmap = H.create h_sz;
    mmap = H.create h_sz;
  } in
  let make_amap (x_ty, y_ty) _ =
    let ax_ty = "["^x_ty and ay_ty = "["^y_ty in
    let xaid = D.find_ty_str dx ax_ty in
    if xaid <> D.no_idx then
    (
      let yaid = find_or_new_ty_str dx ay_ty in
      Log.d ("src: ("^(Log.of_i (D.of_idx xaid))^") "^ax_ty);
      Log.d ("dst: ("^(Log.of_i (D.of_idx yaid))^") "^ay_ty);
      make_cmap maps xaid yaid
    );
    (ax_ty, ay_ty)
  in
  let make_maps is_snd cro =
    let x,y = match cro with
      | Replace_Only_Methods   (a,b,_) -> (a,b)
      | Replace_Except_Methods (a,b,_) -> (a,b)
      | Replace_Full_Class       (a,b) -> (a,b)
    in
    let x_ty = J.to_java_ty x
    and y_ty = J.to_java_ty y in
    let xid::yid::[] = L.map (D.get_cid dx) [x_ty; y_ty] in
    if xid <> D.no_idx then
    (
      let x_flds = D.get_flds dx xid
      and y_flds = D.get_fldS dx yid
      and x_mtds = D.get_mtds dx xid
      and y_mtds = D.get_mtdS dx yid
      in
      if is_snd then
      (
        Log.d ("src: ("^(Log.of_i (D.of_idx xid))^") "^(D.get_ty_str dx xid));
        Log.v "  fields";
        L.iter (print_fit dx) x_flds;
        Log.v "  methods";
        L.iter (print_mit dx) x_mtds
      );
      if yid <> D.no_idx then
      (
        if not is_snd then
        (
          make_cmap maps xid yid;
          ignore (L.fold_left make_amap (x_ty, y_ty) (U.range 1 2 []))
        )
        else (* after making cmap *)
        (
          make_fmap maps dx x_flds y_flds;
          make_mmap maps dx x_mtds y_mtds cro;
        );
        if is_snd then
        (
          Log.d ("dst: ("^(Log.of_i (D.of_idx yid))^") "^(D.get_ty_str dx yid));
          Log.v "  fields";
          L.iter (print_fit dx) y_flds;
          Log.v "  methods";
          L.iter (print_mit dx) y_mtds
        )
      )
    )
  in
  L.iter (make_maps false) crs;
  L.iter (make_maps true ) crs;
  Log.v "class";  print_map maps.cmap;
  Log.v "field";  print_map maps.fmap;
  Log.v "method"; print_map maps.mmap;
  V.iter (new replacer dx maps);
  Log.i ("# of class replacement(s): "^(Log.of_i !sub_cnt))

let rec test_n l =
  match l with
    | h::t ->
    (
      match h with
      | Replace_Only_Methods   (a,b,l) ->
      (
        Log.v ("Replace "^a);
        Log.v ("   with "^b);
        Log.v  "   only methods:";
        L.iter (fun x -> Log.v ("\t"^x)) l
      )
      | Replace_Except_Methods (a,b,l) ->
      (
        Log.v ("Replace "^a);
        Log.v ("   with "^b);
        Log.v  "   except methods:";
        L.iter (fun x -> Log.v ("\t"^x)) l
      )
      | Replace_Full_Class (a,b) ->
      (
        Log.v ("Replace "^a);
        Log.v ("   with "^b)
      )
    ); test_n t
    | [] -> ()
      
(* subst_cls : D.dex -> string list -> string list -> unit *)
let subst_cls (dx: D.dex) (xs: string list) (ys: string list) : unit =
  let aro cro cls =
    match cro with
    | Some (Replace_Only_Methods (a,b,l)) -> 
      Some (Replace_Only_Methods (a,b,cls::l))
    | Some (Replace_Except_Methods (a,b,l)) -> 
      Some (Replace_Except_Methods (a,b,cls::l))
    | _ -> None
  in
  let il cro l= 
    match cro with
    | Some k -> k::l
    | None -> l
  in
  let rec assemble_replacement_list xs ys cro replacements =
    match xs with
    | [] ->
    (
      match cro with 
      | Some k -> k::replacements
      | None -> replacements
    )
    | hd::tl ->
      let name = S.sub hd 1 ((S.length hd) - 1) in
      match hd.[0] with
      | '-' ->
        assemble_replacement_list tl ys (aro cro name) replacements
      | 'F' -> 
        assemble_replacement_list tl (L.tl ys)
          None ((Replace_Full_Class (name, L.hd ys))::(il cro replacements))
      | 'O' ->
        assemble_replacement_list tl (L.tl ys)
          (Some (Replace_Only_Methods (name, L.hd ys, [])))
            (il cro replacements)
      | 'E' ->
        assemble_replacement_list tl (L.tl ys) 
          (Some (Replace_Except_Methods (name, L.hd ys, [])))
            (il cro replacements)
  in
  let l = assemble_replacement_list xs ys None [] in
  test_n l;
  subst_cls_helper dx l

(***********************************************************************)
(* Rename specific things                                              *)
(***********************************************************************)

(*
  renaming is a less error-prone way to avoid dupicates
  e.g., we can rip off pesky annotations classes:
    android.annotation.SuppressLint and ...TargetApi
*)

(* rename_cls : D.dex -> string list -> unit *)
let rename_cls (dx: D.dex) (res: string list) : unit =
  let re = RE.regexp "\\(.+\\) -> \\(.+\\)" in
  let each (str: string) : unit =
    try
      let _ = RE.search_forward re str 0 in
      let old = J.to_java_ty (RE.matched_group 1 str)
      and sub = J.to_java_ty (RE.matched_group 2 str) in
      ignore (replace_str dx old sub)
    with Not_found -> ()
  in
  L.iter each res

(***********************************************************************)
(* Discard specific things                                             *)
(***********************************************************************)

(*
  make a mock class with a null-returning method,
  and replace method calls, related to target classes, with the mock method
  in this way, we don't need to worry about try-catch blocks

  public class MockClass {
    public static Object mockMethod() {
      return null;
    }
  }
*)

let dis_cnt = ref 0

class discarder (dx: D.dex) (mock_mid: D.link) res_cls =
object
  inherit V.iterator dx

  val mutable cur_citm = D.empty_citm ()
  method v_citm (citm: D.code_item) : unit =
    cur_citm <- citm

  method v_ins (ins: D.link) : unit =
    try
      let op, opr = D.get_ins dx ins in
      match I.access_link op with
      | I.METHOD_IDS ->
        let mid = D.opr2idx (get_last opr) in
        let mit = D.get_mit dx mid in
        let rety = get_ty_str dx (D.get_rety dx mit) in
        let cname = D.get_ty_str dx (D.get_cid_from_mid dx mid)
        and mname = D.get_mtd_name dx mid in
        if rety = J.v && mname <> J.init &&
          L.fold_left (regexp_folder cname) false res_cls then
        (
          let mock_ins = I.new_invoke call_stt [D.of_idx mock_mid] in
          D.insrt_ins dx ins mock_ins;
          incr dis_cnt
        ) (* TODO: handle other return types *)
      | _ -> ()
    with D.Wrong_match _ -> ()
end

(* discard_cls_calls : D.dex -> string list -> unit *)
let discard_cls_calls (dx: D.dex) (re: string list) : unit =
  let mock_cid = new_class  dx "umd.redexer.MockClass" D.pub in
  let mock_mid = new_method dx mock_cid "mockMethod" D.spub JL.obj [] in
  let ins0 = I.new_const 0 0
  and ins1 = I.new_return rtrn_obj (Some 0) in
  let _, citm = D.get_citm dx mock_cid mock_mid in
  let _ = insrt_insns_before_start dx citm [ins0; ins1] in
  update_reg_usage dx citm;
  let res = L.map RE.regexp re in
  V.iter (new discarder dx mock_mid res);
  Log.i ("# of discard(s): "^(Log.of_i !dis_cnt))

(***********************************************************************)
(* Call trace                                                          *)
(***********************************************************************)

(*
  make a class with only one static method, which captures the stack
  and prints out its caller's info, like class.method(file.line)

  public class CallTracer {
    public static void getCurrentMethod() {
      StackTraceElement elts[] = (new Throwable ()).getStackTrace();
      Log.d(tag, elts[1].toString());
    }
  }
*)

let trc_cnt = ref 0

class insrt_tracer_call (dx: D.dex) (mid: D.link) res_cls =
  let tr_cid = D.get_cid_from_mid dx mid in
object
  inherit V.iterator dx

  val mutable skip_cls = false
  method v_cdef (cdef: D.class_def_item) : unit =
    let cid = cdef.D.c_class_id in
    let cname = D.get_ty_str dx cid in
    skip_cls <- not (L.fold_left (regexp_folder cname) false res_cls);
    (* avoid the tracer class *)
    skip_cls <- skip_cls || cid = tr_cid

  method v_citm (citm: D.code_item) : unit =
    if not skip_cls then
    (
      let inss = [I.new_invoke call_stt [D.of_idx mid]] in
      let _ = insrt_insns_before_start dx citm inss in
      incr trc_cnt
    )
end

(* call_trace : D.dex -> string list -> unit *)
let call_trace (dx: D.dex) (re: string list) : unit =
  let trc_str = "umd.redexer.CallTracer" in
  let tag_sid = new_str dx trc_str
  and thr_cid = new_class dx Java.Lang.thr D.pub
  and stk_cid = new_class dx Java.Lang.stk D.pub
  and log_cid = new_class dx Android.Util.log D.pub
  and trc_cid = new_class dx trc_str D.pub in
  let thr_mid = new_method dx thr_cid J.init D.pub J.v []
  and stk_mid = new_method dx thr_cid JL.get_stk D.pub ("["^JL.stk) []
  and str_mid = new_method dx stk_cid JL.to_s D.pub JL.str []
  and log_mid = new_method dx log_cid "d" D.spub J.i [JL.str; JL.str]
  and trc_mid = new_method dx trc_cid "d" D.spub J.v [] in
  let ins0 = I.new_obj 0 (D.of_idx thr_cid)
  and ins1 = I.new_invoke call_dir [0; D.of_idx thr_mid]
  and ins2 = I.new_invoke call_vrt [0; D.of_idx stk_mid]
  and ins3 = I.new_move_result mv_r_obj 0
  and ins4 = I.new_const 1 1
  and ins5 = I.new_arr_op aget_obj [0; 0; 1]
  and ins6 = I.new_invoke call_vrt [0; D.of_idx str_mid]
  and ins7 = I.new_move_result mv_r_obj 1
  and ins8 = I.new_const_id cons_str 0 (D.of_idx tag_sid)
  and ins9 = I.new_invoke call_stt [0; 1; D.of_idx log_mid] in
  let inss_trc =
    [ins0; ins1; ins2; ins3; ins4; ins5; ins6; ins7; ins8; ins9; I.rv]
  in
  let _, citm = D.get_citm dx trc_cid trc_mid in
  let _ = insrt_insns_before_start dx citm inss_trc in
  update_reg_usage dx citm;
  let res = L.map RE.regexp re in
  V.iter (new insrt_tracer_call dx trc_mid res);
  Log.i ("# of call trace(s): "^(Log.of_i (!trc_cnt + L.length inss_trc)))

(***********************************************************************)
(* API test                                                            *)
(***********************************************************************)

(*
  public class Hello {
    public static void main (String argv[]) {
      System.out.println("Hello, DEX");
    }
  }
*)

(* hello : unit -> D.dex *)
let hello () : D.dex =
  let dx = D.empty_dex ()
  in (* should declare Object class first *)
  let oid = new_class dx Java.Lang.obj [] in
  let _ = new_method dx oid J.init [] J.v []
  in (* system class w/ stdout *)
  let sid = new_class dx Java.Lang.sys [] in
  let fid = new_field dx sid "out" [] Java.IO.ps
  in (* PrintStream and println method *)
  let pid = new_class dx Java.IO.ps [] in
  let mid = new_method dx pid "println" D.pub J.v [Java.Lang.str]
  in (* at last, add Hello class *)
  let cid = new_class dx "Hello" D.pub in
  let _ = override dx cid J.init in
  let iid, _ = D.get_the_mtd dx cid J.init in
  let _, iitm = D.get_citm dx cid iid in
  let last = get_last_cursor dx iitm in
  let _ = insrt_ins dx iitm (next last) I.rv
  and argv = ["["^Java.Lang.str] in
  let main = new_method dx cid "main" D.spub J.v argv in
  let _, citm = D.get_citm dx cid main
  in (* printing instructions *)
  let str = new_str dx "Hello, DEX" in
  let ins1 = I.new_stt_fld  sget_obj 0 (D.of_idx fid)
  and ins2 = I.new_const_id cons_str 1 (D.of_idx str)
  and ins3 = I.new_invoke   call_vrt [0; 1; (D.of_idx mid)] in
  let _ = insrt_insns_before_start dx citm [ins1; ins2; ins3; I.rv] in
  update_reg_usage dx citm;
  dx

