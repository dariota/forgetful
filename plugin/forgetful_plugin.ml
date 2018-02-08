let help_msg = "Base plugin to work off for forgetful"

module Self = Plugin.Register
    (struct
        let name = "base plugin"
        let shortname = "base"
        let help = help_msg
    end)

module NumberBase = Self.Int
    (struct
        let option_name = "-base-arithmetic"
        let default = 9
        let arg_name = "base"
        let help = "Sets the base for numeric calculations"
    end)
let () = NumberBase.set_range ~min:2 ~max:10

module Greet = Self.String
    (struct
        let option_name = "-base-greet"
        let default = "It's happening!!!"
        let arg_name = "greeting"
        let help = "The message to output at startup"
    end)

module Enable = Self.False
    (struct
        let option_name = "-base"
        let help = "When on (off by default), outputs some stupid things in the console"
    end)

let rec to_base base num accum =
    let quot = num / base in
    let rem = string_of_int (num mod base) in
    let next = rem ^ accum in
    if quot == 0 then
        next
    else
        to_base base quot next

let run () =
    if Enable.get () then
        let output result = 
            if Greet.is_default () then
                Self.feedback ~level:2 "Wow, what an uncreative user...";
            Self.result "%s" (Greet.get ());
            let result =
                Self.feedback ~level:2 "No one will ever know I love base %d" (NumberBase.get ());
                to_base (NumberBase.get ()) result ""
            in
            Self.result "10 + 9 = %s" result
        in
        output 19

let () = Db.Main.extend run
