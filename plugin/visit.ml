open Cil_types

let opt_string = function
    | None   -> "None"
    | Some s -> s

let rec lhost_contains_dyn_mem (l : lhost) : bool = match l with
    | Var v -> Options.feedback ~level:2 "Var";
               Options.feedback ~level:2 "varinfo: %s %s %s %b" v.vname v.vorig_name (opt_string v.vdescr) v.vdescrpure;
               v.vorig_name = "malloc" || v.vorig_name = "free"
    | _     -> false
    and exp_contains_dyn_mem (e : exp_node) (s : stmt) : bool = match e with
    | Lval (h,_) -> Options.feedback ~level:3 "Lval";
                    lhost_contains_dyn_mem h
    | _          -> Options.feedback ~level:3 "wuzz other";
                    false

let instr_contains_dyn_mem (i : instr) (s : stmt) : bool = match i with
    | Call (_,e,es,_) -> Options.feedback ~level:4 "Call";
                         ignore (Options.feedback ~level:4 "e: %a" Printer.pp_exp e);
                         exp_contains_dyn_mem e.enode s
                         || (Options.feedback ~level:4 "list";
                             List.fold_left (||) false (List.map (fun e -> Options.feedback ~level:4 "l: %a" Printer.pp_exp e; exp_contains_dyn_mem e.enode s) es))
    | Local_init _ -> Options.feedback ~level:4 "Local_init";
                      (* getting back to this later true; *)
                      false
    | _            -> false

let stmt_contains_dyn_mem (s : stmt) : bool = match s.skind with
    | Instr i -> instr_contains_dyn_mem i s
    | _       -> false

class print_cfg out = object
    inherit Visitor.frama_c_inplace

    method !vglob_aux g =
        match g with
        | GFun (f,_) -> Options.feedback ~level:6 "Processing function %s" f.svar.vname;
                        Cil.DoChildrenPost (fun g -> g)
        | _          -> Cil.SkipChildren

    method! vstmt_aux s = Options.feedback ~level:5 "Processing statement %a" Printer.pp_stmt s;
        (* (* Leaving this here as sample use of EVA *)
        let color =
            if Db.Value.is_computed () then
                let state = Db.Value.get_stmt_state s in
                let reachable = Db.Value.is_reachable state in
                if reachable then
                    "fillcolor=\"#ccffcc\" style=filled"
                else
                    "fillcolor=pink style=filled"
            else
                ""
        in
            Format.fprintf out "@[s%d@ [label=%S %s]@];@ " s.sid (Pretty_utils.to_string print_stmt s.skind) color;
            List.iter (fun succ -> Format.fprintf out "@[s%d -> s%d;@]@ " s.sid succ.sid) s.succs;
        *)
        let _ =
            if stmt_contains_dyn_mem s then
                Options.result "Found statement with dynamic memory %a" Printer.pp_stmt s
            else
                ();
        in
            Cil.DoChildren
end
