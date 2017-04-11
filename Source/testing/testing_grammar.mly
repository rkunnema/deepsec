%{

open Testing_parser_functions

%}

%token <string> STRING
%token <int> INT

/* Tuples and projections */

%token <int*int> PROJ
%token TUPLE

/* Test declaration */

%token SIGNATURE
%token REWRITING_SYSTEM
%token FST_VARS
%token SND_VARS
%token NAMES
%token AXIOMS
%token INPUT
%token RESULT
%token PROTOCOL
%token RECIPE

/* Process declaration */
%token NIL
%token OUTPUT INPUT
%token TEST LET
%token NEW
%token PAR CHOICE

/* Semantics and equivalence */
%token CLASSIC PRIVATE EAVESDROP
%token TRACEEQ OBSEQ

/* Special token  */
%token EQ NEQ EQI NEQI
%token WEDGE VEE VDASH
%token BOT TOP
%token RIGHTARROW LLEFTARROW
%token LPAR RPAR
%token LBRACE RBRACE
%token LCURL RCURL
%token BAR PLUS SLASH
%token SEMI DDOT DOT COMMA

%token EOF

%left SEMI COMMA WEDGE VEE

/* the entry points */
%start parse_Term_Subst_unify parse_Term_Subst_is_matchable
%start parse_Term_Subst_is_extended_by parse_Term_Subst_is_equal_equations
%start parse_Term_Modulo_syntactic_equations_of_equations
%start parse_Term_Rewrite_rules_normalise parse_Term_Rewrite_rules_skeletons parse_Term_Rewrite_rules_generic_rewrite_rules_formula

%start parse_Data_structure_Eq_implies parse_Data_structure_Tools_partial_consequence
%start parse_Data_structure_Tools_partial_consequence_additional
%start parse_Data_structure_Tools_uniform_consequence

%start parse_Process_of_expansed_process
%start parse_Process_next_output

%type <(Testing_parser_functions.parser)> parse_Term_Subst_unify
%type <(Testing_parser_functions.parser)> parse_Term_Subst_is_matchable
%type <(Testing_parser_functions.parser)> parse_Term_Subst_is_extended_by
%type <(Testing_parser_functions.parser)> parse_Term_Subst_is_equal_equations
%type <(Testing_parser_functions.parser)> parse_Term_Modulo_syntactic_equations_of_equations
%type <(Testing_parser_functions.parser)> parse_Term_Rewrite_rules_normalise
%type <(Testing_parser_functions.parser)> parse_Term_Rewrite_rules_skeletons
%type <(Testing_parser_functions.parser)> parse_Term_Rewrite_rules_generic_rewrite_rules_formula

%type <(Testing_parser_functions.parser)> parse_Data_structure_Eq_implies
%type <(Testing_parser_functions.parser)> parse_Data_structure_Tools_partial_consequence
%type <(Testing_parser_functions.parser)> parse_Data_structure_Tools_partial_consequence_additional
%type <(Testing_parser_functions.parser)> parse_Data_structure_Tools_uniform_consequence

%type <(Testing_parser_functions.parser)> parse_Process_of_expansed_process
%type <(Testing_parser_functions.parser)> parse_Process_next_output

%%
/***********************************
***           Main Entry         ***
************************************/

header_of_test:
  | SIGNATURE DDOT signature
    REWRITING_SYSTEM DDOT rewriting_system
    FST_VARS DDOT fst_var_list
    SND_VARS DDOT snd_var_list
    NAMES DDOT name_list
    AXIOMS DDOT axiom_list
      {
        (fun () ->
          initialise_parsing ();
          parse_signature $3;
          parse_fst_vars $9;
          parse_snd_vars $12;
          parse_names $15;
          parse_axioms $18;
          parse_rewriting_system $6;
        )
      }

parse_Term_Subst_unify:
  | header_of_test
    INPUT DDOT atom
    INPUT DDOT syntactic_equation_list
    RESULT DDOT substitution_option
      {
        (fun mode -> $1 ();
          if $4 = true
          then
            let eq_list = parse_syntactic_equation_list Term.Protocol $7 in
            match mode with
              | Load i ->
                  let result = parse_substitution_option Term.Protocol $10 in
                  RLoad(Testing_functions.load_Term_Subst_unify i Term.Protocol eq_list result)
              | Verify ->
                  RVerify (Testing_functions.apply_Term_Subst_unify Term.Protocol eq_list)
          else
            let eq_list = parse_syntactic_equation_list Term.Recipe $7 in
            match mode with
              | Load i ->
                  let result = parse_substitution_option Term.Recipe $10 in
                  RLoad (Testing_functions.load_Term_Subst_unify i Term.Recipe eq_list result)
              | Verify ->
                  RVerify (Testing_functions.apply_Term_Subst_unify Term.Recipe eq_list)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

parse_Term_Subst_is_matchable:
  | header_of_test
    INPUT DDOT atom
    INPUT DDOT term_list
    INPUT DDOT term_list
    RESULT DDOT boolean
      {
        (fun mode -> $1 ();
          if $4 = true
          then
            let list1 = parse_term_list Term.Protocol $7 in
            let list2 = parse_term_list Term.Protocol $10 in
            match mode with
              | Load i -> RLoad (Testing_functions.load_Term_Subst_is_matchable i Term.Protocol list1 list2 $13)
              | Verify -> RVerify (Testing_functions.apply_Term_Subst_is_matchable Term.Protocol list1 list2)
          else
            let list1 = parse_term_list Term.Recipe $7 in
            let list2 = parse_term_list Term.Recipe $10 in
            match mode with
              | Load i -> RLoad (Testing_functions.load_Term_Subst_is_matchable i Term.Recipe list1 list2 $13)
              | Verify -> RVerify (Testing_functions.apply_Term_Subst_is_matchable Term.Recipe list1 list2)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

parse_Term_Subst_is_extended_by:
  | header_of_test
    INPUT DDOT atom
    INPUT DDOT substitution
    INPUT DDOT substitution
    RESULT DDOT boolean
      {
        (fun mode -> $1 ();
          if $4 = true
          then
            let subst1 = parse_substitution Term.Protocol $7 in
            let subst2 = parse_substitution Term.Protocol $10 in
            match mode with
              | Load i -> RLoad (Testing_functions.load_Term_Subst_is_extended_by i Term.Protocol subst1 subst2 $13)
              | Verify -> RVerify (Testing_functions.apply_Term_Subst_is_extended_by Term.Protocol subst1 subst2)
          else
            let subst1 = parse_substitution Term.Recipe $7 in
            let subst2 = parse_substitution Term.Recipe $10 in
            match mode with
              | Load i -> RLoad (Testing_functions.load_Term_Subst_is_extended_by i Term.Recipe subst1 subst2 $13)
              | Verify -> RVerify (Testing_functions.apply_Term_Subst_is_extended_by Term.Recipe subst1 subst2)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

parse_Term_Subst_is_equal_equations:
  | header_of_test
    INPUT DDOT atom
    INPUT DDOT substitution
    INPUT DDOT substitution
    RESULT DDOT boolean
      {
        (fun mode -> $1 ();
          if $4 = true
          then
            let subst1 = parse_substitution Term.Protocol $7 in
            let subst2 = parse_substitution Term.Protocol $10 in
            match mode with
              | Load i -> RLoad (Testing_functions.load_Term_Subst_is_equal_equations i Term.Protocol subst1 subst2 $13)
              | Verify -> RVerify (Testing_functions.apply_Term_Subst_is_equal_equations Term.Protocol subst1 subst2)
          else
            let subst1 = parse_substitution Term.Recipe $7 in
            let subst2 = parse_substitution Term.Recipe $10 in
            match mode with
              | Load i -> RLoad (Testing_functions.load_Term_Subst_is_equal_equations i Term.Recipe subst1 subst2 $13)
              | Verify -> RVerify (Testing_functions.apply_Term_Subst_is_equal_equations Term.Recipe subst1 subst2)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

parse_Term_Modulo_syntactic_equations_of_equations:
  | header_of_test
    INPUT DDOT equation_list
    RESULT DDOT substitution_list_result
      {
        (fun mode -> $1 ();
          let eq_list = parse_equation_list $4 in
          match mode with
            | Load i ->
                let result = parse_substitution_list_result $7 in
                RLoad(Testing_functions.load_Term_Modulo_syntactic_equations_of_equations i eq_list result)
            | Verify -> RVerify (Testing_functions.apply_Term_Modulo_syntactic_equations_of_equations eq_list)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

parse_Term_Rewrite_rules_normalise:
  | header_of_test
    INPUT DDOT term
    RESULT DDOT term
      {
        (fun mode -> $1 ();
          let term = parse_term Term.Protocol $4 in
          match mode with
            | Load i ->
                let result = parse_term Term.Protocol $7 in
                RLoad(Testing_functions.load_Term_Rewrite_rules_normalise i term result)
            | Verify -> RVerify (Testing_functions.apply_Term_Rewrite_rules_normalise term)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

parse_Term_Rewrite_rules_skeletons:
  | header_of_test
    INPUT DDOT term
    INPUT DDOT ident
    INPUT DDOT INT
    RESULT DDOT skeleton_list
      {
        (fun mode -> $1 ();
          let term = parse_term Term.Protocol $4 in
          let symbol = parse_symbol $7 in
          match mode with
            | Load i ->
                let result = parse_skeleton_list $13 in
                RLoad(Testing_functions.load_Term_Rewrite_rules_skeletons i term symbol $10 result)
            | Verify -> RVerify(Testing_functions.apply_Term_Rewrite_rules_skeletons term symbol $10)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

parse_Term_Rewrite_rules_generic_rewrite_rules_formula:
  | header_of_test
    INPUT DDOT deduction_fact
    INPUT DDOT skeleton
    RESULT DDOT deduction_formula_list
      {
        (fun mode -> $1 ();
          let ded_fct = parse_deduction_fact $4 in
          let skel = parse_skeleton $7 in
          match mode with
            | Load i ->
                let result = parse_deduction_formula_list $10 in
                RLoad(Testing_functions.load_Term_Rewrite_rules_generic_rewrite_rules_formula i ded_fct skel result)
            | Verify -> RVerify(Testing_functions.apply_Term_Rewrite_rules_generic_rewrite_rules_formula ded_fct skel)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

parse_Data_structure_Eq_implies:
  | header_of_test
    INPUT DDOT atom
    INPUT DDOT data_Eq
    INPUT DDOT term
    INPUT DDOT term
    RESULT DDOT boolean
      {
        (fun mode -> $1 ();
          if $4 = true
          then
            let form = parse_Eq Term.Protocol $7 in
            let term1 = parse_term Term.Protocol $10 in
            let term2 = parse_term Term.Protocol $13 in
            match mode with
              | Load i -> RLoad(Testing_functions.load_Data_structure_Eq_implies i Term.Protocol form term1 term2 $16)
              | Verify -> RVerify(Testing_functions.apply_Data_structure_Eq_implies Term.Protocol form term1 term2)
          else
            let form = parse_Eq Term.Recipe $7 in
            let term1 = parse_term Term.Recipe $10 in
            let term2 = parse_term Term.Recipe $13 in
            match mode with
              | Load i -> RLoad(Testing_functions.load_Data_structure_Eq_implies i Term.Recipe form term1 term2  $16)
              | Verify -> RVerify(Testing_functions.apply_Data_structure_Eq_implies Term.Recipe form term1 term2)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

parse_Data_structure_Tools_partial_consequence:
  | header_of_test
    INPUT DDOT atom
    INPUT DDOT sdf
    INPUT DDOT df
    INPUT DDOT term
    RESULT DDOT consequence
      {
        (fun mode -> $1 ();
          if $4 = true
          then
            let sdf = parse_SDF $7 in
            let df = parse_DF $10 in
            let term = parse_term Term.Protocol $13 in
            match mode with
              | Load i ->
                  let result = parse_consequence $16 in
                  RLoad(Testing_functions.load_Data_structure_Tools_partial_consequence i Term.Protocol sdf df term result)
              | Verify -> RVerify(Testing_functions.apply_Data_structure_Tools_partial_consequence Term.Protocol sdf df term)
          else
            let sdf = parse_SDF $7 in
            let df = parse_DF $10 in
            let term = parse_term Term.Recipe $13 in
            match mode with
              | Load i ->
                  let result = parse_consequence $16 in
                  RLoad(Testing_functions.load_Data_structure_Tools_partial_consequence i Term.Recipe sdf df term result)
              | Verify -> RVerify(Testing_functions.apply_Data_structure_Tools_partial_consequence Term.Recipe sdf df term)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

parse_Data_structure_Tools_partial_consequence_additional:
  | header_of_test
    INPUT DDOT atom
    INPUT DDOT sdf
    INPUT DDOT df
    INPUT DDOT basic_deduction_fact_list_conseq
    INPUT DDOT term
    RESULT DDOT consequence
      {
        (fun mode -> $1 ();
          if $4 = true
          then
            let sdf = parse_SDF $7 in
            let df = parse_DF $10 in
            let bfct_l = List.map parse_basic_deduction_fact $13 in
            let term = parse_term Term.Protocol $16 in
            match mode with
              | Load i ->
                  let result = parse_consequence $19 in
                  RLoad(Testing_functions.load_Data_structure_Tools_partial_consequence_additional i Term.Protocol sdf df bfct_l term result)
              | Verify -> RVerify(Testing_functions.apply_Data_structure_Tools_partial_consequence_additional Term.Protocol sdf df bfct_l term)
          else
            let sdf = parse_SDF $7 in
            let df = parse_DF $10 in
            let bfct_l = List.map parse_basic_deduction_fact $13 in
            let term = parse_term Term.Recipe $16 in
            match mode with
              | Load i ->
                  let result = parse_consequence $19 in
                  RLoad(Testing_functions.load_Data_structure_Tools_partial_consequence_additional i Term.Recipe sdf df bfct_l term result)
              | Verify -> RVerify(Testing_functions.apply_Data_structure_Tools_partial_consequence_additional Term.Recipe sdf df bfct_l term)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

parse_Data_structure_Tools_uniform_consequence:
  | header_of_test
    INPUT DDOT sdf
    INPUT DDOT df
    INPUT DDOT uniformity_set
    INPUT DDOT term
    RESULT DDOT recipe_option
      {
        (fun mode -> $1 ();
          let sdf = parse_SDF $4 in
          let df = parse_DF $7 in
          let uniset = parse_Uniformity_Set $10 in
          let term = parse_term Term.Protocol $13 in
          match mode with
            | Load i ->
                let result = parse_recipe_option $16 in
                RLoad(Testing_functions.load_Data_structure_Tools_uniform_consequence i sdf df uniset term result)
            | Verify -> RVerify(Testing_functions.apply_Data_structure_Tools_uniform_consequence sdf df uniset term)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

parse_Process_of_expansed_process:
  | header_of_test
    INPUT DDOT expansed_process
    RESULT DDOT process
      {
        (fun mode -> $1 ();
          let process = parse_expansed_process $4 in
          match mode with
            | Load i ->
                let result = parse_process $7 in
                RLoad(Testing_functions.load_Process_of_expansed_process i process result)
            | Verify -> RVerify(Testing_functions.apply_Process_of_expansed_process process)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

parse_Process_next_output:
  | header_of_test
    INPUT DDOT semantics
    INPUT DDOT equivalence
    INPUT DDOT process
    INPUT DDOT substitution
    RESULT DDOT output_transition_result
      {
        (fun mode -> $1 ();
          let process = parse_process $10 in
          let subst = parse_substitution Term.Protocol $13 in
          match mode with
            | Load i ->
                let result = parse_output_transition $16 in
                RLoad(Testing_functions.load_Process_next_output i $4 $7 process subst result)
            | Verify -> RVerify(Testing_functions.apply_Process_next_output $4 $7 process subst)
        )
      }
  | error
      { error_message (Parsing.symbol_start_pos ()).Lexing.pos_lnum "Syntax Error" }

/***********************************
***     Signature definition     ***
************************************/

signature :
  | LCURL RCURL tuple
      { [],$3 }
  | LCURL signature_list RCURL tuple
      { $2,$4 }

signature_list :
  | ident SLASH INT
      { [$1,$3] }
  | ident SLASH INT COMMA signature_list
      { ($1,$3)::$5 }

tuple :
  | TUPLE DDOT LCURL RCURL
      { [] }
  | TUPLE DDOT LCURL tuple_list RCURL
      { $4 }

tuple_list :
  | INT
      { [ $1 ] }
  | INT COMMA tuple_list
      { $1::$3 }

/***********************************
***        Rewriting rules       ***
************************************/

rewriting_system :
  | LBRACE RBRACE
      { [] }
  | LBRACE rewrite_rules_symbol RBRACE
      { $2 }

rewrite_rules_symbol :
  | ident COMMA LBRACE rules_list RBRACE
      { [ $1,$4 ] }
  | ident COMMA LBRACE rules_list RBRACE SEMI rewrite_rules_symbol
      { ($1,$4)::$7 }

rules_list :
  | left_arguments COMMA term
      { [$1,$3] }
  | left_arguments COMMA term SEMI rules_list
      { ($1,$3)::$5 }

left_arguments :
  | LBRACE RBRACE
      { [] }
  | LBRACE left_arguments_list RBRACE
      { $2 }

left_arguments_list :
  | term
      { [$1] }
  | term SEMI left_arguments_list
      { $1::$3 }

/***********************************
***             ATOM             ***
************************************/

atom :
  | PROTOCOL
      { true }
  | RECIPE
      { false }

/**********************************************
***         Variable, names, axioms         ***
***********************************************/

fst_var_list :
  | LCURL RCURL
      { [] }
  | LCURL sub_fst_var_list RCURL
      { $2 }

sub_fst_var_list :
  | ident
      { [$1] }
  | ident COMMA sub_fst_var_list
      { $1::$3 }

snd_var_list :
  | LCURL RCURL
      { [] }
  | LCURL sub_snd_var_list RCURL
      { $2 }

sub_snd_var_list :
  | ident DDOT INT
      { [$1,$3] }
  | ident DDOT INT COMMA sub_snd_var_list
      { ($1,$3)::$5 }

name_list :
  | LCURL RCURL
      { [] }
  | LCURL sub_name_list RCURL
      { $2 }

sub_name_list :
  | ident
      { [$1] }
  | ident COMMA sub_name_list
      { $1::$3 }

axiom_list :
  | LCURL RCURL
      { [] }
  | LCURL sub_axiom_list RCURL
      { $2 }

single_axiom :
  | ident
      { ($1,None) }
  | ident LBRACE ident RBRACE
      { ($1,Some $3) }

sub_axiom_list :
  | single_axiom
      { [$1] }
  | single_axiom COMMA sub_axiom_list
      { $1::$3 }

/*****************************************
***      Syntactic equation list       ***
******************************************/

syntactic_equation_list :
  | TOP
      { [] }
  | sub_syntactic_equation_list
      { $1 }

sub_syntactic_equation_list :
  | term EQ term
      { [$1, $3] }
  | term EQ term WEDGE sub_syntactic_equation_list
      { ($1,$3)::$5 }

/*****************************************
***           Equations list           ***
******************************************/

equation :
  | term EQI term
      { $1,$3 }

equation_list :
  | TOP
      { [] }
  | sub_equation_list
      { $1 }

sub_equation_list :
  | equation
      { [$1] }
  | equation WEDGE sub_equation_list
      { $1::$3 }

/***********************************
***         Substitution         ***
************************************/

substitution_option:
  | substitution
      { Some $1 }
  | BOT
      { None }

substitution :
  | LCURL RCURL
      { [] }
  | LCURL sub_substitution RCURL
      { $2 }

sub_substitution:
  | ident RIGHTARROW term
      { [$1,$3] }
  | ident RIGHTARROW term COMMA sub_substitution
      { ($1,$3)::$5}

substitution_list_result:
  | TOP
      { Term.Modulo.Top_raised }
  | BOT
      { Term.Modulo.Bot_raised }
  | substitution_list
      { Term.Modulo.Ok $1 }

substitution_list:
  | substitution
      { [$1] }
  | substitution VEE substitution_list
      { $1::$3 }

/**********************************************
***          Basic deduction fact           ***
***********************************************/

basic_deduction_fact:
  | ident DDOT INT VDASH term
      { ($1,$3,$5) }

basic_deduction_fact_list:
  | basic_deduction_fact
      { [$1] }
  | basic_deduction_fact WEDGE basic_deduction_fact_list
      { $1::$3 }

basic_deduction_fact_list_conseq:
  | LCURL RCURL
      { [] }
  | LCURL sub_basic_deduction_fact_list_conseq RCURL
      { $2 }

sub_basic_deduction_fact_list_conseq:
  | basic_deduction_fact
      { [$1] }
  | basic_deduction_fact COMMA sub_basic_deduction_fact_list_conseq
      { $1::$3 }

/****************************************
***          Deduction fact           ***
*****************************************/

deduction_fact:
  | term VDASH term
      { ($1,$3) }

/*******************************************
***          Deduction formula           ***
********************************************/

deduction_formula:
  | deduction_fact LLEFTARROW basic_deduction_fact_list SEMI substitution
      { ($1,$3,$5) }

deduction_formula_list:
  | LCURL RCURL
      { [] }
  | LCURL sub_deduction_formula_list RCURL
      { $2 }


sub_deduction_formula_list:
  | deduction_formula
      { [$1] }
  | deduction_formula COMMA sub_deduction_formula_list
      { $1::$3 }

/***********************************
***          Skeletons           ***
************************************/

skeleton_list:
  | LCURL RCURL
      { [] }
  | LCURL sub_skeleton_list RCURL
      { $2 }

sub_skeleton_list:
  | skeleton
      { [$1] }
  | skeleton COMMA sub_skeleton_list
      { $1::$3 }

skeleton:
  | LPAR ident COMMA term COMMA term COMMA basic_deduction_fact_list COMMA term RIGHTARROW term RPAR
      { ($2,$4,$6,$8,($10,$12)) }

/***********************************
***           Term list          ***
************************************/

term_list:
  | LBRACE RBRACE
      { [] }
  | LBRACE sub_term_list RBRACE
      { $2 }

sub_term_list :
  | term
      { [$1] }
  | term SEMI sub_term_list
      { $1 :: $3 }

/***********************************
***           Boolean            ***
************************************/

boolean:
  | TOP { true }
  | BOT { false }


/***********************************
***            Eq.t              ***
************************************/

data_Eq:
  | TOP
      { Top }
  | BOT
      { Bot }
  | conjunction_syntaxtic_disequation
      { Other $1 }

syntactic_disequation:
  | term NEQ term
      { ($1,$3) }

diseq_t:
  | LPAR sub_diseq_t RPAR
      { $2 }

sub_diseq_t :
  | syntactic_disequation
      { [$1] }
  | syntactic_disequation VEE sub_diseq_t
      { $1::$3 }

conjunction_syntaxtic_disequation:
  | diseq_t
      { [$1] }
  | diseq_t WEDGE conjunction_syntaxtic_disequation
      { $1::$3 }

/*************************
***        SDF         ***
**************************/

sdf:
  | LCURL RCURL
      { [] }
  | LCURL sub_sdf RCURL
      { $2 }

sub_sdf:
  | deduction_fact
      { [$1] }
  | deduction_fact COMMA sub_sdf
      { $1::$3 }

/*************************
***        DF         ***
**************************/

df:
  | LCURL RCURL
      { [] }
  | LCURL sub_df RCURL
      { $2 }

sub_df:
  | basic_deduction_fact
      { [$1] }
  | basic_deduction_fact COMMA sub_df
      { $1::$3 }

/***********************************
***        Uniformity_Set        ***
************************************/

uniformity_set:
  | LCURL RCURL
      { [] }
  | LCURL sub_uniformity_set RCURL
      { $2 }

sub_uniformity_set:
  | LPAR term COMMA term RPAR
      { [($2,$4)] }
  | LPAR term COMMA term RPAR COMMA sub_uniformity_set
      { ($2,$4)::$7 }

/********************************
***        Consequence        ***
*********************************/

consequence:
  | BOT
      { None }
  | LPAR term COMMA term RPAR
      { Some ($2,$4) }

recipe_option:
  | BOT
      { None }
  | term
      { Some $1 }

/*************************
***       Terms        ***
**************************/

ident :
  | STRING
      { ($1,(Parsing.symbol_start_pos ()).Lexing.pos_lnum) }

term:
  | ident
      { Id $1 }
  | PROJ LPAR term RPAR
      {
        let (i,n) = $1 in
        Proj(i,n,$3,(Parsing.symbol_start_pos ()).Lexing.pos_lnum)
      }
  | ident LPAR term_arguments RPAR
      { FuncApp($1,$3) }
  | LPAR term_arguments RPAR
      { if List.length $2 = 1
        then List.hd $2
        else Tuple($2) }

term_arguments :
  | term
      { [$1] }
  | term COMMA term_arguments
      { $1::$3 }

/***********************************
***       Expansed process       ***
************************************/

expansed_process:
  | NIL
      { ENil }
  | OUTPUT LPAR term COMMA term COMMA expansed_process RPAR
      { EOutput($3,$5,$7) }
  | INPUT LPAR term COMMA ident COMMA expansed_process RPAR
      { EInput($3,$5,$7) }
  | TEST LPAR term COMMA term COMMA expansed_process COMMA expansed_process RPAR
      { ETest($3,$5,$7,$9) }
  | LET LPAR term COMMA term COMMA expansed_process COMMA expansed_process RPAR
      { ELet($3,$5,$7,$9) }
  | NEW LPAR ident COMMA expansed_process RPAR
      { ENew($3,$5) }
  | PAR LPAR expansed_process_mult_list RPAR
      { EPar($3) }
  | CHOICE LPAR expansed_process_list RPAR
      { EChoice($3) }

expansed_process_mult_list:
  | expansed_process COMMA INT
      { [$1,$3] }
  | expansed_process COMMA INT SEMI expansed_process_mult_list
      { ($1,$3)::$5 }

expansed_process_list:
  | expansed_process
      { [$1] }
  | expansed_process SEMI expansed_process_list
      { $1::$3 }

/***********************************
***            Process           ***
************************************/

process:
  | LCURL LBRACE content_list RBRACE COMMA LBRACE symbolic_derivation_list RBRACE RCURL
      { ($3,$7) }

content_list:
  | content
      { [$1] }
  | content SEMI content_list
      { $1::$3 }

content:
  | LCURL INT SEMI action RCURL
      { $2, $4 }

renaming:
  | LCURL RCURL
      { [] }
  | LCURL sub_renaming RCURL
      { $2 }

sub_renaming:
  | ident RIGHTARROW ident
      { [$1,$3] }
  | ident RIGHTARROW ident SEMI sub_renaming
      { ($1,$3)::$5 }

action:
  | NIL
      { ANil }
  | OUTPUT LPAR term COMMA term COMMA INT RPAR
      { AOut($3,$5,$7) }
  | INPUT LPAR term COMMA ident COMMA INT RPAR
      { AIn($3,$5,$7) }
  | TEST LPAR term COMMA term COMMA INT COMMA INT RPAR
      { ATest($3,$5,$7,$9) }
  | LET LPAR term COMMA term COMMA INT COMMA INT RPAR
      { ALet($3,$5,$7,$9) }
  | NEW LPAR ident COMMA INT RPAR
      { ANew($3,$5) }
  | PAR LPAR content_mult_list RPAR
      { APar($3) }
  | CHOICE LPAR content_mult_list RPAR
      { AChoice($3) }

content_mult:
  | LPAR INT COMMA INT RPAR
      { $2,$4 }

content_mult_list:
  | content_mult
      { [$1] }
  | content_mult COMMA content_mult_list
      { $1::$3 }

symbolic_derivation_list:
  | symbolic_derivation
      { [$1] }
  | symbolic_derivation SEMI symbolic_derivation_list
      { $1::$3 }

symbolic_derivation:
  | LCURL content_mult SEMI renaming SEMI renaming RCURL
      { $2,$4,$6 }

/*************************************
***           Transition           ***
**************************************/

semantics:
  | CLASSIC     { Process.Classic }
  | PRIVATE     { Process.Private }
  | EAVESDROP   { Process.Eavesdrop }

equivalence:
  | TRACEEQ     { Process.Trace_Equivalence }
  | OBSEQ       { Process.Observational_Equivalence }

output_transition_result:
  | LCURL RCURL
      { [] }
  | LCURL sub_output_transition_result RCURL
      { $2 }

sub_output_transition_result:
  | output_transition
      { [$1] }
  | output_transition SEMI sub_output_transition_result
      { $1::$3 }

out_disequation:
  | TOP
      { [] }
  | conjunction_syntaxtic_disequation
      { $1 }

output_transition:
  | LCURL process SEMI substitution SEMI out_disequation SEMI term SEMI term SEMI term_list RCURL
      { ($2,$4,$6,$8,$10, $12) }
