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
                if f.svar.vname = "f" then
                    let _ = Format.fprintf out "@[< hov 2> subgraph cluster_%a {@ \
                                        @[< hv 2> graph@ [label=\"%a\"];@]@ "
                        Printer.pp_varinfo f.svar Printer.pp_varinfo f.svar in
                    Cil.DoChildrenPost (fun g -> Format.fprintf out "}@]@ "; g)
                else
                    Cil.SkipChildren
        | _ -> Cil.SkipChildren

    method !vstmt_aux s =
        Format.fprintf out "@[< hov 2> s%d@ [label=%S]@];@ " s.sid (Pretty_utils.to_string print_stmt s.skind);
        List.iter (fun succ -> Format.fprintf out "@[s%d -> s%d;@]@ " s.sid succ.sid) s.succs;
        Format.fprintf out "@]";
        Cil.DoChildren
end
