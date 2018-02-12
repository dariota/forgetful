let rec to_base_rec base num accum =
    let quot = num / base in
    let rem = string_of_int (num mod base) in
    let next = rem ^ accum in
    if quot == 0 then
        next
    else
        to_base_rec base quot next

let to_base base num = to_base_rec base num ""

let greet () =
    if Options.Greet.is_default () then
        Options.feedback ~level:2 "Wow, what an uncreative user...";
    Options.result "%s" (Options.Greet.get ())

let output num =
    let base = Options.NumberBase.get ()
    in
        Options.feedback ~level:2 "No one will ever know I love base %d" base;
        let result =
            to_base base num
        in
        Options.result "10 + 9 = %s" result
