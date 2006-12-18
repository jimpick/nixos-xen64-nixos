# Given a configuration, this function returns an object with a `get'
# method for retrieving the values of options, falling back to the
# defaults declared in options.nix if no value is given for an
# option.

lib: config:

rec {

  # The option declarations, i.e., option names with defaults and
  # documentation.
  declarations = import ./options.nix;

  # Get the option named `name' from the user configuration, using
  # its default value if it's not defined.
  get = name:
    let
      sameName = lib.filter (opt: lib.eqLists opt.name name) declarations;
      default =
        if sameName == []
        then abort ("Undeclared option `" + printName name + "'.")
        else if !builtins.head sameName ? default
        then abort ("Option `" + printName name + "' has no default.")
        else (builtins.head sameName).default;
    in lib.getAttr name default config;
  
  printName = name: lib.concatStrings (lib.intersperse "." name);

}