From sflib Require Import sflib.
From ITree Require Export ITree.
From Paco Require Import paco.

Require Import Coq.Classes.RelationClasses.
Require Import Program.

Export ITreeNotations.

From Fairness Require Import Axioms.
From Fairness Require Export ITreeLib FairBeh FairSim NatStructs.
From Fairness Require Import pind PCM World WFLib ThreadsURA.
From Fairness Require Import Mod ModSimYOrd ModSimStid.

Set Implicit Arguments.

Section IMAPAUX1.

  Variable wf: WF.

  Definition imap_proj_id1 {id1 id2: ID} (im: @imap (id_sum id1 id2) wf): @imap id1 wf := fun i => im (inl i).
  Definition imap_proj_id2 {id1 id2: ID} (im: @imap (id_sum id1 id2) wf): @imap id2 wf := fun i => im (inr i).
  Definition imap_proj_id {id1 id2: ID} (im: @imap (id_sum id1 id2) wf): prod (@imap id1 wf) (@imap id2 wf) :=
    (imap_proj_id1 im, imap_proj_id2 im).

  Definition imap_sum_id {id1 id2: ID} (im: prod (@imap id1 wf) (@imap id2 wf)): @imap (id_sum id1 id2) wf :=
    fun i => match i with | inl il => (fst im) il | inr ir => (snd im) ir end.

  Lemma imap_sum_proj_id_inv1
        id1 id2
        (im1: @imap id1 wf)
        (im2: @imap id2 wf)
    :
    imap_proj_id (imap_sum_id (im1, im2)) = (im1, im2).
  Proof. reflexivity. Qed.

  Lemma imap_sum_proj_id_inv2
        id1 id2
        (im: @imap (id_sum id1 id2) wf)
    :
    imap_sum_id (imap_proj_id im) = im.
  Proof. extensionality i. unfold imap_sum_id. des_ifs. Qed.

End IMAPAUX1.
Global Opaque imap_proj_id1.
Global Opaque imap_proj_id2.
Global Opaque imap_sum_id.


Section IMAPAUX2.

  Variable id: ID.

  Definition imap_proj_wf1 {wf1 wf2: WF} (im: @imap id (double_rel_WF wf1 wf2)): @imap id wf1 := fun i => fst (im i).
  Definition imap_proj_wf2 {wf1 wf2: WF} (im: @imap id (double_rel_WF wf1 wf2)): @imap id wf2 := fun i => snd (im i).
  Definition imap_proj_wf {wf1 wf2: WF} (im: @imap id (double_rel_WF wf1 wf2)): prod (@imap id wf1) (@imap id wf2) :=
    (imap_proj_wf1 im, imap_proj_wf2 im).

  Definition imap_sum_wf {wf1 wf2: WF} (im: prod (@imap id wf1) (@imap id wf2)): @imap id (double_rel_WF wf1 wf2) :=
    fun i => (fst im i, snd im i).

  Lemma imap_sum_proj_wf_inv1
        wf1 wf2
        (im1: @imap id wf1)
        (im2: @imap id wf2)
    :
    imap_proj_wf (imap_sum_wf (im1, im2)) = (im1, im2).
  Proof. reflexivity. Qed.

  Lemma imap_sum_proj_wf_inv2
        wf1 wf2
        (im: @imap id (double_rel_WF wf1 wf2))
    :
    imap_sum_wf (imap_proj_wf im) = im.
  Proof.
    extensionality i. unfold imap_sum_wf, imap_proj_wf, imap_proj_wf1, imap_proj_wf2. ss. destruct (im i); ss.
  Qed.

End IMAPAUX2.
Global Opaque imap_proj_wf1.
Global Opaque imap_proj_wf2.
Global Opaque imap_sum_wf.



Section PROOF.

  Context `{M: URA.t}.

  Variable state_src: Type.
  Variable state_tgt: Type.

  Variable ident_src: ID.
  Variable _ident_tgt: ID.
  Let ident_tgt := sum_tid _ident_tgt.

  Variable wf_src: WF.
  Variable wf_tgt: WF.

  Hypothesis wf_tgt_inhabited: inhabited wf_tgt.(T).
  Hypothesis wf_tgt_open: forall (o0: wf_tgt.(T)), exists o1, wf_tgt.(lt) o0 o1.

  Let srcE := ((@eventE ident_src +' cE) +' sE state_src).
  Let tgtE := ((@eventE _ident_tgt +' cE) +' sE state_tgt).

  Let shared :=
        (TIdSet.t *
           (@imap ident_src wf_src) *
           (@imap ident_tgt wf_tgt) *
           state_src *
           state_tgt)%type.
  Let shared_rel: Type := shared -> Prop.
  Variable I: shared -> URA.car -> Prop.

  Variable wf_stt: Type -> Type -> WF.
  Variable wf_stt0: forall R0 R1, (wf_stt R0 R1).(T).


  Let ident_src2 := sum_tid ident_src.

  Let wf_src_th {R0 R1}: WF := clos_trans_WF (prod_WF (prod_WF (wf_stt R0 R1) wf_tgt) (nmo_wf (wf_stt R0 R1))).
  Let wf_src2 {R0 R1}: WF := double_rel_WF (@wf_src_th R0 R1) wf_src.

  Let srcE2 := ((@eventE ident_src2 +' cE) +' sE state_src).
  Let shared2 {R0 R1} :=
        (TIdSet.t *
           (@imap ident_src2 (@wf_src2 R0 R1)) *
           (@imap ident_tgt wf_tgt) *
           state_src *
           state_tgt)%type.
  Let shared2_rel {R0 R1}: Type := (@shared2 R0 R1) -> Prop.

  Let M2 {R0 R1}: URA.t := URA.prod (@thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)) M.

  Definition shared_thsRA {R0 R1}
             (ost: NatMap.t (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T))
    : @thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T) :=
    (fun tid => match NatMap.find tid ost with
             | Some osot => ae_black osot
             | None => ae_black (wf_stt0 R0 R1, wf_stt0 R0 R1) ⋅ ae_white (wf_stt0 R0 R1, wf_stt0 R0 R1)
             end).

  Definition Is {R0 R1}:
    (TIdSet.t * (@imap thread_id (@wf_src_th R0 R1)) * (@imap ident_tgt wf_tgt))%type ->
    (@URA.car (@thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T))) -> Prop :=
    fun '(ths, im_src, im_tgt) ths_r =>
      exists (ost: NatMap.t (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)),
        (<<WFOST: nm_wf_pair ths ost>>) /\
          (<<TRES: ths_r = shared_thsRA ost>>) /\
          (<<IMSRC: forall tid (IN: NatMap.In tid ths)
                      os ot (FIND: NatMap.find tid ost = Some (os, ot)),
              wf_src_th.(lt) ((ot, im_tgt (inl tid)), nm_proj_v1 ost) (im_src tid)>>).

  Definition I2 {R0 R1}: (@shared2 R0 R1) -> (@URA.car (@M2 R0 R1)) -> Prop :=
    fun '(ths, im_src, im_tgt, st_src, st_tgt) '(ths_r, r) =>
      (<<INV: I (ths, imap_proj_wf2 (imap_proj_id2 im_src), im_tgt, st_src, st_tgt) r>>) /\
        (<<INVS: Is (ths, (imap_proj_wf1 (imap_proj_id1 im_src)), im_tgt) ths_r>>).


  Lemma shared_thsRA_th_has_wf_find
        tid
        R0 R1
        ost os ot
        (ctx_r: (@thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)))
        (VALS: URA.wf ((shared_thsRA ost) ⋅ (th_has tid (os, ot)) ⋅ ctx_r))
    :
    NatMap.find tid ost = Some (os, ot).
  Proof.
    ur in VALS. specialize (VALS tid). eapply URA.wf_mon in VALS.
    unfold shared_thsRA in VALS. rewrite th_has_hit in VALS.
    des_ifs.
    - ur in VALS. des. rewrite URA.unit_idl in VALS.
      unfold URA.extends in VALS. des. ur in VALS. des_ifs.
    - rewrite <- URA.add_assoc in VALS. rewrite URA.add_comm in VALS. eapply URA.wf_mon in VALS.
      ur in VALS. ur in VALS. ss.
  Qed.

  Lemma shared_thsRA_th_has_wf_update
        tid
        R0 R1
        ost os ot
        (ctx_r: (@thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)))
        (VALS: URA.wf ((shared_thsRA ost) ⋅ (th_has tid (os, ot)) ⋅ ctx_r))
        os1 ot1
    :
    URA.wf ((shared_thsRA (NatMap.add tid (os1, ot1) ost)) ⋅ (th_has tid (os1, ot1)) ⋅ ctx_r).
  Proof.
    hexploit shared_thsRA_th_has_wf_find; eauto. intro FIND.
    ur. ur in VALS. i. specialize (VALS k).
    destruct (tid_dec k tid); clarify.
    - rewrite th_has_hit in *. unfold shared_thsRA in *.
      rewrite nm_find_add_eq. rewrite FIND in VALS.
      ur. ur in VALS. des_ifs. des. split.
      + rewrite URA.unit_idl in VALS. unfold URA.extends in *. des.
        r_solve. ss. exists ctx. ur in VALS. ur. des_ifs.
      + ur. ss.
    - rewrite th_has_miss in *; auto. rewrite URA.unit_id in VALS. r_solve.
      unfold shared_thsRA in *. rewrite nm_find_add_neq; auto.
  Qed.

  Lemma shared_thsRA_th_has_wf_wf_pair
        tid
        R0 R1
        (ths: TIdSet.t)
        ost os ot
        (ctx_r: (@thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)))
        (VALS: URA.wf ((shared_thsRA ost) ⋅ (th_has tid (os, ot)) ⋅ ctx_r))
        (WFP: nm_wf_pair ths ost)
        os1 ot1
    :
    nm_wf_pair ths (NatMap.add tid (os1, ot1) ost).
  Proof.
    replace ths with (NatMap.add tid tt ths). apply nm_wf_pair_add; auto.
    apply nm_eq_is_equal. ii. destruct (tid_dec y tid); clarify.
    2:{ rewrite nm_find_add_neq; auto. }
    rewrite nm_find_add_eq. symmetry.
    destruct (NatMap.find tid ths) eqn:FIND; ss. destruct u; auto.
    hexploit shared_thsRA_th_has_wf_find. eapply VALS. i.
    hexploit nm_wf_pair_find_cases; eauto. i; des. eapply H0 in FIND.
    ss. clarify.
  Qed.


  Lemma local_RR_impl
        tid
        R0 R1 (RR: R0 -> R1 -> Prop)
        ths
        (im_src: @imap ident_src2 (@wf_src2 R0 R1))
        (im_tgt: @imap ident_tgt wf_tgt)
        st_src st_tgt r_ctx
        r0 r1
        (LRR: ModSimYOrd.local_RR I RR tid r0 r1 r_ctx (ths, imap_proj_wf2 (imap_proj_id2 im_src), im_tgt, st_src, st_tgt))
        (ths_r ctx_r: (@thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)))
        os ot
        (INVS: Is (ths, (imap_proj_wf1 (imap_proj_id1 im_src)), im_tgt) ths_r)
        (VALS: URA.wf (ths_r ⋅ (th_has tid (os, ot)) ⋅ ctx_r))
    :
    ModSimStid.local_RR I2 RR tid r0 r1 (ctx_r, r_ctx) (ths, im_src, im_tgt, st_src, st_tgt).
  Proof.
    unfold ModSimYOrd.local_RR in LRR. des. unfold local_RR.
    unfold Is in INVS. des. set (ost':=NatMap.remove tid ost).
    clarify. esplits; eauto.
    - instantiate (1:=(ε, r_own)). instantiate (1:=(shared_thsRA ost', r_shared)).
      ur. split; auto. hexploit shared_thsRA_th_has_wf_find; eauto. intro FIND.
      r_solve. ur. ur in VALS. i. specialize (VALS k).
      destruct (tid_dec k tid); clarify.
      + rewrite th_has_hit in VALS. unfold shared_thsRA in *.
        subst ost'. rewrite nm_find_rm_eq. rewrite FIND in VALS.
        ur. ur in VALS. des_ifs. des. split.
        * rewrite URA.unit_idl in VALS. unfold URA.extends in *. des.
          r_solve. ss. exists ctx. ur in VALS. ur. des_ifs.
        * ur. ss.
      + rewrite th_has_miss in VALS; auto. rewrite URA.unit_id in VALS.
        unfold shared_thsRA in *. subst ost'. rewrite nm_find_rm_neq; auto.

    - unfold I2. splits; auto. unfold Is. exists ost'. splits; auto.
      { subst ost'. eapply nm_wf_pair_rm; auto. }
      i. specialize (IMSRC tid0). destruct (tid_dec tid0 tid); clarify.
      { exfalso. apply NatMap.remove_1 in IN; auto. }
      hexploit IMSRC; clear IMSRC.
      { eapply NatMapP.F.remove_neq_in_iff; eauto. }
      { subst ost'. rewrite nm_find_rm_neq in FIND; eauto. }
      i. ss. eapply clos_trans_n1_trans. 2: eapply H.
      econs 1. econs 2. auto.
      subst ost'. econs. instantiate (1:=tid).
      { unfold nm_proj_v1. rewrite <- nm_map_rm_comm_eq. rewrite nm_find_rm_eq.
        assert (FINDOST: NatMap.find tid ost = Some (os, ot)).
        { eapply shared_thsRA_th_has_wf_find. eapply VALS. }
        rewrite NatMapP.F.map_o. rewrite FINDOST. ss. econs.
      }
      { i. unfold nm_proj_v1. rewrite <- nm_map_rm_comm_eq. rewrite nm_find_rm_neq; auto. }
  Qed.


  Let St: wf_tgt.(T) -> wf_tgt.(T) := fun o0 => @epsilon _ wf_tgt_inhabited (fun o1 => wf_tgt.(lt) o0 o1).
  Let lt_succ_diag_r_tgt: forall (t: wf_tgt.(T)), wf_tgt.(lt) t (St t).
  Proof.
    i. unfold St. hexploit (@epsilon_spec _ wf_tgt_inhabited (fun o1 => wf_tgt.(lt) t o1)); eauto.
  Qed.

  Lemma yord_implies_stid
        tid
        R0 R1 (RR: R0 -> R1 -> Prop)
        ths
        (im_src: @imap ident_src2 (@wf_src2 R0 R1))
        (im_tgt: @imap ident_tgt wf_tgt)
        st_src st_tgt
        ps pt r_ctx src tgt
        os ot
        (LSIM: ModSimYOrd.lsim I wf_stt tid (ModSimYOrd.local_RR I RR tid)
                               ps pt r_ctx (os, src) (ot, tgt)
                               (ths, imap_proj_wf2 (imap_proj_id2 im_src), im_tgt, st_src, st_tgt))
        (ths_r ctx_r: (@thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)))
        (INVS: Is (ths, (imap_proj_wf1 (imap_proj_id1 im_src)), im_tgt) ths_r)
        (VALS: URA.wf (ths_r ⋅ (th_has tid (os, ot)) ⋅ ctx_r))
    :
    ModSimStid.lsim I2 tid (ModSimStid.local_RR I2 RR tid) ps pt (ctx_r, r_ctx) src tgt
                    (ths, im_src, im_tgt, st_src, st_tgt).
  Proof.
    revert_until R1. pcofix CIH; i.
    match type of LSIM with ModSimYOrd.lsim _ _ _ ?_LRR0 _ _ _ ?_osrc ?_otgt ?_shr => remember _LRR0 as LRR0 in LSIM; remember _osrc as osrc; remember _otgt as otgt; remember _shr as shr end.
    move LSIM before CIH. punfold LSIM. revert_until LSIM.
    revert LRR0 ps pt r_ctx osrc otgt shr LSIM.
    pinduction 7. i. clear LE. clarify.
    rename x1 into ps, x2 into pt, x3 into r_ctx, PR into LSIM.
    eapply pind9_unfold in LSIM; eauto with paco.
    rename INVS into INVS0; assert (INVS:Is (ths, (imap_proj_wf1 (imap_proj_id1 im_src)), im_tgt) ths_r).
    { auto. }
    clear INVS0.
    inv LSIM.

    { pfold. eapply pind9_fold. econs 1. eapply local_RR_impl; eauto. }

    { pfold. eapply pind9_fold. econs 2; eauto.
      split; [|ss]. destruct LSIM0 as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto.
    }
    { pfold. eapply pind9_fold. econs 3; eauto.
      des. exists x.
      split; [|ss]. destruct LSIM0 as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto.
    }
    { pfold. eapply pind9_fold. econs 4; eauto.
      split; [|ss]. destruct LSIM0 as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto.
    }
    { pfold. eapply pind9_fold. econs 5; eauto.
      split; [|ss]. destruct LSIM0 as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto.
    }
    { pfold. eapply pind9_fold. econs 6; eauto.
      split; [|ss]. destruct LSIM0 as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto.
    }
    { pfold. eapply pind9_fold. econs 7; eauto. }

    { pfold. eapply pind9_fold. econs 8; eauto.
      des.
      exists (fun idx => match idx with
                 | inl t => im_src (inl t)
                 | inr i => (imap_proj_wf1 (imap_proj_id2 im_src) i, im_src1 i)
                 end).
      esplits.
      { clear - FAIR. ii. destruct i; ss. specialize (FAIR i). des_ifs.
        - replace (im_src (inr i)) with (imap_proj_wf1 (imap_proj_id2 im_src) i, imap_proj_wf2 (imap_proj_id2 im_src) i).
          econs; auto. rewrite <- (imap_sum_proj_wf_inv2 im_src). ss.
        - rewrite FAIR. rewrite <- (imap_sum_proj_wf_inv2 im_src). ss.
      }
      split; [|ss]. destruct LSIM as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto.
    }

    { pfold. eapply pind9_fold. econs 9; eauto.
      split; [|ss]. destruct LSIM0 as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto.
    }
    { pfold. eapply pind9_fold. econs 10; eauto.
      i. specialize (LSIM0 x).
      split; [|ss]. destruct LSIM0 as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto.
    }
    { pfold. eapply pind9_fold. econs 11; eauto.
      split; [|ss]. destruct LSIM0 as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto.
    }
    { pfold. eapply pind9_fold. econs 12; eauto.
      split; [|ss]. destruct LSIM0 as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto.
    }
    { pfold. eapply pind9_fold. econs 13; eauto.
      split; [|ss]. destruct LSIM0 as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto.
    }

    { pfold. eapply pind9_fold. econs 14; eauto.
      i. specialize (LSIM0 _ FAIR).
      split; [|ss]. destruct LSIM0 as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto.
      clear - FAIR INVS. unfold Is in INVS. des. esplits; eauto. i. hexploit IMSRC; eauto; i.
      replace (im_tgt1 (inl tid)) with (im_tgt (inl tid)); auto.
      clear - FAIR. specialize (FAIR (inl tid)). ss.
    }

    { pfold. eapply pind9_fold. econs 15; eauto.
      i. specialize (LSIM0 ret). pclearbot.
      right. eapply CIH; eauto.
    }

    { pfold. eapply pind9_fold. econs 16; eauto.
      des. unfold Is in INVS. des. subst.
      set (ost':= NatMap.add tid (os1, ot1) ost).
      assert (WFOST': nm_wf_pair ths ost').
      { eapply shared_thsRA_th_has_wf_wf_pair; eauto. }
      exists (fun idx => match idx with
                 | inl t =>
                     if (NatMapP.F.In_dec ths t)
                     then match (NatMap.find t ost') with
                          | None => im_src (inl t)
                          | Some (_, ot) => (((ot, im_tgt (inl t)), nm_proj_v1 ost), snd (im_src (inl t)))
                          end
                     else im_src (inl t)
                 | inr i => im_src (inr i)
                 end).
      splits.
      { clear - LT IMSRC VALS WFOST WFOST'.
        ii. destruct i; ss. destruct (tids_fmap tid ths n) eqn:FM; auto.
        - unfold tids_fmap in FM. destruct (Nat.eq_dec n tid) eqn:EQ; ss. destruct (NatMapP.F.In_dec ths n) eqn:INDEC; ss.
          des_ifs.
          2:{ exfalso. eapply NatMapP.F.in_find_iff; eauto.
              apply nm_wf_pair_sym in  WFOST'. eapply nm_wf_pair_find_cases in WFOST'. des.
              eapply WFOST' in Heq. auto.
          }
          hexploit IMSRC; clear IMSRC.
          3:{ instantiate (1:=n). instantiate (1:=t0). i.
              rewrite surjective_pairing. econs. ss.
          }
          auto.
          subst ost'. rewrite nm_find_add_neq in Heq; eauto.
        - unfold tids_fmap in FM. destruct (Nat.eq_dec n tid) eqn:EQ; ss. destruct (NatMapP.F.In_dec ths n) eqn:INDEC; ss.
      }

      split; [|ss]. destruct LSIM as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto. instantiate (1:=shared_thsRA ost').
      - exists ost'; splits; auto.
        clear - LT IMSRC VALS WFOST WFOST'. subst.
        i. econs 1.
        Local Transparent imap_proj_id1 imap_proj_wf1. unfold imap_proj_id1, imap_proj_wf1.
        Local Opaque imap_proj_id1 imap_proj_wf1.
        des_ifs. ss. econs 2; auto. econs. instantiate (1:=tid).
        + unfold nm_proj_v1. rewrite !NatMapP.F.map_o.
          replace (NatMap.find tid ost) with (Some (os, ot)).
          subst ost'. rewrite nm_find_add_eq. ss. econs. auto.
          symmetry. eapply shared_thsRA_th_has_wf_find; eauto.
        + i. unfold nm_proj_v1. rewrite !NatMapP.F.map_o. subst ost'. rewrite nm_find_add_neq; auto.
      - eapply shared_thsRA_th_has_wf_update; eauto.
    }

    { pfold. eapply pind9_fold. econs 17; eauto. instantiate (1:=(ths_r, r_shared)).
      { split; auto. }
      instantiate (1:=(tid |-> (os, ot) , r_own)).
      { ur. auto. }
      clear - LSIM0 IH; i. unfold I2 in INV. destruct r_shared1 as [shared_r r_shared], r_ctx1 as [ctx_r r_ctx].
      ur in VALID. des. specialize (LSIM0 _ _ _ _ _ _ _ INV0 VALID0 _ TGT). des.
      unfold Is in INVS. des. subst. set (ost':= NatMap.add tid (os1, ot1) ost). clarify.
      assert (WFOST': nm_wf_pair ths1 ost').
      { eapply shared_thsRA_th_has_wf_wf_pair; eauto. }
      split; [|ss]. destruct LSIM as [LSIM IND].
      eapply IH in IND. punfold IND.
      { ii. eapply pind9_mon_gen; eauto. ii. eapply __lsim_mon; eauto. }
      all: eauto. instantiate (1:=shared_thsRA ost').

      - exists ost'. splits; auto. i. specialize (IMSRC _ IN). destruct (tid_dec tid0 tid); clarify.
        + hexploit IMSRC. eapply shared_thsRA_th_has_wf_find; eauto.
          i. subst ost'. rewrite nm_find_add_eq in FIND. clarify.
          eapply clos_trans_n1_trans. 2: eapply H. econs 1. econs 1. econs 1. auto.
        + subst ost'. rewrite nm_find_add_neq in FIND; auto.
          hexploit IMSRC. eauto. i.
          eapply clos_trans_n1_trans. 2: eapply H. econs 1. econs 1. econs 2; auto.
          clear - n IN TGT. specialize (TGT (inl tid0)). ss. unfold tids_fmap in TGT. des_ifs.
      - eapply shared_thsRA_th_has_wf_update; eauto.
    }

    { pfold. eapply pind9_fold. econs 18; eauto. instantiate (1:=(ths_r, r_shared)).
      { split; auto. }
      instantiate (1:=(tid |-> (os, ot) , r_own)).
      { ur. auto. }
      revert LSIM0. clear_upto IH. i.
      unfold I2 in INV. destruct r_shared1 as [shared_r r_shared], r_ctx1 as [ctx_r r_ctx].
      ur in VALID. des. specialize (LSIM0 _ _ _ _ _ _ _ INV0 VALID0 _ TGT). des.
      unfold Is in INVS. des. subst. set (ost':= NatMap.add tid (os1, ot1) ost).
      assert (WFOST': nm_wf_pair ths1 ost').
      { eapply shared_thsRA_th_has_wf_wf_pair; eauto. }
      exists (fun idx => match idx with
                 | inl t =>
                     if (tid_dec t tid)
                     then (((ot1, St (im_tgt2 (inl t))), nm_proj_v1 ost), snd (im_src1 (inl t)))
                     else
                       if (NatMapP.F.In_dec ths1 t)
                       then match (NatMap.find t ost') with
                            | None => im_src1 (inl t)
                            | Some (_, ot) => (((ot, im_tgt1 (inl t)), nm_proj_v1 ost), snd (im_src1 (inl t)))
                            end
                       else im_src1 (inl t)
                 | inr i => im_src1 (inr i)
                 end).
      splits.

      { clear - IMSRC VALID TGT WFOST WFOST'.
        ii. destruct i; ss. destruct (tids_fmap tid ths1 n) eqn:FM; auto.
        - unfold tids_fmap in FM. destruct (Nat.eq_dec n tid) eqn:EQ; ss. destruct (NatMapP.F.In_dec ths1 n) eqn:INDEC; ss.
          des_ifs.
          2:{ exfalso. eapply NatMapP.F.in_find_iff; eauto.
              apply nm_wf_pair_sym in  WFOST'. eapply nm_wf_pair_find_cases in WFOST'. des.
              eapply WFOST' in Heq. auto.
          }
          hexploit IMSRC; clear IMSRC.
          3:{ instantiate (1:=n). instantiate (1:=t0). i.
              rewrite surjective_pairing. econs. ss.
          }
          auto.
          subst ost'. rewrite nm_find_add_neq in Heq; eauto.
        - unfold tids_fmap in FM. destruct (Nat.eq_dec n tid) eqn:EQ; ss. destruct (NatMapP.F.In_dec ths1 n) eqn:INDEC; ss.
          des_ifs.
      }

      pclearbot. right. eapply CIH. eauto.
      instantiate (1:=shared_thsRA ost').
      - exists ost'; splits; auto.
        revert IMSRC VALID TGT WFOST WFOST'. clear_upto tid. i. subst.
        i. econs 1.
        Local Transparent imap_proj_id1 imap_proj_wf1. unfold imap_proj_id1, imap_proj_wf1.
        Local Opaque imap_proj_id1 imap_proj_wf1.
        des_ifs; ss.
        + subst ost'. rewrite nm_find_add_eq in FIND. clarify. econs 1. econs 2; auto.
        + rewrite FIND in Heq. clarify. econs 1. econs 2; auto.
          clear - n IN TGT. specialize (TGT (inl tid0)). ss. unfold tids_fmap in TGT. des_ifs.
        + rewrite FIND in Heq. ss.
      - eapply shared_thsRA_th_has_wf_update; eauto.
    }

    { pfold. eapply pind9_fold. econs 19; eauto. pclearbot. right. eapply CIH; eauto. }

  Qed.

  Lemma init_src_inv
        tid
        R0 R1
        ths
        (im_src1: @imap ident_src2 (@wf_src2 R0 R1))
        (im_tgt1 im_tgt2: @imap ident_tgt wf_tgt)
        (ths_r ctx_r: (@thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)))
        os ot
        (INVS: Is (ths, (imap_proj_wf1 (imap_proj_id1 im_src1)), im_tgt1) ths_r)
        (VALS: URA.wf (ths_r ⋅ (th_has tid (os, ot)) ⋅ ctx_r))
        (TGT: fair_update im_tgt1 im_tgt2 (sum_fmap_l (tids_fmap tid ths)))
    :
    exists im_src2,
      (<<SRC: fair_update im_src1 im_src2 (sum_fmap_l (tids_fmap tid ths))>>) /\
        (<<INVS: Is (ths, (imap_proj_wf1 (imap_proj_id1 im_src2)), im_tgt2) ths_r>>).
  Proof.
    unfold Is in INVS. des.
    exists (fun idx => match idx with
               | inl t =>
                   if (tid_dec t tid)
                   then (((ot, St (im_tgt2 (inl t))), nm_proj_v1 ost), snd (im_src1 (inl t)))
                   else
                     if (NatMapP.F.In_dec ths t)
                     then match (NatMap.find t ost) with
                          | None => im_src1 (inl t)
                          | Some (_, ot) =>
                              (((ot, im_tgt1 (inl t)), nm_proj_v1 ost), snd (im_src1 (inl t)))
                          end
                     else im_src1 (inl t)
               | inr i => im_src1 (inr i)
               end).
    splits.

    - ii. destruct i; ss. unfold tids_fmap. destruct (Nat.eq_dec n tid) eqn:EQT; clarify.
      destruct (NatMapP.F.In_dec ths n) eqn:INT; ss; clarify.
      2:{ des_ifs; ss. }
      clear EQT INT.
      destruct (NatMap.find n ost) eqn:FIND.
      2:{ exfalso. eapply NatMapP.F.in_find_iff in i.
          eapply nm_wf_pair_sym in WFOST. hexploit nm_wf_pair_find_cases; eauto. i. des.
          eapply H in FIND; clarify.
      }
      des_ifs. specialize (IMSRC _ i _ _ FIND). rewrite surjective_pairing. econs 1.
      eapply IMSRC.

    - exists ost. splits; auto. subst. i.
      Local Transparent imap_proj_id1 imap_proj_wf1. unfold imap_proj_id1, imap_proj_wf1.
      Local Opaque imap_proj_id1 imap_proj_wf1.
      des_ifs.
      + ss. hexploit shared_thsRA_th_has_wf_find. eapply VALS. intro FIND2.
        ss; rewrite FIND in FIND2; clarify.
        econs 1. econs 1. econs 2; auto.
      + ss. econs 1. econs 1. econs 2; auto. clear - n i TGT.
        specialize (TGT (inl tid0)). ss. unfold tids_fmap in TGT. des_ifs.
  Qed.

End PROOF.

Section MODSIM.

  Lemma yord_implies_stid_mod
        md_src md_tgt
        (MDSIM: ModSimYOrd.ModSim.mod_sim md_src md_tgt)
    :
    ModSimStid.ModSim.mod_sim md_src md_tgt.
  Proof.
    inv MDSIM.
    set (ident_src := Mod.ident md_src). set (_ident_tgt := Mod.ident md_tgt).
    set (state_src := Mod.state md_src). set (state_tgt := Mod.state md_tgt).
    set (srcE := ((@eventE ident_src +' cE) +' sE state_src)).
    set (tgtE := ((@eventE _ident_tgt +' cE) +' sE state_tgt)).
    set (ident_tgt := @ident_tgt _ident_tgt).
    set (shared := (TIdSet.t * (@imap ident_src wf_src) * (@imap ident_tgt wf_tgt) * state_src * state_tgt)%type).
    set (ident_src2 := sum_tid ident_src).
    set (wf_src_th := fun R0 R1 => clos_trans_WF (prod_WF (prod_WF (wf_stt R0 R1) wf_tgt) (nmo_wf (wf_stt R0 R1)))).
    set (wf_src2 := fun R0 R1 => double_rel_WF (@wf_src_th R0 R1) wf_src).
    set (I2 := fun R0 R1 => (I2 I wf_stt wf_stt0 (R0:=R0) (R1:=R1))). ss.
    set (M2 := fun R0 R1 => URA.prod (@thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)) world).
    eapply (@ModSim.mk _ _ (wf_src2 Val Val) _ wf_tgt_inhabited wf_tgt_open (M2 Val Val) (I2 Val Val)).
    { i. move init after im_tgt. specialize (init im_tgt). des.
      (*TODO*)
      exists (fun ti => match ti with
                | inl t => (((wf_stt0 Val Val, im_tgt (inl t)), NatMap.empty), )
                | inr i => im_src i
                end).
         
    
    econs.
    { instantiate (1:= fun ti => match ti with
                               | inl t => 


    1,2: eauto. instantiate (1:=wf_src2 Val Val). instantiate (1:=I2 Val Val).
    { i. exact (inr None). }
    i. specialize (funs fn args). des_ifs.
    unfold ModSim.local_sim in funs.
    ii. specialize (funs _ _ _ _ _ _ _ INV tid _ THS VALID _ UPD).
    des. do 2 eexists. exists (inr None), (inr None). splits. 1,2: eauto.
    i. specialize (funs1 _ _ _ _ _ _ _ INV1 VALID1 _ TGT fs ft).
    eapply modsim_implies_yord in funs1. des.
    ginit. guclo lsim_ord_weakRC_spec. econs. guclo lsim_ord_weakLC_spec. econs.
    gfinal. right. eapply funs1.
    - clear. destruct os.
      { right. econs. }
      destruct t.
      { right. do 2 econs. }
      { left. auto. }
    - clear. destruct ot.
      { right. econs. }
      destruct t.
      { right. do 2 econs. }
      { left. auto. }
  Qed.

End MODSIM.
