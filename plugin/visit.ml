open Cil_types

let from_option = function
    | None   -> raise (Failure "Option was None in call to from_option")
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

let varinfo_matches (v : varinfo) (s : string) : bool =
    v.vorig_name = s

let is_free (s : stmt) : exp list option = match s.skind with
    | Instr i -> (match i with
        | Call (_,e,es,_) -> (match e.enode with
            | Lval (h,_) -> (match h with
                | Var v -> if varinfo_matches v "free" then
                               Some es
                           else
                               None
                | _ -> None)
            | _ -> None)
        | _ -> None)
    | _ -> None

let extract_varinfo_lval (v : lval option) : varinfo option =
    if is_some v then
        (let (lh,_) = from_option v in
        match lh with
        | Var vi -> Some vi
        | _ -> None)
    else
        None

let is_malloc (s : stmt) : (varinfo * exp list) option = match s.skind with
    | Instr i -> (match i with
        | Call (vl,e,es,_) -> (match e.enode with
            | Lval (h,_) -> (match h with
                | Var v -> let target = extract_varinfo_lval vl in
                           if varinfo_matches v "malloc" then
                               if is_some target then
                                   Some (from_option target, es)
                               else
                                   (Options.feedback ~level:3 "Could not determine target in %a" Printer.pp_stmt s; None)
                           else
                               None
                | _ -> None)
            | _ -> None)
        | Local_init (vl,l,_) -> (match l with
            | ConsInit (v,es,_) ->
                if varinfo_matches v "malloc" then
                    Some (vl, es)
                else
                    None
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
                (Options.feedback ~level:2 "Found free in statement %a" Printer.pp_stmt s;
                let exp = List.nth (from_option free_targets_opt) 0 in
                let value = !Db.Value.access_expr (Kstmt s) exp in
                let bases = Locations.Location_Bytes.get_bases value in
                Base.SetLattice.iter (fun e -> Options.result "freeing base: %a" Base.pretty_addr e) bases)
            else
                ();
            Cil.DoChildren
end
