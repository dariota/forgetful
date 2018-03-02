open Cil_types

let opt_string = function
    | None   -> "None"
    | Some s -> s

exception WasNone of unit
let from_option = function
    | None   -> raise (WasNone ())
    | Some s -> s

let is_some = function
    | Some _ -> true
    | _      -> false

let varinfo_contains_dyn_mem (v : varinfo) : lval option =
               Options.feedback ~level:3 "varinfo: %s %s %s %b" v.vname v.vorig_name (opt_string v.vdescr) v.vdescrpure;
               if v.vorig_name = "malloc" || v.vorig_name = "free" then
                   Some (Var v, NoOffset)
               else
                   None

let rec lhost_contains_dyn_mem (l : lhost) : lval option = match l with
    | Var v -> Options.feedback ~level:2 "Var";
               varinfo_contains_dyn_mem v
    | _     -> None
    and exp_contains_dyn_mem (e : exp_node) : lval option = match e with
    | Lval (h,o) -> Options.feedback ~level:3 "Lval";
                    Options.feedback ~level:3 "lval: %a" Printer.pp_lval (h,o);
                    lhost_contains_dyn_mem h
    | _          -> Options.feedback ~level:3 "wuzz other";
                    None

let exp_list_contains_dyn_mem (es : exp list) : (lval option) list =
     List.map (fun e -> exp_contains_dyn_mem e.enode) es

let local_init_contains_dyn_mem (l : local_init) : (lval option) list = match l with
    | ConsInit (v,es,_) -> Options.feedback ~level:2 "ConsInit";
                           varinfo_contains_dyn_mem v :: exp_list_contains_dyn_mem es
    | _                 -> []

let instr_contains_dyn_mem (i : instr) : (lval option) list = match i with
    | Call (_,e,es,_)    -> Options.feedback ~level:4 "Call";
                            Options.feedback ~level:4 "e: %a" Printer.pp_exp e;
                            exp_contains_dyn_mem e.enode :: exp_list_contains_dyn_mem es
    | Local_init (v,l,_) -> Options.feedback ~level:4 "Local_init";
                            varinfo_contains_dyn_mem v :: local_init_contains_dyn_mem l
    | _                  -> []

let stmt_contains_dyn_mem (s : stmt) : (lval option) list = match s.skind with
    | Instr i -> instr_contains_dyn_mem i
    | _       -> []

class print_cfg out = object
    inherit Visitor.frama_c_inplace

    method !vglob_aux g =
        match g with
        | GFun (f,_) -> Options.feedback ~level:6 "Processing function %s" f.svar.vname;
                        Cil.DoChildrenPost (fun g -> g)
        | _          -> Cil.SkipChildren

    method! vstmt_aux s =
        Options.feedback ~level:5 "Processing statement %a" Printer.pp_stmt s;
        let dyn_accesses = List.filter is_some (stmt_contains_dyn_mem s)
        in
            if List.length dyn_accesses > 0 then
                (Options.result "Found: %a" Printer.pp_stmt s;
                Options.result "%d items" (List.length dyn_accesses))
                (*
                let state = Db.Value.get_state (Kstmt s) in
                let (_,r) = !Db.Value.eval_lval None state (h,o) in
                let i = Integer.to_int (from_option (Locations.Location_Bytes.cardinal r)) in
                Options.result "%a <> %d" Printer.pp_stmt s (Integer.to_int (from_option (Locations.Location_Bytes.cardinal r)));
                *)
            else
                ();
            Cil.DoChildren
end
