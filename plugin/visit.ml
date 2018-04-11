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

(* adapted from https://stackoverflow.com/a/36138145/6519610 *)
let get_value_after (s : stmt) (vi : varinfo) : Db.Value.t option =
  let kinstr = Kstmt s in
  let lv = Cil.var vi in
  let loc =
      !Db.Value.lval_to_loc kinstr ~with_alarms:CilE.warn_none_mode lv
  in
  Db.Value.fold_state_callstack
      (fun state _ ->
          Some (Db.Value.find state loc)
      ) None ~after:true kinstr

class print_cfg out = object
    inherit Visitor.frama_c_inplace

    val mutable locs = Hashtbl.create 10

    method !vglob_aux g =
        match g with
        | GFun (f,_) -> Options.feedback ~level:6 "Processing function %s" f.svar.vname;
                        ignore (locs = Hashtbl.create 10);
                        Cil.DoChildrenPost (fun g -> g)
        | _          -> Cil.SkipChildren

    method! vstmt_aux s =
        Options.feedback ~level:5 "Processing statement %a" Printer.pp_stmt s;
        let free_targets_opt = is_free s in
        let malloc_details = is_malloc s
        in
            if is_some malloc_details then
                let (target, malloc_list) = from_option malloc_details in
                let tvalue = from_option (get_value_after s target) in
                let tbases = Locations.Location_Bytes.get_bases tvalue in
                (Base.SetLattice.iter (fun e -> Options.feedback ~level:2 "malloc resultant bases: %a" Base.pretty_addr e) tbases;
                let exp = List.nth malloc_list 0 in
                let value = !Db.Value.access_expr (Kstmt s) exp in
                let (b, i) = Locations.Location_Bytes.find_lonely_key value in
                let validity = Base.validity b in
                (if Ival.is_bottom i then
                    Options.feedback ~level:2 "Could not determine size of malloc %a" Printer.pp_stmt s
                else
                    (match validity with
                    | Invalid ->
                        let size = if Ival.is_singleton_int i then
                                       Integer.to_int (Ival.project_int i)
                                   else
                                       (Options.result "variable size range from %d to %d in %a" (Integer.to_int (from_option (Ival.min_int i))) (Integer.to_int (from_option (Ival.max_int i))) Printer.pp_stmt s;
                                       Integer.to_int (from_option (Ival.max_int i)))
                        in
                        Base.SetLattice.iter (fun e -> if size <= 48 && not (Base.is_null e) then Hashtbl.add locs (Base.id e) s else ()) tbases
                    | _ -> Options.feedback ~level:2 "Could not determine size of malloc %a" Printer.pp_stmt s)
                ))
            else ();
            if is_some free_targets_opt then
                (Options.feedback ~level:2 "Found free in statement %a" Printer.pp_stmt s;
                let exp = List.nth (from_option free_targets_opt) 0 in
                let value = !Db.Value.access_expr (Kstmt s) exp in
                let bases = Locations.Location_Bytes.get_bases value in
                Base.SetLattice.iter (fun e -> Options.result "freeing base: %a" Base.pretty_addr e; if (not (Base.is_null e)) && Hashtbl.mem locs (Base.id e) then Options.result "previous base is from stmt: %a" Printer.pp_stmt (Hashtbl.find locs (Base.id e))) bases)
            else
                ();
            Cil.DoChildren
end
