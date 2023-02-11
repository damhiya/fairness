From sflib Require Import sflib.
From Paco Require Import paco.
From Fairness Require Import PCM ITreeLib pind.
Require Import Program.
From Fairness Require Import IProp IPM.
From Fairness Require Import PCM MonotonePCM NatMapRA Mod FairBeh.

Set Implicit Arguments.

Section UPD.
  Variable A: Type.
  Context `{IN: @GRA.inG (Auth.t (Excl.t A)) Σ}.

  Lemma black_white_update a0 a' a1
    :
    (OwnM (Auth.black (Excl.just a0: @Excl.t A)))
      -∗
      (OwnM (Auth.white (Excl.just a': @Excl.t A)))
      -∗
      #=> (OwnM (Auth.black (Excl.just a1: @Excl.t A)) ** OwnM (Auth.white (Excl.just a1: @Excl.t A))).
  Proof.
    iIntros "H0 H1". iCombine "H0 H1" as "H".
    iPoseProof (OwnM_Upd with "H") as "> [H0 H1]".
    { apply Auth.auth_update.
      instantiate (1:=Excl.just a1). instantiate (1:=Excl.just a1).
      ii. des. ur in FRAME. des_ifs. split.
      { ur. ss. }
      { ur. ss. }
    }
    iModIntro. iFrame.
  Qed.

  Lemma black_white_equal a a'
    :
    (OwnM (Auth.black (Excl.just a: @Excl.t A)))
      -∗
      (OwnM (Auth.white (Excl.just a': @Excl.t A)))
      -∗
      ⌜a = a'⌝.
  Proof.
    iIntros "H0 H1". iCombine "H0 H1" as "H".
    iOwnWf "H". ur in H. des.
    rr in H. des. ur in H. des_ifs.
  Qed.
End UPD.


Section PAIR.
  Variable A: Type.
  Variable B: Type.

  Context `{IN: @GRA.inG (Auth.t (Excl.t (A * B))) Σ}.
  Context `{INA: @GRA.inG (Auth.t (Excl.t A)) Σ}.
  Context `{INB: @GRA.inG (Auth.t (Excl.t B)) Σ}.

  Definition pair_sat: iProp :=
    ∃ a b,
      (OwnM (Auth.white (Excl.just (a, b): @Excl.t (A * B))))
        **
        (OwnM (Auth.black (Excl.just a: @Excl.t A)))
        **
        (OwnM (Auth.black (Excl.just b: @Excl.t B)))
  .

  Lemma pair_access_fst a
    :
    (OwnM (Auth.white (Excl.just a: @Excl.t A)))
      -∗
      (pair_sat)
      -∗
      (∃ b, (OwnM (Auth.white (Excl.just (a, b): @Excl.t (A * B))))
              **
              (∀ a,
                  ((OwnM (Auth.white (Excl.just (a, b): @Excl.t (A * B))))
                     -*
                     #=> ((OwnM (Auth.white (Excl.just a: @Excl.t A))) ** (pair_sat))))).
  Proof.
    iIntros "H [% [% [[H0 H1] H2]]]".
    iPoseProof (black_white_equal with "H1 H") as "%". subst.
    iExists _. iFrame. iIntros (?) "H0".
    iPoseProof (black_white_update with "H1 H") as "> [H1 H]".
    iModIntro. iFrame. iExists _, _. iFrame.
  Qed.

  Lemma pair_access_snd b
    :
    (OwnM (Auth.white (Excl.just b: @Excl.t B)))
      -∗
      (pair_sat)
      -∗
      (∃ a, (OwnM (Auth.white (Excl.just (a, b): @Excl.t (A * B))))
              **
              (∀ b,
                  ((OwnM (Auth.white (Excl.just (a, b): @Excl.t (A * B))))
                     -*
                     #=> ((OwnM (Auth.white (Excl.just b: @Excl.t B))) ** (pair_sat))))).
  Proof.
    iIntros "H [% [% [[H0 H1] H2]]]".
    iPoseProof (black_white_equal with "H2 H") as "%". subst.
    iExists _. iFrame. iIntros (?) "H0".
    iPoseProof (black_white_update with "H2 H") as "> [H2 H]".
    iModIntro. iFrame. iExists _, _. iFrame.
  Qed.
End PAIR.


From Fairness Require Import FairRA.

Section INVARIANT.
  Variable state_src: Type.
  Variable state_tgt: Type.

  Variable ident_src: ID.
  Variable ident_tgt: ID.

  Definition identSrcRA: URA.t := FairRA.srct ident_src.
  Definition identTgtRA: URA.t := FairRA.tgtt ident_tgt.
  Definition ThreadRA: URA.t := Auth.t (NatMapRA.t unit).
  Definition ArrowRA: URA.t :=
    Region.t ((sum_tid ident_tgt) * nat * Ord.t * Qp * nat).
  Definition EdgeRA: URA.t :=
    Region.t (nat * nat * Ord.t).

  Context `{MONORA: @GRA.inG monoRA Σ}.
  Context `{THDRA: @GRA.inG ThreadRA Σ}.
  Context `{IDENTSRC: @GRA.inG identSrcRA Σ}.
  Context `{IDENTTGT: @GRA.inG identTgtRA Σ}.
  Context `{OBLGRA: @GRA.inG ObligationRA.t Σ}.
  Context `{ARROWRA: @GRA.inG ArrowRA Σ}.
  Context `{EDGERA: @GRA.inG EdgeRA Σ}.
  Context `{ONESHOTRA: @GRA.inG (@FiniteMap.t (OneShot.t unit)) Σ}.

  Variable SI_src : state_src -> iProp.
  Variable SI_tgt : state_tgt -> iProp.

  Definition fairI: iProp :=
    (ObligationRA.edges_sat)
      **
      (ObligationRA.arrows_sat (Id := sum_tid ident_tgt)).

  Definition default_I: TIdSet.t -> (@imap ident_src owf) -> (@imap (sum_tid ident_tgt) nat_wf) -> state_src -> state_tgt -> iProp :=
    fun ths im_src im_tgt st_src st_tgt =>
      (OwnM (Auth.black (Some ths: (NatMapRA.t unit)): ThreadRA))
        **
        (SI_src st_src)
        **
        (SI_tgt st_tgt)
        **
        (FairRA.sat_source im_src)
        **
        (FairRA.sat_target im_tgt ths)
        **
        (ObligationRA.edges_sat)
        **
        (ObligationRA.arrows_sat (Id := sum_tid ident_tgt))
  .

  Definition default_I_past (tid: thread_id): TIdSet.t -> (@imap ident_src owf) -> (@imap (sum_tid ident_tgt) nat_wf) -> state_src -> state_tgt -> iProp :=
    fun ths im_src im_tgt st_src st_tgt =>
      (∃ im_tgt0,
          (⌜fair_update im_tgt0 im_tgt (prism_fmap inlp (tids_fmap tid ths))⌝)
            ** (default_I ths im_src im_tgt0 st_src st_tgt))%I.

  Definition own_thread (tid: thread_id): iProp :=
    (OwnM (Auth.white (NatMapRA.singleton tid tt: NatMapRA.t unit): ThreadRA)).

  Lemma own_thread_unique tid0 tid1
    :
    (own_thread tid0)
      -∗
      (own_thread tid1)
      -∗
      ⌜tid0 <> tid1⌝.
  Proof.
    iIntros "OWN0 OWN1". iCombine "OWN0 OWN1" as "OWN".
    iOwnWf "OWN". ur in H. apply NatMapRA.singleton_unique in H.
    iPureIntro. auto.
  Qed.

  Lemma default_I_SI_src ths im_src im_tgt st_src st_tgt :
    default_I ths im_src im_tgt st_src st_tgt
    -∗ (SI_src st_src ∗ ∀ st_src', SI_src st_src' -∗ default_I ths im_src im_tgt st_src' st_tgt).
  Proof.
    iIntros "[[[[[[A B] C] D] E] F] G]". iFrame. auto.
  Qed.

  Lemma default_I_SI_tgt ths im_src im_tgt st_src st_tgt :
    default_I ths im_src im_tgt st_src st_tgt
    -∗ (SI_tgt st_tgt ∗ ∀ st_tgt', SI_tgt st_tgt' -∗ default_I ths im_src im_tgt st_src st_tgt').
  Proof.
    iIntros "[[[[[[A B] C] D] E] F] G]". iFrame. auto.
  Qed.

  Lemma default_I_thread_alloc ths0 im_src im_tgt0 st_src st_tgt
        tid ths1 im_tgt1
        (THS: TIdSet.add_new tid ths0 ths1)
        (TID_TGT : fair_update im_tgt0 im_tgt1 (prism_fmap inlp (fun i => if tid_dec i tid then Flag.success else Flag.emp)))
    :
    (default_I ths0 im_src im_tgt0 st_src st_tgt)
      -∗
      #=> (own_thread tid ** ObligationRA.duty (inl tid) [] ** default_I ths1 im_src im_tgt1 st_src st_tgt).
  Proof.
    unfold default_I. iIntros "[[[[[[A B] C] D] E] F] G]".
    iPoseProof (OwnM_Upd with "A") as "> [A TH]".
    { apply Auth.auth_alloc.
      eapply (@NatMapRA.add_local_update unit ths0 tid tt). inv THS. auto.
    }
    iPoseProof (FairRA.target_add_thread with "E") as "> [E BLACK]"; [eauto|eauto|].
    iModIntro. inv THS. iFrame.
    unfold ObligationRA.duty. iExists [], 1%Qp. iFrame. ss.
  Qed.

  Lemma default_I_update_ident_thread ths im_src im_tgt0 st_src st_tgt
        tid im_tgt1 l
        (UPD: fair_update im_tgt0 im_tgt1 (prism_fmap inlp (tids_fmap tid ths)))
    :
    (default_I ths im_src im_tgt0 st_src st_tgt)
      -∗
      (ObligationRA.duty (inl tid) l ** ObligationRA.tax l)
      -∗
      #=> (ObligationRA.duty (inl tid) l ** FairRA.white_thread (_Id:=_) ** default_I ths im_src im_tgt1 st_src st_tgt).
  Proof.
    unfold default_I. iIntros "[[[[[[A B] C] D] E] F] G] DUTY".
    iPoseProof (ObligationRA.target_update_thread with "E DUTY G") as "> [G [[E BLACK] WHITE]]"; [eauto|].
    iModIntro. iFrame.
  Qed.

  Lemma default_I_update_ident_target lf ls
        ths im_src im_tgt0 st_src st_tgt
        fm im_tgt1
        (UPD: fair_update im_tgt0 im_tgt1 (prism_fmap inrp fm))
        (SUCCESS: forall i (IN: fm i = Flag.success), List.In i (List.map fst ls))
        (FAIL: forall i (IN: List.In i lf), fm i = Flag.fail)
        (NODUP: List.NoDup lf)
    :
    (default_I ths im_src im_tgt0 st_src st_tgt)
      -∗
      (list_prop_sum (fun '(i, l) => ObligationRA.duty (inr i) l ** ObligationRA.tax l) ls)
      -∗
      #=> ((list_prop_sum (fun '(i, l) => ObligationRA.duty (inr i) l) ls)
             **
             (list_prop_sum (fun i => FairRA.white (Id:=_) (inr i) 1) lf)
             **
             default_I ths im_src im_tgt1 st_src st_tgt).
  Proof.
    unfold default_I. iIntros "[[[[[[A B] C] D] E] F] G] DUTY".
    iPoseProof (ObligationRA.target_update with "E DUTY G") as "> [G [[E BLACK] WHITE]]".
    { eauto. }
    { eauto. }
    { eauto. }
    { eauto. }
    iModIntro. iFrame.
  Qed.

  Lemma default_I_update_ident_source lf ls o
        ths im_src0 im_tgt st_src st_tgt
        fm
        (FAIL: forall i (IN: fm i = Flag.fail), List.In i lf)
        (SUCCESS: forall i (IN: List.In i ls), fm i = Flag.success)
    :
    (default_I ths im_src0 im_tgt st_src st_tgt)
      -∗
      (list_prop_sum (fun i => FairRA.white i Ord.one) lf)
      -∗
      #=> (∃ im_src1,
              (⌜fair_update im_src0 im_src1 fm⌝)
                **
                (list_prop_sum (fun i => FairRA.white i o) ls)
                **
                default_I ths im_src1 im_tgt st_src st_tgt).
  Proof.
    unfold default_I. iIntros "[[[[[[A B] C] D] E] F] G] WHITES".
    iPoseProof (FairRA.source_update with "D WHITES") as "> [% [[% D] WHITE]]".
    { eauto. }
    { eauto. }
    iModIntro. iExists _. iFrame. auto.
  Qed.

  Lemma arrows_sat_sub ths im_src im_tgt st_src st_tgt
    :
    ⊢ SubIProp (ObligationRA.arrows_sat (Id := sum_tid ident_tgt)) (default_I ths im_src im_tgt st_src st_tgt).
  Proof.
    iIntros "[[[[[[A B] C] D] E] F] G]". iModIntro. iFrame. auto.
  Qed.

  Lemma edges_sat_sub ths im_src im_tgt st_src st_tgt
    :
    ⊢ SubIProp (ObligationRA.edges_sat) (default_I ths im_src im_tgt st_src st_tgt).
  Proof.
    iIntros "[[[[[[A B] C] D] E] F] G]". iModIntro. iFrame. auto.
  Qed.

  Lemma default_I_past_SI_src tid ths im_src im_tgt st_src st_tgt :
    default_I_past tid ths im_src im_tgt st_src st_tgt
    -∗ (SI_src st_src ∗ ∀ st_src', SI_src st_src' -∗ default_I_past tid ths im_src im_tgt st_src' st_tgt).
  Proof.
    iIntros "[%im_tgt' [FAIR D]]".
    iPoseProof (default_I_SI_src with "D") as "[S K]".
    iFrame. iIntros (st_src') "S".
    iExists im_tgt'. iSpecialize ("K" with "S"). iFrame.
  Qed.

  Lemma default_I_past_SI_tgt tid ths im_src im_tgt st_src st_tgt :
    default_I_past tid ths im_src im_tgt st_src st_tgt
    -∗ (SI_tgt st_tgt ∗ ∀ st_tgt', SI_tgt st_tgt' -∗ default_I_past tid ths im_src im_tgt st_src st_tgt').
  Proof.
    iIntros "[%im_tgt' [FAIR D]]".
    iPoseProof (default_I_SI_tgt with "D") as "[S K]".
    iFrame. iIntros (st_tgt') "S".
    iExists im_tgt'. iSpecialize ("K" with "S"). iFrame.
  Qed.

  Lemma default_I_past_update_ident_thread ths im_src im_tgt st_src st_tgt
        tid l
    :
    (default_I_past tid ths im_src im_tgt st_src st_tgt)
      -∗
      (ObligationRA.duty (inl tid) l ** ObligationRA.tax l)
      -∗
      #=> (ObligationRA.duty (inl tid) l ** FairRA.white_thread (_Id:=_) ** default_I ths im_src im_tgt st_src st_tgt).
  Proof.
    iIntros "[% [% D]] H".
    iApply (default_I_update_ident_thread with "D H"); auto.
  Qed.

  Lemma default_I_past_update_ident_target tid lf ls
        ths im_src im_tgt0 st_src st_tgt
        fm im_tgt1
        (UPD: fair_update im_tgt0 im_tgt1 (prism_fmap inrp fm))
        (SUCCESS: forall i (IN: fm i = Flag.success), List.In i (List.map fst ls))
        (FAIL: forall i (IN: List.In i lf), fm i = Flag.fail)
        (NODUP: List.NoDup lf)
    :
    (default_I_past tid ths im_src im_tgt0 st_src st_tgt)
      -∗
      (list_prop_sum (fun '(i, l) => ObligationRA.duty (inr i) l ** ObligationRA.tax l) ls)
      -∗
      #=> ((list_prop_sum (fun '(i, l) => ObligationRA.duty (inr i) l) ls)
             **
             (list_prop_sum (fun i => FairRA.white (Id:=_) (inr i) 1) lf)
             **
             default_I_past tid ths im_src im_tgt1 st_src st_tgt).
  Proof.
    iIntros "[% [% D]] H".
    iPoseProof (default_I_update_ident_target with "D H") as "> [[H0 H1] D]"; [eauto|eauto|eauto|eauto|..].
    { instantiate (1:=(fun i =>
                         match i with
                         | inl i => im_tgt2 (inl i)
                         | inr i => im_tgt1 (inr i)
                         end)).
      ii. specialize (UPD i). specialize (H i).
      unfold prism_fmap, tids_fmap in *; ss. unfold is_inl, is_inr in *; ss. des_ifs.
      { rewrite <- H. auto. }
      { rewrite UPD. auto. }
    }
    iModIntro. iFrame.
    unfold default_I_past. iExists _. iSplit; eauto. iPureIntro.
    ii. specialize (UPD i). specialize (H i).
    unfold prism_fmap, tids_fmap in *; ss. unfold is_inl in *; ss. des_ifs.
    { rewrite UPD. auto. }
    { rewrite <- H. auto. }
  Qed.

  Lemma default_I_past_update_ident_source tid lf ls o
        ths im_src0 im_tgt st_src st_tgt
        fm
        (FAIL: forall i (IN: fm i = Flag.fail), List.In i lf)
        (SUCCESS: forall i (IN: List.In i ls), fm i = Flag.success)
    :
    (default_I_past tid ths im_src0 im_tgt st_src st_tgt)
      -∗
      (list_prop_sum (fun i => FairRA.white i Ord.one) lf)
      -∗
      #=> (∃ im_src1,
              (⌜fair_update im_src0 im_src1 fm⌝)
                **
                (list_prop_sum (fun i => FairRA.white i o) ls)
                **
                default_I_past tid ths im_src1 im_tgt st_src st_tgt).
  Proof.
    iIntros "[% [% D]] H".
    iPoseProof (default_I_update_ident_source with "D H") as "> [% [[% H] D]]"; [eauto|eauto|..].
    iModIntro. unfold default_I_past. iExists _. iSplitL "H"; auto.
  Qed.
End INVARIANT.
