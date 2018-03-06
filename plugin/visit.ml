open Cil_types

exception WasNone of unit
let from_option = function
    | None   -> raise (WasNone ())
    | Some s -> s

let is_some = function
    | Some _ -> true
    | _      -> false

let get_expr_lvals (es : exp list) : lval list = List.fold_left (fun a e -> match e.enode with
    | Lval (h,o) -> (h,o) :: a
    | _          -> a) [] es

let rec get_free_target (es : exp list) : lval =
    if List.length es != 1 then
        raise (Failure "Multiple exps in free list")
    else
        let target = List.nth es 0 in
        match target.enode with
        | Lval l -> l
        | CastE (_,e) -> get_free_target [e]
        | _ -> raise (Options.result "failed on %a" Printer.pp_exp target; Failure "Unexpected target for free")

let is_free (s : stmt) : exp list option = match s.skind with
    | Instr i -> (match i with
        | Call (_,e,es,_) -> (match e.enode with
            | Lval (h,_) -> (match h with
                | Var v -> if v.vorig_name = "free" then
                               Some es
                           else
                               None
                | _ -> None)
            | _ -> None)
        | _ -> None)
    | _ -> None

class print_cfg out = object
    inherit Visitor.frama_c_inplace

    method !vglob_aux g =
        match g with
        | GFun (f,_) -> Options.feedback ~level:6 "Processing function %s" f.svar.vname;
                        Cil.DoChildrenPost (fun g -> g)
        | _          -> Cil.SkipChildren

    method! vstmt_aux s =
        Options.feedback ~level:5 "Processing statement %a" Printer.pp_stmt s;
        let free_targets_opt = is_free s
        in
            if is_some free_targets_opt then
                (Options.result "Found: %a" Printer.pp_stmt s;
                let lval = List.nth (from_option free_targets_opt) 0 in
                let value = !Db.Value.access_expr (Kstmt s) lval in
                let (b,i) = Locations.Location_Bytes.find_lonely_key value in
                Options.result "%a <> %d" Printer.pp_stmt s (Base.id b))
            else
                ();
            Cil.DoChildren
end
