let run () =
    if Options.Enable.get () then
        let () = Helper.greet () in
        Helper.output 19

let () = Db.Main.extend run
