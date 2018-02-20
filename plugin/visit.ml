open Cil_types

let print_stmt out = function
    | Instr i -> Printer.pp_instr out i
    | Return ((Some e),_) -> Format.fprintf out "<return> %a " Printer.pp_exp e
    | Return (None,_) -> Format.pp_print_string out "<return>"
    | Goto _ -> Format.pp_print_string out "<goto> "
    | Break _ -> Format.pp_print_string out "<break> "
    | Continue _ -> Format.pp_print_string out "<continue> "
    | If (e,_,_,_) -> Format.fprintf out "if %a" Printer.pp_exp e
    | Switch (e,_,_,_) -> Format.fprintf out "switch %a" Printer.pp_exp e
    | Loop _ -> Format.fprintf out "<loop> "
    | Block _ -> Format.fprintf out "<block> "
    | UnspecifiedSequence _ -> Format.fprintf out "<unspec> "

class print_cfg out = object
    inherit Visitor.frama_c_inplace

    method !vfile _ =
        Format.fprintf out "@[< hov 2> digraph cfg {@ ";
        Cil.DoChildrenPost (fun f -> Format.fprintf out "}@]@."; f)

    method !vglob_aux g =
        match g with
        | GFun (f,_) ->
                Options.result "func: %s" f.svar.vname;
                Format.fprintf out "@[< hov 2> subgraph cluster_%a {@ \
                                    @[< hv 2> graph@ [label=\"%a\"];@]@ "
                    Printer.pp_varinfo f.svar Printer.pp_varinfo f.svar;
                Cil.DoChildrenPost (fun g -> Format.fprintf out "}@]@ "; g)
        | _ -> Cil.SkipChildren

    method! vstmt_aux s =
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
        let _ =
            match s.skind with
            | Instr i -> ignore (match i with
                         | Call (_,e,es,_) -> ignore (Options.result "<call> %a"  Printer.pp_exp e);
                                              ignore (List.iter (fun e -> Options.result "<calls> %a " Printer.pp_exp e) es)
                         (*
                          * Looks like mallocs happen in this next one somewhere as opposed to as a call
                          * This is a result of mallocs always (at least if they're useful) being assigned.
                          * Can still warn on an unassigned malloc...
                          * *)
                         | _ -> ignore (Options.result "not interesting %a" Printer.pp_instr i))
            | _ -> ignore (Options.result "also not interesting")
        in
            Cil.DoChildren
end
