let help_msg = "Find locations with memory allocations trivial to replace with stack allocations"

module Self = Plugin.Register
    (struct
        let name = "forgetful"
        let shortname = "forgetful"
        let help = help_msg
    end)

module AllocSize = Self.Int
    (struct
        let option_name = "-forgetful-max-alloc-size"
        let default = 64
        let arg_name = "max size"
        let help = "Determines the maximum size (in bytes) to report replaceable allocations for"
    end)
let () = AllocSize.set_range ~min:0 ~max:2147483647

module Enable = Self.False
    (struct
        let option_name = "-forgetful"
        let help = "When on (off by default), reports replaceable allocations of size equal to or less than max size"
    end)

let feedback = Self.feedback
let result = Self.result
