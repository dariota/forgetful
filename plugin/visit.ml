open Cil_types

let from_option = function
    | None   -> raise (Failure "Option was None in call to from_option")
    | Some s -> s

let is_some = function
    | Some _ -> true
    | _      -> false

let rec get_free_target (es : exp list) : lval =
    if List.length es != 1 then
        raise (Failure "Multiple exps in free list")
    else
        let target = List.nth es 0 in
        match target.enode with
        | Lval l -> l
        | CastE (_,e) -> get_free_target [e]
        | _ -> raise (Options.result "failed on %a" Printer.pp_exp target; Failure "Unexpected target for free")

let varinfo_matches (s : string) (v : varinfo) : bool =
    v.vorig_name = s

let is_free (s : stmt) : (location * exp list) option = match s.skind with
    | Instr i -> (match i with
        | Call (_,e,es,loc) -> (match e.enode with
            | Lval (h,_) -> (match h with
                | Var v -> if varinfo_matches "free" v then
                               Some (loc, es)
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

let is_malloc (s : stmt) : (location * varinfo * exp list) option =
    let matches = varinfo_matches "malloc" in
    match s.skind with
    | Instr i -> (match i with
        | Call (vl,e,es,loc) -> (match e.enode with
            | Lval (h,_) -> (match h with
                | Var v -> let target = extract_varinfo_lval vl in
                           if matches v then
                               if is_some target then
                                   Some (loc, from_option target, es)
                               else
                                   (Options.feedback ~level:3 "Could not determine target in %a" Printer.pp_stmt s; None)
                           else
                               None
                | _ -> None)
            | _ -> None)
        | Local_init (vl,l,loc) -> (match l with
            | ConsInit (v,es,_) ->
                if matches v then
                    Some (loc, vl, es)
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

let add_candidate_base locs stmt loc size base =
    let id = Base.id base in
    if not (Base.is_null base) && size <= (Options.AllocSize.get ()) then
        Hashtbl.add locs id (loc, stmt)

let print_candidate_base funcName locs stmt loc base =
    let id = Base.id base in
    if not (Base.is_null base) && Hashtbl.mem locs id then
        let (m_loc, m_stmt) = Hashtbl.find locs id in
        Options.result "Candidate for replacement in %s: `%a` (%a) frees base allocated at `%a` (%a)" funcName Printer.pp_stmt stmt Printer.pp_location loc Printer.pp_stmt m_stmt Printer.pp_location m_loc

class print_cfg out = object
    inherit Visitor.frama_c_inplace

    val mutable locs = Hashtbl.create 10
    val mutable currFunc = ""

    method !vglob_aux g =
        match g with
        | GFun (f,_) -> Options.feedback ~level:6 "Processing function %s" f.svar.vname;
                        ignore (locs <- Hashtbl.create 10);
                        ignore (currFunc <- f.svar.vorig_name);
                        Cil.DoChildrenPost (fun g -> g)
        | _          -> Cil.SkipChildren

    method! vstmt_aux s =
        Options.feedback ~level:5 "Processing statement %a" Printer.pp_stmt s;
        let free_details = is_free s in
        let malloc_details = is_malloc s
        in
            if is_some malloc_details then
                let (loc, target, malloc_list) = from_option malloc_details in
                let maybeVal = get_value_after s target in
                if is_some maybeVal then
                    let tvalue = from_option maybeVal in
                    let tbases = Locations.Location_Bytes.get_bases tvalue in
                    let size_exp = List.nth malloc_list 0 in
                    let value = !Db.Value.access_expr (Kstmt s) size_exp in
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
                                           Integer.to_int (from_option (Ival.max_int i))
                            in
                            Base.SetLattice.iter (add_candidate_base locs s loc size) tbases
                        | _ -> Options.feedback ~level:2 "Could not determine size of malloc %a" Printer.pp_stmt s)
                    )
                else ();
            else ();
            if is_some free_details then
                (Options.feedback ~level:2 "Found free in statement %a" Printer.pp_stmt s;
                let (loc, free_list) = from_option free_details in
                let exp = List.nth free_list 0 in
                let value = !Db.Value.access_expr (Kstmt s) exp in
                let bases = Locations.Location_Bytes.get_bases value in
                Base.SetLattice.iter (print_candidate_base currFunc locs s loc) bases)
            else
                ();
            Cil.DoChildren
end
