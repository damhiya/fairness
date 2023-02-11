Unset Universe Checking.
From sflib Require Import sflib.
From Paco Require Import paco.
From Fairness Require Import ITreeLib IProp IPM ModSim ModSimNat PCM Weakest Concurrency ModAdequacy.
Require Import Program.

Set Implicit Arguments.


Module WSim.
  Section WSIM.
    Variable md_src: Mod.t.
    Variable md_tgt: Mod.t.


    Context `{Σ: GRA.t}.
    Context `{MONORA: @GRA.inG monoRA Σ}.
    Context `{THDRA: @GRA.inG ThreadRA Σ}.
    Context `{IDENTSRC: @GRA.inG (identSrcRA md_src.(Mod.ident)) Σ}.
    Context `{IDENTTGT: @GRA.inG (identTgtRA md_tgt.(Mod.ident)) Σ}.
    Context `{OBLGRA: @GRA.inG ObligationRA.t Σ}.
    Context `{ARROWRA: @GRA.inG (ArrowRA md_tgt.(Mod.ident)) Σ}.
    Context `{EDGERA: @GRA.inG EdgeRA Σ}.
    Context `{ONESHOTRA: @GRA.inG (@FiniteMap.t (OneShot.t unit)) Σ}.
    Variable init_res: Σ.
    Variable SI_src : md_src.(Mod.state) -> iProp.
    Variable SI_tgt : md_tgt.(Mod.state) -> iProp.
    Hypothesis RESWF: URA.wf (init_res ⋅ (@default_initial_res _ md_src.(Mod.ident) md_tgt.(Mod.ident) _ _ _ _ _)).

    Definition initial_prop (ths: TIdSet.t) o: iProp :=
      ((FairRA.whites (fun _ => True: Prop) o)
         **
         (FairRA.blacks (fun i => match i with | inr _ => True | _ => False end: Prop))
         **
         (natmap_prop_sum ths (fun tid _ => ObligationRA.duty (inl tid) []))
         **
         (natmap_prop_sum ths (fun tid _ => own_thread tid))
         **
         (SI_src md_src.(Mod.st_init))
         **
         (SI_tgt md_tgt.(Mod.st_init)))%I
    .


    Section WHOLE_PROGRAM_SIM.
      Variable c: list (fname * Any.t).

      Definition fun_pairs :=
        (NatMapP.of_list (numbering (List.map (fun '(fn, arg) => (fn2th md_src fn arg, fn2th md_tgt fn arg)) c))).

      Record whole_sim: Prop :=
        mk_whole_sim {
            I_whole: list iProp;
            init_whole:
            exists o,
              ((initial_prop (NatMapP.of_list (numbering (List.map (fun _ => tt) c))) o) (* INIT *)
                 -∗
                 (#=>
                    ((mset_all (nth_default True%I I_whole) (topset I_whole)) (* I *)
                       **
                       (natmap_prop_sum
                          fun_pairs
                          (fun tid '(th_src, th_tgt) =>
                             stsim
                               I_whole SI_src SI_tgt tid (topset I_whole)
                               ibot5 ibot5
                               (fun r_src r_tgt => own_thread tid ** ObligationRA.duty (inl tid) [] ** ⌜r_src = r_tgt⌝)
                               th_src th_tgt)))))
          }.

      Lemma whole_sim_implies_usersim
            (SIM: whole_sim)
        :
        UserSim.sim md_src md_tgt (prog2ths md_src c) (prog2ths md_tgt c).
      Proof.
        (* just a casting *)
      Admitted.

      Lemma whole_sim_implies_refinement
            (SIM: whole_sim)
        :
        Adequacy.improves (interp_all md_src.(Mod.st_init) (prog2ths md_src c) 0)
                          (interp_all md_tgt.(Mod.st_init) (prog2ths md_tgt c) 0).
      Proof.
        eapply usersim_adequacy. eapply whole_sim_implies_usersim. auto.
      Qed.
    End WHOLE_PROGRAM_SIM.


    Section CONTEXT_SIM.
      Record context_sim: Prop :=
        mk_context_sim {
            I_ctx: list iProp;
            init_ctx:
            exists o,
              ((initial_prop TIdSet.empty o) (* INIT *)
                 -∗
                 (#=> (mset_all (nth_default True%I I_ctx) (topset I_ctx))));
            funs_ctx:
            forall tid fn arg,
              (own_thread tid)
                -∗
                (ObligationRA.duty (inl tid) [])
                -∗
                (stsim
                   I_ctx SI_src SI_tgt tid (topset I_ctx)
                   ibot5 ibot5
                   (fun r_src r_tgt => own_thread tid ** ObligationRA.duty (inl tid) [] ** ⌜r_src = r_tgt⌝)
                   (fn2th md_src fn arg) (fn2th md_tgt fn arg))
          }.

      Lemma context_sim_implies_modsim
            (SIM: context_sim)
        :
        ModSim.mod_sim md_src md_tgt.
      Proof.
        (* just a casting *)
      Admitted.

      Lemma context_sim_implies_contextual_refinement
            (SIM: context_sim)
        :
        forall p,
          Adequacy.improves (interp_all md_src.(Mod.st_init) (prog2ths md_src p) 0)
                            (interp_all md_tgt.(Mod.st_init) (prog2ths md_tgt p) 0).
      Proof.
        eapply modsim_adequacy. eapply context_sim_implies_modsim. auto.
      Qed.
    End CONTEXT_SIM.
  End WSIM.
End WSim.
