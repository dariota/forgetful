let run () =
    if Options.Enable.get () then
        let chan = open_out "cfg.out" in
        let fmt = Format.formatter_of_out_channel chan in
        let () = Visitor.visitFramacFileSameGlobals (new Visit.print_cfg fmt) (Ast.get ()) in
        close_out chan

let () = Db.Main.extend run
