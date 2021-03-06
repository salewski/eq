open Easy_format

type colors =
  Black
| Red
| Green
| Yellow
| Blue
| Magenta
| Cyan
| White

let color_code color =
  match color with
    Black -> 30
  | Red -> 31
  | Green -> 32
  | Yellow -> 33
  | Blue -> 34
  | Magenta -> 35
  | Cyan -> 36
  | White -> 37

let wrap_color color string =
  match color with
    Some color -> Printf.sprintf "\027[%dm%s\027[0m"
                                 (color_code color)
                                 string
  | None -> string

let with_color color x =
  match x with
    Atom (s, a) -> Atom ((wrap_color color s), a)
  | a -> a

let edn_color_scheme x =
  match x with
    (`String _ | `Char _) -> Some Magenta
  | (`Symbol _ | `Keyword _ | `Tag _) -> Some Green
  | _ -> None

let edn_no_color_scheme x = None

let edn_list = {
    list with
    space_after_opening = false;
    space_before_closing = false;
    align_closing = false;
  }

let string_of_symbol (ns, name) =
  match ns with
    None -> name
  | Some s -> s ^ "/" ^ name

let rec format color_scheme (x : Edn.t) =
  let colorize = with_color (color_scheme x) in

  match x with
    `Null       -> colorize (Atom ("nil", atom))
  | `Bool b     -> colorize (Atom ((if b then "true" else "false"), atom))
  | `String s   -> colorize (Atom ("\"" ^ s ^ "\"", atom))
  | `Char b     -> colorize (Atom (b, atom))
  | `Symbol sym -> colorize (Atom (string_of_symbol sym, atom))
  | `Keyword kw -> colorize (Atom (":" ^ string_of_symbol kw, atom))
  | `Int i      -> colorize (Atom (string_of_int i, atom))
  | `BigInt s   -> colorize (Atom (s, atom))
  | `Float f    -> colorize (Atom(string_of_float f, atom))
  | `Decimal d  -> colorize (Atom (d, atom))
  | `List l     -> List (("(", "", ")", edn_list),  List.map (format color_scheme) l)
  | `Vector v   -> List (("[", "", "]", edn_list),  List.map (format color_scheme) v)
  | `Set s      -> List (("#{", "", "}", edn_list), List.map (format color_scheme) s)
  | `Assoc kvs  -> List (("{", "", "}", edn_list),  List.map (format_assoc color_scheme) kvs)
  | `Tag tv     -> format_tag color_scheme tv

and format_assoc color_scheme (k, v) =
  Label ((format color_scheme k, label), format color_scheme v)

and format_tag color_scheme (ns, name, value) =
  let color = color_scheme (`Symbol (None, "")) in
  let tag = with_color color (Atom ("#" ^ string_of_symbol (ns, name), atom)) in
  Label ((tag, label), format color_scheme value)
