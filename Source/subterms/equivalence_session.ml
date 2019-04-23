open Term
open Display
open Process_session


(* a status of symbolic processes. Four possible values: empty, forall, exists,
or both. *)
module QStatus : sig
  type t
  val na : t (* no status attributed *)
  val forall : t (* the forall status *)
  val exists : t (* the exists status *)
  val both : t (* the forall and exists statuses *)
  val subsumes : t -> t -> bool (* checks whether status s1 subsumes s2 *)
  val upgrade : t -> t -> t (* gathers two statuses *)
end
= struct
  include Set.Make(struct type t = bool let compare = compare end)
  let na = empty
  let forall = of_list [true]
  let exists = of_list [false]
  let both = of_list [true;false]
  let subsumes s1 s2 = subset s2 s1
  let upgrade = union
end

type constraint_system = symbolic_process Constraint_system.t
and constraint_system_set = symbolic_process Constraint_system.Set.t
and symbolic_process = {
  origin_process : side;
  conf : configuration;
  mutable next_transitions : (label * bool * constraint_system) list; (* the list of transitions from the process, including the label and the constraint system obtained after normalisation.
  NB. the boolean is set to false when the transition is only used for existential purposes *)
  mutable status : QStatus.t (* indicates what kind of transitions have already been generated *)
}

let new_symbolic_process (origin_process:side) (conf:configuration) : symbolic_process = {
  origin_process = origin_process;
  conf = conf;
  next_transitions = [];
  status = QStatus.na;
}



type matching_exists_forall = symbolic_process * (symbolic_process * bijection_set) list
type matchings = matching_exists_forall list

type partition_tree_node = {
  csys_set : constraint_system_set;
  matching : matchings;
  previous_blocks : block list;
  ongoing_block : block;
  size_frame : int
}




let generate_next_transitions_forall (size_frame:int) (cs:constraint_system) : unit =
  let symp = Constraint_system.get_additional_data cs in
  let generate () =
    match next_transition_to_apply symp.conf with
    | None -> ()
    | Some RNeg ->
      let ax = Axiom.create (size_frame+1) in
      begin match symp.conf.sure_output_proc with
      | [] -> Config.internal_error "[process_session.ml >> generate_next_transitions_forall] Unexpected case."
      | h :: t ->
        let ((ch,term,p),lab,new_output_proc) =
          match unfold_output ~at_most:1 [h] with
          | [(od,lab,[x])] -> (od,lab,x)
          | _ -> Config.internal_error "[process_session.ml >> generate_next_transitions_forall] unfold_output generated an unexpected result." in
        let conf = {symp.conf with
          sure_output_proc = t;
          to_normalise = Some new_output_proc;
          trace = OutAction(ch,ax,term)::symp.conf.trace;
        } in
        let eqn = Constraint_system.get_substitution_solution Protocol cs in
        normalise_configuration conf eqn (fun gather conf_norm ->
          let t0 = Subst.apply gather.equations term (fun x f -> f x) in

          try
            let cs1 =
              Constraint_system.apply_substitution cs gather.equations in
            let cs2 =
              Constraint_system.add_axiom cs1 ax (Rewrite_rules.normalise t0) in
            let cs3 =
              Constraint_system.add_disequations cs2 gather.disequations in
            let cs4 =
              Constraint_system.replace_additional_data cs3 {symp with conf = conf_norm} in

            symp.next_transitions <- (lab,true,cs4) :: symp.next_transitions
          with
            | Constraint_system.Bot -> ()
        ) end
    | Some RFocus -> ()
    | Some RPos -> () in

  if not (QStatus.subsumes symp.status QStatus.forall) then (
    generate();
    symp.status <- QStatus.upgrade symp.status QStatus.forall
  )



(* TODO. THE BIG FUNCTION *)
let generate_next_transitions (m:matchings) : matchings =
  todo


(* a type representing the potential next transitions of a configuration *)
type next_transitions =
  | Pos of label (* executing an already-focused input *)
  | Focus of (label * symbol) list (* focusing an input *)
  | Neg of label * symbol (* executing an output *)

(* generating universally-quantified next transitions *)
let next_transitions_universal (c:configuration) : next_transitions =
  match c.focused_proc with
  | Some {label = None; _} ->
    Config.internal_error "[process_session.ml >> next_transitions_universal] Unexpected case: labels should have been assigned."
  | Some {label = Some l; _} -> Pos l
  | None ->
    match c.sure_output_proc with
    | [] ->
      let label_and_channel p =
        match p with
        | {label = Some l; proc = Input(ch,_,_)} -> l,ch
        | _ -> Config.internal_error "[process_session.ml >> next_transitions_universal] Unexpected case." in
      Focus (List.rev_map (fun (p,_) -> label_and_channel p) (unfold_input ~allow_channel_renaming:true c.input_proc))
    | l ->
      match unfold_output ~at_most:1 l with
      | ((ch,t,p),lab,new_config) :: [] -> Neg (lab,ch)
      | _ -> Config.internal_error "[process_session.ml >> next_transitions_universal] unfold_process returned an unexpected result."

(* generating the next transitions matching the transitions generated by the
previous function. If next_trans_univ is of the form
- Pos l => this function will return either the empty list or a [Pos l']
- Focus [l1;...;ln] => this function will return a list [Focus ll1;...;Focus lln] where lli is the set of labels matching li
- Neg l => this function will return [Neg l1;...;Neg ln] where the li are the
labels matching l. *)
let next_transitions_existential (next_trans_univ:next_transitions) (c:configuration) (bs:bijection_set) : next_transitions list =
  match next_trans_univ with
  | Pos lab ->
    begin match c.focused_proc with
    | None -> []
    | Some {label = Some lab'; _} ->
      Config.debug (fun () ->
        if not (LabelSet.mem lab' (get_compatible_labels lab bs)) then
          Config.internal_error "[process_session.ml >> next_transitions_existential] Inconsistent focus spotted.");
      [Pos lab']
    | Some {label = None; _} ->
      Config.internal_error "[process_session.ml >> next_transitions_existential] Unexpected case: labels should have been assigned." end
  | Focus l ->
    List.map (fun (lab,ch) ->
      let compatibility = get_compatible_labels ~origin:Left lab bs in
      let same_skel p =
        match p with
        | {label = None; proc = _} ->
          Config.internal_error "[process_session.ml >> next_transitions_existential] Unexpected case: labels should have been assigned."
        | {proc = Input(cc,_,_); label = Some lab'} ->
          Symbol.is_equal ch cc && LabelSet.mem lab' compatibility
        | _ -> false in
      let label_and_channel p =
        match p with
        | {label = Some l; proc = Input(ch,_,_)} -> l,ch
        | _ -> Config.internal_error "[process_session.ml >> next_transitions_existential] Unexpected case." in
      let focus_ch =
        unfold_input ~filter:same_skel ~allow_channel_renaming:false c.input_proc in
      Focus (List.map (fun (p,_) -> label_and_channel p) focus_ch)
    ) l
  | Neg (lab,ch) ->
    let compatibility = get_compatible_labels ~origin:Left lab bs in
    let same_skel p =
      match p with
      | {label = None; proc = _} ->
        Config.internal_error "[process_session.ml >> next_transitions_existential] Unexpected case: labels should have been assigned."
      | {proc = OutputSure(cc,_,_); label = Some lab'} ->
        Symbol.is_equal ch cc && LabelSet.mem lab' compatibility
      | _ -> false in

    let l = unfold_output ~filter:same_skel c.input_proc in
    List.map (fun ((ch,t,p),lab,new_conf) -> Neg(lab,ch)) l






let init_partition_tree (csys_set:symbolic_process Constraint_system.Set.t) (m:matchings) : partition_tree_node = {
  csys_set = csys_set;
  matching = m;
  previous_blocks = [];
  ongoing_block = create_block initial_label;
  size_frame = 0
}


type result_analysis =
  | Equivalent
  | Not_Equivalent of constraint_system

exception Not_Session_Equivalent of constraint_system


(* a type to model the result of skeleton checks *)
type skeleton_check =
  | OK of configuration * configuration * bijection_set
  | Faulty of side * configuration * action
  | Improper


(* TODO DOUBLE CHECK THESE TWO FUNCTIONS *)

let final_test_on_nodes_start (f_cont:partition_tree_node->(unit->unit)->unit) (initial_node:partition_tree_node) (csys_set:constraint_system_set) (f_next:unit->unit) : unit =
  if Constraint_system.Set.is_empty csys_set then f_next ()
  else
    let csys_set_1 =
      Constraint_system.Set.optimise_snd_ord_recipes csys_set in
    Config.debug (fun () ->
      let csys = Constraint_system.Set.choose csys_set_1 in
      let same_origin csys' =
        (Constraint_system.get_additional_data csys).origin_process = (Constraint_system.get_additional_data csys').origin_process in
      if Constraint_system.Set.for_all same_origin csys_set_1 then
        Config.internal_error "[equivalence_session.ml >> final_test_on_nodes_start] Unexpected case, equivalence should not be violated after only normalising the two processes."
    );
    let (csys_left, csys_right) =
      Constraint_system.Set.find_representative csys_set (fun csys' ->
        (Constraint_system.get_additional_data csys').origin_process = Left
      ) in
    let sleft = Constraint_system.get_additional_data csys_left in
    let sright = Constraint_system.get_additional_data csys_right in
    let bs_init =
      match initial_node.matching with
      | [_,[_,bs]] -> bs
      | _ -> Config.internal_error "[equivalence_session.ml >> final_test_on_nodes_start] Unexpected case: matching of a bad form." in

    (** skeleton test **)
    let skel_test =
      try
        let bs_upd =
          check_skeleton_in_configuration 0 sleft.conf sright.conf bs_init in
        try
          OK(release_skeleton sleft.conf,release_skeleton sright.conf,bs_upd)
        with Improper_block -> Improper
      with Faulty_skeleton(side,conf,action) -> Faulty(side,conf,action) in

    (** final operations depending on the result of the test **)
    match skel_test with
    | Improper -> f_next ()
    | OK (conf_left, conf_right,bset) ->
      let csys_left =
        Constraint_system.replace_additional_data csys_left {sleft with conf = conf_left } in
      let csys_right =
        Constraint_system.replace_additional_data csys_right {sright with conf = conf_right} in
      let csys_set_upd =
        Constraint_system.Set.of_list [csys_left; csys_right] in
      f_cont {initial_node with csys_set = csys_set_upd} f_next
    | Faulty (side,f_conf,f_action) ->
      let (wit_csys, symb_proc) =
        if side = Left then csys_left, sleft
        else csys_right, sright in
      let eqn =
        Constraint_system.get_substitution_solution Protocol wit_csys in
      begin match f_action with
      | OutAction(_,ax,t) ->
        let wit_csys_1 =
          Constraint_system.add_axiom wit_csys ax (Subst.apply eqn t (fun x f -> f x)) in
        let wit_csys_2 =
          Constraint_system.replace_additional_data wit_csys_1 { symb_proc with conf = f_conf } in
        raise (Not_Session_Equivalent wit_csys_2)
      | InAction(_,var_X,t) ->
        let ded_fact_term = BasicFact.create var_X t in
        let wit_csys_1 =
          Constraint_system.add_basic_fact wit_csys ded_fact_term in
        let wit_csys_2 =
          Constraint_system.replace_additional_data wit_csys_1 { symb_proc with conf = f_conf } in
        raise (Not_Session_Equivalent wit_csys_2)
      end


let normalise_and_split_start (node:partition_tree_node) (f_cont:partition_tree_node->(unit->unit)->'a) (f_next:unit->unit) : unit =

  (** normalisation of the configurations **)
  let initial_csys_set = ref Constraint_system.Set.empty in
  Constraint_system.Set.iter (fun csys ->
    let symb_proc = Constraint_system.get_additional_data csys in
    let eqn = Constraint_system.get_substitution_solution Protocol csys in

    normalise_configuration symb_proc.conf eqn (fun gathering conf ->
      try
        let csys_1 =
          Constraint_system.apply_substitution csys gathering.equations in
        let csys_2 =
          Constraint_system.add_disequations csys_1 gathering.disequations in
        let csys_3 =
          Constraint_system.replace_additional_data csys_2 {symb_proc with conf = conf} in

        initial_csys_set := Constraint_system.Set.add csys_3 !initial_csys_set
      with
        | Constraint_system.Bot -> ()
    )
  ) node.csys_set;
  let initial_csys_set = !initial_csys_set in (* to get rid of the reference *)


  (** Resolution of the constraints using the constraint solver **)

  Constraint_system.Rule.apply_rules_after_input false (final_test_on_nodes_start f_cont node) initial_csys_set f_next



let equivalence_by_session (conf1:configuration) (conf2:configuration) : result_analysis =

  (* Initialisation of the rewrite system *)

  Rewrite_rules.initialise_skeletons ();
  Data_structure.Tools.initialise_constructor ();

  (* Generate the initial constraint systems
  TODO. Introduce factorisation. *)

  let sp1 = {
    origin_process = Left;
    conf = clean_inital_configuration conf1;
    next_transitions = [];
    status = QStatus.both;
  } in
  let sp2 = {
    origin_process = Right;
    conf = clean_inital_configuration conf2;
    next_transitions = [];
    status = QStatus.both;
  } in
  let csys_set_0 =
    Constraint_system.Set.of_list [
      Constraint_system.empty sp1;
      Constraint_system.empty sp2;
    ] in
  let matching0 = [
    sp1,[sp2,void_bijection_set];
    sp2,[sp1,void_bijection_set];
  ] in
  let node0 =
    init_partition_tree csys_set_0 matching0 in

  todo
