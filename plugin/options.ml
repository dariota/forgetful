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

let feedback = Self.feedback
let result = Self.result
