(** The data structures building constraint systems *)

open Types

type basic_fact =
  {
    bf_var : recipe_variable;
    bf_term : term
  }

type deduction_fact =
  {
    df_recipe : recipe;
    df_term : term;
  }

type equality_fact =
  {
    ef_recipe1 : recipe;
    ef_recipe2 : recipe;
  }

type deduction_formula =
  {
    df_head : deduction_fact;
    df_equations : (variable * term) list
  }

type equality_formula =
  {
    ef_head : equality_fact;
    ef_equations : (variable * term) list
  }

(** {2 {% The set of basic deduction facts formulas \texorpdfstring{$\Df$}{DF} %}}*)

module DF : sig

  (** The type represents the set of basic deduction facts that will be used in constraint systems, {% i.e. $\Df$. %} *)
  type t

  (** {3 Generation} *)

  (** The empty set {% $\Df$ %} *)
  val empty : t

  (** [add] {% $\Df$~$\psi$ adds the basic deduction fact $\psi$ into $\Df$. %}
      @raise Internal_error if a basic deduction fact with the same second-order variable already exists in {% $\Df$. \highdebug %} *)
  val add : t -> basic_fact -> t

  (** [remove] {% $\Df$~$X$ remove the basic deduction having $X$ as second-order variable from $\Df$. %}
      @raise Internal_error if no basic deduction in {% $\Df$ has $X$ as variable. \highdebug %} *)
  val remove : t -> recipe_variable -> t

  (** {3 Access} *)

  (** [get] {% $\Df$~$X$ %} returns [Some] {% $\dedfact{X}{u}$ if $\dedfact{X}{u} \in \Df$, %} and returns [None] otherwise.  *)
  val get_term : t -> recipe_variable -> term

  (** {3 Function for MGS generation} *)

  type mgs_applicability =
    | Solved
    | UnifyVariables of t
    | UnsolvedFact of basic_fact * t * bool (* [true] when there were also unification of variables *)

  (** [compute_mgs_applicability] {% $\Df$ %} checks the states of the set of
      basic deduction facts for mgs generation. In particular, when basic deduction Facts
      have the same variable as right hand them, the function unify the recipe
      variables associated. When some unification was found and/or when an unsolved
      basic fact have been found, the function also returns the set of basic facts
      in which we already removed the basic facts that were unified. *)
  val compute_mgs_applicability : t -> mgs_applicability
end

(** {2 {% The set of deduction facts \texorpdfstring{$\Solved$}{SDF} %}}*)

(** The theoretical knowledge base from the paper has been split into two
    sets. The knowledge base and incremented knowledge base. The latter represents
    the deduction facts that corresponding to the latest axiom. The former
    are thus the deduction facts corresponding to previous axiom. *)

module K : sig

  (** The type represents the set of solved deduction formulas that will be used in constraint systems, {% i.e. $\Solved$. %} *)
  type t

  (** The empty set *)
  val empty : t
end

module IK : sig

  (** The type represents the set of solved deduction formulas that will be used in constraint systems, {% i.e. $\Solved$. %} *)
  type t

  (** The empty set *)
  val empty : t
end

(** {2 {% The set of unsolved formulas \texorpdfstring{$\USolved$}{UF} %}}*)

module UF : sig

  type t

  (** {3 Generation} *)

  (** The empty set {% $\USolved$ %} *)
  val empty : t

  (** [add_equality] {% $\USolved$~$\psi$%} [id] returns the set {% $\USolved \cup \{ \psi\}$. Note that we associate to $\psi$ the recipe equivalent id%} [id]. *)
  val add_equality_formula : t -> equality_formula -> t

  val add_equality_fact : t -> equality_fact -> t

  (** [add_deduction] {% $\USolved$~$[\psi_1;\ldots;\psi_n]$ %} [id] returns the set {% $\USolved \cup \{ \psi_1,\ldots, \psi_n\}$. Note that we associate to $\psi_1,\ldots, \psi_n$ the same recipe equivalent id%} [id]. *)
  val add_deduction_formulas : t -> deduction_formula list -> t

  val add_deduction_fact : t -> deduction_fact -> t

  (** [filter fct UF p] returns the set with all the [fct] formulas in [UF] that satisfy predicate [p]. *)
  val filter_unsolved : t -> (deduction_formula -> bool) -> t

  val remove_one_deduction_fact : t -> t

  val remove_equality_fact : t -> t

  val remove_one_unsolved_equality_formula : t -> t

  val remove_one_unsolved_deduction_formula : t -> t

  val replace_deduction_facts : t -> deduction_fact list -> t

  (** {3 Access} *)

  val pop_deduction_fact :  t -> deduction_fact

  val pop_deduction_fact_option :  t -> deduction_fact option

  val pop_equality_fact_option : t -> equality_fact option

  val pop_deduction_formula_option :  t -> deduction_formula option

  val pop_equality_formula_option : t -> equality_formula option

  val number_of_deduction_facts : t -> int

  (** {3 Testing} *)

  val exists_equality_fact : t -> bool

  val exists_deduction_fact : t -> bool

  (** [solved_solved fct UF] checks if at least one unsolved [fct] formula in [UF] occurs. *)
  val exists_unsolved_equality_formula : t -> bool
end
